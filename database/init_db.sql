-- ATTENZIONE: Questo formatterà e ricreerà il database per applicare 
-- la nuova struttura incentrata sugli Indici e sugli ETF.
DROP DATABASE IF EXISTS PortfolioDB;
CREATE DATABASE PortfolioDB;
USE PortfolioDB;

-- =======================================================
-- 1. STRUTTURE BASE (INDICI E PORTAFOGLI)
-- =======================================================

-- Tabella Indices: Rappresenta i benchmark di mercato (es. S&P 500)
CREATE TABLE IF NOT EXISTS Indices (
    id INT AUTO_INCREMENT PRIMARY KEY,
    symbol VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    inception_date DATE
);

-- Tabella Portfolios: Le scatole che contengono i tuoi investimenti
CREATE TABLE IF NOT EXISTS Portfolios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(255),
    creation_date DATE NOT NULL
);

-- =======================================================
-- 2. DATI STORICI PER REGRESSIONE LINEARE
-- =======================================================

-- Tabella Index_Historical_Data: Valori storici dell'indice (cruciale per R)
CREATE TABLE IF NOT EXISTS Index_Historical_Data (
    id INT AUTO_INCREMENT PRIMARY KEY,
    index_id INT NOT NULL,
    history_date DATE NOT NULL,
    close_value DECIMAL(15, 6) NOT NULL, -- Valore dell'indice
    open_value DECIMAL(15, 6),
    high_value DECIMAL(15, 6),
    low_value DECIMAL(15, 6),
    UNIQUE KEY unique_index_date (index_id, history_date),
    FOREIGN KEY (index_id) REFERENCES Indices(id) ON DELETE CASCADE
);

-- =======================================================
-- 3. ASSET (ETF) E DATI STORICI ASSET
-- =======================================================

-- Tabella Assets: Dettaglio profondo sugli ETF
CREATE TABLE IF NOT EXISTS Assets (
    isin VARCHAR(20) PRIMARY KEY, -- L'ISIN è il vero identificatore univoco globale
    ticker VARCHAR(20) NOT NULL,  -- Es. CSPX.MI
    name VARCHAR(100) NOT NULL,
    asset_type VARCHAR(50) NOT NULL, -- Es. 'ETF'
    inception_date DATE,             -- Data di rilascio del fondo
    provider VARCHAR(100),           -- Es. 'iShares', 'Vanguard'
    ter DECIMAL(5, 4),               -- Costo annuo (es. 0.0007 = 0.07%)
    distribution_policy VARCHAR(50), -- 'Accumulating' o 'Distributing'
    currency VARCHAR(10) NOT NULL,   -- Valuta base
    tracked_index_id INT,            -- COLLEGAMENTO ALL'INDICE
    FOREIGN KEY (tracked_index_id) REFERENCES Indices(id) ON DELETE SET NULL
);

-- Tabella Asset_Historical_Prices: Storico prezzi degli ETF
CREATE TABLE IF NOT EXISTS Asset_Historical_Prices (
    id INT AUTO_INCREMENT PRIMARY KEY,
    isin VARCHAR(20) NOT NULL,
    price_date DATE NOT NULL,
    open_price DECIMAL(15, 6),
    high_price DECIMAL(15, 6),
    low_price DECIMAL(15, 6),
    close_price DECIMAL(15, 6),
    adj_close DECIMAL(15, 6),
    volume BIGINT,
    UNIQUE KEY unique_asset_date (isin, price_date),
    FOREIGN KEY (isin) REFERENCES Assets(isin) ON DELETE CASCADE
);

-- =======================================================
-- 4. TRANSAZIONI DEL PORTAFOGLIO
-- =======================================================

CREATE TABLE IF NOT EXISTS Transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    portfolio_id INT NOT NULL,
    isin VARCHAR(20) NOT NULL, -- Si collega tramite l'ISIN
    transaction_date DATE NOT NULL,
    transaction_type VARCHAR(20) NOT NULL, -- 'BUY', 'SELL', 'DIVIDEND'
    quantity DECIMAL(15, 6) NOT NULL,
    price DECIMAL(15, 6) NOT NULL,
    fees DECIMAL(10, 2) DEFAULT 0.00,
    currency VARCHAR(10) NOT NULL,
    FOREIGN KEY (portfolio_id) REFERENCES Portfolios(id) ON DELETE CASCADE,
    FOREIGN KEY (isin) REFERENCES Assets(isin) ON DELETE CASCADE
);

-- =======================================================
-- ESEMPI DI INSERIMENTO (INDICE + ETF CHE LO TRACCIA)
-- =======================================================

-- 1. Creiamo un Indice (S&P 500)
INSERT INTO Indices (symbol, name, inception_date) VALUES 
('^GSPC', 'S&P 500 Index', '1957-03-04');

-- 2. Dati storici finiti per l'indice (S&P 500 a Gennaio 2023)
INSERT INTO Index_Historical_Data (index_id, history_date, close_value) VALUES
(1, '2023-01-01', 3800.00),
(1, '2023-02-01', 3950.00);

-- 3. Creiamo un ETF che traccia l'S&P 500 (collegandolo a index_id = 1)
INSERT INTO Assets (isin, ticker, name, asset_type, inception_date, provider, ter, distribution_policy, currency, tracked_index_id) VALUES 
('IE00B5BMR087', 'CSPX.MI', 'iShares Core S&P 500 UCITS ETF', 'ETF', '2010-05-18', 'iShares', 0.0007, 'Accumulating', 'EUR', 1);

-- 4. Dati storici del prezzo per l'ETF
INSERT INTO Asset_Historical_Prices (isin, price_date, close_price, adj_close) VALUES
('IE00B5BMR087', '2023-01-01', 350.00, 350.00),
('IE00B5BMR087', '2023-02-01', 365.00, 365.00);

-- 5. Creiamo un portafoglio e facciamo finta di aver comprato l'ETF
INSERT INTO Portfolios (name, description, creation_date) VALUES 
('Portafoglio Principale', 'Investimenti base', '2023-01-01');

INSERT INTO Transactions (portfolio_id, isin, transaction_date, transaction_type, quantity, price, fees, currency) VALUES 
(1, 'IE00B5BMR087', '2023-01-15', 'BUY', 10.0, 355.00, 1.50, 'EUR');
