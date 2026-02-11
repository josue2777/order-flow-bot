//+------------------------------------------------------------------+
//|                                      PositionTPSLController.mq5   |
//|                                    Contrôleur TP/SL Avancé       |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Trading Bot 2024"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//--- Paramètres d'entrée
input group "========== Paramètres Généraux =========="
input bool     EnableController = true;                    // Activer le contrôleur
input int      MagicNumber = 123456;                       // Magic Number (0 = toutes positions)
input string   CommentFilter = "";                         // Filtre par commentaire (vide = tous)
input bool     OnlyCurrentSymbol = false;                  // Seulement symbole actuel

input group "========== Take Profit (TP) =========="
input bool     EnableTPControl = true;                     // Activer contrôle TP
input double   TPPoints = 0;                               // TP en points (0 = pas de modification)
input double   TPPercent = 0;                              // TP en % du prix entrée (0 = désactivé)
input double   TPPips = 0;                                 // TP en pips (0 = désactivé)

input group "========== Stop Loss (SL) =========="
input bool     EnableSLControl = true;                     // Activer contrôle SL
input double   SLPoints = 0;                               // SL en points (0 = pas de modification)
input double   SLPercent = 0;                              // SL en % du prix entrée (0 = désactivé)
input double   SLPips = 0;                                 // SL en pips (0 = désactivé)

input group "========== Trailing Stop =========="
input bool     UseTrailingStop = false;                    // Utiliser trailing stop
input double   TrailingStopPoints = 0;                     // Distance trailing en points
input double   TrailingStepPoints = 0;                     // Pas de déplacement en points

input group "========== Break Even =========="
input bool     UseBreakEven = false;                       // Activer break even
input double   BreakEvenPoints = 0;                        // Points de profit pour activer BE
input double   BreakEvenOffset = 0;                        // Offset du break even en points

input group "========== Gestion Avancée =========="
input bool     ModifyOnlyNew = false;                      // Modifier seulement nouvelles positions
input bool     ShowInfo = true;                            // Afficher infos sur graphique
input color    InfoColor = clrWhite;                       // Couleur des infos
input int      RefreshRateMS = 500;                        // Taux de rafraîchissement (ms)

//--- Variables globales
CTrade trade;
CPositionInfo positionInfo;
CSymbolInfo symbolInfo;

datetime lastCheck = 0;
int totalPositionsProcessed = 0;
int totalTPModifications = 0;
int totalSLModifications = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                     |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- Configuration du trade
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(10);
   trade.SetTypeFilling(ORDER_FILLING_FOK);
   trade.SetAsyncMode(false);
   
   //--- Validation des paramètres
   if(!ValidateParameters())
      return(INIT_PARAMETERS_INCORRECT);
   
   //--- Initialisation réussie
   Print("╔════════════════════════════════════════════════════════════╗");
   Print("║       Position TP/SL Controller - Initialisé              ║");
   Print("╚════════════════════════════════════════════════════════════╝");
   Print("TP Control: ", EnableTPControl ? "Activé" : "Désactivé");
   Print("SL Control: ", EnableSLControl ? "Activé" : "Désactivé");
   Print("Trailing Stop: ", UseTrailingStop ? "Activé" : "Désactivé");
   Print("Break Even: ", UseBreakEven ? "Activé" : "Désactivé");
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   //--- Nettoyage des objets graphiques
   CleanupChartObjects();
   
   Print("╔════════════════════════════════════════════════════════════╗");
   Print("║       Position TP/SL Controller - Arrêté                  ║");
   Print("╚════════════════════════════════════════════════════════════╝");
   Print("Total positions traitées: ", totalPositionsProcessed);
   Print("Total modifications TP: ", totalTPModifications);
   Print("Total modifications SL: ", totalSLModifications);
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
   if(!EnableController)
      return;
   
   //--- Contrôle du taux de rafraîchissement
   if(GetTickCount() - lastCheck < RefreshRateMS)
      return;
      
   lastCheck = GetTickCount();
   
   //--- Traitement de toutes les positions
   ProcessAllPositions();
   
   //--- Affichage des informations
   if(ShowInfo)
      DisplayInfo();
}

//+------------------------------------------------------------------+
//| Traite toutes les positions ouvertes                             |
//+------------------------------------------------------------------+
void ProcessAllPositions()
{
   int total = PositionsTotal();
   
   for(int i = total - 1; i >= 0; i--)
   {
      if(!positionInfo.SelectByIndex(i))
         continue;
      
      //--- Filtres
      if(OnlyCurrentSymbol && positionInfo.Symbol() != _Symbol)
         continue;
         
      if(MagicNumber != 0 && positionInfo.Magic() != MagicNumber)
         continue;
         
      if(CommentFilter != "" && StringFind(positionInfo.Comment(), CommentFilter) == -1)
         continue;
      
      //--- Traitement de la position
      ProcessPosition();
      totalPositionsProcessed++;
   }
}

