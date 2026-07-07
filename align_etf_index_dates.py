import mysql.connector

db_config = {
    'host': '127.0.0.1',
    'user': 'root',
    'password': 'Root1234!',
    'database': 'PortfolioDB'
}

def clean_database():
    conn = mysql.connector.connect(**db_config)
    cursor = conn.cursor()

    print("--- 3. ALLINEAMENTO DATE ETF <-> INDICI ---")
    print("Rimozione dei prezzi ETF nei giorni in cui il mercato dell'Indice di riferimento era chiuso...")
    
    # Rimuoviamo i prezzi degli ETF se non esiste un corrispondente valore dell'indice nella stessa data
    delete_query = """
    DELETE ahp
    FROM Asset_Historical_Prices ahp
    JOIN Assets ast ON ahp.isin = ast.isin
    LEFT JOIN Index_Historical_Data ihd 
        ON ast.tracked_index_id = ihd.index_id 
        AND ahp.price_date = ihd.history_date
    WHERE ihd.id IS NULL;
    """
    
    cursor.execute(delete_query)
    deleted_rows = cursor.rowcount
    conn.commit()
    
    print(f"Rimossi {deleted_rows} record disallineati (es. festività nazionali sfalsate).")
    
    cursor.close()
    conn.close()
    print("Allineamento completato!")

if __name__ == "__main__":
    clean_database()
