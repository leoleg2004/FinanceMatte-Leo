import mysql.connector
import yfinance as yf
import pandas as pd

# Credenziali DB
db_config = {
    'host': '127.0.0.1',
    'user': 'root',
    'password': 'Root1234!',
    'database': 'PortfolioDB'
}

def ingest_oil():
    conn = mysql.connector.connect(**db_config)
    cursor = conn.cursor(dictionary=True)
    
    # 1. Inserisci Indice WTI Crude Oil
    index_ticker = "CL=F"
    index_name = "Crude Oil WTI Futures"
    
    cursor.execute("SELECT id FROM Indices WHERE symbol = %s", (index_ticker,))
    result = cursor.fetchone()
    if result:
        print(f"Indice {index_ticker} già presente con ID {result['id']}")
        idx_id = result['id']
    else:
        cursor.execute("INSERT INTO Indices (name, symbol) VALUES (%s, %s)", (index_name, index_ticker))
        idx_id = cursor.lastrowid
        print(f"Inserito nuovo indice {index_ticker} con ID {idx_id}")
    
    # 2. Inserisci ETF USO
    etf_isin = "US91232N2071"
    etf_ticker = "USO"
    etf_name = "United States Oil Fund LP"
    etf_currency = "USD"
    etf_ter = 0.0060 # approx
    
    cursor.execute("SELECT isin FROM Assets WHERE ticker = %s", (etf_ticker,))
    if cursor.fetchone():
        print(f"ETF {etf_ticker} già presente.")
    else:
        cursor.execute("""
            INSERT INTO Assets (isin, ticker, name, asset_type, currency, ter, tracked_index_id) 
            VALUES (%s, %s, %s, 'ETF', %s, %s, %s)
        """, (etf_isin, etf_ticker, etf_name, etf_currency, etf_ter, idx_id))
        print(f"Inserito nuovo ETF {etf_ticker}.")
    conn.commit()
    
    # 3. Scarica Storico Indice
    print(f"Scaricamento dati per Indice {index_ticker}...")
    data_idx = yf.download(index_ticker, period="max", progress=False)
    if not data_idx.empty:
        close_series = data_idx[('Close', index_ticker)] if isinstance(data_idx.columns, pd.MultiIndex) else data_idx['Close']
        records_idx = []
        for date, close_val in close_series.items():
            if not pd.isna(close_val):
                records_idx.append((idx_id, date.strftime('%Y-%m-%d'), float(close_val)))
        cursor.executemany("INSERT IGNORE INTO Index_Historical_Data (index_id, history_date, close_value) VALUES (%s, %s, %s)", records_idx)
        conn.commit()
        print(f"Completato Inserimento Storico Indice {index_ticker}.")

    # 4. Scarica Storico ETF
    print(f"Scaricamento dati per ETF {etf_ticker}...")
    data_etf = yf.download(etf_ticker, period="max", progress=False)
    if not data_etf.empty:
        close_series = data_etf[('Close', etf_ticker)] if isinstance(data_etf.columns, pd.MultiIndex) else data_etf['Close']
        records_etf = []
        for date, close_val in close_series.items():
            if not pd.isna(close_val):
                records_etf.append((etf_isin, date.strftime('%Y-%m-%d'), float(close_val)))
        cursor.executemany("INSERT IGNORE INTO Asset_Historical_Prices (isin, price_date, close_price) VALUES (%s, %s, %s)", records_etf)
        conn.commit()
        print(f"Completato Inserimento Storico ETF {etf_ticker}.")

    cursor.close()
    conn.close()
    print("INGESTIONE OIL COMPLETATA")

if __name__ == "__main__":
    ingest_oil()
