# Scalping M1 Multi-Position Reversal EA

Cet Expert Advisor (EA) implémente une stratégie de scalping agressive sur le graphique M1, basée sur les mouvements rapides du prix et un reset complet à chaque nouvelle bougie.

## Nouvelles fonctionnalités (v1.03)
- **Tableau de bord graphique** : Visualisation en temps réel des performances et du spread.
- **Support Arrière-plan** : Supporte une image de fond statique (`robot_f_0.bmp`) ou animée.
- **Exportateur de données** : Ajout d'un script pour exporter l'historique du marché.
- **Aurum Core (DEMO)** : Ajout d'un EA de démonstration basé sur le croisement d'EMA.

## Installation de l'EA

1. Ouvrez votre terminal MetaTrader 5.
2. Allez dans le menu `Fichier` > `Ouvrir le dossier des données`.
3. Naviguez vers `MQL5` > `Experts` et copiez les fichiers `.mq5` (ScalpingM1Reversal et AurumCore).
4. **Images** : Placez votre fichier `robot_f_0.bmp` dans `MQL5` > `Images`.
5. Dans le terminal MT5, rafraîchissez les Experts et lancez l'EA de votre choix.

## Utilisation d'Aurum Core (DEMO)

Cet EA est une démonstration pédagogique utilisant un croisement de moyennes mobiles exponentielles (EMA).
- **Stratégie** : Achète quand l'EMA rapide croise au-dessus de l'EMA lente, vend dans le cas contraire.
- **Index de bougie** : Utilise les bougies clôturées (index 1 et 2) pour éviter le repainting.
- **Sécurité** : Filtre de spread et désactivation du trading par défaut.

---
*Avertissement : Le trading haute fréquence et les EA de démonstration comportent des risques. Testez toujours sur un compte démo.*
