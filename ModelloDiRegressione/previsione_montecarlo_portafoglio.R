# ==============================================================================
# PREVISIONE DEL FUTURO: SIMULAZIONE MONTE CARLO DEL PORTAFOGLIO
# ==============================================================================
# Questo script estrae le statistiche REALI del tuo portafoglio dal database 
# (Media dei rendimenti e Volatilità/Rischio) e simula 1.000 futuri possibili 
# per i prossimi X anni utilizzando un processo stocastico.

# 1. IMPOSTA IL TUO PORTAFOGLIO
PORTFOLIO_ETFS <- c("SXR8.DE", "VWCE.DE", "IGLN.L")   # ETF
PORTFOLIO_PESI <- c(0.50,      0.30,      0.20)       # Pesi (Totale 1.0)

# 2. IMPOSTA IL TUO PIANO PER IL FUTURO
ANNI_FUTURI        <- 20       # Per quanti anni vuoi simulare il futuro?
CAPITALE_INIZIALE  <- 10000    # Soldi di partenza
VERSAMENTO_MENSILE <- 500      # Soldi aggiunti col PAC ogni mese
INFLAZIONE_ANNUA   <- 0.02     # Inflazione annua stimata (2%) per calcolare il vero potere d'acquisto
NUM_SIMULAZIONI    <- 1000     # Quanti universi paralleli simulare (1000 è lo standard)

# ==============================================================================

library(DBI)
library(RMariaDB)
library(ggplot2)
library(dplyr)
library(tidyr)

# Controlli sicurezza
if(sum(PORTFOLIO_PESI) != 1) stop("Errore: I pesi devono sommare a 1.0")

# --- 1. ESTRAZIONE DATI STORICI DAL DATABASE ---
con <- dbConnect(RMariaDB::MariaDB(), dbname = "PortfolioDB", host = "127.0.0.1", user = "root", password = "Root1234!")

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

# Raggruppamento mensile
dataset_mensile <- dataset_grezzo %>%
  mutate(YearMonth = format(as.Date(Date), "%Y-%m")) %>%
  group_by(Ticker, YearMonth) %>%
  slice_tail(n = 1) %>%
  ungroup()

# Pivot per allineamento
prezzi_allineati <- dataset_mensile %>%
  select(Date, Ticker, Price) %>%
  pivot_wider(names_from = Ticker, values_from = Price) %>%
  drop_na() %>%
  arrange(Date)

n_mesi_storici <- nrow(prezzi_allineati)

# Calcolo rendimenti mensili per ETF
ritorni_mensili <- prezzi_allineati
for(col in PORTFOLIO_ETFS) {
  ritorni_mensili[[col]] <- c(NA, prezzi_allineati[[col]][-1] / prezzi_allineati[[col]][-n_mesi_storici] - 1)
}
ritorni_mensili <- ritorni_mensili[-1, ]

# Calcolo rendimento Portafoglio mensile aggregato
ritorni_mensili$Port_Return <- 0
for(i in 1:length(PORTFOLIO_ETFS)) {
  ritorni_mensili$Port_Return <- ritorni_mensili$Port_Return + (ritorni_mensili[[PORTFOLIO_ETFS[i]]] * PORTFOLIO_PESI[i])
}

# --- 2. STATISTICHE FONDAMENTALI DEL PASSATO ---
# Estraiamo il rendimento medio e la volatilità (Standard Deviation) storica del portafoglio
mu_mensile <- mean(ritorni_mensili$Port_Return)
sigma_mensile <- sd(ritorni_mensili$Port_Return)

cat("\n=========================================================================\n")
cat("   ESTRAZIONE COMPORTAMENTO STORICO DEL PORTAFOGLIO\n")
cat("=========================================================================\n")
cat(sprintf("Rendimento Medio Mensile (Storico):  %.3f %%\n", mu_mensile * 100))
cat(sprintf("Volatilità Mensile (Rischio):        %.3f %%\n", sigma_mensile * 100))
cat("=========================================================================\n\n")

