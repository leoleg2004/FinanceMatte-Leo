📂 USB_Drive (exFAT)

┣ 📂 1_Serie_Storiche_Azionarie
┃  ┣ 📄 SPX_Daily.csv      (S&P 500)
┃  ┣ 📄 SXXP_Daily.csv     (Euro Stoxx 600)
┃  ┣ 📄 MXWD_Daily.csv     (MSCI ACWI)
┃  ┗ 📄 MXEF_Daily.csv     (MSCI Emerging Markets)
┃
┣ 📂 2_Skew_Storico_Merton
┃  ┣ 📄 SPX_Skew.csv       
┃  ┣ 📄 SXXP_Skew.csv      
┃  ┗ 📄 MXWD_Skew.csv      
┃
┣ 📂 3_Superfici_Volatilita_Heston
┃  ┣ 📄 SPX_VolSurface.csv    
┃  ┣ 📄 SXXP_VolSurface.csv   
┃  ┗ 📄 MXEF_VolSurface.csv   
┃
┗ 📂 4_Tassi_OrnsteinUhlenbeck
┣ 📄 US_Rates_Curve.csv 
┗ 📄 EU_Rates_Curve.csv


Dettaglio dei file e delle formule
Per i file storici (Cartelle 1, 2 e 4), imposterai in Excel la formula =BDH con frequenza Daily e un orizzonte temporale di 15-20 anni (es. da 01/01/2006 a oggi).
📁 1_Serie_Storiche_Azionarie
(Serve per: Markowitz, Monte Carlo, Bootstrap, GARCH)
Colonna A: Date
Colonna B: Ticker (es. SPX Index)
Colonna C: PX_LAST (Prezzo spot)
Colonna D: TOT_RETURN_INDEX_GROSS_DVDS (Indice Total Return)
Colonna E: PX_VOLUME (Volumi)
Colonna F: EQY_DIV_YLD_INDX (Dividend Yield)
📁 2_Skew_Storico_Merton
(Serve per: calibrare la frequenza e l'impatto dei salti nel modello Jump-Diffusion)
Colonna A: Date
Colonna B: Ticker
Colonna C: 30D_IMPL_VOL_25D_PUT (Volatilità implicita Put OTM)
Colonna D: 30D_IMPL_VOL_ATM (Volatilità implicita At-The-Money)
Colonna E: 30D_IMPL_VOL_25D_CALL (Volatilità implicita Call OTM)
Colonna F: VOLATILITY_90D (Volatilità storica a 90 giorni)
📁 3_Superfici_Volatilita_Heston
(Serve per: calibrare il parametro di correlazione e la vol-of-vol nel modello Heston)
ATTENZIONE: Non usare =BDH. Usa l'esportazione nativa:
    Digita sul terminale: SPX Index OVDV <GO>
    Vai su Matrix o Surface
  Clicca Export to Excel
  Il file generato conterrà automaticamente una matrice dove le Righe sono il Moneyness/Strike e le Colonne sono le Scadenze temporali.
  📁 4_Tassi_OrnsteinUhlenbeck
  (Serve per: calibrare la mean-reversion sui tassi di sconto stocastici)
  File US_Rates_Curve.csv:
    Date
  USGG3M Index (T-Bill 3 Mesi)
  USGG10YR Index (Treasury 10 Anni)
  SOFRRATE Index (SOFR)
  File EU_Rates_Curve.csv:
    Date
  GTDEM3M Govt (Bund 3 Mesi)
  GTDEM10Y Govt (Bund 10 Anni)
  ESTRON Index (€STR)
  Ricordati i tre passaggi obbligatori in laboratorio prima di salvare i CSV sulla chiavetta: Seleziona tutto → Copia → Incolla Valori.