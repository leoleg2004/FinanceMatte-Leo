# ==============================================================================
# MODELLO 3: MODELLO DI HESTON (Volatilità Stocastica)
# ==============================================================================
# Questo modello ammette che la volatilità non è fissa. Negli anni di crisi
# la volatilità esplode (Cluster), negli anni calmi si abbassa verso una media.

PORTFOLIO_ETFS <- c("SXR8.DE", "VWCE.DE", "IGLN.L")
PORTFOLIO_PESI <- c(0.50,      0.30,      0.20)
ANNI_FUTURI        <- 20
CAPITALE_INIZIALE  <- 10000
VERSAMENTO_MENSILE <- 500
INFLAZIONE_ANNUA   <- 0.02
NUM_SIMULAZIONI    <- 1000

library(DBI)
library(RMariaDB)
library(ggplot2)
library(dplyr)
library(tidyr)

# Funzioni Statistiche
calc_skewness <- function(x) { n <- length(x); (sum((x - mean(x))^3) / n) / (sd(x)^3) }
calc_kurtosis <- function(x) { n <- length(x); (sum((x - mean(x))^4) / n) / (sd(x)^4) }
con <- dbConnect(RMariaDB::MariaDB(), dbname = "PortfolioDB", host = "127.0.0.1", user = "root", password = "Root1234!")
ticker_list <- paste(sprintf("'%s'", PORTFOLIO_ETFS), collapse = ",")
query <- sprintf("SELECT a.ticker as Ticker, p.price_date as Date, p.close_price as Price FROM Asset_Historical_Prices p JOIN Assets a ON p.isin = a.isin WHERE a.ticker IN (%s) ORDER BY p.price_date ASC;", ticker_list)
dataset_grezzo <- dbGetQuery(con, query)
dbDisconnect(con)

prezzi_allineati <- dataset_grezzo %>%
  mutate(YearMonth = format(as.Date(Date), "%Y-%m")) %>%
  group_by(Ticker, YearMonth) %>% slice_tail(n = 1) %>% ungroup() %>%
  select(Date, Ticker, Price) %>% pivot_wider(names_from = Ticker, values_from = Price) %>% drop_na() %>% arrange(Date)

n_mesi_storici <- nrow(prezzi_allineati)
ritorni_mensili <- prezzi_allineati
for(col in PORTFOLIO_ETFS) {
  ritorni_mensili[[col]] <- c(NA, prezzi_allineati[[col]][-1] / prezzi_allineati[[col]][-n_mesi_storici] - 1)
}
ritorni_mensili <- ritorni_mensili[-1, ]
ritorni_mensili$Port_Return <- 0
for(i in 1:length(PORTFOLIO_ETFS)) {
  ritorni_mensili$Port_Return <- ritorni_mensili$Port_Return + (ritorni_mensili[[PORTFOLIO_ETFS[i]]] * PORTFOLIO_PESI[i])
}

mu_mensile <- mean(ritorni_mensili$Port_Return)
sigma_mensile <- sd(ritorni_mensili$Port_Return)
varianza_storica <- sigma_mensile^2

# Parametri Heston Stimati (Valori classici per portafogli bilanciati)
KAPPA <- 2.0         # Velocità di ritorno alla volatilità media
THETA <- varianza_storica  # La volatilità media di lungo termine
XI <- 0.05           # Vol-of-vol (Volatilità della volatilità)
RHO <- -0.7          # Correlazione (Quando il prezzo scende, la volatilità sale)

# --- STATISTICHE FONDAMENTALI DEL PASSATO E DEL MODELLO ---
cat("\n=========================================================================\n")
cat("   ESTRAZIONE COMPORTAMENTO STORICO DEL PORTAFOGLIO\n")
cat("=========================================================================\n")
cat(sprintf("Rendimento Medio Mensile (Storico):  %.3f %%\n", mu_mensile * 100))
cat(sprintf("Volatilità Mensile (Rischio):        %.3f %%\n", sigma_mensile * 100))
cat(sprintf("Asimmetria (Skewness):               %.3f  (Normale = 0)\n", calc_skewness(ritorni_mensili$Port_Return)))
cat(sprintf("Code Grasse (Kurtosis):              %.3f  (Normale = 3)\n", calc_kurtosis(ritorni_mensili$Port_Return)))
cat("=========================================================================\n\n")

