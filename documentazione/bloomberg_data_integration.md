# Integrazione Dati Istituzionali: Roadmap Bloomberg Terminal

Visto che abbiamo accesso a feed dati di livello istituzionale (come il **Bloomberg Terminal** o Refinitiv Eikon), possiamo trasformare il nostro attuale `PortfolioDB` da un semplice archivio di prezzi di chiusura in un vero e proprio **Data Warehouse Quantitativo**. 

L'inserimento di questi dataset avanzati ci permetterebbe di passare da modelli Monte Carlo basati esclusivamente sul passato (storico) a modelli *Forward-Looking* (basati sulle aspettative del mercato prezzate in tempo reale).

Di seguito è riportata la tassonomia completa di ogni tipologia di dato integrabile, strutturata per potenziale modulo del nostro Database.

---

## 1. Dati sui Derivati e Volatilità Implicita (Forward-Looking)
Questo è il dataset più importante per aggiornare il nostro Modello di Heston (che simula la volatilità) da teorico a reale. I derivati ci dicono esattamente quanta paura o avidità sta prezzando il mercato in questo istante.

- **Volatility Surface (Superficie di Volatilità):** I prezzi delle opzioni Call e Put su scadenze diverse (Term Structure) e strike diversi (Volatility Skew). *Ticker BBG: `SPX Volatility Surface`*.
- **Indici di Volatilità e Curve Futures:** L'intero VIX Term Structure (VIX cash, VIX a 1 mese, 2 mesi, ecc.) per capire se il mercato è in Contango (calma) o Backwardation (panico). *Ticker BBG: `VIX Index`, `UXA Comdty`*.
- **SKEW Index:** La misura della probabilità percepita dal mercato per i Cigni Neri (Tail Risk). Più è alto, più gli istituzionali stanno comprando coperture (Put) estreme.

## 2. Fixed Income, Tassi d'Interesse e Rischio di Credito
Il "prezzo del denaro" è la forza di gravità di tutti gli asset (azioni, oro e petrolio inclusi). Modelli come Merton Jump-Diffusion o Black-Scholes richiedono tassi *Risk-Free* ultra-precisi.

- **Yield Curve (Curva dei Rendimenti):** Rendimenti dei titoli di stato USA (Treasuries) e Bund Europei da 1 mese a 30 anni. Ci permette di monitorare l'inversione della curva (segnale primario di recessione).
- **OIS (Overnight Indexed Swap) & SOFR:** La vera curva Risk-Free utilizzata oggi nei desk derivati al posto del vecchio LIBOR.
- **Credit Default Swaps (CDS):** Il costo per assicurarsi contro il fallimento di Stati (Sovereign CDS) o Aziende (Corporate CDS). Il balzo del CDS è il segnale d'allarme più rapido prima di un default (modelli strutturali del rischio di credito).
- **Credit Spreads (High Yield vs Investment Grade):** La differenza di rendimento tra debito spazzatura e debito sicuro. *Ticker BBG: `US HY OAS` (Option-Adjusted Spread)*.

## 3. Dati Macroeconomici e Indicatori Anticipatori
Al momento non abbiamo variabili macroeconomiche. Integrandole, potremmo costruire Modelli di Regressione Multipla che prevedono i rendimenti in base al ciclo economico, o addestrare Reti Neurali.

- **Inflazione & Tassi Centrali:** CPI (Headline e Core), PCE, e le probabilità implicite dei tagli dei tassi della FED estratte dai Fed Funds Futures (*BBG WIRP*).
- **Mercato del Lavoro & Consumi:** Non-Farm Payrolls (NFP), Sussidi di disoccupazione, Vendite al dettaglio.
- **Leading Indicators (PMI):** I Purchasing Managers' Index (PMI Manifatturiero e Servizi) sono indicatori anticipatori. Spesso prevedono gli utili aziendali prima ancora che vengano dichiarati.
- **Indici di Sorpresa Economica (Citigroup Economic Surprise Index):** Misura se i dati macro stanno uscendo migliori o peggiori delle aspettative degli analisti.

## 4. Dati Microstrutturali e di Flusso (Order Flow)
Questi dati ad altissima frequenza sono il pane quotidiano degli HFT (High-Frequency Trading) e servono per algoritmi di esecuzione o per analisi di liquidità.

- **Tick-by-Tick Data & Order Book (Level 2/3):** Non solo il prezzo di chiusura, ma ogni singolo trade avvenuto al millisecondo (Bid/Ask spread, profondità del book, Market Orders vs Limit Orders).
- **Dark Pool Volumes:** La percentuale di transazioni avvenute fuori dai mercati regolamentati, dove operano le mega-istituzioni in blocco.
- **Commitments of Traders (COT):** Per asset come Oro e Petrolio, questo report (pubblicato dalla CFTC) ci dice in modo netto se i Commercials (produttori) o gli Speculators (Hedge Fund) sono net-long o net-short sui futures.
- **Gamma Exposure (GEX):** Il posizionamento netto in opzioni dei Market Maker. Quando il GEX è negativo, i market maker devono vendere quando il mercato scende (accelerando i crash).

## 5. Dati Fondamentali Aggregati ed ESG (Per ETF)
Anche se abbiamo a che fare con ETF e non singole azioni, un ETF è semplicemente un paniere. Con Bloomberg possiamo esplodere questo paniere ("Look-through").

- **Aggregati di Valutazione:** Il vero P/E (Price to Earnings) Forward del VWCE, calcolato pesando i P/E previsti di tutte le sue 3.000 aziende. EPS Growth, Dividend Yield effettivo, Price/Book Ratio aggregato.
- **Dati ESG (Environmental, Social, Governance):** Punteggi di sostenibilità aggregati, Carbon Footprint (impronta di carbonio del portafoglio), esposizione a settori controversi (Armi, Tabacco).

## 6. Alternative Data e Sentiment
I dati quantitativi non-standard che negli ultimi anni hanno dominato la ricerca *Quant*.

- **News Sentiment Analysis:** Dataset in cui un NLP (Natural Language Processing) ha già letto tutte le notizie finanziarie di giornata assegnando un punteggio da -1 (Negativo) a +1 (Positivo) per ogni asset.
- **Short Interest & Cost to Borrow:** Quante azioni di un determinato ETF sono state prese in prestito per essere vendute allo scoperto, e quanto costa prenderle in prestito.

---

### Prossimi Passi per il Database MySQL
Per accogliere questi dati, la struttura del nostro MySQL dovrà essere espansa creando tabelle relazionali specifiche, ad esempio:
- `Macro_Indicators` (per inflazione, tassi, PMI).
- `Options_Implied_Vol` (per mappare la Volatility Surface).
- `Asset_Fundamentals` (per salvare trimestralmente il P/E e i Dividend Yield degli ETF).

**Possiamo integrare in Python la libreria `blpapi` (l'API ufficiale di Bloomberg) o `pdblp` per scaricare automaticamente questi dati dal Terminal e aggiornare `PortfolioDB` ogni notte.**
