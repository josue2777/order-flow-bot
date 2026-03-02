# Suite d'outils Professionnels MQL5

Cette suite contient plusieurs outils de trading algorithmique avancés pour MetaTrader 5, allant du scalping agressif à la stratégie SMC institutionnelle.

## 1. XAUUSD SMC Scalper (`XAUUSD_SMC_Scalper.mq5`)
Un EA sophistiqué basé sur les concepts de **Smart Money (SMC)**.
- **Optimisation** : Spécialement conçu pour l'Or (XAUUSD) en unité de temps **M15**.
- **Logique** :
  - Détecte les changements de structure (**CHoCH**).
  - Identifie les déséquilibres (**Fair Value Gaps - FVG**).
  - Cherche les zones d'institutions (**Order Blocks**).
- **Sécurité** : Calcul de lot basé sur le risque (2% par défaut) et Stop Loss dynamique (ATR).

## 2. Scalping M1 Reversal EA (`ScalpingM1Reversal.mq5`)
Un robot de scalping haute fréquence pour l'unité de temps M1.
- **Stratégie** : Flip de position sur mouvement de prix rapide + Reset complet à chaque nouvelle minute.
- **Visuel** : Tableau de bord intégré et support d'arrière-plan animé (système de frames `.bmp`).

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
