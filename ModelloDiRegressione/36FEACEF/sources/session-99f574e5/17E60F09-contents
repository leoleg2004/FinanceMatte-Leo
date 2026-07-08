# ==============================================================================
# MODELLO 8: FRONTIERA EFFICIENTE DI MARKOWITZ (DINAMICA N-ASSET)
# ==============================================================================

library(DBI)
library(RMariaDB)
library(ggplot2)
library(dplyr)
library(tidyr)

# --- CONFIGURAZIONI ---
# Puoi aggiungere, rimuovere o modificare i ticker qui. Il codice si adatterà in automatico!
PORTFOLIO_ETFS <- c("VWCE.DE", "SXRV.DE", "ZPRR.DE")

# Assicurati che i pesi corrispondano esattamente al numero di ETF scelti sopra 
# e che la somma faccia sempre 1.0.
TUO_PORTAFOGLIO_PESI <- c(0.60, 0.20, 0.20) 

RISK_FREE_RATE <- 0.03 # Tasso privo di rischio stimato al 3% annuo

if(length(PORTFOLIO_ETFS) != length(TUO_PORTAFOGLIO_PESI)) {
  stop("ERRORE: Il numero di ETF non corrisponde al numero di pesi assegnati!")
}
if(abs(sum(TUO_PORTAFOGLIO_PESI) - 1) > 1e-6) {
  stop("ERRORE: La somma dei pesi del tuo portafoglio deve fare 1.0!")
}

cat("1. Estrazione dati dal Database...\n")
con <- tryCatch({
  dbConnect(RMariaDB::MariaDB(), dbname = "PortfolioDB", host = "127.0.0.1", user = "root", password = "Root1234!")
}, error = function(e) stop("ERRORE CRITICO DB"))

