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

## 6. 🏭 Small Cap USA (Aziende a bassa capitalizzazione)
**Ticker Indice nel DB:** `^RUT` *(Russell 2000 Index)*

| Ticker ETF | Nome Fondo | Valuta | TER | Info |
|------------|------------|--------|-----|------|
| **IWM** | iShares Russell 2000 ETF | USD | 0.19% | L'ETF americano più liquido per le Small Cap USA. |
| **ZPRR.DE** | SPDR Russell 2000 US Small Cap UCITS | EUR | 0.30% | La controparte armonizzata UCITS europea. |

---

## 7. 🥇 Oro Fisico (Materia Prima)
**Ticker Indice nel DB:** `GC=F` *(Gold Futures USD)*

| Ticker ETF | Nome Fondo | Valuta | TER | Info |
|------------|------------|--------|-----|------|
| **IGLN.L** | iShares Physical Gold ETC | USD | 0.12% | ETC a replica fisica sull'oro scambiato in dollari. |
| **SGLD.MI** | Invesco Physical Gold ETC | EUR | 0.12% | Ottimo ETC per esporsi all'oro sulla borsa di Milano. |

---

## 8. 💻 Information Technology USA (Settore Tech S&P 500)
**Ticker Indice nel DB:** `XLK` *(Technology Select Sector SPDR Fund proxy)*

| Ticker ETF | Nome Fondo | Valuta | TER | Info |
|------------|------------|--------|-----|------|
| **QDVE.DE** | iShares S&P 500 Info Tech Sector UCITS | EUR | 0.15% | Per sovrappesare le Big Tech americane. |

---

## 9. 🌏 Mercati Emergenti (Cina, India, Brasile, etc.)
**Ticker Indice nel DB:** `EEM` *(iShares MSCI Emerging Markets ETF proxy)*

| Ticker ETF | Nome Fondo | Valuta | TER | Info |
|------------|------------|--------|-----|------|
| **EIMI.MI** | iShares Core MSCI EM IMI UCITS ETF | EUR | 0.18% | L'ETF leader in Europa per i mercati emergenti. |

---

### 🔍 Come usare questa mappa per i modelli
Nel prossimo script R che creeremo, ti basterà inserire il `Ticker ETF` (es. `SXR8.DE`) e lo script andrà automaticamente a cercare il suo indice corrispondente (es. `^GSPC`) calcolando la Tracking Difference, i tassi di crescita e il coefficiente Beta.
