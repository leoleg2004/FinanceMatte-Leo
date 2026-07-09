# Script 9: Test di Ipotesi sulla Normalità e Confronto VaR (Parametrico vs Storico)

library(DBI)
library(RMariaDB)
library(dplyr)
library(tidyr)
library(ggplot2)

# ---------------------------------------------------------
# 1. PARAMETRI DEL PORTAFOGLIO (Dinamici)
# ---------------------------------------------------------
PORTFOLIO_ETFS <- c("VWCE.DE", "SXRV.DE", "ZPRR.DE")
TUO_PORTAFOGLIO_PESI <- c(0.30, 0.40, 0.30) # Devono sommare a 1
livello_confidenza <- 0.95
alpha <- 1 - livello_confidenza

if(length(PORTFOLIO_ETFS) != length(TUO_PORTAFOGLIO_PESI)) stop("Errore: Numero pesi errato")

# ---------------------------------------------------------
# 2. CONNESSIONE AL DATABASE E PREPARAZIONE DATI
# ---------------------------------------------------------
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

# Allineamento mensile e calcolo rendimenti
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

# ---------------------------------------------------------
# 3. CALCOLO RENDIMENTO DEL PORTAFOGLIO STORICO
# ---------------------------------------------------------
matrice_rendimenti <- as.matrix(rendimenti_larghi %>% dplyr::select(all_of(PORTFOLIO_ETFS)))
rendimenti_portafoglio <- as.numeric(matrice_rendimenti %*% TUO_PORTAFOGLIO_PESI)

mu_port <- mean(rendimenti_portafoglio)
sigma_port <- sd(rendimenti_portafoglio)

cat("\n======================================================\n")
cat("      ANALISI DEL RISCHIO E TEST DELLE IPOTESI\n")
cat("======================================================\n")
cat(sprintf("Titoli analizzati: %s\n", paste(PORTFOLIO_ETFS, collapse = ", ")))
cat(sprintf("Rendimento Medio Mensile (Mu): %.4f\n", mu_port))
cat(sprintf("Volatilità Mensile (Sigma): %.4f\n", sigma_port))

# ---------------------------------------------------------
# 4. TEST DI IPOTESI: SHAPIRO-WILK (Verifica Normalità)
# ---------------------------------------------------------
test_shapiro <- shapiro.test(rendimenti_portafoglio)

cat("\n--- TEST DI SHAPIRO-WILK SULLA NORMALITÀ ---\n")
cat(sprintf("Statistica W: %.4f\n", test_shapiro$statistic))
cat(sprintf("p-value: %.10f\n", test_shapiro$p.value))

if (test_shapiro$p.value < 0.05) {
  cat("CONCLUSIONE: L'ipotesi nulla (H0) è RIFIUTATA (p < 0.05).\n")
  cat("I rendimenti del portafoglio NON seguono una distribuzione normale (Presenza di Fat Tails).\n")
} else {
  cat("CONCLUSIONE: L'ipotesi nulla (H0) è ACCETTATA (p >= 0.05).\n")
  cat("I rendimenti del portafoglio si approssimano a una distribuzione normale.\n")
}

# ---------------------------------------------------------
# 5. CONFRONTO VALUE AT RISK (VaR)
# ---------------------------------------------------------
Z_score <- qnorm(alpha) 
VaR_parametrico <- mu_port + (Z_score * sigma_port)
VaR_storico <- quantile(rendimenti_portafoglio, alpha)

cat("\n--- CONFRONTO VALUE AT RISK (95%) ---\n")
cat(sprintf("VaR Parametrico (Teorico con Gaussiana): %.2f%%\n", VaR_parametrico * 100))
cat(sprintf("VaR Storico (Reale 5° Percentile): %.2f%%\n", VaR_storico * 100))
if(VaR_storico < VaR_parametrico) {
  cat("! Il VaR Storico è PEGGIORE del Parametrico: la teoria classica sottostima il rischio reale!\n")
}
cat("======================================================\n")

# ---------------------------------------------------------
# 6. GRAFICO: ISTOGRAMMA CON CURVA NORMALE
# ---------------------------------------------------------
dir.create("../latex/immagini", showWarnings = FALSE, recursive = TRUE)

# Prepariamo i dati per ggplot
df_plot <- data.frame(Rendimenti = rendimenti_portafoglio)

p <- ggplot(df_plot, aes(x = Rendimenti)) +
  geom_histogram(aes(y = after_stat(density)), bins = 30, fill = "steelblue", color = "white", alpha = 0.7) +
  stat_function(fun = dnorm, args = list(mean = mu_port, sd = sigma_port), 
                color = "red", linewidth = 1.5) +
  geom_vline(xintercept = VaR_storico, color = "darkred", linetype = "dashed", linewidth = 1.2) +
  geom_vline(xintercept = VaR_parametrico, color = "orange", linetype = "dotted", linewidth = 1.2) +
  labs(title = "Distribuzione dei Rendimenti vs Curva Normale Teorica",
       subtitle = "La linea rossa è la Campana di Gauss. Nota come i rendimenti reali escano dai bordi (Fat Tails).",
       x = "Rendimento Logaritmico Mensile",
       y = "Densità") +
  theme_minimal() +
  annotate("text", x = VaR_storico, y = 5, label = "VaR Storico", color = "darkred", angle = 90, vjust = -0.5) +
  annotate("text", x = VaR_parametrico, y = 5, label = "VaR Parametrico", color = "orange", angle = 90, vjust = 1.5)

# Mostra il plot a video in R/RStudio
print(p)

# Salva il plot per LaTeX
ggsave("../latex/immagini/istogramma_normalita.png", plot = p, width = 8, height = 6, dpi = 300)

cat("\nGrafico Istogramma salvato in: ../latex/immagini/istogramma_normalita.png\n")
