CREATE OR REPLACE FUNCTION fn_tranche_horaire_existe()
RETURNS TRIGGER AS $$
DECLARE
    existe INT;
BEGIN
    SELECT COUNT(*) INTO existe 
    FROM tranche_horaire
    WHERE id_etude = NEW.id_etude
    AND debut <= NEW.heure_debut
    AND fin >= NEW.heure_fin;

    IF existe <= 0 THEN 
        RAISE EXCEPTION 'Erreur: Tranche horaire non trouver';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_before_appareil
BEFORE INSERT OR UPDATE ON appareil
FOR EACH ROW EXECUTE FUNCTION fn_tranche_horaire_existe();