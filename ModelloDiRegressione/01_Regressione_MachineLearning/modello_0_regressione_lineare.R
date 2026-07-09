# ==============================================================================
# MODELLO 0: REGRESSIONE LINEARE 
# ==============================================================================
# Questo script utilizza un Modello di Regressione Lineare Semplice per 
# estrapolare il trend temporale del portafoglio.
# Per misurarne la potenza predittiva, divide storicamente i dati in due:
# - Training Set (80% più vecchio): Usato per tracciare e addestrare la linea di trend.
# - Test Set (20% più recente): Usato per testare se la linea ha "indovinato" il futuro.

# 1. IMPOSTAZIONI DEL PORTAFOGLIO
PORTFOLIO_ETFS <- c("SXR8.DE", "VWCE.DE", "IGLN.L")   # ETF
PORTFOLIO_PESI <- c(0.50,      0.30,      0.20)       # Pesi (Totale 1.0)
CAPITALE_INIZIALE <- 10000

library(DBI)
library(RMariaDB)
library(ggplot2)
library(dplyr)
library(tidyr)
library(lubridate)

# Controlli sicurezza
if(sum(PORTFOLIO_PESI) != 1) stop("Errore: I pesi devono sommare a 1.0")

# --- 1. ESTRAZIONE DATI STORICI DAL DATABASE ---
cat("1. Connessione al Database e Download Dati...\n")
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

# Allineamento dei prezzi a fine mese
dataset_mensile <- dataset_grezzo %>%
  mutate(Date = as.Date(Date),
         YearMonth = format(Date, "%Y-%m")) %>%
  group_by(Ticker, YearMonth) %>%
  slice_tail(n = 1) %>%
  ungroup()

# Pivot per affiancare gli ETF
prezzi_allineati <- dataset_mensile %>%
  select(Date, Ticker, Price) %>%
  pivot_wider(names_from = Ticker, values_from = Price) %>%
  drop_na() %>%
  arrange(Date)

# Normalizziamo i prezzi (Partenza da 1.0 per tutti per calcolare la crescita vera)
prezzi_normalizzati <- prezzi_allineati
for(col in PORTFOLIO_ETFS) {
  prezzi_normalizzati[[col]] <- prezzi_allineati[[col]] / prezzi_allineati[[col]][1]
}

# Calcoliamo il Valore Assoluto del Portafoglio Mese per Mese
prezzi_normalizzati$Portfolio_Value <- 0
for(i in 1:length(PORTFOLIO_ETFS)) {
  prezzi_normalizzati$Portfolio_Value <- prezzi_normalizzati$Portfolio_Value + 
    (prezzi_normalizzati[[PORTFOLIO_ETFS[i]]] * PORTFOLIO_PESI[i] * CAPITALE_INIZIALE)
}

# Creiamo il dataset per la Regressione
df_reg <- prezzi_normalizzati %>%
  select(Date, Portfolio_Value) %>%
  mutate(Date_Numeric = as.numeric(Date)) # Convertiamo la data in un numero per l'algoritmo lineare

# --- 2. TRAIN / TEST SPLIT (80% / 20%) ---
cat("2. Divisione dei dati in Training Set (80%) e Test Set (20%)...\n")
n_totale <- nrow(df_reg)
n_train <- floor(0.80 * n_totale)

train_data <- df_reg[1:n_train, ]
test_data  <- df_reg[(n_train + 1):n_totale, ]

# --- 3. ADDESTRAMENTO (FIT) DEL MODELLO LINEARE ---
cat("3. Addestramento Algoritmo (Linear Regression) sul Training Set...\n")
# OLS: Ordinari Minimi Quadrati. Cerchiamo la linea che minimizza la distanza dai prezzi
modello_lineare <- lm(Portfolio_Value ~ Date_Numeric, data = train_data)

# Estrazione Statistiche del Modello
statistiche <- summary(modello_lineare)
intercetta <- coef(modello_lineare)[1]
pendenza <- coef(modello_lineare)[2]
r_quadro_train <- statistiche$r.squared