# --- 3. SIMULAZIONE MONTE CARLO DEL FUTURO ---
mesi_futuri <- ANNI_FUTURI * 12
matrice_simulazioni <- matrix(0, nrow = mesi_futuri + 1, ncol = NUM_SIMULAZIONI)
matrice_simulazioni[1, ] <- CAPITALE_INIZIALE

inflazione_mensile <- (1 + INFLAZIONE_ANNUA)^(1/12) - 1

cat("Avvio simulazione di 1.000 futuri paralleli...\n")

# Per ogni simulazione (universo)
for(sim in 1:NUM_SIMULAZIONI) {
  # Generiamo un vettore di rendimenti casuali futuri, distribuiti secondo la volatilità e la media storiche
  rendimenti_futuri <- rnorm(mesi_futuri, mean = mu_mensile, sd = sigma_mensile)
  
  for(m in 1:mesi_futuri) {
    # Crescita/Decrescita del mese + Versamento PAC
    capitale_cresciuto <- matrice_simulazioni[m, sim] * (1 + rendimenti_futuri[m])
    matrice_simulazioni[m+1, sim] <- capitale_cresciuto + VERSAMENTO_MENSILE
    
    # Scontiamo l'inflazione (il potere d'acquisto cala ogni mese)
    matrice_simulazioni[m+1, sim] <- matrice_simulazioni[m+1, sim] / (1 + inflazione_mensile)
  }
}

# --- 4. ANALISI RISULTATI (PERCENTILI) ---
# Calcoliamo la mediana e i percentili estremi (5% peggiore, 95% migliore) per ogni singolo mese futuro
risultati_finali <- matrice_simulazioni[mesi_futuri + 1, ]
peggiore_5 <- quantile(risultati_finali, 0.05)
mediano_50 <- quantile(risultati_finali, 0.50)
migliore_95 <- quantile(risultati_finali, 0.95)
totale_versato <- CAPITALE_INIZIALE + (VERSAMENTO_MENSILE * mesi_futuri)

cat("=========================================================================\n")
cat(sprintf(" RISULTATO PREVISTO TRA %d ANNI (Mille universi simulati)\n", ANNI_FUTURI))
cat(" I risultati sono espressi in Potere d'Acquisto Odierno (Inflazione Dedotta)\n")
cat("=========================================================================\n")
cat(sprintf("Totale Denaro Fisico Versato:   € %s\n\n", format(totale_versato, big.mark=".", decimal.mark=",")))

cat(sprintf("[CASO PESSIMO 5%%]               € %s\n", format(round(peggiore_5, 0), big.mark=".", decimal.mark=",")))
cat(sprintf("[CASO VEROSIMILE 50%%]           € %s\n", format(round(mediano_50, 0), big.mark=".", decimal.mark=",")))
cat(sprintf("[CASO OTTIMO 95%%]               € %s\n", format(round(migliore_95, 0), big.mark=".", decimal.mark=",")))
cat("=========================================================================\n\n")

# --- 5. GRAFICO FAN CHART (SPAGHETTI PLOT) ---
# Per non sovraccaricare il grafico, plottiamo solo 100 scenari a caso, 
# ma evidenziamo in grassetto il 5°, 50° e 95° percentile.

mesi_seq <- 0:mesi_futuri
df_plot <- data.frame(Mese = mesi_seq)
for(i in 1:100) {
  df_plot[[paste0("Sim_", i)]] <- matrice_simulazioni[, i]
}

# Calcoliamo le linee dei percentili mese per mese
df_plot$Pessimo <- apply(matrice_simulazioni, 1, quantile, probs = 0.05)
df_plot$Mediano <- apply(matrice_simulazioni, 1, quantile, probs = 0.50)
df_plot$Ottimo  <- apply(matrice_simulazioni, 1, quantile, probs = 0.95)

# Trasformiamo i dati per ggplot (Pivot Long)
df_spaghetti <- df_plot %>%
  select(Mese, starts_with("Sim_")) %>%
  pivot_longer(cols = -Mese, names_to = "Simulazione", values_to = "Capitale")

