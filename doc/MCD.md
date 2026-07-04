# MCD du projet gestion energie solaire

## 1. Indentification des entites

- Etude
- Appareil
- Tranche horaire
- Rendement
- Prix electrique
- Heure de pointe
- Resultat

## 2. Les attributs de chaque entites

### Etude

- id
- nom
- date_creation

### Appareil

- id
- nom
- heure_debut
- heure_fin
- puissance

### Tranche horaire

- id
- debut
- fin
- label

### Rendement

- id
- rendement_panneau
- rendement_batterie

### Prix electrique

- id
- prix (ar/kwh)
- type_jour

### Heure de pointe

- id
- debut
- fin
- majoration
- type_jour

### Resultat

- id
- puissance_panneau
- capacite_batterie
- puissance_convertisseur
- surplus
- deficit
- consommation_totale
- consommation_nocturne
- cout_ouvrable
- cout_weekend

## 3. Association et cardinalite

ETUDE (1,1) — contient — (1,N) APPAREIL  
ETUDE (1,1) — contient — (1,N) TRANCHE_HORAIRE
ETUDE (1,1) — configure — (1,1) RENDEMENT  
ETUDE (1,1) — fixe — (1,N) PRIX_ELECTRIQUE
ETUDE (1,1) — definit — (1,N) HEURE_POINTE
ETUDE (1,1) — genere — (1,N) RESULTAT

## MLD

### Table:

- etude: id, nom, date_creation
- appareil: id, nom, heure_debut, heure_fin, puissance, id_etude
- tranche_horaire: id, debut, fin, label (ex: nuit, jour), id_etude
- rendement: id, rendement_panneau, rendement_batterie, id_etude
- prix_electrique: id, prix, type_jour, id_etude
- heure_pointe: id, debut, fin, majoration, type_jour, id_etude
- resultat: id, puissance_panneau, capacite_batterie, puissance_convertisseur, surplus, deficit, consommation_totale, date_calcule, consommation_nocturne, cout_ouvrable, cout_weekend, id_etude

### Contraintes:

- appareil:
  - NOT NULL: id, nom
  - CHECK: puissance > 0, heure_fin > heure_debut
  - UNIQUE: id

- tranche_horaire:
  - NOT NULL: id, debut, fin, label, id_etude
  - CHECK: fin > debut
  - UNIQUE: id

- rendement:
  - NOT NULL: id, rendemenet_panneau, rendement_batterie, id_etude
  - CHECK: rendement_panneau > 0, rendement_batterie > 0, les 2 rendements BETWENN 0 AND 1
  - UNIQUE: id

- prix_electrique:
  - NOT NULL: id, prix, type_jour, id_etude
  - CHECK: prix > 0, type_jour IN ('ouvrable', 'weekend')
  - UNIQUE: id

- heure_pointe:
  - NOT NULL: id, debut, fin, majoration, type_jour, id_etude
  - CHECK: fin > debut, majoration > 0, type_jour IN ('ouvrable', 'weekend')
  - UNIQUE: id

- resultat:
  - NOT NULL: id, puissance_panneau, capacite_batterie, puissance_convertisseur, surplus, deficit, consommation_totale, date_calcule, consommation_nocturne, cout_ouvrable, cout_weekend, id_etude
  - CHECK: puissance_panneau > 0, capacite_batterie > 0, ... (tous positif pour les nombres), surplus >= 0, deficit >= 0
  - UNIQUE: id
