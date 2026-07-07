# 🗺️ Mappatura Database: ETF e Indici di Riferimento

Questo documento esplica la struttura del database `PortfolioDB` aggiornato. Mostra esattamente quali Indici abbiamo a disposizione per le regressioni e quali ETF sono collegati ad essi, inclusa la loro valuta di negoziazione e il TER (Total Expense Ratio).

---

## 1. 🇺🇸 S&P 500 (Le 500 maggiori aziende USA)
**Ticker Indice nel DB:** `^GSPC`

| Ticker ETF | Nome Fondo | Valuta | TER | Info |
|------------|------------|--------|-----|------|
| **VOO** | Vanguard S&P 500 ETF | USD | 0.03% | L'ETF nativo americano per eccellenza sull'S&P 500. |
| **SXR8.DE** | iShares Core S&P 500 UCITS ETF | EUR | 0.07% | La versione europea (Xetra) ad accumulazione, perfetta per investitori in Euro. |

---

## 2. 💻 Nasdaq 100 (Le 100 maggiori aziende tech USA)
**Ticker Indice nel DB:** `^NDX`

| Ticker ETF | Nome Fondo | Valuta | TER | Info |
|------------|------------|--------|-----|------|
| **QQQ** | Invesco QQQ Trust | USD | 0.20% | L'ETF storico americano che traccia il Nasdaq. |
| **SXRV.DE** | iShares Nasdaq 100 UCITS ETF | EUR | 0.33% | La versione armonizzata europea prezzata in Euro. |

---

## 3. 🇪🇺 EURO STOXX 50 (Le 50 maggiori aziende dell'Eurozona)
**Ticker Indice nel DB:** `^STOXX50E`

| Ticker ETF | Nome Fondo | Valuta | TER | Info |
|------------|------------|--------|-----|------|
| **EXW1.DE** | iShares EURO STOXX 50 UCITS ETF (DE) | EUR | 0.16% | L'ETF più liquido in Europa per investire direttamente sulle blue-chip dell'Eurozona. |

---

## 4. 🌍 MSCI World / FTSE All-World (Paesi Sviluppati Globali)
**Ticker Indice nel DB:** `URTH` *(Usato come proxy nativo in USD per l'indice MSCI World)*

| Ticker ETF | Nome Fondo | Valuta | TER | Info |
|------------|------------|--------|-----|------|
| **SWDA.MI** | iShares Core MSCI World UCITS ETF | EUR | 0.20% | Uno degli ETF più famosi in Italia per coprire i paesi sviluppati. |
| **VWCE.DE** | Vanguard FTSE All-World UCITS ETF | EUR | 0.22% | Il re dei PAC europei, include anche i mercati emergenti. |
| **VWRA.L** | Vanguard FTSE All-World UCITS ETF | USD | 0.22% | La versione in Dollari del VWCE scambiata sulla borsa di Londra. |

---

## 5. 🌐 MSCI ACWI (Azionario Globale Completo)
**Ticker Indice nel DB:** `MSCI ACWI` *(Importato storicamente dal tuo file Excel)*

| Ticker ETF | Nome Fondo | Valuta | TER | Info |
|------------|------------|--------|-----|------|
| **IUSQ.DE** | iShares MSCI ACWI UCITS ETF | EUR | 0.20% | ETF azionario globale completo scambiato su Xetra. |
| **SSAC.L** | iShares MSCI ACWI UCITS ETF | USD | 0.20% | Stesso fondo scambiato a Londra in Dollari. |

---

### 🔍 Come usare questa mappa per i modelli
Nel prossimo script R che creeremo, ti basterà inserire il `Ticker ETF` (es. `SXR8.DE`) e lo script andrà automaticamente a cercare il suo indice corrispondente (es. `^GSPC`) calcolando la Tracking Difference, i tassi di crescita e il coefficiente Beta.
