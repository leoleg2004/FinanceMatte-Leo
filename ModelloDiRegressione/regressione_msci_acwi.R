# ==============================================================================
# Modello di Regressione Lineare: MSCI ACWI (Indice) vs IUSQ.DE (ETF)
# ==============================================================================

# 1. Installa i pacchetti necessari (togli il commento se non li hai già)
# install.packages("DBI")
# install.packages("RMariaDB")
# install.packages("ggplot2")

library(DBI)
library(RMariaDB)
library(ggplot2)

# 2. Connessione al Database MySQL
cat("Connessione al database PortfolioDB...\n")
con <- dbConnect(RMariaDB::MariaDB(),
                 dbname = "PortfolioDB",
                 host = "127.0.0.1",
                 user = "root",
                 password = "Root1234!")

# 3. Query per unire i dati dell'Indice (dal tuo Excel) e dell'ETF (da Yahoo)
# Useremo l'ETF 'IUSQ.DE' (iShares MSCI ACWI in Euro) per il confronto.
query <- "
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

# Esegui la query e salva i dati in un Data Frame
dataset <- dbGetQuery(con, query)
cat("Dati estratti con successo! Numero di osservazioni:", nrow(dataset), "\n\n")

# Disconnessione pulita dal database
dbDisconnect(con)

# 4. Costruzione del Modello di Regressione Lineare
# Vogliamo vedere come il prezzo dell'ETF (Y) dipenda dal valore dell'Indice (X)
modello_lineare <- lm(ETF_Price ~ Index_Value, data = dataset)

# Stampa i risultati statistici (R-quadro, P-value, Intercetta e Beta)
cat("=== RISULTATI DELLA REGRESSIONE ===\n")
summary(modello_lineare)

# 5. Visualizzazione Grafica (Scatterplot + Retta di Regressione)
grafico <- ggplot(dataset, aes(x = Index_Value, y = ETF_Price)) +
  geom_point(color = "blue", alpha = 0.6) +          # I punti reali
  geom_smooth(method = "lm", color = "red", se = TRUE) + # La retta di regressione
  labs(
    title = "Regressione Lineare: MSCI ACWI vs ETF (IUSQ.DE)",
    x = "Valore Indice MSCI ACWI (Excel)",
    y = "Prezzo ETF IUSQ.DE (Yahoo Finance)"
  ) +
  theme_minimal()

# Mostra il grafico
print(grafico)
