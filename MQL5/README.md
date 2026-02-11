# Position TP/SL Controller - Bot MQL5

## 📋 Description

Bot MQL5 moderne et professionnel pour MetaTrader 5 qui permet de contrôler et modifier automatiquement les Take Profit (TP) et Stop Loss (SL) de toutes les positions ouvertes.

## ✨ Fonctionnalités Principales

### 🎯 Contrôle TP/SL
- **Take Profit configurable** : en points, pips ou pourcentage
- **Stop Loss configurable** : en points, pips ou pourcentage
- **Trailing Stop** : suivi automatique avec pas de déplacement
- **Break Even** : placement automatique au prix d'entrée après X points de profit

### 🔧 Gestion Avancée
- **Filtrage flexible** :
  - Par Magic Number (ou toutes positions)
  - Par commentaire de position
  - Par symbole (actuel uniquement ou tous)
- **Modification sélective** :
  - Option pour modifier uniquement les nouvelles positions
  - Conservation des TP/SL existants si souhaité

### 📊 Interface
- Affichage en temps réel des statistiques sur le graphique
- Compteurs de positions traitées et modifications effectuées
- Interface visuelle élégante avec encadrés

## 🚀 Installation

1. Copiez le fichier `PositionTPSLController.mq5` dans :
   ```
   [Dossier MT5]\MQL5\Experts\
   ```

2. Ouvrez MetaEditor et compilez le fichier (F7)

3. Le bot apparaîtra dans la liste des Expert Advisors

## ⚙️ Paramètres

### Paramètres Généraux
| Paramètre | Type | Défaut | Description |
|-----------|------|--------|-------------|
| `EnableController` | bool | true | Active/désactive le contrôleur |
| `MagicNumber` | int | 123456 | Magic Number (0 = toutes positions) |
| `CommentFilter` | string | "" | Filtre par commentaire (vide = tous) |
| `OnlyCurrentSymbol` | bool | false | Traite seulement le symbole actuel |

### Take Profit (TP)
| Paramètre | Type | Défaut | Description |
|-----------|------|--------|-------------|
| `EnableTPControl` | bool | true | Active le contrôle TP |
| `TPPoints` | double | 0 | TP en points (0 = pas de modification) |
| `TPPercent` | double | 0 | TP en % du prix d'entrée (0 = désactivé) |
| `TPPips` | double | 0 | TP en pips (0 = désactivé) |

### Stop Loss (SL)
| Paramètre | Type | Défaut | Description |
|-----------|------|--------|-------------|
| `EnableSLControl` | bool | true | Active le contrôle SL |
| `SLPoints` | double | 0 | SL en points (0 = pas de modification) |
| `SLPercent` | double | 0 | SL en % du prix d'entrée (0 = désactivé) |
| `SLPips` | double | 0 | SL en pips (0 = désactivé) |

### Trailing Stop
| Paramètre | Type | Défaut | Description |
|-----------|------|--------|-------------|
| `UseTrailingStop` | bool | false | Active le trailing stop |
| `TrailingStopPoints` | double | 0 | Distance du trailing en points |
| `TrailingStepPoints` | double | 0 | Pas de déplacement en points |

### Break Even
| Paramètre | Type | Défaut | Description |
|-----------|------|--------|-------------|
| `UseBreakEven` | bool | false | Active le break even |
| `BreakEvenPoints` | double | 0 | Points de profit pour activer BE |
| `BreakEvenOffset` | double | 0 | Offset du break even en points |

### Gestion Avancée
| Paramètre | Type | Défaut | Description |
|-----------|------|--------|-------------|
| `ModifyOnlyNew` | bool | false | Modifie seulement les nouvelles positions |
| `ShowInfo` | bool | true | Affiche les infos sur le graphique |
| `InfoColor` | color | clrWhite | Couleur des informations affichées |
| `RefreshRateMS` | int | 500 | Taux de rafraîchissement (millisecondes) |

## 📖 Exemples d'Utilisation

### Exemple 1 : TP/SL Simple en Points
```
TPPoints = 500      // TP à 500 points du prix d'entrée
SLPoints = 200      // SL à 200 points du prix d'entrée
```

