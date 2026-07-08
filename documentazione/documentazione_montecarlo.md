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

---

## 6. L'Arsenale Avanzato (I 5 Modelli Stocastici)

Oltre al classico Moto Browniano basato sulla distribuzione normale, il progetto include ora **5 motori fisico-matematici avanzati**, situati nella cartella `ModelloDiRegressione`. Ciascuno di questi script attacca una vulnerabilità specifica della teoria classica, applicando calcoli stocastici avanzati.

Di seguito il dettaglio tecnico su come operano sotto il cofano.

### 1. `previsione_1_bootstrap.R` (Historical Resampling)
La simulazione Monte Carlo standard presume che i mercati seguano una perfetta "Curva a Campana" (Distribuzione Normale). Tuttavia, nel mondo reale, la Borsa è soggetta a "Code Grasse" (Fat Tails): eventi estremi catastrofici (o estremamente positivi) accadono molto più frequentemente di quanto la statistica normale ammetta.
- **Come funziona:** Questo script butta via la formula teorica `rnorm`. Estrae il vettore reale dei rendimenti mensili passati vissuti dal tuo portafoglio. Per simulare il futuro, il ciclo inserisce la "mano" nell'urna del passato e pesca un mese a caso, lo applica al capitale, lo rimette nell'urna e pesca di nuovo (Resampling con re-immissione).
- **Vantaggio matematico:** Preserva intrinsecamente la "Kurtosi" (la probabilità di eventi estremi) e lo "Skew" (l'asimmetria) dei tuoi specifici ETF. Se l'ETF ha subito un crollo del -20% nel marzo 2020, c'è una concreta possibilità che il modello estragga quel mese nero due o tre volte in un anno, simulando una recessione prolungata gravissima, impossibile da prevedere con il classico Moto Browniano.

### 2. `previsione_2_merton_jump.R` (Jump-Diffusion Model)
Ideato da Robert Merton, questo modello teorizza che l'asset model segua un tragitto tranquillo intervallato da "Salti" (Jump) di prezzo impulsivi e discontinui.
- **Come funziona:** Usa due generatori stocastici. Il primo è un normale Moto Browniano che simula le contrattazioni quotidiane. Il secondo è un **Processo di Poisson** (una distribuzione matematica degli eventi rari).
- **Implementazione nel codice:** Impostiamo `LAMBDA = 0.5`, dicendo al sistema che ci aspettiamo in media un grande shock di borsa ogni due anni. Il loop usa `rpois` per determinare se in un mese specifico scatta la bomba. Se l'esito è positivo, usa una seconda normale per calcolare l'entità del collasso (es. un drop medio del -15%). Il rendimento di quel mese sarà la somma del rumore standard più il cratere lasciato dal salto.

### 3. `previsione_3_heston.R` (Volatilità Stocastica)
Il limite più grande del modello base è che calcola una singola volatilità ($\sigma$) oggi e la mantiene fissa nel calcolo per 20 anni. Nella realtà, i mercati passano da anni di estrema apatia (bassa volatilità) ad anni di panico selvaggio (altissima volatilità).
- **Come funziona:** Usa l'equazione differenziale stocastica di Heston che richiede la simulazione parallela di **due** moti browniani correlati. Nel loop for di 240 mesi, il programma calcola una traiettoria per la Volatilità usando un processo CIR (che le impedisce di diventare negativa), e una traiettoria per il Prezzo. 
- **Implementazione nel codice:** È inserito un parametro chiave, `RHO = -0.7`. Significa che le due traiettorie sono inversamente correlate: quando il prezzo scende, l'algoritmo alza in automatico la volatilità del mese successivo, rendendo il crollo più instabile, mimando perfettamente l'Effetto Leva (Leverage Effect) dei mercati azionari reali.

### 4. `previsione_4_ornstein_uhlenbeck.R` (Mean Reverting)
Le azioni tech e gli indici globali come l'S&P 500 tendono a salire per decenni in modo esplosivo (Random Walk con Drift). Tuttavia, altre grandezze finanziarie - come l'Oro, le materie prime o i tassi di interesse delle banche centrali - rispondono a forze fisiche di attrazione verso una media storica, e non possono crescere a dismisura.
- **Come funziona:** Modella la "forza elastica". Il processo assegna al rendimento mensile una trazione verso il parametro $\theta$ (la media a lungo termine), controllata da una velocità $\kappa$.
- **Implementazione nel codice:** Nel ciclo, calcoliamo `Rendimento = Rendimento_Ieri + KAPPA * (Media_Storica - Rendimento_Ieri) + Rumore_Casuale`. Se a causa del rumore casuale il portafoglio segna un +20% fittizio, il mese successivo la formula lo spingerà con forza verso il basso per riassorbirlo verso il suo naturale rendimento mensile (es. +0.6%). Ideale per simulazioni macroeconomiche (inflazione) o asset aurei (`IGLN.L`).

### 5. `previsione_5_garch.R` (Volatility Clustering)
In finanza si dice che "la turbolenza chiama turbolenza" (Cluster di volatilità). Se oggi l'indice crolla del 5%, domani è altamente improbabile che faccia uno 0% calmo; è molto più probabile che faccia un -4% o un +6%. Il modello base non sa nulla del mese precedente.
- **Come funziona:** È il modello più sofisticato del pacchetto, basato sull'algoritmo Autoregressivo Eteroschedastico Condizionato Generalizzato (GARCH 1,1). Tramite la massiccia libreria R `rugarch`, lo script esegue un "Fit" sui dati storici passati del tuo portafoglio. Cerca di "imparare" quanto a lungo dura un tipico momento di panico del tuo ETF.
- **Implementazione nel codice:** Non generiamo numeri grezzi. Invochiamo `ugarchsim`, che in base al modello addestrato produce interi vettori temporali in cui si alternano decenni di quiete a improvvisi "grappoli" pluriennali di estrema volatilità (come il periodo 2000-2003 o 2008-2010). Guardando lo Spaghetti plot di questo modello noterai che, al contrario degli altri, le traiettorie non sono frastagliate in modo omogeneo, ma vivono lunghissime fasi lisce interrotte da improvvisi elettrocardiogrammi impazziti. È la simulazione in assoluto più fedele al comportamento della psicologia umana sui mercati.
