# Arhitectura Bazei de Date - Proiect Arheologie

Acest repository conține schema structurală și configurația necesară pentru lansarea automată a bazei de date relaționale (PostgreSQL) destinate managementului descoperirilor arheologice (morminte, schelete, fragmente osoase și asocieri QR).

Infrastructura este standardizată folosind `docker-compose`, asigurând un mediu de rulare identic pentru toți membrii echipei la o singură comandă distanță, indiferent de sistemul de operare utilizat.

## 1. Cerințe preliminare

Instalați mediul necesar în funcție de sistemul de operare:

*   **Windows / macOS:** Instalați [Docker Desktop](https://www.docker.com/products/docker-desktop/).
*   **Linux:** Instalați Docker Engine împreună cu plugin-ul `docker-compose`, sau Podman împreună cu `podman-compose`.

## 2. Inițializarea bazei de date

Descărcați acest repository pe mașina locală și deschideți un terminal (sau PowerShell pe Windows) în interiorul folderului proiectului.

Pentru a descărca imaginea de sistem, a crea volumele de persistență a datelor și a executa scriptul SQL de inițializare, rulați comanda:

```bash
docker compose up -d
```
*(Utilizatorii de Linux care folosesc Podman vor rula: `podman-compose up -d`)*

Această comandă rulează containerul în fundal (`-d`). Scriptul `init_schema.sql` va fi executat automat doar la această primă inițializare, generând toate tabelele și relațiile.

## 3. Date de conectare

Pentru a accesa baza de date din editoare vizuale (DBeaver, DataGrip, extensii VSCodium) sau pentru a conecta platforma Directus, utilizați următoarele credențiale:

*   **Host:** `localhost` (sau `127.0.0.1`)
*   **Port:** `5433`
*   **Database:** `arheologie`
*   **User:** `admin_arheo`
*   **Password:** `parola_secreta`

## 4. Operațiuni zilnice

Deoarece parametrul `restart: unless-stopped` este activ în fișierul de configurare, baza de date va porni automat odată cu deschiderea aplicației Docker Desktop sau la pornirea sistemului. 

Dacă doriți să gestionați manual starea containerului, puteți folosi butoanele grafice Start/Stop din interfața Docker Desktop, sau următoarele comenzi în terminal (din același folder):

**Oprirea bazei de date:**
```bash
docker compose stop
```

**Pornirea bazei de date:**
```bash
docker compose start
```

## 5. Validarea instalării (Opțional)

Pentru a vă asigura că tabelele au fost create corect, puteți accesa consola internă PostgreSQL rulând:

```bash
docker exec -it db_arheologie psql -U admin_arheo -d arheologie
```

În interiorul consolei, executați următorul cod pentru a insera un set de date de test și a verifica funcția de căutare ierarhică (simularea scanării unui cod QR):

```sql
-- 1. Inserare date de test
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

-- 2. Rulare interogare de testare a relatiilor
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
WHERE f.numar_ordine ILIKE '%001%';
```
*(Pentru a ieși din consola PostgreSQL, tastați `\q` și apăsați Enter).*