// Scalping M1 Multi-Position Reversal EA – Trigger sur mouvement de prix (0.20 Gold & adaptatif) + Reset Bougie M1
// Version optimisée pour espacement léger selon le marché – Février 2026

#property strict
#property copyright "Copyright 2026"
#property version   "1.01"
#property description "EA de scalping M1 avec tableau de bord graphique et image de fond personnalisée."

//--- Includes
#include <Trade\Trade.mqh>

//--- Inputs
input double PriceMoveThreshold = 0.20;     // 0.20 pour Gold, 0.00020 pour EURUSD 5 digits, 5.0 pour BTCUSDT
input double LotSize = 0.01;                // Taille des lots
input int MaxTotalPositions = 20;           // Limite de positions cumulées
input ulong MagicNumber = 20260228;         // Identifiant unique des positions
input double MaxSpread = 30.0;              // Spread maximum en points

//--- Inputs Esthétiques
input string InpBackgroundImage = "robot_hybride.bmp"; // Nom du fichier image (MQL5/Images/)
input color  InpDashboardBg    = C'20,20,20';         // Couleur de fond du tableau
input color  InpHeaderColor    = clrGold;             // Couleur des entêtes
input color  InpTextColor      = clrWhite;            // Couleur du texte
input int    InpFontSize       = 10;                  // Taille de police

//--- Variables Globales
double lastTriggerPrice = 0;                // Dernier prix ayant déclenché une action
CTrade trade;                               // Instance de la classe CTrade pour les opérations
datetime lastBarTime = 0;                   // Temps d'ouverture de la dernière bougie traitée
string lastMoveType = "Aucun";              // Type du dernier mouvement détecté

//--- Constantes UI
#define UI_PREFIX "SF_UI_"

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // Configuration du Magic Number pour les opérations de trading
   trade.SetExpertMagicNumber(MagicNumber);

   // Initialisation du dernier prix de déclenchement avec le prix actuel
   lastTriggerPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   // Initialisation du temps de la dernière bougie
   datetime times[];
   ArraySetAsSeries(times, true);
   if(CopyTime(_Symbol, PERIOD_M1, 0, 1, times) > 0)
      lastBarTime = times[0];

   // Initialisation graphique
   SetBackgroundImage();
   CreateDashboard();

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Nettoyage des objets graphiques
   ObjectsDeleteAll(0, UI_PREFIX);
   Comment("");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // 1. Vérification du reset à chaque nouvelle bougie M1
   ResetAtNewBar();

   // 2. Vérification du mouvement de prix pour l'ouverture/fermeture de positions
   CheckPriceMoveAndFlip();

   // 3. Mise à jour du tableau de bord
   UpdateDashboard();
}

//+------------------------------------------------------------------+
//| Création du tableau de bord graphique                            |
//+------------------------------------------------------------------+
void CreateDashboard()
{
   int x = 10, y = 30, w = 300, h = 180;

   // Fond du tableau
   CreateRectLabel("MainBg", x, y, w, h, InpDashboardBg);

   // Titre
   CreateLabel("Title", x+5, y+5, "--- EA SCALPING M1 REVERSAL ---", InpHeaderColor, 12);

   // Labels Statiques
   int row = y + 30;
   CreateLabel("L_Threshold", x+10, row, "Seuil de mouvement:", InpTextColor); row+=20;
   CreateLabel("L_LastMove", x+10, row, "Dernier mouvement:", InpTextColor); row+=20;
   CreateLabel("L_TriggerPrice", x+10, row, "Prix déclencheur:", InpTextColor); row+=20;
   CreateLabel("L_Positions", x+10, row, "Positions (B/S):", InpTextColor); row+=20;
   CreateLabel("L_Total", x+10, row, "Total positions:", InpTextColor); row+=20;
   CreateLabel("L_Spread", x+10, row, "Spread (Max):", InpTextColor);

   // Labels Dynamiques (Valeurs)
   row = y + 30;
   int valX = x + 180;
   CreateLabel("V_Threshold", valX, row, "", clrLightBlue); row+=20;
   CreateLabel("V_LastMove", valX, row, "", clrOrange); row+=20;
   CreateLabel("V_TriggerPrice", valX, row, "", clrWhite); row+=20;
   CreateLabel("V_Positions", valX, row, "", clrWhite); row+=20;
   CreateLabel("V_Total", valX, row, "", clrWhite); row+=20;
   CreateLabel("V_Spread", valX, row, "", clrWhite);
}

//+------------------------------------------------------------------+
//| Mise à jour des données du tableau de bord                       |
//+------------------------------------------------------------------+
void UpdateDashboard()
{
   ObjectSetString(0, UI_PREFIX+"V_Threshold", OBJPROP_TEXT, DoubleToString(PriceMoveThreshold, _Digits));
   ObjectSetString(0, UI_PREFIX+"V_LastMove", OBJPROP_TEXT, lastMoveType);
   ObjectSetString(0, UI_PREFIX+"V_TriggerPrice", OBJPROP_TEXT, DoubleToString(lastTriggerPrice, _Digits));

   int buy = CountBuyPositions();
   int sell = CountSellPositions();
   ObjectSetString(0, UI_PREFIX+"V_Positions", OBJPROP_TEXT, IntegerToString(buy) + " / " + IntegerToString(sell));

   string totalStr = IntegerToString(buy+sell) + " / " + IntegerToString(MaxTotalPositions);
   color totalColor = (buy+sell >= MaxTotalPositions) ? clrRed : clrSpringGreen;
   ObjectSetString(0, UI_PREFIX+"V_Total", OBJPROP_TEXT, totalStr);
   ObjectSetInteger(0, UI_PREFIX+"V_Total", OBJPROP_COLOR, totalColor);

   int currentSpread = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   string spreadStr = IntegerToString(currentSpread) + " (" + DoubleToString(MaxSpread, 0) + ")";
   color spreadColor = (currentSpread > MaxSpread) ? clrRed : clrWhite;
   ObjectSetString(0, UI_PREFIX+"V_Spread", OBJPROP_TEXT, spreadStr);
   ObjectSetInteger(0, UI_PREFIX+"V_Spread", OBJPROP_COLOR, spreadColor);

   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Affichage de l'image de fond                                     |
//+------------------------------------------------------------------+
void SetBackgroundImage()
{
   string name = UI_PREFIX + "Background";
   if(ObjectFind(0, name) < 0)
   {
      ObjectCreate(0, name, OBJ_BITMAP_LABEL, 0, 0, 0);
   }

   ObjectSetString(0, name, OBJPROP_BMPFILE, "\\Images\\" + InpBackgroundImage);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, 0);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, 0);
   ObjectSetInteger(0, name, OBJPROP_BACK, true); // Mettre en arrière-plan
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}