df_percentili <- df_plot %>%
  select(Mese, Pessimo, Mediano, Ottimo) %>%
  pivot_longer(cols = -Mese, names_to = "Scenario", values_to = "Capitale")

fan_chart <- ggplot() +
  # Le linee spaghetti grigie in background (simulazioni casuali)
  geom_line(data = df_spaghetti, aes(x = Mese, y = Capitale, group = Simulazione), color = "gray80", alpha = 0.3) +
  # Le tre linee in evidenza (Percentili)
  geom_line(data = df_percentili, aes(x = Mese, y = Capitale, color = Scenario), linewidth = 1.5) +
  scale_color_manual(values = c("Pessimo" = "red", "Mediano" = "blue", "Ottimo" = "forestgreen")) +
  scale_y_continuous(labels = scales::label_comma(big.mark = ".", decimal.mark = ",")) +
  labs(
    title = sprintf("Simulazione Monte Carlo: Proiezione a %d Anni", ANNI_FUTURI),
    subtitle = "Capitale aggiustato per l'Inflazione (Potere d'acquisto reale)",
    x = "Mesi Trascorsi",
    y = "Valore del Portafoglio (€)",
    color = "Probabilità"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 16, face = "bold"),
    legend.position = "bottom",
    legend.text = element_text(size = 12, face="bold")
# --- 6. PLOT DELLE GAUSSIANE (DISTRIBUZIONI) ---

# Plot A: La Campana di Gauss dei Ritorni Storici (Il Motore del Modello)
df_storico <- data.frame(Rendimenti = ritorni_mensili$Port_Return)

grafico_gaussiana_ritorni <- ggplot(df_storico, aes(x = Rendimenti)) +
  geom_histogram(aes(y = after_stat(density)), bins = 50, fill = "lightblue", color = "black", alpha = 0.7) +
  stat_function(fun = dnorm, args = list(mean = mu_mensile, sd = sigma_mensile), color = "red", linewidth = 1.5) +
  geom_vline(xintercept = mu_mensile, color = "darkblue", linetype = "dashed", linewidth = 1) +
  labs(
    title = "Distribuzione dei Rendimenti Storici Mensili",
    subtitle = "Istogramma reale vs Curva Normale Teorica (Rossa) usata dal modello",
    x = "Rendimento Mensile",
    y = "Densità di Probabilità"
  ) +
  scale_x_continuous(labels = scales::percent) +
  theme_minimal() +
  theme(plot.title = element_text(size = 14, face = "bold"))

# Plot B: La Distribuzione dei Risultati Finali tra 20 Anni
df_finali <- data.frame(Capitale_Finale = risultati_finali)

grafico_gaussiana_finali <- ggplot(df_finali, aes(x = Capitale_Finale)) +
  geom_density(fill = "lightgreen", color = "darkgreen", alpha = 0.6) +
  geom_vline(aes(xintercept = peggiore_5, color = "Pessimo (5%)"), linetype = "dashed", linewidth = 1.2) +
  geom_vline(aes(xintercept = mediano_50, color = "Mediano (50%)"), linetype = "solid", linewidth = 1.5) +
  geom_vline(aes(xintercept = migliore_95, color = "Ottimo (95%)"), linetype = "dashed", linewidth = 1.2) +
  scale_color_manual(name = "Percentili", values = c("Pessimo (5%)" = "red", "Mediano (50%)" = "blue", "Ottimo (95%)" = "forestgreen")) +
  scale_x_continuous(labels = scales::label_comma(big.mark = ".", decimal.mark = ",")) +
  labs(
    title = sprintf("Distribuzione del Capitale Finale (Tra %d Anni)", ANNI_FUTURI),
    subtitle = "Più la campana è larga, maggiore è l'incertezza sul risultato esatto.",
    x = "Capitale Finale Accumulato (€)",
    y = "Frequenza (Densità)"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    legend.position = "bottom"
  )

# Stampa tutti i grafici
print(fan_chart)
print(grafico_gaussiana_ritorni)
print(grafico_gaussiana_finali)