cat("\n=========================================================================\n")
cat("   PARAMETRI DEL MODELLO (Regressione OLS)\n")
cat("=========================================================================\n")
cat(sprintf("Intercetta (Alpha):                  %.4f\n", intercetta))
cat(sprintf("Pendenza Temporale (Beta):           %.4f (Crescita per giorno)\n", pendenza))
cat(sprintf("R-Quadro sul Training Set:           %.2f %% (Spiega il %.2f %% dei movimenti passati)\n", r_quadro_train * 100, r_quadro_train * 100))
cat("=========================================================================\n\n")

# --- 4. PREVISIONE E CALCOLO ERRORI SUL TEST SET ---
cat("4. Previsione dei dati futuri (Test Set) e Calcolo Errori...\n")

# Prevediamo i valori sia per il Train che per il Test usando l'equazione della retta
train_data$Predicted <- predict(modello_lineare, newdata = train_data)
test_data$Predicted  <- predict(modello_lineare, newdata = test_data)

# Uniamo il dataset per il grafico
df_reg$Predicted <- c(train_data$Predicted, test_data$Predicted)
df_reg$Tipo <- c(rep("Training (80%)", n_train), rep("Test (20%)", n_totale - n_train))

# Calcoliamo il Mean Squared Error (MSE)
mse_train <- mean((train_data$Portfolio_Value - train_data$Predicted)^2)
mse_test  <- mean((test_data$Portfolio_Value - test_data$Predicted)^2)

cat("=========================================================================\n")
cat("   TEST DI ACCURATEZZA PREDITTIVA (Out-of-Sample)\n")
cat("=========================================================================\n")
cat(sprintf("Errore Medio Quadratico (Train MSE): € %.2f\n", mse_train))
cat(sprintf("Errore Medio Quadratico (Test MSE):  € %.2f\n", mse_test))
if(mse_test > mse_train * 2) {
  cat("Attenzione: Il Test MSE è molto più alto del Train MSE. Il modello lineare fatica a prevedere i trend futuri (Normale in finanza, andamento non lineare).\n")
} else {
  cat("Ottimo: L'errore sul Test Set è in linea con il Training Set. Il mercato ha mantenuto un trend costante.\n")
}
cat("=========================================================================\n\n")

# --- 5. GRAFICO GGPLOT2 (RISULTATO VISIVO) ---
cat("5. Generazione Grafico...\n")

data_split <- test_data$Date[1] # La data esatta in cui finisce il Train e inizia il Test

grafico <- ggplot(df_reg, aes(x = Date)) +
  # Linea reale (Nera = Passato noto, Blu = Futuro nascosto usato per il test)
  geom_line(aes(y = Portfolio_Value, color = Tipo), linewidth = 1.2) +
  # La retta di regressione (Rossa)
  geom_line(aes(y = Predicted, linetype = "Retta di Regressione (Trend)"), color = "red", linewidth = 1) +
  
  # Linea verticale per indicare lo split 80/20
  geom_vline(xintercept = as.numeric(data_split), linetype = "dotted", color = "darkgray", linewidth = 1) +
  annotate("text", x = data_split - 100, y = max(df_reg$Portfolio_Value)*0.9, label = "Fine Training", angle = 90, color="darkgray") +
  annotate("text", x = data_split + 100, y = max(df_reg$Portfolio_Value)*0.9, label = "Inizio Test", angle = 90, color="blue") +
  
  scale_color_manual(name = "Dati di Mercato:", values = c("Training (80%)" = "black", "Test (20%)" = "blue")) +
  scale_linetype_manual(name = "Modello Predittivo:", values = c("Retta di Regressione (Trend)" = "dashed")) +
  scale_y_continuous(labels = scales::label_comma(big.mark = ".", decimal.mark = ",")) +
  
  labs(
    title = "Modello 0: Regressione Lineare (Train / Test Split)",
    subtitle = "Addestramento della linea di Trend sull'80% dei dati (Nero) e Validazione sul 20% (Blu)",
    x = "Anno",
    y = "Valore del Portafoglio Reale (€)"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 16, face = "bold"),
    legend.position = "bottom"
  )

print(grafico)
cat("Grafico generato. Controlla la tab 'Plots' in RStudio.\n")



