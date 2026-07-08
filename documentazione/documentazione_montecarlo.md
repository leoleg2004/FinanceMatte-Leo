# 🔮 Guida Definitiva: Simulazione Monte Carlo di Portafoglio

Questo documento spiega l'architettura logica e matematica che fa funzionare lo script `previsione_montecarlo_portafoglio.R`. 
Si tratta di un modello di **Finanza Quantitativa** di altissimo livello, lo stesso utilizzato da fondi pensione e banche d'affari per lo stress-test dei portafogli.

---

## 1. Il Concetto Matematico (Perché Monte Carlo?)
Nel mondo reale, i mercati azionari non crescono lungo una linea retta perfetta (es. +8% fisso ogni anno). Ci sono anni da +20%, anni da -15% e mesi stagnanti. Per prevedere quanto capitale avrai tra 20 anni, non possiamo applicare la formula dell'interesse composto puro, perché ignora il fattore **Rischio/Volatilità**.

La **Simulazione Monte Carlo** risolve questo problema. Invece di tracciare un solo futuro ipotetico, ne simula migliaia (nel nostro script: 1.000 universi paralleli). In alcuni universi vivrai la crisi del '29 o il crollo Covid, in altri un decennio d'oro stile anni '90. 

Mettendo insieme statisticamente tutti questi universi, possiamo capire quali sono gli scenari più probabili e calcolare la forbice di rischio per la tua pensione. Il modello stocastico (probabilistico) che guida tutto questo si chiama **Moto Browniano Geometrico**.

---

## 2. La Costruzione del Modello Dati (Dal Passato al Futuro)

Il codice R è strutturato in 5 blocchi logici sequenziali.

### A. Impostazione delle Regole (Costanti)
All'inizio del file, imposti:
- Gli ETF e i loro Pesi (che formano il tuo "Meta-Strumento").
- L'orizzonte temporale (`ANNI_FUTURI`).
- L'investimento (Capitale inziale e `VERSAMENTO_MENSILE` per il PAC).
- `INFLAZIONE_ANNUA`: Per evitare "l'illusione monetaria" (es. ritrovarsi milioni di Euro che in futuro varranno come noccioline), lo script decurta automaticamente il tasso d'inflazione ogni mese, garantendoti che i numeri calcolati siano "Potere di Acquisto Odierno".

### B. Ingestione e Allineamento Dati
Lo script entra in MySQL e fa il lavoro sporco:
1. Trasforma i prezzi giornalieri in chiusure di fine mese (`slice_tail(n=1)`).
2. Usa il `pivot_wider()` e `drop_na()` per allineare gli ETF su una griglia temporale perfetta. Se un ETF è nato nel 2018 e uno nel 2010, il modello studierà il portafoglio *solo* a partire dal 2018, periodo in cui entrambi gli asset erano tradabili contemporaneamente sul mercato.

### C. Calcolo dei Parametri (Training su dati storici)
Il portafoglio viene fuso riga per riga calcolando i ritorni mensili di ciascun ETF moltiplicati per il loro peso. Dal "super-vettore" dei ritorni storici del portafoglio, lo script estrae le due chiavi di volta del modello:
- **Rendimento Medio ($\mu$):** `mean(Port_Return)`
- **Volatilità/Rischio ($\sigma$):** `sd(Port_Return)`

---

## 3. Il Motore di Generazione degli Universi Paralleli

Questo è il cuore pulsante del codice (il loop).

```R
for(sim in 1:NUM_SIMULAZIONI) {
  rendimenti_futuri <- rnorm(mesi_futuri, mean = mu_mensile, sd = sigma_mensile)
  ...
}
```
Per 1.000 volte, lo script usa la funzione stocastica `rnorm` (generazione di numeri pseudocasuali su Curva di Gauss). `rnorm` crea per magia una sequenza di `mesi_futuri` (es. 240 mesi) di tassi d'interesse. Essendo parametrato su $\mu$ e $\sigma$, questa sequenza probabilistica **rispetterà l'anima del tuo portafoglio**: se hai un portafoglio azionario molto volatile (alto $\sigma$), tirerà fuori spesso mesi da -8% e mesi da +10%. Se hai obbligazioni (basso $\sigma$), i numeri staranno quasi sempre rasenti allo 0%.

Per ogni mese futuro, all'interno del ciclo:
1. Incrementa il saldo precedente moltiplicandolo per il rendimento casuale tirato a sorte dal dado.
2. Aggiunge i soldi freschi del versamento mensile (PAC).
3. Sottrae l'effetto dell'inflazione di quel mese.
Tutto questo viene salvato in una massiccia **Matrice** da 241 righe e 1000 colonne.

---

## 4. Estrazione Statistica: I Percentili
Avendo 1.000 portafogli finali tra 20 anni, calcoliamo le quote di probabilità.

- **[CASO PESSIMO 5%]**: Significa che in 950 universi su 1.000 (95% delle probabilità) avrai *almeno* questa cifra o di più. È l'atterraggio duro, quello che consideri se scoppia una crisi planetaria prolungata. Serve a rispondere alla domanda: *"Mal che vada, a quanto posso affidarmi per la pensione?"*
- **[CASO VEROSIMILE 50%]**: È la mediana matematica. In metà dei mondi possibili farai di più, nell'altra metà farai di meno. È l'asticella di base.
- **[CASO OTTIMO 95%]**: In soli 50 universi su 1.000 sarai così sfacciatamente fortunato da accumulare questo gigantesco capitale o più, cavalcando bolle ininterrotte senza gravi crisi nel mezzo.

---

## 5. Lettura del Grafico: "Spaghetti Plot"
L'output finale è la **Fan Chart** in `ggplot2`.
Vedere a occhio la nuvola grigia delle simulazioni che si espande a dismisura (a forma di ventaglio) dimostra un principio cardine della finanza:
> *"Più a lungo investi, più il ventaglio dei risultati si allarga a dismisura per via dell'interesse composto."*

Le 3 linee colorate ti aiutano visivamente a capire la pendenza dei tre scenari guida, per capire non solo dove finirai tra 20 anni, ma anche le ipotetiche traiettorie che attraverserai nel tragitto!
