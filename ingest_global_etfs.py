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

# Definizione dei nuovi ETF
etfs_to_fetch = [
    # S&P 500 (index_id = 1)
    {"isin": "US9229083632", "ticker": "VOO", "name": "Vanguard S&P 500 ETF", "currency": "USD", "ter": 0.0003, "index_id": 1},
    {"isin": "IE00B5BMR087", "ticker": "SXR8.DE", "name": "iShares Core S&P 500 UCITS ETF EUR Acc", "currency": "EUR", "ter": 0.0007, "index_id": 1},
    
    # Nasdaq 100 (index_id = 3)
    {"isin": "US46090E1038", "ticker": "QQQ", "name": "Invesco QQQ Trust", "currency": "USD", "ter": 0.0020, "index_id": 3},
    {"isin": "IE00B53SZB19", "ticker": "SXRV.DE", "name": "iShares Nasdaq 100 UCITS ETF EUR Acc", "currency": "EUR", "ter": 0.0033, "index_id": 3},
    
    # EURO STOXX 50 (index_id = 4)
    {"isin": "DE0005933956", "ticker": "EXW1.DE", "name": "iShares EURO STOXX 50 UCITS ETF (DE)", "currency": "EUR", "ter": 0.0016, "index_id": 4},
    
    # MSCI World / FTSE All-World (index_id = 5 proxy)
    {"isin": "IE00B4L5Y983", "ticker": "SWDA.MI", "name": "iShares Core MSCI World UCITS ETF USD (Acc)", "currency": "EUR", "ter": 0.0020, "index_id": 5},
    {"isin": "IE00BK5BQT80", "ticker": "VWCE.DE", "name": "Vanguard FTSE All-World UCITS ETF USD Acc (EUR)", "currency": "EUR", "ter": 0.0022, "index_id": 5},
    {"isin": "IE00BK5BQT80_USD", "ticker": "VWRA.L", "name": "Vanguard FTSE All-World UCITS ETF USD Acc", "currency": "USD", "ter": 0.0022, "index_id": 5}
]

def ingest_etfs():
    conn = mysql.connector.connect(**db_config)
    cursor = conn.cursor(dictionary=True)

    print("--- 1. INSERIMENTO ETF IN DATABASE ---")
    for etf in etfs_to_fetch:
        # Check se esiste già
        cursor.execute("SELECT isin FROM Assets WHERE ticker = %s", (etf['ticker'],))
        if cursor.fetchone():
            print(f"ETF {etf['ticker']} già presente.")
        else:
            cursor.execute("""
                INSERT INTO Assets (isin, ticker, name, asset_type, currency, ter, tracked_index_id) 
                VALUES (%s, %s, %s, 'ETF', %s, %s, %s)
            """, (etf['isin'], etf['ticker'], etf['name'], etf['currency'], etf['ter'], etf['index_id']))
            print(f"Inserito nuovo ETF {etf['ticker']}.")
    conn.commit()

    print("\n--- 2. DOWNLOAD STORICO PREZZI ETF DA YAHOO FINANCE ---")
    for etf in etfs_to_fetch:
        print(f"Scaricamento dati per {etf['ticker']}...")
        
        try:
            data = yf.download(etf['ticker'], period="max", progress=False)
            if data.empty:
                print(f"ERRORE: Nessun dato trovato per {etf['ticker']}")
                continue
                
            if not isinstance(data.index, pd.DatetimeIndex):
                print(f"Indice non riconosciuto per {etf['ticker']}")
                continue
            
            if isinstance(data.columns, pd.MultiIndex):
                try:
                    close_series = data[('Close', etf['ticker'])]
                except KeyError:
                    print(f"Colonna Close non trovata per {etf['ticker']} nel MultiIndex")
                    continue
            else:
                try:
                    close_series = data['Close']
                except KeyError:
                    print(f"Colonna Close non trovata per {etf['ticker']}")
                    continue
                    
            records = []
            for date, close_val in close_series.items():
                if pd.isna(close_val):
                    continue
                records.append((etf['isin'], date.strftime('%Y-%m-%d'), float(close_val)))
            
            # Inseriamo i dati nel database
            print(f"Inserimento di {len(records)} record per {etf['ticker']} nel DB...")
            cursor.executemany("""
                INSERT IGNORE INTO Asset_Historical_Prices (isin, price_date, close_price)
                VALUES (%s, %s, %s)
            """, records)
            conn.commit()
            print(f"Completato per {etf['ticker']}.")
            
        except Exception as e:
            print(f"Errore durante l'elaborazione di {etf['ticker']}: {e}")

    cursor.close()
    conn.close()
    print("\nPROCESSO DI INGESTIONE ETF COMPLETATO!")

if __name__ == "__main__":
    ingest_etfs()
