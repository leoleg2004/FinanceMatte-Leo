# ==============================================================================
# MODELLO 6: MULTI-FATTORIALE CON DECOMPOSIZIONE DI CHOLESKY
# ==============================================================================
# Questo script non simula un singolo asset, ma un portafoglio diversificato.
# Estrae i dati storici, calcola la matrice di covarianza reale e utilizza
# l'algebra lineare (Cholesky) per generare shock casuali Z correlati.
# In questo modo, le simulazioni rispettano la vera "fisica" del mercato
# (es: quando l'azionario crolla, l'oro sale secondo la sua correlazione storica).

PORTFOLIO_ETFS <- c("VWCE.DE", "IGLN.L", "USO")   # Azionario, Oro, Petrolio
PORTFOLIO_PESI <- c(1.0,      0.0,     0.0)    # Pesi
CAPITALE_INIZIALE <- 10000
VERSAMENTO_MENSILE <- 0  # PAC mensile
TER_ANNUO <- 0.0020        # Costo di gestione (0.20%)
INFLAZIONE_ANNUA <- 0.02   # Inflazione (2.0%)
MESI_FUTURI <- 120
N_SIMULAZIONI <- 1000

library(DBI)
library(RMariaDB)
library(ggplot2)
library(dplyr)
library(tidyr)
library(MASS)

if(sum(PORTFOLIO_PESI) != 1) stop("Errore: I pesi devono sommare a 1.0")

