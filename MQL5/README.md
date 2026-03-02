# Scalping M1 Multi-Position Reversal EA

Cet Expert Advisor (EA) implémente une stratégie de scalping agressive sur le graphique M1, basée sur les mouvements rapides du prix et un reset complet à chaque nouvelle bougie.

## Nouvelles fonctionnalités (v1.03)
- **Tableau de bord graphique** : Visualisation en temps réel des performances et du spread.
- **Support Arrière-plan** : Supporte une image de fond statique (`robot_f_0.bmp`) ou animée.
- **Exportateur de données** : Ajout d'un script pour exporter l'historique du marché.

## Installation de l'EA

1. Ouvrez votre terminal MetaTrader 5.
2. Allez dans le menu `Fichier` > `Ouvrir le dossier des données`.
3. Naviguez vers `MQL5` > `Experts` et copiez le fichier `ScalpingM1Reversal.mq5`.
4. **Images** : Placez votre fichier `robot_f_0.bmp` dans `MQL5` > `Images`.
5. Dans le terminal MT5, rafraîchissez les Experts et glissez l'EA sur un graphique **M1**.

## Utilisation du Data Exporter (`DataExporter.mq5`)

Ce script vous permet d'extraire les données historiques de votre courtier au format JSON.

1. Copiez `DataExporter.mq5` dans `MQL5` > `Scripts`.
2. Dans MetaTrader, allez dans le Navigateur > `Scripts` et double-cliquez sur `DataExporter`.
3. Le script va générer des fichiers JSON pour plusieurs unités de temps.
4. **Récupération** : Allez dans le dossier de données de MT5 > `MQL5` > `Files`. Vous y trouverez les fichiers `.json` prêts à être utilisés.

## Configuration de l'EA
- **Gold (XAUUSD)** : PriceMoveThreshold = 0.20.
- **Forex (EURUSD)** : PriceMoveThreshold = 0.00020.
- **Crypto (BTCUSDT)** : PriceMoveThreshold = 5.0 à 10.0.

---
*Avertissement : Le trading haute fréquence comporte des risques. Testez toujours sur un compte démo.*
