# ==============================================================================
# MODELLO DI MACHINE LEARNING (TRAIN/TEST SPLIT SULLA REGRESSIONE LINEARE)
# ==============================================================================
# Inserisci il ticker di un ETF tra quelli mappati per addestrare il modello.
# Il modello userà l'80% della storia per imparare il comportamento dell'ETF
# rispetto al suo indice, e proverà a indovinare i prezzi del restante 20% 
# (mai visto prima). Ne calcoleremo poi l'errore (MSE).

TARGET_ETF <- "SXR8.DE"   # <--- Puoi provare anche ZPRR.DE, EIMI.MI, SGLD.MI, QDVE.DE

# ==============================================================================

library(DBI)
library(RMariaDB)
library(ggplot2)

# 1. Connessione e Recupero Dati
con <- dbConnect(RMariaDB::MariaDB(), dbname = "PortfolioDB", host = "127.0.0.1", user = "root", password = "Root1234!")

query <- sprintf("
SELECT 
    i.history_date as Date, 
    i.close_value as Index_Value, 
    ind.symbol as Index_Ticker,
    ind.name as Index_Name,
    e.close_price as ETF_Price,
    a.name as ETF_Name
FROM Index_Historical_Data i
JOIN Indices ind ON i.index_id = ind.id
JOIN Assets a ON a.tracked_index_id = ind.id
JOIN Asset_Historical_Prices e ON e.isin = a.isin AND e.price_date = i.history_date
WHERE a.ticker = '%s'
ORDER BY i.history_date ASC;
", TARGET_ETF)

dataset <- dbGetQuery(con, query)
dbDisconnect(con)

if(nrow(dataset) == 0) {
  stop(sprintf("Errore: Nessun dato trovato per l'ETF '%s'. Controlla il Ticker.", TARGET_ETF))
}

# 2. Normalizzazione Dati (Base 100)
dataset$Index_Norm <- 100 * (dataset$Index_Value / dataset$Index_Value[1])
dataset$ETF_Norm <- 100 * (dataset$ETF_Price / dataset$ETF_Price[1])
n_totale <- nrow(dataset)

# 3. Train / Test Split Cronologico (80% / 20%)
# Essendo serie storiche finanziarie, non possiamo mischiare il dataset casualmente (Look-Ahead Bias)
split_index <- floor(n_totale * 0.80)

train_data <- dataset[1:split_index, ]
test_data  <- dataset[(split_index + 1):n_totale, ]

cat("\n=========================================================================\n")
cat(sprintf(" MACHINE LEARNING: REGRESSIONE SU %s vs %s\n", TARGET_ETF, dataset$Index_Ticker[1]))
cat("=========================================================================\n\n")

cat(sprintf("Dati Totali:    %d giorni di borsa\n", n_totale))
cat(sprintf("Training Set:   %d giorni (Dal %s al %s)\n", nrow(train_data), min(train_data$Date), max(train_data$Date)))
cat(sprintf("Test Set:       %d giorni (Dal %s al %s)\n\n", nrow(test_data), min(test_data$Date), max(test_data$Date)))

# 4. Addestramento del Modello (Training)
# Il modello usa SOLO i dati storici più vecchi per calcolare la retta
modello_ml <- lm(ETF_Norm ~ Index_Norm, data = train_data)

beta_train <- coef(modello_ml)["Index_Norm"]
r_quadro_train <- summary(modello_ml)$r.squared

cat("--- FASE DI TRAINING (Apprendimento) ---\n")
cat(sprintf("Beta Ottimale Trovato:    %7.4f\n", beta_train))
cat(sprintf("R-Quadro sul Training:    %7.4f\n", r_quadro_train))
cat("----------------------------------------\n\n")

# 5. Inferenza (Predizione sul Test Set Nascosto)
# Chiediamo al modello di prevedere l'ETF basandosi solo sul valore dell'Indice nel periodo recente
test_data$Predicted_ETF <- predict(modello_ml, newdata = test_data)

# Calcolo dell'Errore sulle predizioni
mse <- mean((test_data$ETF_Norm - test_data$Predicted_ETF)^2)
mae <- mean(abs(test_data$ETF_Norm - test_data$Predicted_ETF))

cat("--- FASE DI TEST (Verifica Predittiva) ---\n")
cat("Se il modello ha imparato bene, la distanza tra la previsione e il prezzo reale \n")
cat("dell'ETF nel Test Set (il futuro) dovrebbe essere minima.\n\n")

cat(sprintf("Mean Squared Error (MSE): %7.4f\n", mse))
cat(sprintf("Mean Absolute Error (MAE):%7.4f punti percentuale\n", mae))
cat("=========================================================================\n\n")

# 6. Rappresentazione Grafica del Machine Learning
# Uniamo train e test per il grafico, aggiungendo un'etichetta
train_data$Set <- "Train (80%)"
test_data$Set <- "Test (20%)"
# test_data ha la colonna Predicted_ETF che in train non ci serve per lo scatter. 
# Creiamo un dataframe completo solo per lo scatter
plot_data <- rbind(
  train_data[, c("Index_Norm", "ETF_Norm", "Set")],
  test_data[, c("Index_Norm", "ETF_Norm", "Set")]
)
plot_data$Set <- factor(plot_data$Set, levels = c("Train (80%)", "Test (20%)"))

# Estraiamo i coefficienti per disegnare la retta predittiva su TUTTO il grafico
intercetta <- coef(modello_ml)[1]
pendenza <- coef(modello_ml)[2]

grafico_ml <- ggplot(plot_data, aes(x = Index_Norm, y = ETF_Norm, color = Set)) +
  geom_point(alpha = 0.6, size = 1.5) +
  # Disegniamo la retta di regressione calcolata SOLO sul Train
  geom_abline(intercept = intercetta, slope = pendenza, color = "blue", linewidth = 1.2, linetype = "dashed") +
  labs(
    title = sprintf("Modello Machine Learning: %s", TARGET_ETF),
    subtitle = sprintf("Retta (Blu) addestrata sul Train Set. Errore Assoluto (MAE) sul Test: %.2f", mae),
    x = sprintf("Valore %s (Input X)", dataset$Index_Ticker[1]),
    y = sprintf("Valore %s (Target Y)", TARGET_ETF)
  ) +
  scale_color_manual(values = c("Train (80%)" = "black", "Test (20%)" = "red")) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 16, face = "bold"),
    legend.position = "bottom",
    legend.title = element_blank()
  )

print(grafico_ml)

