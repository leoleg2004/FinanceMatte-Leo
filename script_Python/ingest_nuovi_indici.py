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

# Nuovi Indici / Benchmark
indices_to_fetch = [
    {"ticker": "^RUT", "name": "Russell 2000 Index"},
    {"ticker": "GC=F", "name": "Gold Futures (USD)"},
    {"ticker": "XLK",  "name": "S&P 500 Info Tech Proxy (XLK)"},
    {"ticker": "EEM",  "name": "MSCI Emerging Markets Proxy (EEM)"}
]

def ingest_indices():
    conn = mysql.connector.connect(**db_config)
    cursor = conn.cursor(dictionary=True)

    print("--- 1. INSERIMENTO NUOVI INDICI IN DATABASE ---")
    for idx in indices_to_fetch:
        cursor.execute("SELECT id FROM Indices WHERE symbol = %s", (idx['ticker'],))
        result = cursor.fetchone()
        
        if result:
            print(f"Indice {idx['ticker']} già presente con ID {result['id']}")
            idx['db_id'] = result['id']
        else:
            cursor.execute("""
                INSERT INTO Indices (name, symbol) 
                VALUES (%s, %s)
            """, (idx['name'], idx['ticker']))
            idx['db_id'] = cursor.lastrowid
            print(f"Inserito nuovo indice {idx['ticker']} con ID {idx['db_id']}")
    conn.commit()

    print("\n--- 2. DOWNLOAD STORICO NUOVI INDICI DA YAHOO FINANCE ---")
    for idx in indices_to_fetch:
        print(f"Scaricamento dati per {idx['ticker']}...")
        
        try:
            data = yf.download(idx['ticker'], period="max", progress=False)
            if data.empty:
                print(f"ERRORE: Nessun dato trovato per {idx['ticker']}")
                continue
            
            if isinstance(data.columns, pd.MultiIndex):
                try:
                    close_series = data[('Close', idx['ticker'])]
                except KeyError:
                    print(f"Colonna Close non trovata nel MultiIndex per {idx['ticker']}")
                    continue
            else:
                close_series = data['Close']
                
            records = []
            for date, close_val in close_series.items():
                if pd.isna(close_val):
                    continue
                records.append((idx['db_id'], date.strftime('%Y-%m-%d'), float(close_val)))
                
            print(f"Inserimento di {len(records)} record per {idx['ticker']} nel DB...")
            cursor.executemany("""
                INSERT IGNORE INTO Index_Historical_Data (index_id, history_date, close_value)
                VALUES (%s, %s, %s)
            """, records)
            conn.commit()
            print(f"Completato per {idx['ticker']}.")
            
        except Exception as e:
            print(f"Errore durante l'elaborazione di {idx['ticker']}: {e}")

    cursor.close()
    conn.close()
    print("\nPROCESSO DI INGESTIONE NUOVI INDICI COMPLETATO!")

if __name__ == "__main__":
    ingest_indices()
