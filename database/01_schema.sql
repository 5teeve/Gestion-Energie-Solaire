CREATE DATABASE gestion_energie;

\c gestion_energie;
-- ETUDE
CREATE TABLE IF NOT EXISTS etude(
    id SERIAL PRIMARY KEY,
    nom VARCHAR(255) NOT NULL,
    date_creation TIMESTAMP NOT NULL
);

-- APPAREIL
CREATE TABLE IF NOT EXISTS appareil(
    id SERIAL PRIMARY KEY,
    nom VARCHAR(255) NOT NULL,
    heure_debut TIME NOT NULL,
    heure_fin TIME NOT NULL,
    puissance DECIMAL(8, 2) NOT NULL,
    id_etude INT NOT NULL,

    FOREIGN KEY (id_etude) REFERENCES etude(id),
    CHECK (heure_fin > heure_debut),
    CHECK (puissance > 0)
);

-- TRANCHE HORAIRE
CREATE TABLE IF NOT EXISTS tranche_horaire(
    id SERIAL PRIMARY KEY,
    debut TIME NOT NULL,
    fin TIME NOT NULL,
    label VARCHAR(10) NOT NULL DEFAULT 'jour',
    id_etude INT NOT NULL,
    
    FOREIGN KEY (id_etude) REFERENCES etude(id),
    CHECK (fin > debut),
    CHECK (label IN ('nuit', 'jour'))
);

-- RENDEMENT
CREATE TABLE IF NOT EXISTS rendement(
    id SERIAL PRIMARY KEY,
    rendement_panneau DECIMAL(8, 2) NOT NULL,
    rendement_batterie DECIMAL(8, 2) NOT NULL,
    id_etude INT NOT NULL,

    FOREIGN KEY (id_etude) REFERENCES etude (id),
    CHECK (rendement_panneau BETWEEN 0 AND 1),
    CHECK (rendement_batterie BETWEEN 0 AND 1)
);

-- PRIX ELECTRIQUE
CREATE TABLE IF NOT EXISTS prix_electrique(
    id SERIAL PRIMARY KEY,
    prix DECIMAL(8,2) NOT NULL,
    type_jour VARCHAR(20) NOT NULL DEFAULT 'ouvrable',
    id_etude INT NOT NULL,

    FOREIGN KEY (id_etude) REFERENCES etude (id),
    CHECK (prix > 0),
    CHECK (type_jour IN ('ouvrable', 'weekend'))
);

-- HEURE POINTE
CREATE TABLE IF NOT EXISTS heure_pointe(
    id SERIAL PRIMARY KEY,
    debut TIME NOT NULL,
    fin TIME NOT NULL,
    majoration DECIMAL(8, 2) NOT NULL,
    type_jour VARCHAR(20) NOT NULL DEFAULT 'ouvrable',
    id_etude INT NOT NULL,

    FOREIGN KEY (id_etude) REFERENCES etude (id),
    CHECK (fin > debut),
    CHECK (majoration >= 0),
    CHECK (type_jour IN ('ouvrable', 'weekend'))
);

-- RESULTAT
CREATE TABLE IF NOT EXISTS resultat(
    id SERIAL PRIMARY KEY,
    puissance_panneau DECIMAL(8, 2) NOT NULL,
    capacite_batterie DECIMAL(8, 2) NOT NULL,
    puissance_convertisseur DECIMAL(8, 2) NOT NULL,
    surplus DECIMAL(8, 2) NOT NULL,
    deficit DECIMAL(8, 2) NOT NULL,
    consommation_totale DECIMAL(8, 2) NOT NULL,
    date_calcule TIMESTAMP NOT NULL,
    consommation_nocturne DECIMAL(8, 2) NOT NULL,
    cout_ouvrable DECIMAL(8, 2) NOT NULL,
    cout_weekend DECIMAL(8, 2) NOT NULL,
    id_etude INT NOT NULL,

    FOREIGN KEY (id_etude) REFERENCES etude(id),
    CHECK (puissance_panneau >= 0),
    CHECK (capacite_batterie >= 0),
    CHECK (puissance_convertisseur >= 0),
    CHECK (surplus >= 0),
    CHECK (deficit >= 0),
    CHECK (consommation_totale >= 0),
    CHECK (consommation_nocturne >= 0),
    CHECK (cout_ouvrable >= 0),
    CHECK (cout_weekend >= 0)
);