//+------------------------------------------------------------------+
//| Traite une position spécifique                                    |
//+------------------------------------------------------------------+
void ProcessPosition()
{
   string symbol = positionInfo.Symbol();
   ulong ticket = positionInfo.Ticket();
   ENUM_POSITION_TYPE type = positionInfo.PositionType();
   double openPrice = positionInfo.PriceOpen();
   double currentTP = positionInfo.TakeProfit();
   double currentSL = positionInfo.StopLoss();
   
   //--- Initialisation du symbole
   if(!symbolInfo.Name(symbol))
      return;
   
   symbolInfo.Refresh();
   double currentPrice = (type == POSITION_TYPE_BUY) ? symbolInfo.Bid() : symbolInfo.Ask();
   double point = symbolInfo.Point();
   double tickSize = symbolInfo.TickSize();
   int digits = (int)symbolInfo.Digits();
   
   //--- Calcul du nouveau TP
   double newTP = currentTP;
   if(EnableTPControl)
      newTP = CalculateNewTP(type, openPrice, currentTP, currentPrice, point, digits);
   
   //--- Calcul du nouveau SL
   double newSL = currentSL;
   if(EnableSLControl)
      newSL = CalculateNewSL(type, openPrice, currentSL, currentPrice, point, digits);
   
   //--- Trailing Stop
   if(UseTrailingStop && TrailingStopPoints > 0)
      newSL = CalculateTrailingStop(type, currentSL, currentPrice, point, digits);
   
   //--- Break Even
   if(UseBreakEven && BreakEvenPoints > 0)
      newSL = CalculateBreakEven(type, openPrice, currentSL, currentPrice, point, digits);
   
   //--- Modification de la position si nécessaire
   if(NormalizeDouble(newTP, digits) != NormalizeDouble(currentTP, digits) ||
      NormalizeDouble(newSL, digits) != NormalizeDouble(currentSL, digits))
   {
      ModifyPosition(ticket, newSL, newTP);
   }
}

//+------------------------------------------------------------------+
//| Calcule le nouveau Take Profit                                   |
//+------------------------------------------------------------------+
double CalculateNewTP(ENUM_POSITION_TYPE type, double openPrice, double currentTP, 
                      double currentPrice, double point, int digits)
{
   double newTP = currentTP;
   
   //--- Si modification seulement des nouvelles positions et TP existe déjà
   if(ModifyOnlyNew && currentTP > 0)
      return currentTP;
   
   //--- TP en points
   if(TPPoints > 0)
   {
      if(type == POSITION_TYPE_BUY)
         newTP = openPrice + TPPoints * point;
      else
         newTP = openPrice - TPPoints * point;
   }
   //--- TP en pips
   else if(TPPips > 0)
   {
      double pipSize = point * 10; // Pour la plupart des paires
      if(digits == 3 || digits == 5)
         pipSize = point * 10;
      else
         pipSize = point;
         
      if(type == POSITION_TYPE_BUY)
         newTP = openPrice + TPPips * pipSize;
      else
         newTP = openPrice - TPPips * pipSize;
   }
   //--- TP en pourcentage
   else if(TPPercent > 0)
   {
      double tpDistance = openPrice * (TPPercent / 100.0);
      if(type == POSITION_TYPE_BUY)
         newTP = openPrice + tpDistance;
      else
         newTP = openPrice - tpDistance;
   }
   
   return NormalizeDouble(newTP, digits);
}

//+------------------------------------------------------------------+
//| Calcule le nouveau Stop Loss                                     |
//+------------------------------------------------------------------+
double CalculateNewSL(ENUM_POSITION_TYPE type, double openPrice, double currentSL,
                      double currentPrice, double point, int digits)
{
   double newSL = currentSL;
   
   //--- Si modification seulement des nouvelles positions et SL existe déjà
   if(ModifyOnlyNew && currentSL > 0)
      return currentSL;
   
   //--- SL en points
   if(SLPoints > 0)
   {
      if(type == POSITION_TYPE_BUY)
         newSL = openPrice - SLPoints * point;
      else
         newSL = openPrice + SLPoints * point;
   }
   //--- SL en pips
   else if(SLPips > 0)
   {
      double pipSize = point * 10;
      if(digits == 3 || digits == 5)
         pipSize = point * 10;
      else
         pipSize = point;
         
      if(type == POSITION_TYPE_BUY)
         newSL = openPrice - SLPips * pipSize;
      else
         newSL = openPrice + SLPips * pipSize;
   }
   //--- SL en pourcentage
   else if(SLPercent > 0)
   {
      double slDistance = openPrice * (SLPercent / 100.0);
      if(type == POSITION_TYPE_BUY)
         newSL = openPrice - slDistance;
      else
         newSL = openPrice + slDistance;
   }
   
   return NormalizeDouble(newSL, digits);
}

