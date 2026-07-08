# ==============================================================================
# Confronto Definitivo: ETF Puro vs TER Bancario vs TER + Commissione Ingresso
# ==============================================================================

library(DBI)
library(RMariaDB)
library(ggplot2)
library(tidyr)

# 1. Connessione ed Estrazione
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

# 2. Calcolo dei ritorni periodici dell'ETF
dataset$Ret_ETF <- c(NA, (dataset$ETF_Price[2:n] / dataset$ETF_Price[1:(n-1)]) - 1)

data_iniziale <- as.Date(min(dataset$Date))
data_finale <- as.Date(max(dataset$Date))
anni_passati <- as.numeric(data_finale - data_iniziale) / 365.25
periodi_per_anno <- (n - 1) / anni_passati

# 3. IMPOSTAZIONI DEGLI SCENARI BANCARI
ter_banca <- 0.015         # Costo Annuo (TER) fisso all'1.5% per entrambe le banche
ingresso_banca <- 0.020    # Commissione ingresso del 2.0% (solo per la terza opzione)

# Sottraiamo il TER mensile/periodico
dataset$Ret_Banca <- dataset$Ret_ETF - (ter_banca / periodi_per_anno)

# 4. RICOSTRUZIONE DEI PORTAFOGLI (Tre Scenari)
capitale_iniziale_teorico <- 10000

# - Scenario 1: ETF Puro (Nessuna commissione extra aggiunta)
dataset$Price_ETF_Puro <- capitale_iniziale_teorico

# - Scenario 2: Banca "Onesta" (Applica l'1.5% di TER ogni anno, ma NON fa pagare l'ingresso)
dataset$Price_Banca_NoIngresso <- capitale_iniziale_teorico

# - Scenario 3: Banca "Classica" (1.5% di TER + si trattiene il 2% subito al Giorno 1)
dataset$Price_Banca_Ingresso <- capitale_iniziale_teorico * (1 - ingresso_banca) # Parte da 9800€

for(i in 2:n) {
  dataset$Price_ETF_Puro[i] <- dataset$Price_ETF_Puro[i-1] * (1 + dataset$Ret_ETF[i])
  dataset$Price_Banca_NoIngresso[i] <- dataset$Price_Banca_NoIngresso[i-1] * (1 + dataset$Ret_Banca[i])
  dataset$Price_Banca_Ingresso[i] <- dataset$Price_Banca_Ingresso[i-1] * (1 + dataset$Ret_Banca[i])
}

# 5. CALCOLO DEI CAGR E DELLE DIFFERENZE FINALI
cagr_etf <- ((dataset$Price_ETF_Puro[n] / capitale_iniziale_teorico) ^ (1 / anni_passati)) - 1
cagr_banca_noingr <- ((dataset$Price_Banca_NoIngresso[n] / capitale_iniziale_teorico) ^ (1 / anni_passati)) - 1
cagr_banca_ingr <- ((dataset$Price_Banca_Ingresso[n] / capitale_iniziale_teorico) ^ (1 / anni_passati)) - 1

# --- FORMATTAZIONE OUTPUT LEGGIBILE ---
cat("\n=========================================================================\n")
cat(sprintf("   ANALISI PROGRESSIVA DEI COSTI BANCARI (su %.1f Anni)\n", anni_passati))
cat("=========================================================================\n\n")

cat("CAPITALE INIZIALE INVESTITO: € 10.000,00\n\n")

cat(sprintf("%-42s %-20s %s\n", "STRUMENTO", "CAPITALE FINALE", "RENDIMENTO ANNUO (CAGR)"))
cat(sprintf("%-42s %-20s %s\n", "------------------------------------------", "-------------------", "-----------------------"))
cat(sprintf("%-42s € %-18s %.2f %%\n", "[Verde]  1. ETF Puro", format(round(dataset$Price_ETF_Puro[n], 2), big.mark=".", decimal.mark=","), cagr_etf*100))
cat(sprintf("%-42s € %-18s %.2f %%\n", "[Giallo] 2. Banca (SOLO TER 1.5%)", format(round(dataset$Price_Banca_NoIngresso[n], 2), big.mark=".", decimal.mark=","), cagr_banca_noingr*100))
cat(sprintf("%-42s € %-18s %.2f %%\n", "[Rosso]  3. Banca (TER 1.5% + Ingr. 2%)", format(round(dataset$Price_Banca_Ingresso[n], 2), big.mark=".", decimal.mark=","), cagr_banca_ingr*100))
cat("-------------------------------------------------------------------------\n\n")

