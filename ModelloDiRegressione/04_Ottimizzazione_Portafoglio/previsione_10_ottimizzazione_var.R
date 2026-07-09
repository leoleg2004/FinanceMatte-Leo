# ==============================================================================
# SCRIPT 10: OTTIMIZZAZIONE MIN-VAR (Value at Risk Storico)
# ==============================================================================
# A differenza della classica teoria di Markowitz (Script 8) che minimizza la 
# Varianza (simmetrica e cieca alle code grasse), questo script cerca la
# combinazione esatta di ETF che minimizza il CROLLO ESTREMO, ottimizzando
# esplicitamente il 5° Percentile (Value at Risk Storico).
# ==============================================================================

library(DBI)
library(RMariaDB)
library(ggplot2)
library(dplyr)
library(tidyr)

# --- CONFIGURAZIONI ---
PORTFOLIO_ETFS <- c("VWCE.DE", "SXRV.DE", "ZPRR.DE")
alpha_var <- 0.05 # Calcoliamo il VaR al 95% (peggior 5%)

# 1. ESTREZIONE DATI 
cat("1. Connessione al Database e Allineamento Dati...\n")
con <- tryCatch({
  dbConnect(RMariaDB::MariaDB(), dbname = "PortfolioDB", host = "127.0.0.1", user = "root", password = "Root1234!")
}, error = function(e) stop("ERRORE CRITICO DB"))

