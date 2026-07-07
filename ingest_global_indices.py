import mysql.connector
import yfinance as yf
import pandas as pd
from datetime import datetime

# Credenziali DB
db_config = {
    'host': '127.0.0.1',
    'user': 'root',
    'password': 'Root1234!',
    'database': 'PortfolioDB'
}

# Definizione degli Indici (Ticker su Yahoo Finance)
indices_to_fetch = [
    {"name": "S&P 500 (USA)", "ticker": "^GSPC", "desc": "Le 500 maggiori aziende statunitensi"},
    {"name": "Nasdaq 100 (USA Tech)", "ticker": "^NDX", "desc": "Le 100 maggiori aziende tecnologiche USA"},
    {"name": "EURO STOXX 50 (Europe)", "ticker": "^STOXX50E", "desc": "Le 50 maggiori aziende dell'Eurozona"},
    {"name": "MSCI World (Proxy YF)", "ticker": "URTH", "desc": "Proxy per l'MSCI World in USD (Paesi Sviluppati)"}
]

def ingest_indices():
    conn = mysql.connector.connect(**db_config)
    cursor = conn.cursor(dictionary=True)

    print("--- 1. INSERIMENTO INDICI IN DATABASE ---")
    for idx in indices_to_fetch:
        # Check se esiste già
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

    print("\n--- 2. DOWNLOAD STORICO INDICI DA YAHOO FINANCE ---")
    for idx in indices_to_fetch:
        print(f"Scaricamento dati per {idx['ticker']}...")
        
        try:
            # Scarichiamo il massimo storico disponibile
            data = yf.download(idx['ticker'], period="max", progress=False)
            if data.empty:
                print(f"ERRORE: Nessun dato trovato per {idx['ticker']}")
                continue
                
            # Convertiamo l'indice (date) in stringa per SQL
            # Se la colonna Date non è già colonna
            if not isinstance(data.index, pd.DatetimeIndex):
                print(f"Indice non riconosciuto per {idx['ticker']}")
                continue
            
            # Gestione del MultiIndex (se presente)
            if isinstance(data.columns, pd.MultiIndex):
                # Flatten the MultiIndex keeping only the 'Close' column for the ticker
                try:
                    close_series = data[('Close', idx['ticker'])]
                except KeyError:
                    print(f"Colonna Close non trovata per {idx['ticker']} nel MultiIndex")
                    continue
            else:
                try:
                    close_series = data['Close']
                except KeyError:
                    print(f"Colonna Close non trovata per {idx['ticker']}")
                    continue
                    
            records = []
            for date, close_val in close_series.items():
                if pd.isna(close_val):
                    continue
                records.append((idx['db_id'], date.strftime('%Y-%m-%d'), float(close_val)))
            
            # Inseriamo i dati nel database (IGNORANDO I DUPLICATI)
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
    print("\nPROCESSO DI INGESTIONE INDICI COMPLETATO!")

if __name__ == "__main__":
    ingest_indices()