ticker_list <- paste(sprintf("'%s'", PORTFOLIO_ETFS), collapse = ",")
dataset_grezzo <- dbGetQuery(con, sprintf("
SELECT a.ticker as Ticker, p.price_date as Date, p.close_price as Price
FROM Asset_Historical_Prices p
JOIN Assets a ON p.isin = a.isin
WHERE a.ticker IN (%s)
ORDER BY p.price_date ASC;
", ticker_list))
dbDisconnect(con)

# Allineamento mensile
dataset_mensile <- dataset_grezzo %>%
  mutate(Date = as.Date(Date), YearMonth = format(Date, "%Y-%m")) %>%
  group_by(Ticker, YearMonth) %>% slice_tail(n = 1) %>% ungroup() %>%
  dplyr::select(Date, Ticker, Price) %>%
  pivot_wider(names_from = Ticker, values_from = Price) %>%
  arrange(Date)

# Statistiche (mu e sigma su massimi storici disponibili)
n_assets <- length(PORTFOLIO_ETFS)
mu_mensile <- numeric(n_assets)
sigma_mensile <- numeric(n_assets)
names(mu_mensile) <- PORTFOLIO_ETFS
names(sigma_mensile) <- PORTFOLIO_ETFS

for(i in 1:n_assets) {
  ticker <- PORTFOLIO_ETFS[i]
  dati_singolo <- dataset_mensile[[ticker]]
  dati_singolo <- dati_singolo[!is.na(dati_singolo)]
  rend_singolo <- log(dati_singolo[-1] / dati_singolo[-length(dati_singolo)])
  mu_mensile[i] <- mean(rend_singolo)
  sigma_mensile[i] <- sd(rend_singolo)
}

# Correlazioni (sui soli dati allineati)
rendimenti_allineati <- dataset_mensile %>%
  drop_na() %>%
  dplyr::select(all_of(PORTFOLIO_ETFS)) %>%
  mutate(across(everything(), ~ log(. / lag(.)))) %>%
  drop_na()

Cor_matrix <- cor(rendimenti_allineati)

# Annualizzazione
mu_annuo <- mu_mensile * 12
sigma_annuo <- sigma_mensile * sqrt(12)
Sigma_annua <- diag(sigma_annuo) %*% Cor_matrix %*% diag(sigma_annuo)
rownames(Sigma_annua) <- PORTFOLIO_ETFS
colnames(Sigma_annua) <- PORTFOLIO_ETFS

cat(sprintf("2. Generazione Frontiera Dinamica su %d Asset...\n", n_assets))
N_PORT <- 20000
set.seed(123)

pesi_casuali <- matrix(runif(N_PORT * n_assets), ncol = n_assets)
pesi_casuali <- t(apply(pesi_casuali, 1, function(x) x / sum(x)))

# Aggiungiamo i vertici (portafogli 100% su un singolo asset) per precisione grafica
vertici <- diag(1, n_assets)
pesi_casuali <- rbind(pesi_casuali, vertici)
N_PORT <- nrow(pesi_casuali)

port_returns <- as.vector(pesi_casuali %*% mu_annuo)
port_volatility <- numeric(N_PORT)

for(i in 1:N_PORT) {
  w <- pesi_casuali[i, ]
  port_volatility[i] <- sqrt(as.numeric(t(w) %*% Sigma_annua %*% w))
}

port_sharpe <- (port_returns - RISK_FREE_RATE) / port_volatility

df_markowitz <- data.frame(
  Rendimento = port_returns,
  Volatilita = port_volatility,
  Sharpe = port_sharpe
)

# --- Calcolo del Tuo Portafoglio (Personalizzato) ---
tuo_rendimento <- sum(TUO_PORTAFOGLIO_PESI * mu_annuo)
tuo_volatilita <- sqrt(as.numeric(t(TUO_PORTAFOGLIO_PESI) %*% Sigma_annua %*% TUO_PORTAFOGLIO_PESI))

etichetta_custom_pesi <- paste(round(TUO_PORTAFOGLIO_PESI * 100), collapse="/")
etichetta_custom <- sprintf("Il tuo Mix (%s)", etichetta_custom_pesi)

tuo_port_df <- data.frame(
  Rendimento = tuo_rendimento,
  Volatilita = tuo_volatilita,
  Label = etichetta_custom
)

# --- Ottimo Markowitz ---
idx_max_sharpe <- which.max(df_markowitz$Sharpe)
port_opt <- df_markowitz[idx_max_sharpe, ]
pesi_ottimi <- pesi_casuali[idx_max_sharpe, ]


# ==============================================================================
# STAMPA A SCHERMO DINAMICA
# ==============================================================================
cat("\n=========================================================================\n")
cat("   1) PUNTO PIÙ EFFICIENTE (MAX SHARPE RATIO MATEMATICO)\n")
cat("=========================================================================\n")
cat(sprintf("Rendimento Atteso (Annuo): %.2f%%\n", port_opt$Rendimento * 100))
cat(sprintf("Rischio (Volatilità Annua): %.2f%%\n", port_opt$Volatilita * 100))
cat("Per massimizzare i profitti e minimizzare lo stress, l'algoritmo distribuisce così:\n")
for(i in 1:n_assets) {
  cat(sprintf("-> %s: %.1f%%\n", PORTFOLIO_ETFS[i], pesi_ottimi[i] * 100))
}
cat("=========================================================================\n")

cat("\n=========================================================================\n")
cat(sprintf("   2) COME HAI DIVISO IL TUO PORTAFOGLIO (%s)\n", etichetta_custom_pesi))
cat("=========================================================================\n")
cat(sprintf("Rendimento Atteso (Annuo): %.2f%%\n", tuo_rendimento * 100))
cat(sprintf("Rischio (Volatilità Annua): %.2f%%\n", tuo_volatilita * 100))
cat("Pesi da te scelti:\n")
for(i in 1:n_assets) {
  cat(sprintf("-> %s: %.1f%%\n", PORTFOLIO_ETFS[i], TUO_PORTAFOGLIO_PESI[i] * 100))
}
cat("\n")

diff_rend <- (port_opt$Rendimento - tuo_rendimento) * 100
diff_rischio <- (tuo_volatilita - port_opt$Volatilita) * 100

if(diff_rend > 0 && diff_rischio > 0) {
  cat(sprintf("-> CONFRONTO: Rispetto all'allocazione ottima, stai PERDENDO il %.2f%% di rendimento annuo\n", diff_rend))
  cat(sprintf("              e stai SUBENDO il %.2f%% di rischio (oscillazioni) in più!\n", diff_rischio))
} else if (diff_rend > 0 && diff_rischio <= 0) {
  cat(sprintf("-> CONFRONTO: Guadagneresti il %.2f%% in più all'anno con la composizione ottima,\n", diff_rend))
  cat(sprintf("              ma la tua attuale scelta ha un rischio leggermente inferiore (%.2f%%).\n", abs(diff_rischio)))
} else {
  cat("-> CONFRONTO: Il tuo portafoglio è matematicamente perfetto e sfiora l'efficienza assoluta!\n")
}
cat("=========================================================================\n")


# ==============================================================================
# GENERAZIONE GRAFICO
# ==============================================================================
cat("\n3. Generazione Scatterplot Dinamico...\n")

grafico_markowitz <- ggplot(df_markowitz, aes(x = Volatilita, y = Rendimento, color = Sharpe)) +
  geom_point(alpha = 0.5, size = 1.5) +
  scale_color_viridis_c(option = "plasma", name = "Sharpe Ratio") +
  
  # Punto Ottimo
  geom_point(data = port_opt, aes(x = Volatilita, y = Rendimento), color = "green", size = 6, shape = 18) +
  annotate("text", x = port_opt$Volatilita, y = port_opt$Rendimento, 
           label = "PUNTO OTTIMO", vjust = -1.5, color = "darkgreen", fontface="bold") +
           
  # Il tuo portafoglio
  geom_point(data = tuo_port_df, aes(x = Volatilita, y = Rendimento), color = "cyan", size = 5, shape = 17) +
  annotate("text", x = tuo_port_df$Volatilita, y = tuo_port_df$Rendimento, 
           label = tuo_port_df$Label, vjust = 1.5, color = "cyan4", fontface="bold") +
           
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  scale_x_continuous(labels = scales::percent_format(accuracy = 1)) +
  labs(
    title = sprintf("Frontiera Efficiente Dinamica (%d Asset)", n_assets),
    subtitle = "Ottimizzazione di Markowitz Algoritmica",
    x = "Rischio (Volatilità Annualizzata)",
    y = "Rendimento Atteso Annualizzato"
  ) +
  theme_minimal() +
  theme(legend.position = "right")

print(grafico_markowitz)
cat("Grafico multi-asset generato con successo! Controlla i Plots in RStudio.\n")

