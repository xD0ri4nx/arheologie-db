-- Activarea extensiei pentru generarea automata a UUID-urilor
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Nomenclatoare
CREATE TABLE IF NOT EXISTS catalog_specii (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    denumire_stiintifica VARCHAR(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS catalog_tip_os (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    denumire_anatomica VARCHAR(255) NOT NULL
);

-- 2. Entitati principale
CREATE TABLE IF NOT EXISTS morminte (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    numar_mormant VARCHAR(100) NOT NULL,
    nume_mormant VARCHAR(255),
    imagine_mormant TEXT,
    bibliografie TEXT,
    sit_arheologic VARCHAR(255),
    localitate VARCHAR(255),
    tip_mormant VARCHAR(150),
    latitudine NUMERIC(10, 6),
    longitudine NUMERIC(10, 6),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS schelete (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    mormant_id UUID NOT NULL,
    nume_schelet VARCHAR(255),
    grad_completare_schelet NUMERIC(5, 2),
    sex_estimat VARCHAR(50),
    varsta_estimata VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_schelete_mormant FOREIGN KEY (mormant_id) 
        REFERENCES morminte(id) ON DELETE CASCADE
);

-- 3. Fisa fragmentului
CREATE TABLE IF NOT EXISTS fragmente_os (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    schelet_id UUID NOT NULL,
    specie_id UUID,
    tip_os_id UUID,
    numar_ordine VARCHAR(100),
    informatii_fragment TEXT,
    datare VARCHAR(100),
    context TEXT,
    ilustratie_context TEXT,
    imagine_preluata BOOLEAN DEFAULT FALSE,
    grad_completare_os NUMERIC(5, 2),
    metadate_externe JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_fragmente_schelet FOREIGN KEY (schelet_id) 
        REFERENCES schelete(id) ON DELETE CASCADE,
    CONSTRAINT fk_fragmente_specie FOREIGN KEY (specie_id) 
        REFERENCES catalog_specii(id) ON DELETE SET NULL,
    CONSTRAINT fk_fragmente_tip_os FOREIGN KEY (tip_os_id) 
        REFERENCES catalog_tip_os(id) ON DELETE SET NULL
);

-- 4. Date adiacente fragmentului
CREATE TABLE IF NOT EXISTS masuratori_fragment (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    fragment_id UUID NOT NULL UNIQUE, -- Constrangere UNIQUE pentru relatia 1-la-1
    lungime NUMERIC(10, 2),
    latime NUMERIC(10, 2),
    diametru NUMERIC(10, 2),
    greutate NUMERIC(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_masuratori_fragment FOREIGN KEY (fragment_id) 
        REFERENCES fragmente_os(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS imagini_fragment (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    fragment_id UUID NOT NULL,
    url_fisier TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_imagini_fragment FOREIGN KEY (fragment_id) 
        REFERENCES fragmente_os(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS analize_centre (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    fragment_id UUID NOT NULL,
    nume_centru VARCHAR(255) NOT NULL,
    data_analizei DATE,
    rezultat_analiza TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_analize_fragment FOREIGN KEY (fragment_id) 
        REFERENCES fragmente_os(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS fotografii_schelet (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    schelet_id UUID NOT NULL REFERENCES schelete(id) ON DELETE CASCADE,
    numar_cadru INTEGER NOT NULL CHECK (numar_cadru > 0),
    fisier_imagine VARCHAR(255) NOT NULL,
    descriere TEXT,
    data_adaugarii TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_foto_schelet_cadru 
ON fotografii_schelet (schelet_id, numar_cadru);
