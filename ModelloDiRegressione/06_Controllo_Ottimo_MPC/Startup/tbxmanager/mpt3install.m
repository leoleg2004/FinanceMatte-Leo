% =========================================================================
% SCRIPT DI INSTALLAZIONE MPT3 PER APPLE SILICON (M1/M2/M3)
% Risolve: incompatibilità MACI64/MACA64, dipendenze C++, Path e Gatekeeper
% =========================================================================

fprintf('Inizio procedura di installazione automatica...\n\n');

% 1. INSTALLAZIONE DIPENDENZE DI SISTEMA (HOMEBREW)
fprintf('1/7: Controllo e installazione dipendenze di sistema (cddlib)...\n');
% Forza MATLAB a usare il percorso di Homebrew
[status, ~] = system('export PATH="/opt/homebrew/bin:$PATH" && brew install cddlib');
if status ~= 0
    fprintf('⚠️ Avviso: Impossibile eseguire Homebrew da MATLAB. Se hai già cddlib ignora questo messaggio.\n');
end

% 2. SETUP TBXMANAGER
fprintf('2/7: Download del gestore tbxmanager...\n');
websave('tbxmanager.m', 'http://www.tbxmanager.com/tbxmanager.m');

% 3. INGANNO ARCHITETTURA E DOWNLOAD PACCHETTI
fprintf('3/7: Download di MPT e YALMIP (simulazione Intel in corso...)...\n');
% Crea una finta funzione "computer" per ingannare tbxmanager
fid = fopen('computer.m', 'w');
fprintf(fid, 'function [c, m, e] = computer(varargin)\n    c = ''MACI64''; m = 281474976710655; e = ''L'';\nend\n');
fclose(fid);
rehash;

try
    tbxmanager;
    tbxmanager install mpt mptdoc yalmip; % Ignoriamo sedumi volutamente
catch ME
    delete('computer.m'); % Rimuove l'inganno in caso di errore
    rethrow(ME);
end
delete('computer.m'); % Rimuove l'inganno a download completato
rehash;

% 4. DOWNLOAD PATCH APPLE SILICON
fprintf('4/7: Download della patch nativa per chip M3...\n');
zipUrl = 'https://github.com/sukruayyildiz/mpt3-apple-silicon/archive/refs/heads/main.zip';
zipFile = fullfile(pwd, 'mpt3_patch.zip');
websave(zipFile, zipUrl);

extractedFolder = fullfile(pwd, 'mpt3_patch_extracted');
if exist(extractedFolder, 'dir')
    rmdir(extractedFolder, 's');
end
unzip(zipFile, extractedFolder);

% 5. RICERCA DINAMICA E INSTALLAZIONE BINARI
fprintf('5/7: Applicazione dinamica della patch per MACA64...\n');
tbxDir = fileparts(which('tbxmanager'));
if isempty(tbxDir)
    tbxDir = pwd;
end

% Creazione forzata delle cartelle di destinazione
cddPath = fullfile(tbxDir, 'toolboxes', 'cddmex', 'default');
fourPath = fullfile(tbxDir, 'toolboxes', 'fourier', 'default');
lcpPath = fullfile(tbxDir, 'toolboxes', 'lcp', 'default');
if ~exist(cddPath, 'dir'), mkdir(cddPath); end
if ~exist(fourPath, 'dir'), mkdir(fourPath); end
if ~exist(lcpPath, 'dir'), mkdir(lcpPath); end

% Scansione e smistamento dei file .mexmaca64
mexFiles = dir(fullfile(extractedFolder, '**', '*.mexmaca64'));
for i = 1:length(mexFiles)
    srcFile = fullfile(mexFiles(i).folder, mexFiles(i).name);
    if contains(mexFiles(i).name, 'cddmex', 'IgnoreCase', true)
        copyfile(srcFile, cddPath, 'f');
    elseif contains(mexFiles(i).name, 'fourier', 'IgnoreCase', true)
        copyfile(srcFile, fourPath, 'f');
    elseif contains(mexFiles(i).name, 'lcp', 'IgnoreCase', true)
        copyfile(srcFile, lcpPath, 'f');
    end
end

% 6. AGGIORNAMENTO PATH E PULIZIA
fprintf('6/7: Aggiornamento delle variabili di sistema e pulizia...\n');
addpath(cddPath); addpath(fourPath); addpath(lcpPath);
savepath;

delete(zipFile);
rmdir(extractedFolder, 's');

% 7. SBLOCCO SICUREZZA MACOS E RIAVVIO CACHE
fprintf('7/7: Sblocco di macOS Gatekeeper e pulizia cache...\n');
toolboxesDir = fullfile(tbxDir, 'toolboxes');
system(sprintf('xattr -r -d com.apple.quarantine "%s" 2>/dev/null', toolboxesDir));

clear classes;
rehash toolboxcache;
mpt