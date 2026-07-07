# 1. Carica le librerie (devono essere sempre le prime)
library(DBI)
library(RMariaDB)
library(ggplot2)

# 2. Apri la connessione al database
cat("Connessione al database PortfolioDB...\n")
con <- dbConnect(RMariaDB::MariaDB(),
                 dbname = "PortfolioDB",
                 host = "127.0.0.1",
                 user = "root",
                 password = "Root1234!")

# 3. Definisci il testo della query
testo_della_query <- "
SELECT 
    i.history_date as Date,
    i.close_value as Index_Value,
    e.close_price as ETF_Price
FROM 
    Index_Historical_Data i
JOIN 
    Assets a ON a.tracked_index_id = i.index_id
JOIN 
    Asset_Historical_Prices e ON e.isin = a.isin AND e.price_date = i.history_date
WHERE 
    a.ticker = 'IUSQ.DE'
ORDER BY 
    i.history_date ASC;
"

# 4. Estrai i dati usando la query appena definita e chiudi la connessione
dataset <- dbGetQuery(con, testo_della_query)
dbDisconnect(con)

cat("Dati estratti con successo! Numero di righe estratte:", nrow(dataset), "\n")

# 5. Costruisci il Modello di Regressione Lineare
modello_lineare <- lm(ETF_Price ~ Index_Value, data = dataset)

# 6. Stampa i risultati statistici a video
cat("\n=== RISULTATI DELLA REGRESSIONE ===\n")
summary(modello_lineare)

# 7. Crea il grafico a dispersione con la retta di regressione
grafico <- ggplot(dataset, aes(x = Index_Value, y = ETF_Price)) +
  geom_point(color = "blue", alpha = 0.6) +
  geom_smooth(method = "lm", color = "red", se = TRUE) +
  labs(
    title = "Regressione Lineare: MSCI ACWI vs ETF (IUSQ.DE)",
    x = "Valore Indice MSCI ACWI (Excel)",
    y = "Prezzo ETF IUSQ.DE (Yahoo Finance)"
  ) +
  theme_minimal()

# Mostra il grafico
print(grafico)
# 1. Convertiamo le date in numeri (giorni passati dal 1970) per farle digerire alla matematica
dataset$Giorni <- as.numeric(as.Date(dataset$Date))

# 2. Creiamo il nuovo modello: Il Prezzo dell'ETF guidato solo dallo scorrere del Tempo
modello_etf_tempo <- lm(ETF_Price ~ Giorni, data = dataset)

# 3. Stampiamo i risultati di questo nuovo modello
cat("\n=== REGRESSIONE DELL'ETF SUL TEMPO (Trend) ===\n")
summary(modello_etf_tempo)

# 4. Facciamo il grafico della crescita nel tempo dell'ETF
grafico_tempo <- ggplot(dataset, aes(x = as.Date(Date), y = ETF_Price)) +
  geom_line(color = "black") +                               # La linea del prezzo reale
  geom_smooth(method = "lm", color = "green", se = TRUE) +   # La retta di regressione del trend
  labs(
    title = "Crescita dell'ETF IUSQ.DE nel tempo",
    x = "Anni",
    y = "Prezzo ETF in Euro"
  ) +
  theme_minimal()

print(grafico_tempo)
# 1. Assicuriamoci che i dati siano in ordine cronologico
dataset <- dataset[order(dataset$Date), ]
n <- nrow(dataset)

# 2. Calcolo dei ritorni percentuali (Prezzo Oggi / Prezzo Ieri - 1) per ENTRAMBI
dataset$Ritorno_Perc_ETF <- c(NA, (dataset$ETF_Price[2:n] / dataset$ETF_Price[1:(n-1)]) - 1)
dataset$Ritorno_Perc_Index <- c(NA, (dataset$Index_Value[2:n] / dataset$Index_Value[1:(n-1)]) - 1)

# Media semplice dei periodi
ritorno_medio_etf <- mean(dataset$Ritorno_Perc_ETF, na.rm = TRUE)
ritorno_medio_index <- mean(dataset$Ritorno_Perc_Index, na.rm = TRUE)

# 3. Calcolo del CAGR (Rendimento Annuo) per ENTRAMBI
data_iniziale <- as.Date(min(dataset$Date))
data_finale <- as.Date(max(dataset$Date))
anni_passati <- as.numeric(data_finale - data_iniziale) / 365.25

cagr_etf <- ((dataset$ETF_Price[n] / dataset$ETF_Price[1]) ^ (1 / anni_passati)) - 1
cagr_index <- ((dataset$Index_Value[n] / dataset$Index_Value[1]) ^ (1 / anni_passati)) - 1

# 4. Calcolo della Tracking Difference
tracking_difference <- cagr_etf - cagr_index

# 5. Stampa a video del Report Analitico
cat("\n======================================================\n")
cat("       CONFRONTO RENDIMENTI: ETF vs INDICE \n")
cat("======================================================\n")
cat("Anni totali analizzati:", round(anni_passati, 2), "anni\n\n")

cat("--- RENDIMENTO MEDIO SUL SINGOLO PERIODO ---\n")
cat("Media ETF:    ", round(ritorno_medio_etf * 100, 3), "%\n")
cat("Media Indice: ", round(ritorno_medio_index * 100, 3), "%\n\n")

cat("--- RENDIMENTO MEDIO ANNUO (CAGR) ---\n")
cat("CAGR ETF:     ", round(cagr_etf * 100, 3), "%\n")
cat("CAGR Indice:  ", round(cagr_index * 100, 3), "%\n")
cat("------------------------------------------------------\n")
cat("TRACKING DIFFERENCE (Scarto Annuo): ", round(tracking_difference * 100, 3), "%\n")
cat("======================================================\n")

