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

def get_index_id(cursor, symbol):
    cursor.execute("SELECT id FROM Indices WHERE symbol = %s", (symbol,))
    result = cursor.fetchone()
    if result:
        return result['id']
    return None

def ingest_etfs():
    conn = mysql.connector.connect(**db_config)
    cursor = conn.cursor(dictionary=True)
    
    # Mappiamo gli ID degli indici inseriti precedentemente
    id_rut = get_index_id(cursor, "^RUT")
    id_gold = get_index_id(cursor, "GC=F")
    id_tech = get_index_id(cursor, "XLK")
    id_eem = get_index_id(cursor, "EEM")
    
    etfs_to_fetch = [
        # Russell 2000
        {"isin": "US4642876555", "ticker": "IWM", "name": "iShares Russell 2000 ETF", "currency": "USD", "ter": 0.0019, "index_id": id_rut},
        {"isin": "IE00B60SQZ31", "ticker": "ZPRR.DE", "name": "SPDR Russell 2000 US Small Cap UCITS", "currency": "EUR", "ter": 0.0030, "index_id": id_rut},
        
        # Gold
        {"isin": "IE00B4ND3602", "ticker": "IGLN.L", "name": "iShares Physical Gold ETC", "currency": "USD", "ter": 0.0012, "index_id": id_gold},
        {"isin": "IE00B579F325", "ticker": "SGLD.MI", "name": "Invesco Physical Gold ETC", "currency": "EUR", "ter": 0.0012, "index_id": id_gold},
        
        # Info Tech
        {"isin": "IE00B3WJKG14", "ticker": "QDVE.DE", "name": "iShares S&P 500 Info Tech Sector UCITS", "currency": "EUR", "ter": 0.0015, "index_id": id_tech},
        
        # Emerging Markets
        {"isin": "IE00BKM4GZ66", "ticker": "EIMI.MI", "name": "iShares Core MSCI EM IMI UCITS ETF", "currency": "EUR", "ter": 0.0018, "index_id": id_eem}
    ]

    print("--- 1. INSERIMENTO NUOVI ETF IN DATABASE ---")
    for etf in etfs_to_fetch:
        if etf['index_id'] is None:
            print(f"Skipping {etf['ticker']} perché l'indice non è stato trovato.")
            continue
            
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

    print("\n--- 2. DOWNLOAD STORICO NUOVI ETF DA YAHOO FINANCE ---")
    for etf in etfs_to_fetch:
        print(f"Scaricamento dati per {etf['ticker']}...")
        try:
            data = yf.download(etf['ticker'], period="max", progress=False)
            if data.empty:
                print(f"ERRORE: Nessun dato trovato per {etf['ticker']}")
                continue
                
            if isinstance(data.columns, pd.MultiIndex):
                try:
                    close_series = data[('Close', etf['ticker'])]
                except KeyError:
                    print(f"Colonna Close non trovata per {etf['ticker']} nel MultiIndex")
                    continue
            else:
                close_series = data['Close']
                
            records = []
            for date, close_val in close_series.items():
                if pd.isna(close_val):
                    continue
                records.append((etf['isin'], date.strftime('%Y-%m-%d'), float(close_val)))
            
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
    print("\nPROCESSO DI INGESTIONE NUOVI ETF COMPLETATO!")

if __name__ == "__main__":
    ingest_etfs()