//+------------------------------------------------------------------+
//| Fonctions helper pour la création d'objets                       |
//+------------------------------------------------------------------+
void CreateRectLabel(string name, int x, int y, int w, int h, color bg)
{
   string objName = UI_PREFIX + name;
   ObjectCreate(0, objName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, objName, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, objName, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, objName, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, objName, OBJPROP_BORDER_TYPE, BORDER_SUNKEN);
   ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, objName, OBJPROP_BACK, false);
}

void CreateLabel(string name, int x, int y, string text, color clr, int fontSize=0)
{
   string objName = UI_PREFIX + name;
   ObjectCreate(0, objName, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, objName, OBJPROP_TEXT, text);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, (fontSize==0 ? InpFontSize : fontSize));
   ObjectSetString(0, objName, OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
}

//+------------------------------------------------------------------+
//| Reset à chaque nouvelle bougie M1                                |
//+------------------------------------------------------------------+
void ResetAtNewBar()
{
   datetime times[];
   ArraySetAsSeries(times, true);
   if(CopyTime(_Symbol, PERIOD_M1, 0, 1, times) <= 0) return;

   if(times[0] > lastBarTime)
   {
      lastBarTime = times[0];
      Print("Nouvelle bougie M1 détectée. Fermeture de toutes les positions.");
      CloseAllPositions();

      double pricesOpen[], pricesClose[];
      ArraySetAsSeries(pricesOpen, true);
      ArraySetAsSeries(pricesClose, true);

      if(CopyOpen(_Symbol, PERIOD_M1, 1, 1, pricesOpen) > 0 && CopyClose(_Symbol, PERIOD_M1, 1, 1, pricesClose) > 0)
      {
         double openPrev = pricesOpen[0];
         double closePrev = pricesClose[0];

         if(SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) <= MaxSpread)
         {
            if(closePrev > openPrev) { trade.Buy(LotSize, _Symbol); Print("Ouverture BUY initiale"); }
            else if(closePrev < openPrev) { trade.Sell(LotSize, _Symbol); Print("Ouverture SELL initiale"); }
         }
         lastTriggerPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         lastMoveType = "Reset Bougie";
      }
   }
}

//+------------------------------------------------------------------+
//| Vérification du mouvement de prix et inversion de position       |
//+------------------------------------------------------------------+
void CheckPriceMoveAndFlip()
{
   double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double diff = currentPrice - lastTriggerPrice;

   if(MathAbs(diff) >= PriceMoveThreshold)
   {
      bool actionTaken = false;
      if(diff <= -PriceMoveThreshold) // Baisse
      {
         lastMoveType = "Baisse";
         CloseOldestPosition(POSITION_TYPE_BUY);
         if(CountBuyPositions() + CountSellPositions() < MaxTotalPositions && SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) <= MaxSpread)
            if(trade.Sell(LotSize, _Symbol)) actionTaken = true;
         actionTaken = true;
      }
      else if(diff >= PriceMoveThreshold) // Hausse
      {
         lastMoveType = "Hausse";
         CloseOldestPosition(POSITION_TYPE_SELL);
         if(CountBuyPositions() + CountSellPositions() < MaxTotalPositions && SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) <= MaxSpread)
            if(trade.Buy(LotSize, _Symbol)) actionTaken = true;
         actionTaken = true;
      }

      if(actionTaken) lastTriggerPrice = currentPrice;
   }
}

void CloseAllPositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
         if(PositionGetInteger(POSITION_MAGIC) == MagicNumber && PositionGetString(POSITION_SYMBOL) == _Symbol)
            trade.PositionClose(ticket);
   }
}

void CloseOldestPosition(ENUM_POSITION_TYPE type)
{
   ulong oldestTicket = 0; long oldestTime = 0;
   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
         if(PositionGetInteger(POSITION_MAGIC) == MagicNumber && PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_TYPE) == type)
         {
            long posTime = PositionGetInteger(POSITION_TIME_MSC);
            if(oldestTicket == 0 || posTime < oldestTime) { oldestTime = posTime; oldestTicket = ticket; }
         }
   }
   if(oldestTicket != 0) trade.PositionClose(oldestTicket);
}

int CountBuyPositions()
{
   int count = 0;
   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
         if(PositionGetInteger(POSITION_MAGIC) == MagicNumber && PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
            count++;
   }
   return count;
}

int CountSellPositions()
{
   int count = 0;
   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
         if(PositionGetInteger(POSITION_MAGIC) == MagicNumber && PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
            count++;
   }
   return count;
}
