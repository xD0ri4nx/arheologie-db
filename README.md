Arhitectura Bazei de Date - Proiect Arheologie
Acest repository conține schema structurală și instrucțiunile necesare pentru inițializarea bazei de date relaționale (PostgreSQL) destinate managementului descoperirilor arheologice (morminte, schelete, fragmente osoase și asocieri QR).

Baza de date rulează izolat într-un container, asigurând un mediu de dezvoltare identic pentru toți membrii echipei, indiferent de sistemul de operare utilizat.

1. Cerințe preliminare
Înainte de a rula comenzile, asigurați-vă că aveți instalat unul dintre următoarele medii, în funcție de sistemul dumneavoastră de operare:

Windows / macOS: Instalați Docker Desktop.

Linux: Instalați Podman (recomandat pe Arch/Fedora) sau Docker Engine. Notă: În comenzile de mai jos, docker și podman sunt interschimbabile.

2. Inițializarea containerului și a bazei de date
Descărcați acest repository pe mașina locală și deschideți terminalul (sau PowerShell) în directorul în care se află fișierul init_schema.sql. La prima rulare, scriptul SQL va crea automat toate tabelele și relațiile necesare.

Rulați comanda corespunzătoare sistemului dumneavoastră:

Pentru Linux (Podman / Docker):

Bash
podman run -d \
  --name db_arheologie \
  -e POSTGRES_USER=admin_arheo \
  -e POSTGRES_PASSWORD=parola_secreta \
  -e POSTGRES_DB=arheologie \
  -p 5433:5432 \
  -v $(pwd)/init_schema.sql:/docker-entrypoint-initdb.d/init_schema.sql:Z \
  -v pgdata_arheo:/var/lib/postgresql/data \
  docker.io/library/postgres:16-alpine
Pentru macOS (Terminal cu Docker Desktop):

Bash
docker run -d \
  --name db_arheologie \
  -e POSTGRES_USER=admin_arheo \
  -e POSTGRES_PASSWORD=parola_secreta \
  -e POSTGRES_DB=arheologie \
  -p 5433:5432 \
  -v $(pwd)/init_schema.sql:/docker-entrypoint-initdb.d/init_schema.sql \
  -v pgdata_arheo:/var/lib/postgresql/data \
  postgres:16-alpine
Pentru Windows (PowerShell cu Docker Desktop):

PowerShell
docker run -d `
  --name db_arheologie `
  -e POSTGRES_USER=admin_arheo `
  -e POSTGRES_PASSWORD=parola_secreta `
  -e POSTGRES_DB=arheologie `
  -p 5433:5432 `
  -v ${PWD}/init_schema.sql:/docker-entrypoint-initdb.d/init_schema.sql `
  -v pgdata_arheo:/var/lib/postgresql/data `
  postgres:16-alpine
3. Date de conectare
Dacă utilizați editoare vizuale (ex. DBeaver, DataGrip, extensii VSCodium) sau conectați un backend, folosiți următoarele credențiale:

Host: localhost (sau 127.0.0.1)

Port: 5433

Database: arheologie

User: admin_arheo

Password: parola_secreta

4. Operațiuni zilnice (Start / Stop)
Odată creat, containerul nu trebuie recreat. Îl puteți gestiona direct din interfața grafică Docker Desktop (apăsând butoanele Play/Stop din dreptul containerului db_arheologie) sau din linia de comandă:

Pornire:

Bash
docker start db_arheologie
Oprire:

Bash
docker stop db_arheologie
Verificare status:

Bash
docker ps
5. Accesarea consolei bazei de date (CLI)
Pentru a executa interogări direct din terminal, intrați în consola internă PostgreSQL (containerul trebuie să fie pornit):

Bash
docker exec -it db_arheologie psql -U admin_arheo -d arheologie
(Pentru a ieși din consolă, tastați \q și apăsați Enter).

6. Testarea arhitecturii (Interogări de test)
După conectarea la baza de date, puteți rula următorul bloc de cod SQL pentru a introduce un set de date demonstrativ:

SQL
WITH new_mormant AS (
    INSERT INTO morminte (numar_mormant, sit_arheologic, localitate) 
    VALUES ('M-101', 'Sucidava', 'Corabia') RETURNING id
),
new_schelet AS (
    INSERT INTO schelete (mormant_id, nume_schelet) 
    SELECT id, 'Scheletul A' FROM new_mormant RETURNING id
),
new_tip_os AS (
    INSERT INTO catalog_tip_os (denumire_anatomica) 
    VALUES ('Femur') RETURNING id
)
INSERT INTO fragmente_os (schelet_id, tip_os_id, numar_ordine, informatii_fragment)
SELECT new_schelet.id, new_tip_os.id, 'QR-001', 'Urme de taietura' 
FROM new_schelet, new_tip_os;
Validarea funcției de căutare parțială (Fuzzy Search pe morminte):

SQL
SELECT 
    numar_mormant, 
    sit_arheologic, 
    localitate
FROM morminte
WHERE numar_mormant ILIKE '%101%' 
   OR sit_arheologic ILIKE '%sucidava%';
Validarea ierarhică (Simularea scanării codului QR pentru a găsi contextul):

SQL
SELECT 
    f.numar_ordine AS identificator_fragment,
    cto.denumire_anatomica AS osul,
    s.nume_schelet,
    m.numar_mormant,
    m.sit_arheologic
FROM fragmente_os f
LEFT JOIN catalog_tip_os cto ON f.tip_os_id = cto.id
JOIN schelete s ON f.schelet_id = s.id
JOIN morminte m ON s.mormant_id = m.id
WHERE f.numar_ordine ILIKE '%001%'
   OR cto.denumire_anatomica ILIKE '%femur%';
