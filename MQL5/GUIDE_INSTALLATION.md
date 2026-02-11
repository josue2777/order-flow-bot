# 📚 Guide d'Installation et d'Utilisation
## Position TP/SL Controller pour MetaTrader 5

---

## 📦 Installation

### Étape 1 : Localiser le Dossier MQL5

1. Ouvrez MetaTrader 5
2. Cliquez sur **Fichier** → **Ouvrir le dossier de données**
3. Un explorateur de fichiers s'ouvre, naviguez vers le dossier **MQL5**
4. Ensuite, allez dans le dossier **Experts**

**Chemin complet typique :**
```
C:\Users\[VotreNom]\AppData\Roaming\MetaQuotes\Terminal\[ID]\MQL5\Experts\
```

### Étape 2 : Copier le Fichier

1. Copiez le fichier `PositionTPSLController.mq5`
2. Collez-le dans le dossier **Experts** localisé à l'étape 1

### Étape 3 : Compiler le Bot

#### Option A : Compilation via MetaEditor (Recommandé)
1. Dans MT5, cliquez sur **Outils** → **Editeur MetaQuotes Language**
2. Dans MetaEditor, cliquez sur **Fichier** → **Ouvrir**
3. Naviguez vers le dossier Experts et sélectionnez `PositionTPSLController.mq5`
4. Appuyez sur **F7** ou cliquez sur **Compiler** (icône ✓)
5. Vérifiez qu'il n'y a **0 erreur** dans l'onglet **Boîte à outils** en bas
6. Un fichier `.ex5` est créé automatiquement

#### Option B : Compilation Rapide
1. Dans MT5, ouvrez le **Navigateur** (Ctrl+N)
2. Développez **Expert Advisors**
3. Faites un clic droit sur `PositionTPSLController`
4. Sélectionnez **Compiler**

### Étape 4 : Vérification

Le bot devrait maintenant apparaître dans :
```
Navigateur → Expert Advisors → PositionTPSLController
```

---

## 🚀 Utilisation

### Démarrage du Bot

#### Méthode 1 : Glisser-Déposer
1. Dans le **Navigateur**, trouvez `PositionTPSLController`
2. Glissez-déposez le bot sur un graphique
3. Une fenêtre de paramètres s'ouvre
4. Configurez selon vos besoins (voir section Configuration)
5. **Important** : Cochez **Autoriser le trading automatique**
6. Cliquez sur **OK**

#### Méthode 2 : Double-clic
1. Double-cliquez sur `PositionTPSLController` dans le Navigateur
2. Sélectionnez le graphique cible
3. Configurez et validez

### Configuration Initiale Simple

Pour un premier test, utilisez cette configuration de base :

```
Paramètres Généraux :
- EnableController : true
- MagicNumber : 0 (toutes positions)
- OnlyCurrentSymbol : true

Take Profit :
- EnableTPControl : true
- TPPips : 50

Stop Loss :
- EnableSLControl : true
- SLPips : 25

Autres : laisser par défaut
```

---

## ⚙️ Configuration Détaillée

### 1. Paramètres Généraux

#### EnableController
- **Type** : Oui/Non
- **Défaut** : Oui
- **Usage** : Active ou désactive complètement le bot
- **Conseil** : Désactiver temporairement pendant les news importantes

#### MagicNumber
- **Type** : Nombre entier
- **Défaut** : 123456
- **Usage** : Filtre les positions par Magic Number
- **Valeurs** :
  - `0` = Traite TOUTES les positions (tous EA, positions manuelles)
  - `123456` = Traite uniquement les positions avec ce Magic Number
- **Conseil** : Utilisez `0` pour gérer toutes vos positions d'un coup

#### CommentFilter
- **Type** : Texte
- **Défaut** : "" (vide)
- **Usage** : Filtre les positions par commentaire
- **Exemples** :
  - `"Scalping"` = Ne traite que les positions avec "Scalping" dans le commentaire
  - `""` (vide) = Traite toutes les positions
- **Conseil** : Utile si vous nommez vos stratégies

#### OnlyCurrentSymbol
- **Type** : Oui/Non
- **Défaut** : Non
- **Usage** : Limite le traitement au symbole du graphique
- **Exemples** :
  - Si le bot est sur un graphique EURUSD et `OnlyCurrentSymbol = true`, seules les positions EURUSD seront traitées
  - Si `false`, toutes les positions de tous les symboles sont traitées
- **Conseil** : Activez pour un contrôle précis par paire

