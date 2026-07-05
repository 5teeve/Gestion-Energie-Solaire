-- utils
CREATE OR REPLACE FUNCTION get_consommation_totale(p_id_etude INT)
RETURNS DECIMAL AS $$
DECLARE v DECIMAL;
BEGIN
    SELECT SUM(puissance * EXTRACT(EPOCH FROM (heure_fin - heure_debut)) / 3600) INTO v
    FROM appareil WHERE id_etude = p_id_etude;
    RETURN v;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_heure_ensoleillement(p_id_etude INT)
RETURNS DECIMAL AS $$
DECLARE v DECIMAL;
BEGIN
    SELECT EXTRACT(EPOCH FROM (fin - debut)) / 3600 INTO v
    FROM tranche_horaire WHERE id_etude = p_id_etude AND label = 'jour';
    RETURN v;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_rendement_panneau(p_id_etude INT)
RETURNS DECIMAL AS $$
DECLARE v DECIMAL;
BEGIN
    SELECT r.rendement_panneau INTO v
    FROM rendement r
    JOIN tranche_horaire t ON r.id_tranche = t.id
    WHERE r.id_etude = p_id_etude AND t.label = 'jour';
    RETURN v;
END;
$$ LANGUAGE plpgsql;

-- principaux
CREATE OR REPLACE FUNCTION calculer_consommation_nocturne(p_id_etude INT)
RETURNS DECIMAL AS $$
DECLARE v DECIMAL;
BEGIN
    SELECT SUM(a.puissance * EXTRACT(EPOCH FROM (a.heure_fin - a.heure_debut)) / 3600) INTO v
    FROM appareil a
    JOIN tranche_horaire t ON t.id_etude = a.id_etude
    WHERE a.id_etude = p_id_etude
    AND t.label = 'nuit'
    AND a.heure_debut < t.fin
    AND a.heure_fin > t.debut;
    RETURN v;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION calculer_panneau(p_id_etude INT)
RETURNS DECIMAL AS $$
DECLARE puissance_panneau DECIMAL;
BEGIN
    puissance_panneau := (get_consommation_totale(p_id_etude) + calculer_consommation_nocturne(p_id_etude))
                        / (get_heure_ensoleillement(p_id_etude) * get_rendement_panneau(p_id_etude));
    RETURN puissance_panneau;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION calculer_batterie(p_id_etude INT)
RETURNS DECIMAL AS $$
DECLARE
    rendement_nuit DECIMAL;
    capacite_batterie DECIMAL;
BEGIN
    SELECT r.rendement_batterie INTO rendement_nuit
    FROM rendement r
    JOIN tranche_horaire t ON r.id_tranche = t.id
    WHERE r.id_etude = p_id_etude AND t.label = 'nuit';
    capacite_batterie := calculer_consommation_nocturne(p_id_etude) / rendement_nuit;
    RETURN capacite_batterie;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION calculer_convertisseur(p_id_etude INT)
RETURNS DECIMAL AS $$
DECLARE
    marge DECIMAL;
    pic_consommation DECIMAL;
BEGIN
    SELECT marge_securite INTO marge FROM rendement WHERE id_etude = p_id_etude;
    SELECT MAX(somme) INTO pic_consommation FROM (
        SELECT SUM(a2.puissance) as somme
        FROM appareil a1
        JOIN appareil a2 ON a2.id_etude = a1.id_etude
            AND a1.heure_debut < a2.heure_fin
            AND a1.heure_fin > a2.heure_debut
        WHERE a1.id_etude = p_id_etude
        GROUP BY a1.id
    ) AS chevauchements;
    RETURN pic_consommation * marge;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION calculer_energie(p_id_etude INT)
RETURNS TABLE(surplus DECIMAL, deficit DECIMAL) AS $$
DECLARE
    production DECIMAL;
    consommation DECIMAL;
