# Scalping M1 Multi-Position Reversal EA

Cet Expert Advisor (EA) implémente une stratégie de scalping agressive sur le graphique M1, basée sur les mouvements rapides du prix et un reset complet à chaque nouvelle bougie.

## Nouvelles fonctionnalités (v1.01)
- **Tableau de bord graphique** : Affiche en temps réel le seuil, le dernier mouvement, le nombre de positions et le spread directement sur le graphique.
- **Image de fond personnalisée** : Supporte l'affichage d'une image en arrière-plan du graphique.

## Installation

1. Ouvrez votre terminal MetaTrader 5.
2. Allez dans le menu `Fichier` > `Ouvrir le dossier des données`.
3. Naviguez vers `MQL5` > `Experts`.
4. Copiez le fichier `ScalpingM1Reversal.mq5` dans ce dossier.
5. **Image de fond** : Si vous souhaitez utiliser une image personnalisée :
   - Allez dans le dossier de données MT5 : `MQL5` > `Images`.
   - Placez-y votre fichier image au format **.bmp**.
   - Par défaut, l'EA cherche `robot_hybride.bmp`. Vous pouvez changer ce nom dans les réglages de l'EA.
6. Dans le terminal MT5, faites un clic droit sur `Experts` dans le Navigateur et sélectionnez `Rafraîchir`.
7. Glissez l'EA sur un graphique **M1**.
8. Assurez-vous que le "Trading Algorithmique" est activé dans la barre d'outils de MT5.

## Configuration du Seuil (`PriceMoveThreshold`)

Le seuil doit être adapté à la volatilité :
- **Gold (XAUUSD)** : 0.20.
- **Forex (EURUSD)** : 0.00020.
- **Crypto (BTCUSDT)** : 5.0 à 10.0.

## Réglages Esthétiques
- `InpBackgroundImage` : Nom du fichier image (ex: `ma_photo.bmp`) situé dans `MQL5/Images/`.
- `InpDashboardBg` : Couleur du fond du tableau de bord.
- `InpHeaderColor` : Couleur du titre.
- `InpTextColor` : Couleur des labels de données.

## Fonctionnement
- **Reset Bougie** : À chaque minute, toutes les positions sont fermées et une nouvelle est ouverte selon la bougie précédente.
- **Trigger Mouvement** : Si le prix varie de `PriceMoveThreshold`, l'EA ferme la plus ancienne position opposée et en ouvre une nouvelle dans le sens du flux.

---
*Avertissement : Le scalping haute fréquence est risqué. Testez toujours sur un compte démo.*