### 2. Take Profit (TP)

#### EnableTPControl
- **Type** : Oui/Non
- **Défaut** : Oui
- **Usage** : Active la modification automatique du Take Profit

#### TPPoints / TPPips / TPPercent
- **Règle** : **Utilisez UN SEUL de ces trois paramètres** (les autres à 0)

##### TPPoints
- **Type** : Nombre décimal
- **Défaut** : 0
- **Usage** : TP en points de cotation
- **Exemples** :
  - EURUSD (5 digits) : `500` points = 50 pips
  - USDJPY (3 digits) : `500` points = 50 pips
  - US30 (indices) : `200` points = 200 points
- **Formule** : `TP = Prix d'entrée ± TPPoints × Point`

##### TPPips
- **Type** : Nombre décimal
- **Défaut** : 0
- **Usage** : TP en pips (plus intuitif)
- **Exemples** :
  - `50` = TP à 50 pips
  - `100` = TP à 100 pips
- **Note** : Conversion automatique en points selon les digits du symbole

##### TPPercent
- **Type** : Nombre décimal
- **Défaut** : 0
- **Usage** : TP en pourcentage du prix d'entrée
- **Exemples** :
  - `2.0` = TP à +2% du prix d'entrée
  - `0.5` = TP à +0.5% du prix d'entrée
- **Idéal pour** : Cryptos, actions, instruments volatiles

### 3. Stop Loss (SL)

#### EnableSLControl
- **Type** : Oui/Non
- **Défaut** : Oui
- **Usage** : Active la modification automatique du Stop Loss

#### SLPoints / SLPips / SLPercent
- **Règle** : **Utilisez UN SEUL de ces trois paramètres** (identique au TP)
- **Fonctionnement** : Identique aux paramètres TP (voir ci-dessus)

### 4. Trailing Stop

#### UseTrailingStop
- **Type** : Oui/Non
- **Défaut** : Non
- **Usage** : Active le trailing stop (SL qui suit le prix)

#### TrailingStopPoints
- **Type** : Nombre décimal
- **Défaut** : 0
- **Usage** : Distance du trailing en points
- **Exemple** : `300` = Le SL suivra à 30 pips (pour 5 digits)
- **Comportement** :
  - Position BUY : SL remonte quand le prix monte
  - Position SELL : SL descend quand le prix descend

#### TrailingStepPoints
- **Type** : Nombre décimal
- **Défaut** : 0
- **Usage** : Pas minimum de déplacement du SL
- **Exemples** :
  - `0` = Déplace à chaque tick (très réactif mais gourmand)
  - `50` = Déplace uniquement par paliers de 5 pips
- **Conseil** : Utilisez 50-100 points pour optimiser

### 5. Break Even

#### UseBreakEven
- **Type** : Oui/Non
- **Défaut** : Non
- **Usage** : Active le déplacement automatique du SL au prix d'entrée

#### BreakEvenPoints
- **Type** : Nombre décimal
- **Défaut** : 0
- **Usage** : Points de profit nécessaires pour activer le Break Even
- **Exemple** : `300` = Après 30 pips de profit, le SL passe au prix d'entrée

#### BreakEvenOffset
- **Type** : Nombre décimal
- **Défaut** : 0
- **Usage** : Offset du SL par rapport au prix d'entrée (en points)
- **Exemples** :
  - `0` = SL exactement au prix d'entrée
  - `20` = SL à +2 pips du prix d'entrée (sécurité supplémentaire)
- **Conseil** : Toujours mettre un offset positif (10-20 points)

### 6. Gestion Avancée

#### ModifyOnlyNew
- **Type** : Oui/Non
- **Défaut** : Non
- **Usage** : Modifie uniquement les positions sans TP/SL existants
- **Cas d'usage** :
  - `false` = Modifie TOUTES les positions
  - `true` = Laisse intactes les positions déjà configurées
- **Conseil** : Activez si certaines positions sont gérées manuellement

#### ShowInfo
- **Type** : Oui/Non
- **Défaut** : Oui
- **Usage** : Affiche les statistiques sur le graphique

#### InfoColor
- **Type** : Couleur
- **Défaut** : Blanc
- **Usage** : Couleur du texte des informations

#### RefreshRateMS
- **Type** : Nombre entier
- **Défaut** : 500
- **Usage** : Fréquence de vérification en millisecondes
- **Exemples** :
  - `500` = Vérifie toutes les 0.5 secondes (recommandé)
  - `1000` = Vérifie toutes les secondes (moins gourmand)
  - `100` = Vérifie 10 fois par seconde (très réactif)
