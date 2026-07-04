# Gestion d'énergie solaire

## QUOI

### Composants
- Panneau solaire
- Batterie

---

## Fonctionnalités

### Puissance réelle du panneau solaire
- Puissance réelle = 40% de la puissance théorique  
- Formule :  
  P_reel = P_th * 0.4

---

### Batterie suggérée
- Capacité batterie = consommation nuit (19h → 06h) + 50% de marge

---

### Intervalles horaires et rendements

- 06h → 17h (11h)  
  Production max (40%) + alimentation + charge batterie

- 17h → 19h (2h)  
  Production réduite (20%) + alimentation + charge batterie

- 19h → 06h (11h)  
  Pas de production → utilisation batterie uniquement

---

### Logique de calcul du panneau (P_th)

- Le panneau doit couvrir toute la consommation des 24h pendant sa période de production

- Coefficient de production journalier :  
  (11 * 0.4) + (2 * 0.2) = 4.8

- Puissance théorique :  
  P_th = Energie_totale_24h / 4.8

- Contrainte de puissance instantanée (important) :  
  P_th >= Puissance_instantanee / 0.2

---

### Recharge batterie
- La recharge de la batterie dépend de la puissance du panneau
- Elle est incluse dans la production totale

---

### Format input

Exemple :
TV 9->12h 75W

---

### Format output

Panneau solaire : [Valeur] W  
Batterie : [Valeur] Wh

---

### Exemple consommation / recharge

- 1000 Wh consommés en 1h = appareil de 1000 W  
- 1000 Wh rechargés en 1h = source de 1000 W  

---

### Règle critique

- La batterie doit être rechargée à 100% chaque jour

---

## Stack

### Python
- UI : PyQt (PySide6)
- Base de données : pyodbc

### Base de données
- SQL Server

---

## Structure
- MVC (Modèle - Vue - Contrôleur)
