# ==============================================================================
# MODELLO 7: CONFRONTO ASSETTI E FRONTIERA DEL RISCHIO (CHOLESKY)
# ==============================================================================
# Obiettivo: Testare 4 configurazioni di portafoglio diverse utilizzando
# gli stessi scenari stocastici (PAC, TER, Inflazione e Correlazione Cholesky)
# per individuare il portafoglio più "efficiente".

library(DBI)
library(RMariaDB)
library(ggplot2)
library(dplyr)
library(tidyr)
library(MASS)

# --- CONFIGURAZIONI ---
PORTFOLIO_ETFS <- c("VWCE.DE", "IGLN.L", "USO")

portafogli <- list(
  "1_Baseline_60_20_20"    = c(0.60, 0.20, 0.20),
  "2_Aggressivo_100_Azioni" = c(1.00, 0.00, 0.00),
  "3_Conservativo_40_40_20"  = c(0.40, 0.40, 0.20),
  "4_Equilibrato_34_33_33"   = c(0.34, 0.33, 0.33)
)

CAPITALE_INIZIALE <- 10000
VERSAMENTO_MENSILE <- 500
TER_ANNUO <- 0.0020
INFLAZIONE_ANNUA <- 0.02
MESI_FUTURI <- 120
N_SIMULAZIONI <- 1000

# --- 1. ESTRAZIONE DATI ---
cat("1. Connessione al DB e Download Dati...\n")
con <- tryCatch({
  dbConnect(RMariaDB::MariaDB(), dbname = "PortfolioDB", host = "127.0.0.1", user = "root", password = "Root1234!")
}, error = function(e) {
  stop("ERRORE CRITICO: Impossibile connettersi al Database MySQL.")
})