### Exemple 2 : TP/SL en Pourcentage
```
TPPercent = 2.0     // TP à +2% du prix d'entrée
SLPercent = 1.0     // SL à -1% du prix d'entrée
```

### Exemple 3 : Trailing Stop
```
UseTrailingStop = true
TrailingStopPoints = 300      // Trail à 300 points du prix actuel
TrailingStepPoints = 50       // Ne déplace que par pas de 50 points
```

### Exemple 4 : Break Even
```
UseBreakEven = true
BreakEvenPoints = 300         // Active BE après 300 points de profit
BreakEvenOffset = 20          // Place le SL à +20 points du prix d'entrée
```

### Exemple 5 : Filtrage Spécifique
```
MagicNumber = 12345           // Seulement les positions avec ce Magic Number
CommentFilter = "MyStrategy"  // Seulement les positions contenant "MyStrategy"
OnlyCurrentSymbol = true      // Seulement sur EURUSD (si graphique EURUSD)
```

## 🎓 Cas d'Usage

### 1. Gestion Globale de Portfolio
Appliquez des règles TP/SL uniformes à toutes vos positions ouvertes, quelle que soit leur stratégie d'origine.

### 2. Protection d'Urgence
Placez rapidement des stops de sécurité sur toutes les positions en cas de news imprévue.

### 3. Trailing Automatique
Sécurisez vos profits automatiquement sans surveillance constante.

### 4. Break Even Automatique
Protégez votre capital en déplaçant automatiquement le SL au point mort.

### 5. Gestion Multi-Stratégies
Utilisez différents Magic Numbers pour appliquer des règles spécifiques à chaque stratégie.

## 🛡️ Sécurité et Précautions

- ⚠️ **Testez toujours en compte démo** avant utilisation réelle
- 🔍 **Vérifiez les spreads** : les niveaux TP/SL doivent respecter les distances minimales du broker
- 📊 **Surveillez les logs** : le bot affiche toutes les modifications dans le journal
- 🎯 **Utilisez ModifyOnlyNew** : pour éviter de modifier des positions déjà configurées
- ⏱️ **Ajustez RefreshRateMS** : pour optimiser la charge CPU (500ms recommandé)

## 🔍 Dépannage

### Le bot ne modifie pas les positions
- Vérifiez que `EnableController = true`
- Vérifiez que `EnableTPControl` ou `EnableSLControl = true`
- Vérifiez les filtres (MagicNumber, CommentFilter, OnlyCurrentSymbol)
- Consultez les logs pour les messages d'erreur

### Erreurs de modification
- Vérifiez que les niveaux TP/SL respectent les distances minimales (SYMBOL_TRADE_STOPS_LEVEL)
- Assurez-vous que le compte a les permissions pour modifier les positions
- Vérifiez que les positions ne sont pas en train d'être fermées

### Performance
- Augmentez `RefreshRateMS` si le CPU est trop sollicité
- Désactivez `ShowInfo` si non nécessaire
- Utilisez des filtres pour limiter le nombre de positions traitées

## 📝 Logs et Monitoring

Le bot affiche dans le journal :
- ✓ Confirmations de modifications réussies
- ❌ Erreurs avec codes d'erreur
- 📊 Statistiques au démarrage et à l'arrêt
- 🔄 État des fonctionnalités activées

## 🔄 Mises à Jour

**Version 1.00** (2024)
- Version initiale
- Support complet TP/SL en points, pips et pourcentage
- Trailing stop avec pas de déplacement
- Break even automatique
- Filtrage avancé par Magic Number, commentaire et symbole
- Interface graphique avec statistiques en temps réel

## 📄 Licence

Ce code est fourni à titre éducatif et d'exemple. Utilisez-le à vos propres risques.

## 🤝 Support

Pour toute question ou suggestion d'amélioration, n'hésitez pas à ouvrir une issue sur le repository.

## ⚡ Compilation

Pour compiler le bot :
1. Ouvrez MetaEditor
2. Ouvrez le fichier `PositionTPSLController.mq5`
3. Appuyez sur F7 ou cliquez sur "Compiler"
4. Vérifiez qu'il n'y a pas d'erreurs dans l'onglet "Erreurs"

Le bot est maintenant prêt à être utilisé !

---

**Bon trading ! 📈**