danno_solo_ter <- dataset$Price_ETF_Puro[n] - dataset$Price_Banca_NoIngresso[n]
danno_totale <- dataset$Price_ETF_Puro[n] - dataset$Price_Banca_Ingresso[n]
peso_solo_ingresso <- dataset$Price_Banca_NoIngresso[n] - dataset$Price_Banca_Ingresso[n]

cat("💸 DANNO ECONOMICO SCOMPOSTO:\n")
cat(sprintf("   - Danno causato SOLO dal TER (1.5%%): € %s\n", format(round(danno_solo_ter, 2), big.mark=".", decimal.mark=",")))
cat(sprintf("   - Danno aggiuntivo della Comm. Ingresso: € %s\n", format(round(peso_solo_ingresso, 2), big.mark=".", decimal.mark=",")))
cat(sprintf("   - Perdita TOTALE Scenario Peggiore:      € %s\n", format(round(danno_totale, 2), big.mark=".", decimal.mark=",")))
cat("\n=========================================================================\n\n")

# 6. ANALISI DI REGRESSIONE: CONFRONTO GIALLO VS ROSSO
# Normalizziamo l'indice ai 10.000€ per avere la base di confronto
dataset$Index_Norm <- 10000 * (dataset$Index_Value / dataset$Index_Value[1])

# Regressione Giallo (Solo TER)
mod_giallo <- lm(Price_Banca_NoIngresso ~ Index_Norm, data = dataset)
# Regressione Rosso (TER + Ingresso)
mod_rosso <- lm(Price_Banca_Ingresso ~ Index_Norm, data = dataset)

cat("=== CONFRONTO STATISTICO: GIALLO vs ROSSO ===\n")
cat(sprintf("Beta [Giallo - Solo TER]:            %.4f\n", coef(mod_giallo)["Index_Norm"]))
cat(sprintf("Beta [Rosso  - TER + 2%% Ingresso]:   %.4f\n", coef(mod_rosso)["Index_Norm"]))
cat("-------------------------------------------------------------------------\n")
cat("SPIEGAZIONE:\n")
cat("Il Beta rappresenta la 'forza' del fondo rispetto all'indice (se = 1.0, lo replica al 100%).\n")
cat("Come vedi, la commissione di ingresso del 2% abbatte proporzionalmente la capacità\n")
cat("del fondo (Rosso) di tenere il passo col mercato per tutti i 14 anni successivi!\n\n")

# 7. GENERAZIONE DEL GRAFICO A 3 LINEE MIGLIORATO
data_long <- data.frame(
  Data = as.Date(dataset$Date),
  "ETF_Puro" = dataset$Price_ETF_Puro,
  "Banca_SoloTER" = dataset$Price_Banca_NoIngresso,
  "Banca_Completa" = dataset$Price_Banca_Ingresso,
  check.names = FALSE
)
data_long <- gather(data_long, key = "Strumento", value = "Capitale", -Data)

# Definiamo l'ordine della legenda
data_long$Strumento <- factor(data_long$Strumento, levels = c("ETF_Puro", "Banca_SoloTER", "Banca_Completa"))

grafico_costi <- ggplot(data_long, aes(x = Data, y = Capitale, color = Strumento)) +
  geom_line(linewidth = 1.2) + 
  labs(
    title = "L'Anatomia dei Costi Bancari",
    subtitle = sprintf("Il peso progressivo di TER (1.5%%) e Commissioni d'Ingresso (2%%) su 10.000€ in %.1f anni", anni_passati),
    x = "Anni Trascorsi",
    y = "Valore del Capitale (€)"
  ) +
  scale_y_continuous(labels = scales::label_comma(big.mark = ".", decimal.mark = ",")) +
  scale_color_manual(
    values = c(
      "ETF_Puro" = "#27ae60",        
      "Banca_SoloTER" = "#f1c40f",   
      "Banca_Completa" = "#c0392b"    
    ),
    labels = c(
      "1. ETF Puro", 
      "2. Banca (Solo TER 1.5%)", 
      "3. Banca (TER 1.5% + 2% Ingresso)"
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

print(grafico_costi)