ticker_list <- paste(sprintf("'%s'", PORTFOLIO_ETFS), collapse = ",")
query <- sprintf("
SELECT a.ticker as Ticker, p.price_date as Date, p.close_price as Price
FROM Asset_Historical_Prices p
JOIN Assets a ON p.isin = a.isin
WHERE a.ticker IN (%s)
ORDER BY p.price_date ASC;
", ticker_list)
dataset_grezzo <- dbGetQuery(con, query)
dbDisconnect(con)

# Allineamento mensile CON TUTTI I DATI
dataset_mensile <- dataset_grezzo %>%
  mutate(Date = as.Date(Date), YearMonth = format(Date, "%Y-%m")) %>%
  group_by(Ticker, YearMonth) %>% slice_tail(n = 1) %>% ungroup() %>%
  dplyr::select(Date, Ticker, Price) %>%
  pivot_wider(names_from = Ticker, values_from = Price) %>%
  arrange(Date)

# 1. Calcolo di mu e sigma sui MAXIMI STORICI INDIVIDUALI
mu <- numeric(length(PORTFOLIO_ETFS))
sigma <- numeric(length(PORTFOLIO_ETFS))
names(mu) <- PORTFOLIO_ETFS
names(sigma) <- PORTFOLIO_ETFS

for(i in 1:length(PORTFOLIO_ETFS)) {
  ticker <- PORTFOLIO_ETFS[i]
  # Estrae la colonna ignorando i NA
  dati_singolo <- dataset_mensile[[ticker]]
  dati_singolo <- dati_singolo[!is.na(dati_singolo)]
  
  # Calcola rendimenti
  rend_singolo <- log(dati_singolo[-1] / dati_singolo[-length(dati_singolo)])
  
  mu[i] <- mean(rend_singolo)
  sigma[i] <- sd(rend_singolo)
}

# 2. Calcolo Matrice Correlazione sui Dati ALLINEATI
rendimenti_allineati <- dataset_mensile %>%
  drop_na() %>%
  dplyr::select(all_of(PORTFOLIO_ETFS)) %>%
  mutate(across(everything(), ~ log(. / lag(.)))) %>%
  drop_na()

Cor_matrix <- cor(rendimenti_allineati)

# 3. Sintesi Nuova Matrice di Covarianza
Sigma <- diag(sigma) %*% Cor_matrix %*% diag(sigma)
rownames(Sigma) <- PORTFOLIO_ETFS
colnames(Sigma) <- PORTFOLIO_ETFS

L <- t(chol(Sigma))

prezzi_attuali <- numeric(length(PORTFOLIO_ETFS))
names(prezzi_attuali) <- PORTFOLIO_ETFS
for(ticker in PORTFOLIO_ETFS) {
  dati_validi <- dataset_mensile[[ticker]][!is.na(dataset_mensile[[ticker]])]
  prezzi_attuali[ticker] <- tail(dati_validi, 1)
}
ter_mensile <- TER_ANNUO / 12

# --- 2. LOOP SUI PORTAFOGLI ---
cat("2. Avvio Simulazioni Comparate...\n\n")

risultati_df <- data.frame()

for (nome_port in names(portafogli)) {
  pesi <- portafogli[[nome_port]]
  
  cat(sprintf("-> Simulo: %s\n", nome_port))
  
  # Usiamo un seed fisso in modo che ogni portafoglio affronti gli STESSI IDENTICI
  # 1.000 scenari stocastici, permettendo un confronto perfetto.
  set.seed(42)
  
  prezzi_finali_reali <- numeric(N_SIMULAZIONI)
  
  for(sim in 1:N_SIMULAZIONI) {
    percorso_prezzi <- matrix(0, nrow = MESI_FUTURI + 1, ncol = length(PORTFOLIO_ETFS))
    percorso_prezzi[1, ] <- prezzi_attuali
    
    quote_correnti <- (CAPITALE_INIZIALE * pesi) / prezzi_attuali
    # Per evitare divisioni per zero sui portafogli al 100% (che hanno peso zero su alcuni ETF)
    quote_correnti[is.na(quote_correnti)] <- 0
    quote_correnti[is.infinite(quote_correnti)] <- 0
    
    valore_nom <- CAPITALE_INIZIALE
    valore_reale <- CAPITALE_INIZIALE
    
    X <- matrix(rnorm(length(PORTFOLIO_ETFS) * MESI_FUTURI), nrow = length(PORTFOLIO_ETFS), ncol = MESI_FUTURI)
    Z <- L %*% X
    
    for(t_step in 1:MESI_FUTURI) {
      for(i in 1:length(PORTFOLIO_ETFS)) {
        if(pesi[i] > 0 || quote_correnti[i] > 0) {
          S_t <- percorso_prezzi[t_step, i]
          drift <- mu[i] - 0.5 * Sigma[i, i]
          shock <- Z[i, t_step]
          
          P_nuovo <- S_t * exp(drift + shock)
          percorso_prezzi[t_step + 1, i] <- P_nuovo
          
          # PAC
          nuove_quote <- (VERSAMENTO_MENSILE * pesi[i]) / P_nuovo
          quote_correnti[i] <- quote_correnti[i] + nuove_quote
          
          # TER
          quote_correnti[i] <- quote_correnti[i] * (1 - ter_mensile)
        } else {
          # Se l'asset non è in portafoglio, portiamo avanti il prezzo a zero
          percorso_prezzi[t_step + 1, i] <- percorso_prezzi[t_step, i]
        }
      }
      
      # Calcolo Nominale
      valore_nom <- sum(quote_correnti * percorso_prezzi[t_step + 1, ])
      
      # Sconto Inflazione
      sconto_inflazione <- (1 + INFLAZIONE_ANNUA)^(t_step / 12)
      valore_reale <- valore_nom / sconto_inflazione
    }
    
    prezzi_finali_reali[sim] <- valore_reale
  }
  
  # Estrazione metriche per il portafoglio
  mediana_reale <- median(prezzi_finali_reali)
  perc_05 <- quantile(prezzi_finali_reali, 0.05)
  cvar_reale <- mean(prezzi_finali_reali[prezzi_finali_reali < perc_05])
  volatilita_reale <- sd(prezzi_finali_reali) # Deviazione standard (Rischio CAPM)
  
  # Aggiunta ai risultati
  risultati_df <- rbind(risultati_df, data.frame(
    Portafoglio = nome_port,
    Mediana_Reale = mediana_reale,
    CVaR_5_Reale = cvar_reale,
    Volatilita_Reale = volatilita_reale
  ))
}

# --- 3. OUTPUT E GRAFICO ---
cat("\n=========================================================================\n")
cat("   RISULTATI CONFRONTO (POTERE D'ACQUISTO REALE A 10 ANNI)\n")
cat("=========================================================================\n")
print(risultati_df %>% mutate(
  Mediana_Reale = format(round(Mediana_Reale, 2), big.mark = ".", decimal.mark = ","),
  CVaR_5_Reale = format(round(CVaR_5_Reale, 2), big.mark = ".", decimal.mark = ","),
  Volatilita_Reale = format(round(Volatilita_Reale, 2), big.mark = ".", decimal.mark = ",")
))
cat("=========================================================================\n\n")

cat("3. Generazione Grafico CAPM / Markowitz...\n")
grafico_frontiera <- ggplot(risultati_df, aes(x = Volatilita_Reale, y = Mediana_Reale, color = Portafoglio, label = Portafoglio)) +
  geom_point(size = 6) +
  geom_text(vjust = -1.5, fontface = "bold") +
  # Aggiungiamo una linea stilizzata che simula la Capital Market Line (CML)
  geom_abline(intercept = CAPITALE_INIZIALE, slope = (max(risultati_df$Mediana_Reale) - CAPITALE_INIZIALE) / max(risultati_df$Volatilita_Reale), 
              color = "darkgray", linetype = "dashed", alpha = 0.6) +
  scale_y_continuous(labels = scales::label_comma(big.mark = ".", decimal.mark = ",")) +
  scale_x_continuous(labels = scales::label_comma(big.mark = ".", decimal.mark = ",")) +
  labs(
    title = "Modello CAPM / Frontiera di Markowitz",
    subtitle = "Asse X: Rischio (Volatilità). Asse Y: Rendimento Atteso (Mediana).",
    x = "Rischio (Deviazione Standard del Capitale in €)",
    y = "Rendimento (Capitale Mediano Atteso in €)"
  ) +
  theme_minimal() +

    theme(legend.position = "none")

print(grafico_frontiera)
cat("Confronto completato con successo!\n")

