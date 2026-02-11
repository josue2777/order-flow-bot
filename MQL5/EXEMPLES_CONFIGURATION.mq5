//+------------------------------------------------------------------+
//|                               EXEMPLES DE CONFIGURATION          |
//|                          PositionTPSLController.mq5              |
//+------------------------------------------------------------------+

/*
   Ce fichier contient des exemples de configuration pour différents 
   scénarios d'utilisation du bot PositionTPSLController.
   
   Copiez et adaptez ces configurations selon vos besoins.
*/

//+------------------------------------------------------------------+
//| EXEMPLE 1 : SCALPING AGRESSIF                                    |
//+------------------------------------------------------------------+
/*
   Objectif : TP rapide avec SL serré et break even agressif
   
   Configuration :
   - TP : 20 pips
   - SL : 10 pips
   - Break Even après 10 pips de profit
   - Offset BE : +2 pips pour sécuriser
*/

input bool     EnableController = true;
input int      MagicNumber = 0;                 // Toutes positions
input string   CommentFilter = "";
input bool     OnlyCurrentSymbol = true;        // Symbole actuel uniquement

input bool     EnableTPControl = true;
input double   TPPips = 20;                     // TP à 20 pips

input bool     EnableSLControl = true;
input double   SLPips = 10;                     // SL à 10 pips

input bool     UseBreakEven = true;
input double   BreakEvenPoints = 100;           // BE après 10 pips (100 points)
input double   BreakEvenOffset = 20;            // Offset de +2 pips

//+------------------------------------------------------------------+
//| EXEMPLE 2 : SWING TRADING                                        |
//+------------------------------------------------------------------+
/*
   Objectif : Positions à moyen terme avec trailing stop
   
   Configuration :
   - TP : 200 pips
   - SL : 100 pips
   - Trailing Stop à 50 pips
   - Pas de déplacement : 10 pips
*/

input bool     EnableController = true;
input int      MagicNumber = 54321;             // Stratégie swing spécifique
input string   CommentFilter = "";
input bool     OnlyCurrentSymbol = false;       // Tous symboles

input bool     EnableTPControl = true;
input double   TPPips = 200;                    // TP à 200 pips

input bool     EnableSLControl = true;
input double   SLPips = 100;                    // SL à 100 pips

input bool     UseTrailingStop = true;
input double   TrailingStopPoints = 500;        // Trail à 50 pips
input double   TrailingStepPoints = 100;        // Déplace par pas de 10 pips

//+------------------------------------------------------------------+
//| EXEMPLE 3 : GESTION CONSERVATIVE                                 |
//+------------------------------------------------------------------+
/*
   Objectif : Risk/Reward 1:2 avec protection capital
   
   Configuration :
   - TP : 2% du prix d'entrée
   - SL : 1% du prix d'entrée
   - Break Even après 1% de profit
*/

input bool     EnableController = true;
input int      MagicNumber = 0;
input string   CommentFilter = "Conservative";
input bool     OnlyCurrentSymbol = false;

input bool     EnableTPControl = true;
input double   TPPercent = 2.0;                 // TP à +2%

input bool     EnableSLControl = true;
input double   SLPercent = 1.0;                 // SL à -1%

input bool     UseBreakEven = true;
input double   BreakEvenPoints = 100;           // BE après 1% (ajuster selon symbole)
input double   BreakEvenOffset = 10;

//+------------------------------------------------------------------+
//| EXEMPLE 4 : DAY TRADING EURUSD                                   |
//+------------------------------------------------------------------+
/*
   Objectif : Trading journalier avec objectifs fixes
   
   Configuration :
   - TP : 500 points (50 pips sur 5 digits)
   - SL : 300 points (30 pips sur 5 digits)
   - Trailing après 400 points de profit
*/

input bool     EnableController = true;
input int      MagicNumber = 0;
input string   CommentFilter = "";
input bool     OnlyCurrentSymbol = true;        // EURUSD uniquement

