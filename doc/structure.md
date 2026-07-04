projet_solaire/
  sql/
    01_schema.sql            # CREATE TABLE, clés, CHECK
    02_triggers.sql          # validation (puissance>0, champs non vides, heures cohérentes)
    03_functions.sql         # coeur PL/pgSQL :
                              #   simuler_consommation(id_etude)
                              #   calculer_panneau(id_etude)
                              #   calculer_batterie(id_etude)
                              #   calculer_convertisseur(id_etude)
                              #   calculer_energie(id_etude)
                              #   calculer_finance(id_etude)
                              #   calculer_etude(id_etude)  -- orchestre tout
    04_views.sql              # vue_resultats_detaille, vue_historique
  python/
    db.py                    # connexion psycopg2
    main.py                  # lance GUI
    ui/
      appareil_form.py
      tranche_form.py
      config_form.py         # rendements, prix, heures pointe
      resultat_view.py
      historique_view.py
  README.md