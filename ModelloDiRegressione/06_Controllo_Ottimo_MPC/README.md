Sviluppatore: Ing. Leonardo Leggeri

Ambito: Sistemi di Controllo del Volo (Flight Control Systems - FCS)

Descrizione del Progetto

In qualità di progettista del sistema, ho sviluppato una suite di software dedicata all'automazione del controllo longitudinale di un velivolo F-16 Fighting Falcon. L'obiettivo primario dell'architettura è la gestione della stabilità e della risposta dinamica lungo l'asse di beccheggio (pitch), garantendo precisione millimetrica nelle fasi di assetto variabile.

Il cuore dell'algoritmo risiede nell'elaborazione dei modelli in spazio di stato (State-Space), dove il comportamento del velivolo viene linearizzato e gestito attraverso matrici dinamiche.

Implementazione Attuale: Controllo Longitudinale

Il software attuale opera filtrando ed elaborando i parametri estratti dalle matrici di sistema specifiche per la dinamica longitudinale:

Matrice di Stato (A 
long
​	
 ): Definisce come le variabili di stato (velocità, angolo d'attacco, velocità di beccheggio) interagiscono tra loro.

Matrice di Input (B 
long
​	
 ): Definisce l'autorità dei comandi (principalmente gli equilibratori/stabilizzatori orizzontali) sul sistema, viene poi divisa in B_ctrl e B_wind, la prima sarà utilizzata per creare il controllo lqr e mpc.

L'automazione garantisce che il velivolo mantenga i parametri desiderati anche in regimi di volo complessi, correggendo istantaneamente le perturbazioni esterne.

Estensioni Future: Controllo Latero-Direzionale

La struttura modulare degli script che ho creato è stata progettata per essere altamente scalabile. È infatti possibile estendere l'efficacia del controllo anche alla dinamica latero-direzionale (rollio e imbardata).

L'estensione prevede una transizione metodologica chiara:

Sostituzione delle Matrici: Integrazione delle matrici A 
lat
​	
  e B 
lat
​	
 , che descrivono le interazioni tra l'angolo di derapata (sideslip), il tasso di rollio e il tasso di imbardata.

Filtraggio Specifico: Gli algoritmi di filtraggio verranno ricalibrati per isolare le diverse costanti di tempo tipiche dei modi latero-direzionali (come il modo di rollio, il modo spirale e il "Dutch Roll").

Controllo Multivariabile: L'autorità di comando verrà estesa agli alettoni e al timone direzionale, mantenendo la stessa logica di automazione robusta già implementata per il beccheggio.
