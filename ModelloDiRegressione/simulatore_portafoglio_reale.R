# ==============================================================================
# SIMULATORE DEFINITIVO DI PORTAFOGLIO REALE (PAC + COSTI BANCARI)
# ==============================================================================
# Inserisci i tuoi ETF (presi dal file etf_index_mapping.md), i loro pesi nel 
# portafoglio e le regole di investimento (Capitale Iniziale e PAC Mensile).
# Lo script userà lo STORICO REALE dal database per simulare cosa sarebbe 
# successo ai tuoi soldi, calcolando i danni di eventuali promotori.
# ==============================================================================

# 1. IMPOSTA IL TUO PORTAFOGLIO IDEALE
PORTFOLIO_ETFS <- c("SXR8.DE", "IUSQ.DE", "SWDA.MI")   # Ticker degli ETF
PORTFOLIO_PESI <- c(0.10,      0.80,      0.10)        # Devono sommare a 1.0 (100%)

# 2. IMPOSTA I TUOI SOLDI
CAPITALE_INIZIALE  <- 1000   # Euro inseriti il primo giorno
VERSAMENTO_MENSILE <- 500     # Euro inseriti alla fine di ogni mese (Piano Accumulo)

# 3. IMPOSTA I COSTI DEL PROMOTORE BANCARIO DA CONFRONTARE
TER_BANCA      <- 0.015       # 1.5% di costo annuo 
INGRESSO_BANCA <- 0.02        # 2.0% di trattenuta su OGNI versamento effettuato

# ==============================================================================
#                       MOTORE DI CALCOLO INTERNO
# ==============================================================================

library(DBI)
library(RMariaDB)
library(ggplot2)
library(dplyr)
library(tidyr)

# Controlli di sicurezza
if(sum(PORTFOLIO_PESI) != 1) stop("Errore: I pesi del portafoglio devono sommare a 1.0")
if(length(PORTFOLIO_ETFS) != length(PORTFOLIO_PESI)) stop("Errore: Numero di ETF e pesi diverso")

# Connessione al Database
con <- dbConnect(RMariaDB::MariaDB(), dbname = "PortfolioDB", host = "127.0.0.1", user = "root", password = "Root1234!")

# Scarica tutti i prezzi degli ETF scelti
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

# Raggruppamento per fine mese (trasformiamo i dati giornalieri in mensili per simulare il PAC)
dataset_mensile <- dataset_grezzo %>%
  mutate(YearMonth = format(as.Date(Date), "%Y-%m")) %>%
  group_by(Ticker, YearMonth) %>%
  slice_tail(n = 1) %>% # Prendi solo l'ultimo giorno di borsa di ogni mese
  ungroup()

# Ruotiamo la tabella (Pivot) per allineare gli ETF sulle stesse date
prezzi_allineati <- dataset_mensile %>%
  select(Date, Ticker, Price) %>%
  pivot_wider(names_from = Ticker, values_from = Price) %>%
  drop_na() %>% # Elimina i mesi in cui un ETF non esisteva ancora (allinea tutti alla partenza del più giovane)
  arrange(Date)

n_mesi <- nrow(prezzi_allineati)
if(n_mesi < 12) stop("Errore: Dati storici insufficienti in comune tra questi ETF (Meno di 1 anno di sovrapposizione).")

# Calcolo rendimenti mensili per ogni ETF
ritorni_mensili <- prezz_allineati <- prezzi_allineati
for(col in PORTFOLIO_ETFS) {
  # (Prezzo oggi / Prezzo mese scorso) - 1
  ritorni_mensili[[col]] <- c(NA, prezzi_allineati[[col]][-1] / prezzi_allineati[[col]][-n_mesi] - 1)
}
ritorni_mensili <- ritorni_mensili[-1, ] # Togliamo il primo mese (NA)
n_mesi <- nrow(ritorni_mensili)

# Calcolo del rendimento mensile del Portafoglio (Media ponderata per i pesi)
ritorni_mensili$Port_Return <- 0
for(i in 1:length(PORTFOLIO_ETFS)) {
  ritorni_mensili$Port_Return <- ritorni_mensili$Port_Return + (ritorni_mensili[[PORTFOLIO_ETFS[i]]] * PORTFOLIO_PESI[i])
}

# --- LA SIMULAZIONE DELL'INTERESSE COMPOSTO ---
storia_puro <- numeric(n_mesi + 1)
storia_banca <- numeric(n_mesi + 1)
storia_versamenti <- numeric(n_mesi + 1)
date_vettore <- c(prezzi_allineati$Date[1], ritorni_mensili$Date)

# Mese 1 (Versamento Iniziale)
storia_versamenti[1] <- CAPITALE_INIZIALE
storia_puro[1]       <- CAPITALE_INIZIALE
storia_banca[1]      <- CAPITALE_INIZIALE * (1 - INGRESSO_BANCA)

