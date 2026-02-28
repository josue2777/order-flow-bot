# Scalping M1 Multi-Position Reversal EA

Cet Expert Advisor (EA) implémente une stratégie de scalping agressive sur le graphique M1, basée sur les mouvements rapides du prix et un reset complet à chaque nouvelle bougie.

## Installation

1. Ouvrez votre terminal MetaTrader 5.
2. Allez dans le menu `Fichier` > `Ouvrir le dossier des données`.
3. Naviguez vers `MQL5` > `Experts`.
4. Copiez le fichier `ScalpingM1Reversal.mq5` dans ce dossier (ou un sous-dossier comme `Scalping`).
5. Dans le terminal MT5, faites un clic droit sur `Experts` dans le Navigateur et sélectionnez `Rafraîchir`.
6. Glissez l'EA sur un graphique **M1**.
7. Assurez-vous que le "Trading Algorithmique" est activé dans la barre d'outils de MT5.

## Configuration du Seuil (`PriceMoveThreshold`)

Le seuil doit être adapté à la volatilité et à la précision du symbole :

- **Gold (XAUUSD)** : 0.20 (soit 20 pips/points selon le broker).
- **Forex (EURUSD, etc.)** : 0.00020 (pour un mouvement de 2 pips sur un compte 5 digits).
- **Crypto (BTCUSDT)** : 5.0 à 10.0 selon la volatilité actuelle.
- **Indices (DAX, Dow Jones)** : 1.0 à 5.0.

## Comment Tester l'EA

1. **Compte Démo** : Testez toujours cet EA sur un compte démo pendant au moins une semaine pour comprendre son comportement agressif.
2. **Testeur de Stratégie** :
   - Sélectionnez `ScalpingM1Reversal.mq5`.
   - Symbole : XAUUSD ou EURUSD.
   - Période : **M1**.
   - Modélisation : "Chaque tick basé sur des ticks réels" (très important pour le scalping).
   - Dépôt : 1000$ minimum recommandé vu l'accumulation possible de positions.

## Fonctionnement
- **Reset Bougie** : À chaque nouvelle minute, toutes les positions sont fermées. Une nouvelle position est ouverte selon la direction de la bougie précédente (BUY si Close > Open).
- **Trigger Mouvement** : Si le prix bouge du seuil défini, l'EA ferme la plus ancienne position opposée et ouvre une nouvelle position dans le sens du mouvement.
- **Hedging** : L'EA gère plusieurs positions simultanément.

---
*Avertissement : Le scalping haute fréquence comporte des risques élevés. Utilisez des tailles de lots appropriées.*
