# ==============================================================================
# Confronto Costi: ETF vs Fondo Bancario (1.0% e 1.5% di TER)
# ==============================================================================
library(DBI)
library(RMariaDB)
library(ggplot2)

# 1. Connessione ed Estrazione Dati
con <- dbConnect(RMariaDB::MariaDB(), dbname = "PortfolioDB", host = "127.0.0.1", user = "root", password = "Root1234!")
query <- "
SELECT i.history_date as Date, i.close_value as Index_Value, e.close_price as ETF_Price
FROM Index_Historical_Data i
JOIN Assets a ON a.tracked_index_id = i.index_id
JOIN Asset_Historical_Prices e ON e.isin = a.isin AND e.price_date = i.history_date
WHERE a.ticker = 'IUSQ.DE' ORDER BY i.history_date ASC;
"
dataset <- dbGetQuery(con, query)
dbDisconnect(con)

dataset <- dataset[order(dataset$Date), ]
n <- nrow(dataset)

# 2. Calcolo dei ritorni percentuali (P_oggi / P_ieri - 1)
dataset$Ret_ETF <- c(NA, (dataset$ETF_Price[2:n] / dataset$ETF_Price[1:(n-1)]) - 1)
dataset$Ret_Index <- c(NA, (dataset$Index_Value[2:n] / dataset$Index_Value[1:(n-1)]) - 1)

# Quanti periodi ci sono in un anno? (Utile per dividere il TER)
data_iniziale <- as.Date(min(dataset$Date))
data_finale <- as.Date(max(dataset$Date))
anni_passati <- as.numeric(data_finale - data_iniziale) / 365.25
periodi_per_anno <- (n - 1) / anni_passati

# 3. SIMULAZIONE DEI FONDI BANCARI
# Sottraiamo il TER annuale frazionato per ogni singolo periodo
ter_banca_1 <- 0.010  # 1.0%
ter_banca_2 <- 0.015  # 1.5%

dataset$Ret_Banca_1 <- dataset$Ret_ETF - (ter_banca_1 / periodi_per_anno)
dataset$Ret_Banca_2 <- dataset$Ret_ETF - (ter_banca_2 / periodi_per_anno)

# Ricostruiamo la storia dei prezzi partendo dagli stessi 100€ virtuali per tutti
dataset$Price_ETF_Norm <- 100
dataset$Price_Banca_1 <- 100
dataset$Price_Banca_2 <- 100

for(i in 2:n) {
  dataset$Price_ETF_Norm[i] <- dataset$Price_ETF_Norm[i-1] * (1 + dataset$Ret_ETF[i])
  dataset$Price_Banca_1[i] <- dataset$Price_Banca_1[i-1] * (1 + dataset$Ret_Banca_1[i])
  dataset$Price_Banca_2[i] <- dataset$Price_Banca_2[i-1] * (1 + dataset$Ret_Banca_2[i])
}

# 4. CALCOLO DEI CAGR E DIFFERENZE FINALI IN SOLDI
cagr_etf <- ((dataset$Price_ETF_Norm[n] / 100) ^ (1 / anni_passati)) - 1
cagr_banca_1 <- ((dataset$Price_Banca_1[n] / 100) ^ (1 / anni_passati)) - 1
cagr_banca_2 <- ((dataset$Price_Banca_2[n] / 100) ^ (1 / anni_passati)) - 1

cat("\n=== IMPATTO DEI COSTI BANCARI SUI RENDIMENTI (", round(anni_passati, 1), "Anni ) ===\n")
cat("Se avessi investito 10.000 Euro all'inizio:\n")
cat("- ETF Reale (Basso Costo):   €", round(10000 * (dataset$Price_ETF_Norm[n]/100), 2), " (CAGR:", round(cagr_etf*100, 2), "%)\n")
cat("- Fondo Banca (TER 1.0%):    €", round(10000 * (dataset$Price_Banca_1[n]/100), 2), " (CAGR:", round(cagr_banca_1*100, 2), "%)\n")
cat("- Fondo Banca (TER 1.5%):    €", round(10000 * (dataset$Price_Banca_2[n]/100), 2), " (CAGR:", round(cagr_banca_2*100, 2), "%)\n")
cat("--------------------------------------------------\n")
cat("SOLDI PERSI in commissioni (vs 1.5%): €", round(10000 * (dataset$Price_ETF_Norm[n]/100) - 10000 * (dataset$Price_Banca_2[n]/100), 2), "\n\n")

# 5. MODELLO DI REGRESSIONE LINEARE (Fondo TER 1.5% vs Indice)
# Siccome abbiamo normalizzato i prezzi, normalizziamo anche l'indice per la regressione
dataset$Index_Norm <- 100 * (dataset$Index_Value / dataset$Index_Value[1])

cat("=== REGRESSIONE: FONDO BANCA (TER 1.5%) vs INDICE ===\n")
modello_banca <- lm(Price_Banca_2 ~ Index_Norm, data = dataset)
print(summary(modello_banca))

# 6. GRAFICO DEL CONFRONTO (EFFETTO COMPOSITO DEI COSTI)
# Trasformiamo il dataset in formato lungo per fare un bel grafico con ggplot
library(tidyr)
data_long <- data.frame(
  Data = as.Date(dataset$Date),
  ETF_Reale = dataset$Price_ETF_Norm,
  Fondo_Banca_1.0 = dataset$Price_Banca_1,
  Fondo_Banca_1.5 = dataset$Price_Banca_2
)

data_long <- gather(data_long, key = "Strumento", value = "Valore", -Data)

grafico_costi <- ggplot(data_long, aes(x = Data, y = Valore, color = Strumento)) +
  geom_line(linewidth = 1) +
  labs(
    title = "Il 'Ladro Silenzioso': Effetto delle Commissioni Bancarie",
    subtitle = "Simulazione: 100€ investiti per 14.6 anni",
    x = "Anno",
    y = "Valore del Portafoglio (€)"
  ) +
  scale_color_manual(values = c("ETF_Reale" = "green", "Fondo_Banca_1.0" = "orange", "Fondo_Banca_1.5" = "red")) +
  theme_minimal()

print(grafico_costi)
