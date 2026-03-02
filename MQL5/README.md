# Suite d'outils Professionnels MQL5

Cette suite contient plusieurs outils de trading algorithmique avancés pour MetaTrader 5, allant du scalping agressif à la stratégie SMC institutionnelle.

## 1. Universal SMC Scalper (`Universal_SMC_Scalper.mq5`)
Un EA sophistiqué basé sur les concepts de **Smart Money (SMC)**, désormais compatible avec tous les marchés et optimisé pour le Strategy Tester.
- **Polyvalence** : Utilise `_Symbol` pour s'adapter automatiquement au graphique actuel.
- **Logique** :
  - Détecte les changements de structure (**CHoCH**).
  - Identifie les déséquilibres (**Fair Value Gaps - FVG**).
  - Cherche les zones d'intérêt institutionnel (**Order Blocks**).
- **Gestion du Risque** : Calcul de lot dynamique et Stop Loss basé sur l'ATR.

## 2. Universal TrendBreak Trauma (`Universal_TrendBreak_Trauma.mq5`)
Une stratégie de cassure de tendance confirmée par l'indicateur Trauma et le RSI.
- **Concept** : Achète si le prix est au-dessus du Trauma et casse une résistance. Vend si le prix est en dessous du Trauma et casse un support.
- **Sortie** : Utilise le RSI (Surachat/Survente) pour sécuriser les profits.
- **Universel** : Adapté pour l'Or, le Forex, les Cryptos et les Indices.

## 3. Scalping M1 Reversal EA (`ScalpingM1Reversal.mq5`)
Un robot de scalping haute fréquence pour l'unité de temps M1.
- **Stratégie** : Flip de position sur mouvement de prix rapide + Reset complet à chaque nouvelle minute.
- **Visuel** : Tableau de bord intégré et support d'arrière-plan animé (système de frames `.bmp`).

### Guide Rapide : Scalping M1 Reversal
- **Installation** : Copiez le fichier dans `MQL5/Experts`, compilez dans MetaEditor (F7) et glissez-le sur un graphique **XAUUSD M1**.
- **Réglages (Seuil/Threshold)** :
  - **Or (Gold)** : `0.20` pour un scalping réactif, `0.50` pour plus de prudence.
  - **Forex (5 digits)** : `0.00020` (2 pips) pour les paires majeures comme EURUSD.
  - **Crypto (BTC)** : `5.0` ou `10.0` selon la volatilité actuelle.
- **Test Démo** : Utilisez le Testeur de Stratégie (Ctrl+R) en mode "Chaque tick basé sur des ticks réels" pour une simulation fidèle du scalping.

## 3. Aurum Core DEMO (`AurumCore.mq5`)
EA éducatif basé sur un croisement de moyennes mobiles (EMA).
- **Correction** : Zéro repainting grâce à l'utilisation des bougies clôturées.
- **Usage** : Idéal pour apprendre la structure d'un EA propre.

## 4. Data Exporter (`DataExporter.mq5`)
Script utilitaire pour exporter les données de votre courtier.
- **Usage** : Génère des fichiers **JSON** complets (OHLCV, Spread, Swap, Commissions).
- **Emplacement** : Les fichiers exportés se trouvent dans `MQL5/Files`.

---

## Installation Générale
1. Ouvrez MetaTrader 5 > `Fichier` > `Ouvrir le dossier des données`.
2. Copiez les fichiers `.mq5` dans `MQL5/Experts` (ou `Scripts` pour l'exportateur).
3. Placez vos images d'animation (si utilisées) dans `MQL5/Images`.
4. Rafraîchissez le navigateur dans MT5 et lancez l'outil souhaité.

---
*Avertissement : Le trading comporte des risques importants. Utilisez ces outils uniquement sur des comptes de démonstration avant d'envisager un usage réel.*