input bool     EnableTPControl = true;
input double   TPPoints = 500;                  // 50 pips

input bool     EnableSLControl = true;
input double   SLPoints = 300;                  // 30 pips

input bool     UseTrailingStop = true;
input double   TrailingStopPoints = 200;        // Trail à 20 pips
input double   TrailingStepPoints = 50;         // Pas de 5 pips

input bool     UseBreakEven = true;
input double   BreakEvenPoints = 300;           // BE après 30 pips
input double   BreakEvenOffset = 20;            // +2 pips de sécurité

//+------------------------------------------------------------------+
//| EXEMPLE 5 : PROTECTION D'URGENCE                                 |
//+------------------------------------------------------------------+
/*
   Objectif : Placer rapidement des stops sur toutes positions
   
   Configuration :
   - Pas de TP (laisser courir)
   - SL uniquement à 1% du prix d'entrée
   - Modification de toutes positions existantes
*/

input bool     EnableController = true;
input int      MagicNumber = 0;                 // TOUTES les positions
input string   CommentFilter = "";
input bool     OnlyCurrentSymbol = false;       // TOUS les symboles

input bool     EnableTPControl = false;         // Pas de TP
input double   TPPoints = 0;

input bool     EnableSLControl = true;
input double   SLPercent = 1.0;                 // SL à -1% pour protection
input bool     ModifyOnlyNew = false;           // Modifier TOUTES les positions

//+------------------------------------------------------------------+
//| EXEMPLE 6 : MULTI-STRATÉGIES                                     |
//+------------------------------------------------------------------+
/*
   Objectif : Gérer plusieurs stratégies avec règles différentes
   
   STRATEGIE A (Magic 11111) :
   - TP : 30 pips
   - SL : 15 pips
   - BE après 15 pips
*/

input bool     EnableController = true;
input int      MagicNumber = 11111;             // Stratégie A uniquement
input string   CommentFilter = "";
input bool     OnlyCurrentSymbol = false;

input bool     EnableTPControl = true;
input double   TPPips = 30;

input bool     EnableSLControl = true;
input double   SLPips = 15;

input bool     UseBreakEven = true;
input double   BreakEvenPoints = 150;           // 15 pips
input double   BreakEvenOffset = 10;

/*
   NOTE : Pour la stratégie B (Magic 22222), attachez une autre 
   instance du bot avec MagicNumber = 22222 et paramètres différents
*/

//+------------------------------------------------------------------+
//| EXEMPLE 7 : TRAILING AGRESSIF                                    |
//+------------------------------------------------------------------+
/*
   Objectif : Sécuriser profits rapidement avec trailing serré
   
   Configuration :
   - TP désactivé (laisser le trailing gérer)
   - SL initial : 50 pips
   - Trailing : 30 pips
   - Pas : 5 pips (réactif)
   - BE après 30 pips
*/

input bool     EnableController = true;
input int      MagicNumber = 0;
input string   CommentFilter = "Trending";
input bool     OnlyCurrentSymbol = true;

input bool     EnableTPControl = false;         // Pas de TP fixe
input double   TPPips = 0;

input bool     EnableSLControl = true;
input double   SLPips = 50;                     // SL initial

input bool     UseTrailingStop = true;
input double   TrailingStopPoints = 300;        // Trail à 30 pips
input double   TrailingStepPoints = 50;         // Très réactif

input bool     UseBreakEven = true;
input double   BreakEvenPoints = 300;           // BE rapide à 30 pips
input double   BreakEvenOffset = 10;

//+------------------------------------------------------------------+
//| EXEMPLE 8 : NOUVELLES POSITIONS UNIQUEMENT                       |
//+------------------------------------------------------------------+
/*
   Objectif : Appliquer règles seulement aux nouvelles positions
   
   Configuration :
   - Ne modifie pas les positions avec TP/SL existants
   - Utile si certaines positions sont déjà gérées manuellement
*/