cat("=========================================================================\n")
cat("   PARAMETRI DEL MODELLO DI HESTON\n")
cat("=========================================================================\n")
cat(sprintf("Velocità Reversione Varianza (K):    %.2f\n", KAPPA))
cat(sprintf("Varianza di Lungo Termine (Theta):   %.5f\n", THETA))
cat(sprintf("Volatilità della Volatilità (Xi):    %.2f\n", XI))
cat(sprintf("Correlazione Prezzo/Vol (Rho):       %.2f\n", RHO))
cat("=========================================================================\n\n")

# --- MOTORE STOCASTICO: HESTON (Discretizzazione Euler-Maruyama) ---
mesi_futuri <- ANNI_FUTURI * 12
matrice_simulazioni <- matrix(0, nrow = mesi_futuri + 1, ncol = NUM_SIMULAZIONI)
matrice_simulazioni[1, ] <- CAPITALE_INIZIALE
inflazione_mensile <- (1 + INFLAZIONE_ANNUA)^(1/12) - 1

cat("Avvio Modello HESTON: Volatilità Stocastica...\n")
for(sim in 1:NUM_SIMULAZIONI) {
  # Simuliamo due moti browniani correlati
  z1 <- rnorm(mesi_futuri)
  z2 <- rnorm(mesi_futuri)
  w1 <- z1
  w2 <- RHO * z1 + sqrt(1 - RHO^2) * z2
  
  v_t <- THETA # Partiamo dalla varianza media
  
  for(m in 1:mesi_futuri) {
    # Evitiamo varianze negative
    v_t <- max(v_t, 0.000001)
    
    # 1. Aggiornamento Varianza (CIR Process)
    v_t_next <- v_t + KAPPA * (THETA - v_t) + XI * sqrt(v_t) * w2[m]
    
    # 2. Aggiornamento Prezzo (Rendimento)
    rendimento_m <- mu_mensile + sqrt(v_t) * w1[m]
    
    matrice_simulazioni[m+1, sim] <- matrice_simulazioni[m, sim] * (1 + rendimento_m) + VERSAMENTO_MENSILE
    matrice_simulazioni[m+1, sim] <- matrice_simulazioni[m+1, sim] / (1 + inflazione_mensile)
    
    v_t <- v_t_next
  }
}

# Percentili
risultati_finali <- matrice_simulazioni[mesi_futuri + 1, ]
cat(sprintf("[CASO PESSIMO 5%%]               € %s\n", format(round(quantile(risultati_finali, 0.05), 0), big.mark=".", decimal.mark=",")))
cat(sprintf("[CASO VEROSIMILE 50%%]           € %s\n", format(round(quantile(risultati_finali, 0.50), 0), big.mark=".", decimal.mark=",")))
cat(sprintf("[CASO OTTIMO 95%%]               € %s\n", format(round(quantile(risultati_finali, 0.95), 0), big.mark=".", decimal.mark=",")))

cat("=========================================================================\n\n")
cat("=========================================================================\n")
cat("   ANALISI STATISTICA DEI FUTURI (CAPITALE FINALE)\n")
cat("=========================================================================\n")
cat(sprintf("Asimmetria del Capitale:             %.3f\n", calc_skewness(risultati_finali)))
cat(sprintf("Curtosi del Capitale:                %.3f\n", calc_kurtosis(risultati_finali)))
cat("=========================================================================\n\n")

# Grafico
df_plot <- data.frame(Mese = 0:mesi_futuri)
for(i in 1:100) df_plot[[paste0("Sim_", i)]] <- matrice_simulazioni[, i]
df_plot$Pessimo <- apply(matrice_simulazioni, 1, quantile, probs = 0.05)
df_plot$Mediano <- apply(matrice_simulazioni, 1, quantile, probs = 0.50)
df_plot$Ottimo  <- apply(matrice_simulazioni, 1, quantile, probs = 0.95)