- **Conseil** : 500ms est optimal pour la plupart des cas

---

## 🎯 Scénarios d'Utilisation Pratiques

### Scénario 1 : Protection Rapide de Toutes Positions

**Situation** : News économique imprévue, vous voulez protéger rapidement tout votre portfolio

**Configuration** :
```
MagicNumber : 0 (toutes positions)
OnlyCurrentSymbol : Non
EnableTPControl : Non (pas de TP)
EnableSLControl : Oui
SLPercent : 1.0 (SL à -1%)
ModifyOnlyNew : Non (modifier tout)
```

**Résultat** : Toutes vos positions auront un SL à -1% en quelques secondes

### Scénario 2 : Gestion Automatique Nouvelles Positions

**Situation** : Vous ouvrez des positions manuellement et voulez appliquer automatiquement vos règles TP/SL

**Configuration** :
```
MagicNumber : 0
EnableTPControl : Oui
TPPips : 50
EnableSLControl : Oui
SLPips : 25
ModifyOnlyNew : Oui (nouvelles positions uniquement)
UseBreakEven : Oui
BreakEvenPoints : 250 (25 pips)
BreakEvenOffset : 20
```

**Résultat** : Chaque nouvelle position aura automatiquement TP=50 pips, SL=25 pips, et BE à 25 pips

### Scénario 3 : Trailing pour Positions en Profit

**Situation** : Vos positions sont en profit, vous voulez les laisser courir avec trailing

**Configuration** :
```
EnableTPControl : Non
EnableSLControl : Non (garde les SL existants)
UseTrailingStop : Oui
TrailingStopPoints : 300 (30 pips)
TrailingStepPoints : 50 (5 pips)
```

**Résultat** : Les SL suivront le prix à 30 pips de distance

### Scénario 4 : Multi-Stratégies Distinctes

**Situation** : Vous avez 2 stratégies avec des règles différentes

**Solution** : Attachez le bot 2 fois sur 2 graphiques différents

**Instance 1** (Stratégie Scalping) :
```
MagicNumber : 11111
TPPips : 20
SLPips : 10
UseBreakEven : Oui
BreakEvenPoints : 100
```

**Instance 2** (Stratégie Swing) :
```
MagicNumber : 22222
TPPips : 100
SLPips : 50
UseTrailingStop : Oui
TrailingStopPoints : 400
```

**Résultat** : Chaque stratégie a ses propres règles de gestion

---

## 📊 Lecture des Informations Affichées

Lorsque `ShowInfo = true`, un panneau s'affiche sur le graphique :

```
╔═══════════════════════════════════╗
║  TP/SL Controller v1.0            ║
╠═══════════════════════════════════╣
║ Status: ACTIF                     ║
║ Positions: 5                      ║
║ Traitées: 127                     ║
╠═══════════════════════════════════╣
║ TP Control: ON                    ║
║ SL Control: ON                    ║
║ Trailing: OFF                     ║
║ Break Even: ON                    ║
╠═══════════════════════════════════╣
║ Modifs TP: 8                      ║
║ Modifs SL: 15                     ║
╚═══════════════════════════════════╝
```

**Explications** :
- **Status** : ACTIF = le bot fonctionne, INACTIF = désactivé
- **Positions** : Nombre de positions ouvertes actuellement
- **Traitées** : Nombre total de positions vérifiées depuis le démarrage
- **Modifs TP/SL** : Nombre de modifications effectuées avec succès

---

## 🛠️ Dépannage

### Problème : Le bot ne modifie aucune position

**Vérifications** :
1. ✅ `EnableController = true`
2. ✅ Au moins `EnableTPControl` ou `EnableSLControl = true`
3. ✅ Au moins un paramètre TP/SL est > 0
4. ✅ Les filtres ne sont pas trop restrictifs
5. ✅ Le bouton **AutoTrading** est activé dans MT5 (icône en haut)

**Solution** : Consultez l'onglet **Journal** (Ctrl+T) pour voir les erreurs

### Problème : Erreur "Trade context is busy"

**Cause** : Un autre EA ou opération manuelle modifie déjà une position

**Solution** : 
- Augmentez `RefreshRateMS` à 1000
- Vérifiez qu'un seul bot modifie les mêmes positions

### Problème : "Invalid stops" ou "Invalid TP/SL"