//+------------------------------------------------------------------+
//| Calcule le Trailing Stop                                         |
//+------------------------------------------------------------------+
double CalculateTrailingStop(ENUM_POSITION_TYPE type, double currentSL, 
                             double currentPrice, double point, int digits)
{
   double newSL = currentSL;
   double trailDistance = TrailingStopPoints * point;
   double trailStep = (TrailingStepPoints > 0) ? TrailingStepPoints * point : 0;
   
   if(type == POSITION_TYPE_BUY)
   {
      double newStop = currentPrice - trailDistance;
      if(newStop > currentSL || currentSL == 0)
      {
         if(trailStep == 0 || newStop >= currentSL + trailStep)
            newSL = newStop;
      }
   }
   else // SELL
   {
      double newStop = currentPrice + trailDistance;
      if(newStop < currentSL || currentSL == 0)
      {
         if(trailStep == 0 || newStop <= currentSL - trailStep)
            newSL = newStop;
      }
   }
   
   return NormalizeDouble(newSL, digits);
}

//+------------------------------------------------------------------+
//| Calcule le Break Even                                            |
//+------------------------------------------------------------------+
double CalculateBreakEven(ENUM_POSITION_TYPE type, double openPrice, double currentSL,
                          double currentPrice, double point, int digits)
{
   double newSL = currentSL;
   double beDistance = BreakEvenPoints * point;
   double bePrice = openPrice + (BreakEvenOffset * point);
   
   if(type == POSITION_TYPE_BUY)
   {
      //--- Si le prix a progressé suffisamment et le SL n'est pas encore au BE
      if(currentPrice >= openPrice + beDistance && currentSL < bePrice)
         newSL = bePrice;
   }
   else // SELL
   {
      bePrice = openPrice - (BreakEvenOffset * point);
      if(currentPrice <= openPrice - beDistance && (currentSL > bePrice || currentSL == 0))
         newSL = bePrice;
   }
   
   return NormalizeDouble(newSL, digits);
}

//+------------------------------------------------------------------+
//| Modifie une position                                             |
//+------------------------------------------------------------------+
void ModifyPosition(ulong ticket, double sl, double tp)
{
   if(!trade.PositionModify(ticket, sl, tp))
   {
      Print("Erreur modification position #", ticket, ": ", GetLastError());
      return;
   }
   
   //--- Mise à jour des compteurs
   if(sl != positionInfo.StopLoss())
      totalSLModifications++;
   if(tp != positionInfo.TakeProfit())
      totalTPModifications++;
   
   Print("✓ Position #", ticket, " modifiée: SL=", sl, " TP=", tp);
}

//+------------------------------------------------------------------+
//| Valide les paramètres d'entrée                                   |
//+------------------------------------------------------------------+
bool ValidateParameters()
{
   if(TPPoints < 0 || SLPoints < 0 || TPPips < 0 || SLPips < 0)
   {
      Print("Erreur: Les valeurs ne peuvent pas être négatives");
      return false;
   }
   
   if(TrailingStopPoints < 0 || TrailingStepPoints < 0 || BreakEvenPoints < 0)
   {
      Print("Erreur: Les valeurs de trailing/break even ne peuvent pas être négatives");
      return false;
   }
   
   if(UseTrailingStop && TrailingStopPoints == 0)
   {
      Print("Erreur: Trailing stop activé mais distance = 0");
      return false;
   }
   
   if(UseBreakEven && BreakEvenPoints == 0)
   {
      Print("Erreur: Break even activé mais distance = 0");
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Affiche les informations sur le graphique                        |
//+------------------------------------------------------------------+
void DisplayInfo()
{
   string objName = "TPSLControllerInfo";
   int yPos = 20;
   int xPos = 20;
   
   //--- Création du label si nécessaire
   if(ObjectFind(0, objName) < 0)
   {
      ObjectCreate(0, objName, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, xPos);
      ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, yPos);
      ObjectSetInteger(0, objName, OBJPROP_COLOR, InfoColor);
      ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, 9);
      ObjectSetString(0, objName, OBJPROP_FONT, "Courier New");
   }
   
   //--- Construction du texte d'information
   string info = "╔═══════════════════════════════════╗\n";
   info += "║  TP/SL Controller v1.0            ║\n";
   info += "╠═══════════════════════════════════╣\n";
   info += StringFormat("║ Status: %s\n", EnableController ? "ACTIF    " : "INACTIF  ");
   info += StringFormat("║ Positions: %d\n", PositionsTotal());
   info += StringFormat("║ Traitées: %d\n", totalPositionsProcessed);
   info += "╠═══════════════════════════════════╣\n";
   info += StringFormat("║ TP Control: %s\n", EnableTPControl ? "ON " : "OFF");
   info += StringFormat("║ SL Control: %s\n", EnableSLControl ? "ON " : "OFF");
   info += StringFormat("║ Trailing: %s\n", UseTrailingStop ? "ON " : "OFF");
   info += StringFormat("║ Break Even: %s\n", UseBreakEven ? "ON " : "OFF");
   info += "╠═══════════════════════════════════╣\n";
   info += StringFormat("║ Modifs TP: %d\n", totalTPModifications);
   info += StringFormat("║ Modifs SL: %d\n", totalSLModifications);
   info += "╚═══════════════════════════════════╝";
   
   ObjectSetString(0, objName, OBJPROP_TEXT, info);
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Nettoie les objets graphiques                                    |
//+------------------------------------------------------------------+
void CleanupChartObjects()
{
   ObjectDelete(0, "TPSLControllerInfo");
}

//+------------------------------------------------------------------+