# Ciclo Mese per Mese
for(i in 1:n_mesi) {
  # 1. Rendimento del mese (La banca toglie il TER diviso 12)
  rendimento_puro <- ritorni_mensili$Port_Return[i]
  rendimento_banca <- rendimento_puro - (TER_BANCA / 12)
  
  capitale_puro_cresciuto <- storia_puro[i] * (1 + rendimento_puro)
  capitale_banca_cresciuto <- storia_banca[i] * (1 + rendimento_banca)
  
  # 2. Aggiunta PAC (Versamento di fine mese)
  storia_puro[i+1]  <- capitale_puro_cresciuto + VERSAMENTO_MENSILE
  storia_banca[i+1] <- capitale_banca_cresciuto + (VERSAMENTO_MENSILE * (1 - INGRESSO_BANCA))
  storia_versamenti[i+1] <- storia_versamenti[i] + VERSAMENTO_MENSILE
}

# --- STATISTICHE FINALI ---
data_inizio <- date_vettore[1]
data_fine <- date_vettore[length(date_vettore)]
anni_totali <- as.numeric(data_fine - data_inizio) / 365.25
totale_versato <- storia_versamenti[length(storia_versamenti)]
valore_puro <- storia_puro[length(storia_puro)]
valore_banca <- storia_banca[length(storia_banca)]
danno_economico <- valore_puro - valore_banca

cagr_puro <- ((valore_puro / totale_versato) ^ (1/anni_totali)) - 1
cagr_banca <- ((valore_banca / totale_versato) ^ (1/anni_totali)) - 1

# Stampa Risultati Console
cat("\n=========================================================================\n")
cat(sprintf("   SIMULAZIONE REALE DI PORTAFOGLIO (%.1f Anni, %s -> %s)\n", anni_totali, data_inizio, data_fine))
cat("=========================================================================\n\n")
cat("COMPOSIZIONE PORTAFOGLIO:\n")
for(i in 1:length(PORTFOLIO_ETFS)) {
  cat(sprintf(" - %s : %.0f%%\n", PORTFOLIO_ETFS[i], PORTFOLIO_PESI[i]*100))
}
cat(sprintf("\nCAPITALE INIZIALE:  € %s\n", format(CAPITALE_INIZIALE, big.mark=".", decimal.mark=",")))
cat(sprintf("PAC MENSILE:        € %s\n", format(VERSAMENTO_MENSILE, big.mark=".", decimal.mark=",")))
cat(sprintf("TOTALE VERSATO:     € %s\n\n", format(totale_versato, big.mark=".", decimal.mark=",")))

cat(sprintf("%-38s %-18s %s\n", "STRUMENTO", "CAPITALE FINALE", "RENDIMENTO ANNUO LORDO (CAGR*)"))
cat("-------------------------------------------------------------------------\n")
cat(sprintf("[Verde]  Portafoglio ETF Puro           € %-15s %.2f %%\n", 
            format(round(valore_puro, 2), big.mark=".", decimal.mark=","), cagr_puro*100))
cat(sprintf("[Rosso]  Fondo Promotore (Banca)        € %-15s %.2f %%\n", 
            format(round(valore_banca, 2), big.mark=".", decimal.mark=","), cagr_banca*100))
cat("-------------------------------------------------------------------------\n\n")

cat("💸 IL COSTO DELLA CONSULENZA BANCARIA:\n")
cat(sprintf("Se avessi fatto fare questo identico investimento storico in banca,\n"))
cat(sprintf("le commissioni ti avrebbero mangiato esattamente: ==> € %s <==\n", format(round(danno_economico, 2), big.mark=".", decimal.mark=",")))
cat("\n*Nota: Il CAGR indicato e' calcolato sul capitale totale versato, non tiene conto dell'orizzonte differito del PAC.\n")
cat("=========================================================================\n\n")

# --- GRAFICO ---
data_grafico <- data.frame(
  Data = date_vettore,
  Versamenti_Nudi = storia_versamenti,
  Portafoglio_Puro = storia_puro,
  Portafoglio_Banca = storia_banca
)
data_long <- gather(data_grafico, key = "Strumento", value = "Capitale", -Data)
data_long$Strumento <- factor(data_long$Strumento, levels = c("Portafoglio_Puro", "Portafoglio_Banca", "Versamenti_Nudi"))

grafico <- ggplot(data_long, aes(x = Data, y = Capitale, color = Strumento)) +
  geom_line(linewidth = 1.2) +
  labs(
    title = "Backtest Reale: Portafoglio ETF vs Fondo Bancario",
    subtitle = sprintf("Dati Storici dal %s al %s", data_inizio, data_fine),
    x = "Anno",
    y = "Valore del Capitale (€)"
  ) +
  scale_y_continuous(labels = scales::label_comma(big.mark = ".", decimal.mark = ",")) +
  scale_color_manual(
    values = c(
      "Portafoglio_Puro" = "#27ae60",
      "Portafoglio_Banca" = "#c0392b",
      "Versamenti_Nudi" = "#95a5a6"
    ),
    labels = c(
      "Portafoglio ETF Puro (Max Guadagno)",
      "Fondo Bancario (Effetto TER + Ingresso)",
      "Capitale Fisico Versato (I tuoi soldi)"
    )
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 16, face = "bold", color = "#333333"),
    axis.title = element_text(size = 12, face = "bold"),
    legend.position = "bottom", 
    legend.title = element_blank(),
    legend.text = element_text(size = 11, face = "bold")
  )

print(grafico)