BEGIN
    production := get_heure_ensoleillement(p_id_etude) * calculer_panneau(p_id_etude) * get_rendement_panneau(p_id_etude);
    consommation := get_consommation_totale(p_id_etude);
    surplus := GREATEST(production - consommation, 0);
    deficit := GREATEST(consommation - production, 0);
    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION calculer_finance(p_id_etude INT)
RETURNS TABLE(cout_ouvrable DECIMAL, cout_weekend DECIMAL, gain DECIMAL) AS $$
DECLARE
    prix_ouv DECIMAL;
    prix_wkd DECIMAL;
    conso_pointe DECIMAL;
    conso_hors_pointe DECIMAL;
    maj_ouv DECIMAL;
    maj_wkd DECIMAL;
BEGIN
    SELECT prix INTO prix_ouv FROM prix_electrique
    WHERE id_etude = p_id_etude AND type_jour = 'ouvrable';

    SELECT prix INTO prix_wkd FROM prix_electrique
    WHERE id_etude = p_id_etude AND type_jour = 'weekend';

    SELECT majoration INTO maj_ouv FROM heure_pointe
    WHERE id_etude = p_id_etude AND type_jour = 'ouvrable';

    SELECT majoration INTO maj_wkd FROM heure_pointe
    WHERE id_etude = p_id_etude AND type_jour = 'weekend';

    -- conso pendant heures pointe ouvrable
    SELECT COALESCE(SUM(a.puissance * EXTRACT(EPOCH FROM (
        LEAST(a.heure_fin, h.fin) - GREATEST(a.heure_debut, h.debut)
    )) / 3600), 0) INTO conso_pointe
    FROM appareil a
    JOIN heure_pointe h ON h.id_etude = a.id_etude
    WHERE a.id_etude = p_id_etude
    AND h.type_jour = 'ouvrable'
    AND a.heure_debut < h.fin
    AND a.heure_fin > h.debut;

    conso_hors_pointe := get_consommation_totale(p_id_etude) - conso_pointe;

    cout_ouvrable := (conso_hors_pointe * prix_ouv) + (conso_pointe * prix_ouv * (1 + maj_ouv));
    cout_weekend  := (conso_hors_pointe * prix_wkd) + (conso_pointe * prix_wkd * (1 + maj_wkd));
    gain := cout_ouvrable - ((SELECT deficit FROM calculer_energie(p_id_etude)) * prix_ouv);

    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION calculer_etude(p_id_etude INT)
RETURNS VOID AS $$
DECLARE
    v_puissance_panneau DECIMAL;
    v_capacite_batterie DECIMAL;
    v_puissance_convertisseur DECIMAL;
    v_surplus DECIMAL;
    v_deficit DECIMAL;
    v_consommation_totale DECIMAL;
    v_consommation_nocturne DECIMAL;
    v_cout_ouvrable DECIMAL;
    v_cout_weekend DECIMAL;
    v_gain DECIMAL;
BEGIN
    v_puissance_panneau       := calculer_panneau(p_id_etude);
    v_capacite_batterie       := calculer_batterie(p_id_etude);
    v_puissance_convertisseur := calculer_convertisseur(p_id_etude);
    v_consommation_totale     := get_consommation_totale(p_id_etude);
    v_consommation_nocturne   := calculer_consommation_nocturne(p_id_etude);

    SELECT surplus, deficit INTO v_surplus, v_deficit
    FROM calculer_energie(p_id_etude);

    SELECT cout_ouvrable, cout_weekend, gain INTO v_cout_ouvrable, v_cout_weekend, v_gain
    FROM calculer_finance(p_id_etude);

    INSERT INTO resultat(
        id_etude, puissance_panneau, capacite_batterie, puissance_convertisseur,
        surplus, deficit, consommation_totale, consommation_nocturne,
        cout_ouvrable, cout_weekend, date_calcul
    ) VALUES (
        p_id_etude, v_puissance_panneau, v_capacite_batterie, v_puissance_convertisseur,
        v_surplus, v_deficit, v_consommation_totale, v_consommation_nocturne,
        v_cout_ouvrable, v_cout_weekend, NOW()
    );
END;
$$ LANGUAGE plpgsql;