input bool     EnableController = true;
input int      MagicNumber = 0;
input string   CommentFilter = "";
input bool     OnlyCurrentSymbol = false;

input bool     EnableTPControl = true;
input double   TPPips = 50;

input bool     EnableSLControl = true;
input double   SLPips = 25;

input bool     ModifyOnlyNew = true;            // NE PAS modifier positions existantes
input bool     UseTrailingStop = false;
input bool     UseBreakEven = false;

//+------------------------------------------------------------------+
//| EXEMPLE 9 : BREAKOUT STRATEGY                                    |
//+------------------------------------------------------------------+
/*
   Objectif : Laisser courir les breakouts avec trailing large
   
   Configuration :
   - TP large : 150 pips
   - SL : 50 pips
   - Trailing : 60 pips (laisser respirer)
   - BE après 50 pips pour sécuriser
*/

input bool     EnableController = true;
input int      MagicNumber = 99999;
input string   CommentFilter = "Breakout";
input bool     OnlyCurrentSymbol = true;

input bool     EnableTPControl = true;
input double   TPPips = 150;                    // TP large

input bool     EnableSLControl = true;
input double   SLPips = 50;

input bool     UseTrailingStop = true;
input double   TrailingStopPoints = 600;        // Trail large à 60 pips
input double   TrailingStepPoints = 100;        // Pas de 10 pips

input bool     UseBreakEven = true;
input double   BreakEvenPoints = 500;           // BE après 50 pips
input double   BreakEvenOffset = 20;

//+------------------------------------------------------------------+
//| EXEMPLE 10 : INDICES (US30, NAS100, etc.)                        |
//+------------------------------------------------------------------+
/*
   Objectif : Trading d'indices avec points adaptés
   
   Configuration :
   - TP : 200 points
   - SL : 100 points
   - Trailing : 80 points
   - Pas : 20 points
*/

input bool     EnableController = true;
input int      MagicNumber = 0;
input string   CommentFilter = "";
input bool     OnlyCurrentSymbol = true;        // US30 ou NAS100

input bool     EnableTPControl = true;
input double   TPPoints = 200;                  // Adapté aux indices

input bool     EnableSLControl = true;
input double   SLPoints = 100;

input bool     UseTrailingStop = true;
input double   TrailingStopPoints = 80;
input double   TrailingStepPoints = 20;

input bool     UseBreakEven = true;
input double   BreakEvenPoints = 100;
input double   BreakEvenOffset = 10;

//+------------------------------------------------------------------+
//| CONSEILS DE CONFIGURATION                                        |
//+------------------------------------------------------------------+

/*
   POINTS vs PIPS :
   - Pour paires 5 digits (EURUSD 1.12345) : 10 points = 1 pip
   - Pour paires 3 digits (USDJPY 110.123) : 10 points = 1 pip
   - Pour paires 2 digits (indices) : 1 point = 1 point
   
   POURCENTAGE :
   - Utile pour cryptos et actions avec grands mouvements
   - Adapte automatiquement aux différents niveaux de prix
   
   TRAILING STOP :
   - TrailingStepPoints = 0 : déplace à chaque tick (peut être gourmand)
   - TrailingStepPoints > 0 : déplace par paliers (recommandé)
   
   BREAK EVEN :
   - Toujours mettre un offset positif (ex: +2 pips) pour sécurité
   - BreakEvenPoints doit être > spread pour être atteignable
   
   FILTRES :
   - MagicNumber = 0 : applique à TOUTES les positions
   - CommentFilter utile pour filtrer par nom de stratégie
   - OnlyCurrentSymbol pour contrôle précis par paire
   
   PERFORMANCES :
   - RefreshRateMS = 500 recommandé (équilibre perf/réactivité)
   - Augmenter si beaucoup de positions ouvertes
   - ShowInfo = false pour économiser ressources
*/

//+------------------------------------------------------------------+