# --- 1. ESTRAZIONE DATI ---
cat("1. Connessione al DB e Download Dati...\n")
con <- tryCatch({
  dbConnect(RMariaDB::MariaDB(), dbname = "PortfolioDB", host = "127.0.0.1", user = "root", password = "Root1234!")
}, error = function(e) {
  stop("ERRORE CRITICO: Impossibile connettersi al Database MySQL. Verifica che il server sia acceso e le credenziali corrette.")
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

if(nrow(dataset_grezzo) == 0) {
  stop("ERRORE: La query non ha restituito dati. Controlla che i Ticker siano corretti e presenti nel DB.")
}

# Allineamento mensile CON TUTTI I DATI (lasciando NA)
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

# 2. Calcolo Matrice Correlazione sui Dati ALLINEATI (dove esistono tutti e tre)
rendimenti_allineati <- dataset_mensile %>%
  drop_na() %>%
  dplyr::select(all_of(PORTFOLIO_ETFS)) %>%
  mutate(across(everything(), ~ log(. / lag(.)))) %>%
  drop_na()

Cor_matrix <- cor(rendimenti_allineati)

cat("\n--- MATRICE DI CORRELAZIONE STORICA (Empirica) ---\n")
print(Cor_matrix)
cat("--------------------------------------------------\n\n")

# 3. Sintesi Nuova Matrice di Covarianza (Cov = Cor * vol * vol)
cat("2. Sintesi Matrice di Covarianza sui Massimi Storici Individuali...\n")
Sigma <- diag(sigma) %*% Cor_matrix %*% diag(sigma)
rownames(Sigma) <- PORTFOLIO_ETFS
colnames(Sigma) <- PORTFOLIO_ETFS

L <- t(chol(Sigma)) 

# # --- 3. SIMULAZIONE MONTE CARLO (PAC, TER, INFLAZIONE) ---
cat("3. Esecuzione Simulazione Finanziaria Reale (1.000 Universi)...\n")

prezzi_finali_reali <- numeric(N_SIMULAZIONI)
risultati_simulazioni_reali <- list()
tutti_z_correlati <- list()

valori_tutte_sim_reali <- matrix(0, nrow = N_SIMULAZIONI, ncol = MESI_FUTURI + 1)
valori_tutte_sim_nominali <- matrix(0, nrow = N_SIMULAZIONI, ncol = MESI_FUTURI + 1)

prezzi_attuali <- numeric(length(PORTFOLIO_ETFS))
names(prezzi_attuali) <- PORTFOLIO_ETFS
for(ticker in PORTFOLIO_ETFS) {
  dati_validi <- dataset_mensile[[ticker]][!is.na(dataset_mensile[[ticker]])]
  prezzi_attuali[ticker] <- tail(dati_validi, 1)
}

ter_mensile <- TER_ANNUO / 12

for(sim in 1:N_SIMULAZIONI) {
  percorso_prezzi <- matrix(0, nrow = MESI_FUTURI + 1, ncol = length(PORTFOLIO_ETFS))
  percorso_prezzi[1, ] <- prezzi_attuali
  
  # Quote correnti all'istante t=0
  quote_correnti <- (CAPITALE_INIZIALE * PORTFOLIO_PESI) / prezzi_attuali
  
  percorso_valore_nom <- numeric(MESI_FUTURI + 1)
  percorso_valore_reale <- numeric(MESI_FUTURI + 1)
  
  percorso_valore_nom[1] <- CAPITALE_INIZIALE
  percorso_valore_reale[1] <- CAPITALE_INIZIALE
  
  X <- matrix(rnorm(length(PORTFOLIO_ETFS) * MESI_FUTURI), nrow = length(PORTFOLIO_ETFS), ncol = MESI_FUTURI)
  Z <- L %*% X
  
  if(sim <= 100) { 
    tutti_z_correlati[[sim]] <- t(Z)
  }
  
  for(t_step in 1:MESI_FUTURI) {
    for(i in 1:length(PORTFOLIO_ETFS)) {
      S_t <- percorso_prezzi[t_step, i]
      drift <- mu[i] - 0.5 * Sigma[i, i]
      shock <- Z[i, t_step]
      
      P_nuovo <- S_t * exp(drift + shock)
      percorso_prezzi[t_step + 1, i] <- P_nuovo
      
      # 1. Investimento PAC (Acquisto nuove quote al P_nuovo)
      nuove_quote <- (VERSAMENTO_MENSILE * PORTFOLIO_PESI[i]) / P_nuovo
      quote_correnti[i] <- quote_correnti[i] + nuove_quote
      
      # 2. Prelevamento TER (Riduzione delle quote)
      quote_correnti[i] <- quote_correnti[i] * (1 - ter_mensile)
    }
    
    # Valore Nominale del portafoglio al tempo t_step
    valore_nom <- sum(quote_correnti * percorso_prezzi[t_step + 1, ])
    percorso_valore_nom[t_step + 1] <- valore_nom
    
    # Valore Reale (Scontato per Inflazione)
    sconto_inflazione <- (1 + INFLAZIONE_ANNUA)^(t_step / 12)
    percorso_valore_reale[t_step + 1] <- valore_nom / sconto_inflazione
  }
  
  valori_tutte_sim_nominali[sim, ] <- percorso_valore_nom
  valori_tutte_sim_reali[sim, ] <- percorso_valore_reale
  prezzi_finali_reali[sim] <- tail(percorso_valore_reale, 1)
  
  if(sim <= 100) {
    risultati_simulazioni_reali[[sim]] <- data.frame(
      Mese = 0:MESI_FUTURI,
      Simulazione = as.factor(sim),
      Valore = percorso_valore_reale
    )
  }
}

df_plot <- do.call(rbind, risultati_simulazioni_reali)

# Calcolo percentili FUNZIONALI (sul Valore REALE)
percentili_nel_tempo <- data.frame(
  Mese = 0:MESI_FUTURI,
  P_05 = apply(valori_tutte_sim_reali, 2, quantile, probs = 0.05),
  P_50 = apply(valori_tutte_sim_reali, 2, quantile, probs = 0.50),
  P_95 = apply(valori_tutte_sim_reali, 2, quantile, probs = 0.95)
)

# --- 4. OUTPUT STATISTICO (POTERE D'ACQUISTO) ---
totale_versato <- CAPITALE_INIZIALE + (VERSAMENTO_MENSILE * MESI_FUTURI)
perc_05_nominale <- quantile(valori_tutte_sim_nominali[, MESI_FUTURI + 1], 0.05)
perc_50_nominale <- quantile(valori_tutte_sim_nominali[, MESI_FUTURI + 1], 0.50)

perc_05_reale <- quantile(prezzi_finali_reali, 0.05)
perc_50_reale <- quantile(prezzi_finali_reali, 0.50)
perc_95_reale <- quantile(prezzi_finali_reali, 0.95)
cvar_5_reale <- mean(prezzi_finali_reali[prezzi_finali_reali < perc_05_reale])

cat("=========================================================================\n")
cat("   STATISTICHE GLOBALI PORTAFOGLIO (Al netto di Inflazione e Costi)\n")
cat("=========================================================================\n")
cat(sprintf("Capitale Totale Versato (PIC + PAC): € %.2f\n", totale_versato))
cat(sprintf("Costo Bancario Medio Annuo (TER):    %.2f%%\n", TER_ANNUO * 100))
cat(sprintf("Inflazione Media Annua Simulata:     %.2f%%\n\n", INFLAZIONE_ANNUA * 100))
cat("--- RISULTATI NOMINALI (Quello che vedrai sul conto) ---\n")
cat(sprintf("5° Percentile Nominale:            € %.2f\n", perc_05_nominale))
cat(sprintf("50° Percentile Nominale (Mediano): € %.2f\n\n", perc_50_nominale))
cat("--- RISULTATI REALI (Il vero potere d'acquisto) ---\n")
cat(sprintf("5° Percentile (Scenario Pessimo):  € %.2f\n", perc_05_reale))
cat(sprintf("50° Percentile (Scenario Mediano): € %.2f\n", perc_50_reale))
cat(sprintf("95° Percentile (Scenario Ottimo):  € %.2f\n", perc_95_reale))
cat(sprintf("CVaR (Expected Shortfall Reale):   € %.2f\n", cvar_5_reale))
cat("=========================================================================\n\n")

# --- 5. PLOT DELLE VARIABILI Z NORMALIZZATE (2D ROBUSTO) ---
cat("4. Generazione Grafici...\n")
# Ritorniamo a ggplot2 classico bidimensionale per evitare problemi di rendering 3D
df_z_corr <- data.frame(do.call(rbind, tutti_z_correlati))
colnames(df_z_corr) <- PORTFOLIO_ETFS

plot_z <- ggplot(df_z_corr, aes(x = VWCE.DE, y = IGLN.L)) +
  geom_point(alpha = 0.3, color = "darkblue") +
  geom_density_2d(color = "red") +
  labs(title = "Shocks Correlati: Azioni vs Oro (Decorrelazione)", x = "Shock Azionario", y = "Shock Oro") +
  theme_minimal()

plot_z2 <- ggplot(df_z_corr, aes(x = VWCE.DE, y = USO)) +
  geom_point(alpha = 0.3, color = "darkgreen") +
  geom_density_2d(color = "red") +
  labs(title = "Shocks Correlati: Azioni vs Petrolio (Correlazione Positiva)", x = "Shock Azionario", y = "Shock Petrolio") +
  theme_minimal()

print(plot_z)
print(plot_z2)

# --- 6. SPAGHETTI PLOT CON PERCENTILI FUNZIONALI ---
grafico_mc <- ggplot() +
  # Linee delle singole simulazioni (grigio chiaro)
  geom_line(data = df_plot, aes(x = Mese, y = Valore, group = Simulazione), alpha = 0.1, color = "darkgray") +
  
  # CURVE DEI PERCENTILI (Crescono nel tempo)
  geom_line(data = percentili_nel_tempo, aes(x = Mese, y = P_50), color = "blue", linewidth = 1.2) +
  geom_line(data = percentili_nel_tempo, aes(x = Mese, y = P_05), color = "red", linewidth = 1.2, linetype = "solid") +
  geom_line(data = percentili_nel_tempo, aes(x = Mese, y = P_95), color = "gold", linewidth = 1.2, linetype = "solid") +
  
  # Etichette finali
  annotate("text", x = MESI_FUTURI, y = perc_05_reale, label = "5° P.", color = "red", vjust = -0.5, fontface = "bold", hjust=1) +
  annotate("text", x = MESI_FUTURI, y = perc_50_reale, label = "50° P.", color = "blue", vjust = -0.5, fontface = "bold", hjust=1) +
  annotate("text", x = MESI_FUTURI, y = perc_95_reale, label = "95° P.", color = "gold", vjust = -0.5, fontface = "bold", hjust=1) +
  
  scale_y_continuous(labels = scales::label_comma(big.mark = ".", decimal.mark = ",")) +
  labs(
    title = "Monte Carlo Multi-Fattoriale (Valori Reali al netto dell'Inflazione)",
    subtitle = "Spaghetti Plot con Curve di Percentile Dinamiche",
    x = "Mesi Futuri", y = "Potere d'Acquisto Reale (€)"
  ) +
  theme_minimal()

print(grafico_mc)

# --- 7. GRAFICO DISTRIBUZIONE NORMALE FINALE ---
df_finali <- data.frame(Capitale = prezzi_finali_reali)
grafico_dist <- ggplot(df_finali, aes(x = Capitale)) +
  geom_histogram(aes(y = after_stat(density)), bins = 50, fill = "lightblue", color = "black", alpha = 0.7) +
  geom_density(color = "darkblue", linewidth = 1) +
  stat_function(fun = dnorm, args = list(mean = mean(df_finali$Capitale), sd = sd(df_finali$Capitale)), 
                color = "red", linetype = "dashed", linewidth = 1) +
  geom_vline(xintercept = perc_05_reale, color = "red", linetype = "dashed", linewidth = 1) +
  geom_vline(xintercept = perc_50_reale, color = "blue", linetype = "solid", linewidth = 1) +
  labs(
    title = "Distribuzione Probabilistica del Potere d'Acquisto Finale",
    subtitle = "Istogramma (Azzurro), Densità Reale (Blu) e Curva Normale Teorica (Rossa Trat.)",
    x = "Capitale Reale a Scadenza (€)", y = "Frequenza (Densità)"
  ) +
  theme_minimal()

print(grafico_dist)
cat("Tutti i grafici generati con successo!\n")