**Cause** : Les niveaux TP/SL sont trop proches du prix actuel

**Solution** :
- Vérifiez le `SYMBOL_TRADE_STOPS_LEVEL` de votre broker
- Dans MT5 : Market Watch → Symbole → clic droit → Spécification
- Augmentez vos valeurs TP/SL au-delà du niveau minimum

### Problème : Le trailing ne fonctionne pas

**Vérifications** :
1. ✅ `UseTrailingStop = true`
2. ✅ `TrailingStopPoints > 0`
3. ✅ Les positions sont en profit
4. ✅ Le profit actuel est > à la distance de trailing

**Note** : Le trailing ne fonctionne que pour les positions en profit

### Problème : Break Even ne s'active pas

**Vérifications** :
1. ✅ `UseBreakEven = true`
2. ✅ `BreakEvenPoints > 0`
3. ✅ Le profit actuel dépasse `BreakEvenPoints`
4. ✅ Le SL n'est pas déjà au prix d'entrée ou supérieur

---

## 📝 Journal et Logs

Le bot écrit dans le **Journal** de MT5 :

### Messages de Démarrage
```
╔════════════════════════════════════════════════════════════╗
║       Position TP/SL Controller - Initialisé              ║
╚════════════════════════════════════════════════════════════╝
TP Control: Activé
SL Control: Activé
Trailing Stop: Désactivé
Break Even: Activé
```

### Messages de Modification
```
✓ Position #123456789 modifiée: SL=1.10500 TP=1.11000
```

### Messages d'Erreur
```
Erreur modification position #123456789: Invalid stops [130]
```

### Messages d'Arrêt
```
╔════════════════════════════════════════════════════════════╗
║       Position TP/SL Controller - Arrêté                  ║
╚════════════════════════════════════════════════════════════╝
Total positions traitées: 450
Total modifications TP: 25
Total modifications SL: 38
```

---

## ⚡ Optimisation des Performances

### Pour un Petit Nombre de Positions (1-10)
```
RefreshRateMS : 500
ShowInfo : true
```

### Pour un Grand Nombre de Positions (10-50)
```
RefreshRateMS : 1000
ShowInfo : true
OnlyCurrentSymbol : true (si possible)
```

### Pour un Très Grand Nombre de Positions (50+)
```
RefreshRateMS : 2000
ShowInfo : false
Utilisez MagicNumber pour filtrer
```

---

## 🔒 Sécurité et Bonnes Pratiques

### ⚠️ TOUJOURS Tester en Démo d'abord
1. Créez un compte démo
2. Testez toutes vos configurations
3. Vérifiez les comportements
4. Seulement après, passez en réel

### ✅ Bonnes Pratiques
- Utilisez des valeurs réalistes de TP/SL (respect du spread)
- Activez `ModifyOnlyNew` si vous gérez certaines positions manuellement
- Surveillez les logs régulièrement
- N'utilisez pas de valeurs trop agressives en trailing

### 🚫 À Éviter
- Ne pas tester en démo avant le réel
- Mettre des TP/SL trop proches (< spread × 3)
- Avoir plusieurs bots qui modifient les mêmes positions
- Modifier manuellement des positions gérées par le bot (conflits possibles)

---

## 💡 Astuces Pro

### Astuce 1 : Combiner BE et Trailing
```
UseBreakEven : Oui
BreakEvenPoints : 200
UseTrailingStop : Oui
TrailingStopPoints : 300
```
Le BE sécurise d'abord, puis le trailing prend le relais

### Astuce 2 : Gestion Asymétrique
Attachez 2 instances :
- Instance 1 : Long positions uniquement
- Instance 2 : Short positions avec règles différentes

### Astuce 3 : Protection News
Créez un Set de paramètres "News Mode" :
```
EnableTPControl : Non
SLPercent : 1.0 (protection serrée)
UseTrailingStop : Non
UseBreakEven : Non
```
Chargez-le rapidement avant les news

### Astuce 4 : Mode Weekend
Avant le weekend, activez :
```
SLPercent : 0.5 (protection gap)
TPPercent : 0 (laisser ouvert)
```

---

## 📞 Support

- Consultez le fichier README.md pour la documentation complète
- Consultez EXEMPLES_CONFIGURATION.mq5 pour des configurations prêtes à l'emploi
- Vérifiez toujours les logs dans le Journal MT5

---

**Bon trading avec Position TP/SL Controller ! 🚀📈**
