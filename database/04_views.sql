CREATE OR REPLACE VIEW vue_resultats_detailles AS
SELECT 
    e.id AS id_etude, e.nom, e.date_creation,
    r.id AS id_resultat, r.puissance_panneau, r.capacite_batterie,
    r.puissance_convertisseur, r.surplus, r.deficit,
    r.consommation_totale, r.consommation_nocturne,
    r.cout_ouvrable, r.cout_weekend, r.date_calcul
FROM resultat r
JOIN etude e ON r.id_etude = e.id;

CREATE OR REPLACE VIEW vue_historique AS
SELECT 
    e.nom AS etude,
    r.date_calcul,
    r.puissance_panneau,
    r.capacite_batterie,
    r.puissance_convertisseur,
    r.surplus,
    r.deficit,
    r.cout_ouvrable,
    r.cout_weekend
FROM resultat r
JOIN etude e ON r.id_etude = e.id
ORDER BY e.id, r.date_calcul DESC;