ticker_list <- paste(sprintf("'%s'", PORTFOLIO_ETFS), collapse = ",")
dataset_grezzo <- dbGetQuery(con, sprintf("
SELECT a.ticker as Ticker, p.price_date as Date, p.close_price as Price
FROM Asset_Historical_Prices p
JOIN Assets a ON p.isin = a.isin
WHERE a.ticker IN (%s)
ORDER BY p.price_date ASC;
", ticker_list))
dbDisconnect(con)

# Allineamento mensile e calcolo rendimenti continui
dati <- dataset_grezzo %>%
  mutate(Date = as.Date(Date), YearMonth = format(Date, "%Y-%m")) %>%
  group_by(Ticker, YearMonth) %>% slice_tail(n = 1) %>% ungroup() %>%
  group_by(Ticker) %>%
  mutate(Rendimento = log(Price / lag(Price))) %>%
  filter(!is.na(Rendimento)) %>%
  ungroup()

rendimenti_larghi <- dati %>%
  dplyr::select(YearMonth, Ticker, Rendimento) %>%
  pivot_wider(names_from = Ticker, values_from = Rendimento) %>%
  drop_na()

matrice_storica <- as.matrix(rendimenti_larghi %>% dplyr::select(all_of(PORTFOLIO_ETFS)))

# ==============================================================================
# 2. IL MOTORE DI OTTIMIZZAZIONE MIN-VAR (Metodo Monte Carlo)
# ==============================================================================
# Essendo il VaR Empirico una funzione "a gradini" e non derivabile, i normali
# ottimizzatori matematici (come quelli di Markowitz) falliscono.
# Usiamo quindi la tecnica della "Random Portfolio Generation": simuliamo
# 100.000 portafogli con pesi casuali, e peschiamo quello che ha il VaR migliore.
# ==============================================================================

cat("2. Avvio Motore di Ottimizzazione Stocastica per Min-VaR...\n")
set.seed(42) # Per riproducibilità
num_portafogli <- 100000
num_assets <- length(PORTFOLIO_ETFS)

cat(sprintf("   - Generazione di %s combinazioni di portafoglio...\n", format(num_portafogli, big.mark=".")))
# Genero pesi casuali positivi e li normalizzo a somma 1
pesi_casuali <- matrix(runif(num_portafogli * num_assets), nrow = num_portafogli, ncol = num_assets)
pesi_normalizzati <- pesi_casuali / rowSums(pesi_casuali)

cat("   - Calcolo storico vettorializzato per tutte le combinazioni...\n")
# Moltiplicazione Matriciale: (Mesi x Asset) %*% (Asset x Portafogli) = (Mesi x Portafogli)
tutti_i_rendimenti <- matrice_storica %*% t(pesi_normalizzati)

cat("   - Calcolo del VaR Storico per ogni portafoglio...\n")
# Calcolo il 5° percentile per ogni colonna (portafoglio)
# ATTENZIONE: apply è lento su 100.000 colonne, usiamo matrixStats::colQuantiles se serve,
# ma su R base possiamo usare un trucco o semplicemente aspettare 5 secondi.
var_values <- apply(tutti_i_rendimenti, 2, function(x) quantile(x, probs = alpha_var))

# Calcolo il Rendimento Medio per ogni portafoglio
mean_returns <- colMeans(tutti_i_rendimenti)

# Vogliamo MASSIMIZZARE il VaR (Renderlo il meno negativo possibile)
# In alternativa, definiamo il Rischio come il valore assoluto del VaR da minimizzare
rischio_var <- abs(var_values)

# Troviamo il portafoglio a Minimo VaR
indice_ottimo <- which.min(rischio_var)
pesi_ottimali_min_var <- pesi_normalizzati[indice_ottimo, ]
var_ottimale <- var_values[indice_ottimo]
rend_ottimale <- mean_returns[indice_ottimo]

# Portafoglio Scelto dall'Utente (es. 60% VWCE, 20% SXRV, 20% ZPRR)
pesi_utente <- c(0.60, 0.20, 0.20)
rendimenti_utente <- matrice_storica %*% matrix(pesi_utente, ncol=1)
var_utente <- quantile(rendimenti_utente, probs = alpha_var)
rend_mean_utente <- mean(rendimenti_utente)

cat("\n======================================================\n")
cat("      IL PORTAFOGLIO OTTIMO SECONDO IL RISK MANAGER\n")
cat("                  (Obiettivo: Min-VaR)\n")
cat("======================================================\n")
for(i in 1:num_assets) {
  cat(sprintf("%s: %.2f%%\n", PORTFOLIO_ETFS[i], pesi_ottimali_min_var[i] * 100))
}
cat(sprintf("\nVaR Storico (95%%) Atteso nel mese peggiore: %.2f%%\n", var_ottimale * 100))
cat("======================================================\n")

# ---------------------------------------------------------
# 3. GRAFICO: FRONTIERA MEAN-VAR (Scatter Plot)
# ---------------------------------------------------------
dir.create("../latex/immagini", showWarnings = FALSE, recursive = TRUE)

df_plot <- data.frame(
  Rischio = rischio_var * 100, # Valore assoluto del VaR in %
  Rendimento = mean_returns * 12 * 100 # Annualizzato
)

# Sottocampionamento per non far crashare ggplot con 100k punti
if(num_portafogli > 5000) {
  set.seed(42)
  idx_sample <- sample(1:num_portafogli, 5000)
  df_plot_sample <- df_plot[idx_sample, ]
} else {
  df_plot_sample <- df_plot
}

p <- ggplot(df_plot_sample, aes(x = Rischio, y = Rendimento)) +
  geom_point(alpha = 0.3, color = "gray50", size = 1) +
  geom_point(aes(x = abs(var_ottimale)*100, y = rend_ottimale*12*100), 
             color = "green", shape = 18, size = 5) +
  geom_point(aes(x = abs(var_utente)*100, y = rend_mean_utente*12*100), 
             color = "cyan", shape = 17, size = 4) +
  annotate("text", x = abs(var_ottimale)*100, y = rend_ottimale*12*100, 
           label = "Min-VaR Ottimo", vjust = -1, color = "darkgreen", fontface = "bold") +
  annotate("text", x = abs(var_utente)*100, y = rend_mean_utente*12*100, 
           label = "Portafoglio Utente", vjust = -1, color = "darkcyan", fontface = "bold") +
  labs(title = "Frontiera Efficiente Mean-VaR",
       subtitle = "La Nuvola delle combinazioni simulate. Rischio = Perdita Massima Attesa (VaR)",
       x = "Rischio: Value at Risk Assoluto Mensile (%)",
       y = "Rendimento Atteso Annualizzato (%)") +
  theme_minimal()

print(p)
ggsave("../latex/immagini/markowitz_var_plot.png", plot = p, width = 8, height = 6, dpi = 300)
cat("\nGrafico scatter Mean-VaR salvato in: ../latex/immagini/markowitz_var_plot.png\n")

