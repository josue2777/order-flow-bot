# Scalping M1 Multi-Position Reversal EA

Cet Expert Advisor (EA) implémente une stratégie de scalping agressive sur le graphique M1, basée sur les mouvements rapides du prix et un reset complet à chaque nouvelle bougie.

## Nouvelles fonctionnalités (v1.02)
- **Animation de fond** : Supporte désormais les arrière-plans animés (ex: pour simuler un mouvement/twerk).
- **Tableau de bord graphique** : Visualisation en temps réel des performances et du spread.

## Installation

1. Ouvrez votre terminal MetaTrader 5.
2. Allez dans le menu `Fichier` > `Ouvrir le dossier des données`.
3. Naviguez vers `MQL5` > `Experts` et copiez le fichier `ScalpingM1Reversal.mq5`.
4. **Configuration de l'Animation** :
   - Allez dans `MQL5` > `Images`.
   - Placez vos frames d'animation au format **.bmp**.
   - Nommez-les avec un préfixe et un index (ex: `robot_f_0.bmp`, `robot_f_1.bmp`, `robot_f_2.bmp`, etc.).
   - Dans les réglages de l'EA :
     - `InpImagePrefix` : Mettez le préfixe utilisé (ex: `robot_f_`).
     - `InpFrameCount` : Le nombre total d'images dans votre animation.
     - `InpAnimationMs` : Le délai entre chaque image en millisecondes (ex: 100ms pour une animation fluide).
5. Dans le terminal MT5, rafraîchissez les Experts et glissez l'EA sur un graphique **M1**.

## Configuration du Seuil (`PriceMoveThreshold`)
- **Gold (XAUUSD)** : 0.20.
- **Forex (EURUSD)** : 0.00020.
- **Crypto (BTCUSDT)** : 5.0 à 10.0.

## Réglages Esthétiques
- `InpDashboardBg` : Couleur du fond du tableau.
- `InpHeaderColor` : Couleur du titre.
- `InpTextColor` : Couleur des données.

---
*Avertissement : Le trading haute fréquence comporte des risques. Testez toujours sur un compte démo.*