df_spaghetti <- df_plot %>% select(Mese, starts_with("Sim_")) %>% pivot_longer(-Mese, names_to="Simulazione", values_to="Capitale")
df_percentili <- df_plot %>% select(Mese, Pessimo, Mediano, Ottimo) %>% pivot_longer(-Mese, names_to="Scenario", values_to="Capitale")

fan_chart <- ggplot() + geom_line(data=df_spaghetti, aes(x=Mese, y=Capitale, group=Simulazione), color="gray80", alpha=0.3) +
  geom_line(data=df_percentili, aes(x=Mese, y=Capitale, color=Scenario), linewidth=1.5) +
  scale_color_manual(values=c("Pessimo"="red", "Mediano"="blue", "Ottimo"="forestgreen")) +
  scale_y_continuous(labels = scales::label_comma(big.mark=".", decimal.mark=",")) +
  labs(title="Modello 3: Heston Stochastic Volatility", subtitle="La volatilità non è fissa, ma oscilla casualmente mese dopo mese", y="Capitale Reale (€)") + theme_minimal()

print(fan_chart)

# --- PLOT DELLE DISTRIBUZIONI ---
mu_storico <- mean(ritorni_mensili$Port_Return)
sigma_storico <- sd(ritorni_mensili$Port_Return)

df_storico <- data.frame(Rendimenti = ritorni_mensili$Port_Return)
grafico_gaussiana_ritorni <- ggplot(df_storico, aes(x = Rendimenti)) +
  geom_histogram(aes(y = after_stat(density)), bins = 50, fill = "lightblue", color = "black", alpha = 0.7) +
  stat_function(fun = dnorm, args = list(mean = mu_storico, sd = sigma_storico), color = "red", linewidth = 1.5) +
  geom_vline(xintercept = mu_storico, color = "darkblue", linetype = "dashed", linewidth = 1) +
  labs(title = "Distribuzione Storica vs Curva Normale Teorica (Rossa)", subtitle = "Nel modello di Heston, la curva rossa viene dinamicamente ingrandita e ristretta nel tempo.", x = "Rendimento Mensile", y = "Densità") +
  scale_x_continuous(labels = scales::percent) + theme_minimal()

peggiore_5 <- quantile(risultati_finali, 0.05)
mediano_50 <- quantile(risultati_finali, 0.50)
migliore_95 <- quantile(risultati_finali, 0.95)

df_finali <- data.frame(Capitale_Finale = risultati_finali)
grafico_gaussiana_finali <- ggplot(df_finali, aes(x = Capitale_Finale)) +
  geom_density(fill = "lightgreen", color = "darkgreen", alpha = 0.6) +
  geom_vline(aes(xintercept = peggiore_5, color = "Pessimo (5%)"), linetype = "dashed", linewidth = 1.2) +
  geom_vline(aes(xintercept = mediano_50, color = "Mediano (50%)"), linetype = "solid", linewidth = 1.5) +
  geom_vline(aes(xintercept = migliore_95, color = "Ottimo (95%)"), linetype = "dashed", linewidth = 1.2) +
  scale_color_manual(name = "Percentili", values = c("Pessimo (5%)" = "red", "Mediano (50%)" = "blue", "Ottimo (95%)" = "forestgreen")) +
  scale_x_continuous(labels = scales::label_comma(big.mark = ".", decimal.mark = ",")) +
  labs(title = sprintf("Distribuzione del Capitale Finale (Tra %d Anni)", ANNI_FUTURI), subtitle = "Effetto congiunto dei percorsi stocastici del Prezzo e della Volatilità.", x = "Capitale Finale Accumulato (€)", y = "Densità") + theme_minimal() + theme(legend.position = "bottom")

print(grafico_gaussiana_ritorni)
print(grafico_gaussiana_finali)

