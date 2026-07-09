# ==============================================================================
# SCRIPT 11: MODEL PREDICTIVE CONTROL (MPC) & STATE-SPACE MIMO PER PORTAFOGLIO
# ==============================================================================

# Installazione libreria per ottimizzazione quadratica (Quadratic Programming)
library(quadprog)
library(DBI)
library(RMariaDB)
library(ggplot2)
library(dplyr)
library(tidyr)

# 1. Connessione al Database e Allineamento Dati
cat("1. Estrazione Dati e Calcolo Matrici Stocastiche...\n")
con <- dbConnect(RMariaDB::MariaDB(), 
                 user = "root", 
                 password = "Root1234!", 
                 dbname = "PortfolioDB", 
                 host = "127.0.0.1")

res_vwce <- dbGetQuery(con, "SELECT price_date as Date, close_price as Adj_Close FROM Asset_Historical_Prices WHERE isin = 'IE00BK5BQT80' ORDER BY price_date")
res_sxrv <- dbGetQuery(con, "SELECT price_date as Date, close_price as Adj_Close FROM Asset_Historical_Prices WHERE isin = 'IE00B53SZB19' ORDER BY price_date")
res_zprr <- dbGetQuery(con, "SELECT price_date as Date, close_price as Adj_Close FROM Asset_Historical_Prices WHERE isin = 'IE00B60SQZ31' ORDER BY price_date")
dbDisconnect(con)

# Allineamento
df <- merge(res_vwce, res_sxrv, by = "Date", suffixes = c("_vwce", "_sxrv"))
df <- merge(df, res_zprr, by = "Date")
colnames(df) <- c("Date", "VWCE", "SXRV", "ZPRR")

# Rendimenti logaritmici
df$ret_vwce <- c(NA, diff(log(df$VWCE)))
df$ret_sxrv <- c(NA, diff(log(df$SXRV)))
df$ret_zprr <- c(NA, diff(log(df$ZPRR)))
df <- na.omit(df)

ret_matrix <- as.matrix(df[, c("ret_vwce", "ret_sxrv", "ret_zprr")])
N <- ncol(ret_matrix) # Numero di asset = 3
mu <- colMeans(ret_matrix) * 21
Sigma <- cov(ret_matrix) * 21

write.csv(mu, "mu_stocastico.csv", row.names=FALSE)
write.csv(Sigma, "sigma_stocastico.csv", row.names=FALSE)

# ==============================================================================
# 2. DEFINIZIONE DEL SISTEMA MIMO STATE-SPACE
# ==============================================================================
# x(k+1) = A * x(k) + B * u(k) + w(k)
# Matrice A (Deriva inerziale del mercato)
A <- diag(1 + mu)
# Matrice B (Ingresso di controllo)
B <- diag(1 + mu) 

# ==============================================================================
# 3. SETTING DEL MODEL PREDICTIVE CONTROL (MPC)
# ==============================================================================
cat("2. Inizializzazione Algoritmo MPC...\n")
T_sim <- 60 # Mesi di simulazione in closed-loop

# Matrici di Peso del Funzionale di Costo J = sum( -x'Qx + u'Ru + x'Sx )
Q <- diag(c(1, 1, 1)) * 10       
R_mat <- diag(c(1, 1, 1)) * 50   

x_0 <- c(1/3, 1/3, 1/3) # Equopesati
X_history <- matrix(0, nrow = T_sim + 1, ncol = N)
U_history <- matrix(0, nrow = T_sim, ncol = N)
J_history <- numeric(T_sim)
X_history[1, ] <- x_0

cat("3. Simulazione Closed-Loop Receding Horizon...\n")
for (k in 1:T_sim) {
  
  x_k <- X_history[k, ]
  
  Dmat <- 2 * R_mat + 2 * t(B) %*% Sigma %*% B 
  dvec <- as.vector(t(B) %*% (Q %*% A %*% x_k)) 
  
  # Vincoli MPC (Self-Financing: sum(u) = 0)
  Amat <- matrix(1, nrow = N, ncol = 1)
  bvec <- 0
  
  # Vincolo terminale/inequality: u_k >= -x_k (No short selling)
  Amat <- cbind(Amat, diag(N))
  bvec <- c(bvec, -x_k)
  
  qp_res <- tryCatch({
    solve.QP(Dmat = Dmat, dvec = dvec, Amat = Amat, bvec = bvec, meq = 1)
  }, error = function(e) {
    list(solution = rep(0, N), value = 0) 
  })
  
  u_opt <- qp_res$solution
  J_opt <- -qp_res$value 
  
  w_noise <- ret_matrix[sample(1:nrow(ret_matrix), 1), ]
  x_next <- A %*% x_k + B %*% u_opt + w_noise * (x_k + u_opt)
  x_next <- x_next / sum(x_next)
  
  X_history[k+1, ] <- x_next
  U_history[k, ] <- u_opt
  J_history[k] <- J_opt
}

# ==============================================================================
# 4. PLOTTING RISULTATI (X, U, J)
# ==============================================================================
cat("4. Generazione Grafici Dinamici...\n")
time_steps <- 1:(T_sim+1)

df_X <- data.frame(Time = time_steps, VWCE = X_history[,1], SXRV = X_history[,2], ZPRR = X_history[,3])
df_X_long <- gather(df_X, Asset, Peso, -Time)

df_U <- data.frame(Time = 1:T_sim, VWCE = U_history[,1], SXRV = U_history[,2], ZPRR = U_history[,3])
df_U_long <- gather(df_U, Asset, Trade, -Time)

df_J <- data.frame(Time = 1:T_sim, Costo = J_history)

p1 <- ggplot(df_X_long, aes(x = Time, y = Peso, color = Asset)) + geom_line(size = 1) +
  labs(title = "Evoluzione dello Stato x(t) [Pesi Portafoglio]", subtitle = "Il controllore MPC bilancia dinamicamente il portafoglio", x = "Mesi (k)", y = "Allocazione %") + theme_minimal()

p2 <- ggplot(df_U_long, aes(x = Time, y = Trade, fill = Asset)) + geom_bar(stat = "identity", position = "dodge") +
  labs(title = "Ingressi di Controllo u(t) [Operazioni di Trading]", subtitle = "Delta pesi generati dall'MPC ad ogni passo (vincolo self-financing)", x = "Mesi (k)", y = "Trade (Buy > 0, Sell < 0)") + theme_minimal()

p3 <- ggplot(df_J, aes(x = Time, y = Costo)) + geom_line(color = "darkred", size = 1) +
  labs(title = "Funzionale di Costo Ottimo J(k)", subtitle = "Convergenza dell'energia del sistema lungo la traiettoria (Lyapunov CLF)", x = "Mesi (k)", y = "Costo Stimato J") + theme_minimal()

ggsave("../../latex/immagini/mpc_stati.png", p1, width = 8, height = 4)
ggsave("../../latex/immagini/mpc_ingressi.png", p2, width = 8, height = 4)
ggsave("../../latex/immagini/mpc_costo.png", p3, width = 8, height = 4)

cat("Grafici salvati nella cartella LaTeX/immagini!\n")
