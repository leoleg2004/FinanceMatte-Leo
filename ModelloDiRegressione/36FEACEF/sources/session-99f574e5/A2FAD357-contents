# ==============================================================================
# PAC: Piano di Accumulo del Capitale a 30 Anni (500€ / mese)
# ETF vs Fondi Bancari
# ==============================================================================

library(ggplot2)
library(tidyr)

# 1. PARAMETRI DELLA SIMULAZIONE
anni <- 30
mesi <- anni * 12
versamento_mensile <- 500
capitale_totale_versato <- versamento_mensile * mesi

# Ipotizziamo un rendimento medio annuo realistico per il mercato azionario globale (es. MSCI ACWI)
rendimento_annuo_lordo <- 0.09  # 9.0% all'anno

# Costi ETF
ter_etf <- 0.002        # 0.20% annuo
ingresso_etf <- 0.00    # 0%

# Costi Banca 1 (Classica)
ter_banca_1 <- 0.030   # 1.50% annuo
ingresso_banca_1 <- 0.00 # 0%

# Costi Banca 2 (Pessima)
ter_banca_2 <- 0.030    # 1.50% annuo
ingresso_banca_2 <- 0.02 # 2.0% su ogni singolo versamento!

# Calcolo rendimento netto mensile (approssimato per semplicità di calcolo)
ret_mensile_etf <- (1 + (rendimento_annuo_lordo - ter_etf)) ^ (1/12) - 1
ret_mensile_b_1 <- (1 + (rendimento_annuo_lordo - ter_banca_1)) ^ (1/12) - 1
ret_mensile_b_2 <- (1 + (rendimento_annuo_lordo - ter_banca_2)) ^ (1/12) - 1

# 2. INIZIALIZZAZIONE VETTORI
storia_etf <- numeric(mesi + 1)
storia_b_1 <- numeric(mesi + 1)
storia_b_2 <- numeric(mesi + 1)
storia_versato <- numeric(mesi + 1)

storia_etf[1] <- 0
storia_b_1[1] <- 0
storia_b_2[1] <- 0
storia_versato[1] <- 0

# 3. IL CICLO DELL'INTERESSE COMPOSTO (Mese per Mese)
for(i in 1:mesi) {
  # 1. Il capitale del mese precedente matura gli interessi
  storia_etf[i+1] <- storia_etf[i] * (1 + ret_mensile_etf)
  storia_b_1[i+1] <- storia_b_1[i] * (1 + ret_mensile_b_1)
  storia_b_2[i+1] <- storia_b_2[i] * (1 + ret_mensile_b_2)
  
  # 2. Aggiungiamo il nuovo versamento mensile (sottraendo la fee d'ingresso se c'è)
  storia_etf[i+1] <- storia_etf[i+1] + (versamento_mensile * (1 - ingresso_etf))
  storia_b_1[i+1] <- storia_b_1[i+1] + (versamento_mensile * (1 - ingresso_banca_1))
  storia_b_2[i+1] <- storia_b_2[i+1] + (versamento_mensile * (1 - ingresso_banca_2))
  
  # Tracciamo i soldi tolti dal nostro conto corrente
  storia_versato[i+1] <- storia_versato[i] + versamento_mensile
}

# 4. RISULTATI FINALI E STAMPA IN CONSOLE
cat("\n=========================================================================\n")
cat(sprintf("   SIMULAZIONE PAC 30 ANNI (Versamento: 500€/mese)\n"))
cat("=========================================================================\n\n")

cat(sprintf("TOTALE SOLDI VERSATI DI TASCA TUA: € %s\n\n", format(capitale_totale_versato, big.mark=".", decimal.mark=",")))

cat(sprintf("%-42s %-20s %s\n", "STRUMENTO", "CAPITALE FINALE", "GUADAGNO NETTO"))
cat(sprintf("%-42s %-20s %s\n", "------------------------------------------", "-------------------", "-----------------------"))

guadagno_etf <- storia_etf[mesi+1] - capitale_totale_versato
cat(sprintf("%-42s € %-18s € %s\n", "[Verde]  1. ETF Puro (0.2% TER)", 
            format(round(storia_etf[mesi+1], 2), big.mark=".", decimal.mark=","),
            format(round(guadagno_etf, 2), big.mark=".", decimal.mark=",")))

guadagno_b1 <- storia_b_1[mesi+1] - capitale_totale_versato
cat(sprintf("%-42s € %-18s € %s\n", "[Giallo] 2. Banca (SOLO TER 1.5%)", 
            format(round(storia_b_1[mesi+1], 2), big.mark=".", decimal.mark=","),
            format(round(guadagno_b1, 2), big.mark=".", decimal.mark=",")))

guadagno_b2 <- storia_b_2[mesi+1] - capitale_totale_versato
cat(sprintf("%-42s € %-18s € %s\n", "[Rosso]  3. Banca (TER 1.5% + 2% Ingr.)", 
            format(round(storia_b_2[mesi+1], 2), big.mark=".", decimal.mark=","),
            format(round(guadagno_b2, 2), big.mark=".", decimal.mark=",")))
cat("-------------------------------------------------------------------------\n\n")

danno_banca_2 <- storia_etf[mesi+1] - storia_b_2[mesi+1]

cat("💸 DANNO ECONOMICO (Costo totale delle commissioni in 30 anni):\n")
cat(sprintf("Se scegli la Banca 3 invece dell'ETF Puro, \nregali letteralmente al promotore finanziario:\n"))
cat(sprintf("======> € %s <======\n", format(round(danno_banca_2, 2), big.mark=".", decimal.mark=",")))
cat("Questi sono soldi che avrebbero potuto essere tuoi per la pensione.\n")
cat("\n=========================================================================\n\n")

# 5. CREAZIONE DEL GRAFICO
data_long <- data.frame(
  Mese = 0:mesi,
  Anni = (0:mesi) / 12,
  "1_Soldi_Versati" = storia_versato,
  "2_ETF_Puro" = storia_etf,
  "3_Banca_SoloTER" = storia_b_1,
  "4_Banca_Completa" = storia_b_2,
  check.names = FALSE
)

data_long <- gather(data_long, key = "Strumento", value = "Capitale", -Mese, -Anni)

# Colori per il grafico
colori <- c(
  "1_Soldi_Versati" = "#95a5a6",   # Grigio per i versamenti base
  "2_ETF_Puro" = "#27ae60",        # Verde per l'ETF
  "3_Banca_SoloTER" = "#f1c40f",   # Giallo
  "4_Banca_Completa" = "#c0392b"   # Rosso
)

grafico_pac <- ggplot(data_long, aes(x = Anni, y = Capitale, color = Strumento)) +
  geom_line(linewidth = 1.2) +
  labs(
    title = "La Magia (e il Furto) dell'Interesse Composto in 30 Anni",
    subtitle = "PAC di 500€ al mese: ETF vs Fondi Bancari",
    x = "Anni Trascorsi",
    y = "Valore del Capitale (€)"
  ) +
  scale_y_continuous(labels = scales::label_comma(big.mark = ".", decimal.mark = ",")) +
  scale_color_manual(
    values = colori,
    labels = c(
      "Soldi Versati Nudi (180k)",
      "ETF Puro", 
      "Banca (Solo TER)", 
      "Banca (TER + Ingresso)"
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

print(grafico_pac)

