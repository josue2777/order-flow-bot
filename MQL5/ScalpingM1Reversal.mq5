// Scalping M1 Multi-Position Reversal EA – Trigger sur mouvement de prix (0.20 Gold & adaptatif) + Reset Bougie M1
// Version optimisée pour espacement léger selon le marché – Février 2026

#property strict
#property copyright "Copyright 2026"
#property version   "1.03"
#property description "EA de scalping M1 avec tableau de bord graphique et arrière-plan (statique ou animé)."

//--- Includes
#include <Trade\Trade.mqh>

//--- Inputs
input double PriceMoveThreshold = 0.20;     // 0.20 pour Gold, 0.00020 pour EURUSD 5 digits, 5.0 pour BTCUSDT
input double LotSize = 0.01;                // Taille des lots
input int MaxTotalPositions = 20;           // Limite de positions cumulées
input ulong MagicNumber = 20260228;         // Identifiant unique des positions
input double MaxSpread = 30.0;              // Spread maximum en points

//--- Inputs Esthétiques & Animation
input string InpImagePrefix    = "robot_f_";          // Préfixe des fichiers (ex: robot_f_0.bmp)
input int    InpFrameCount      = 1;                   // Nombre de frames (1 pour image seule, >1 pour animation)
input int    InpAnimationMs     = 100;                 // Vitesse d'animation en millisecondes
input color  InpDashboardBg     = C'20,20,20';         // Couleur de fond du tableau
input color  InpHeaderColor     = clrGold;             // Couleur des entêtes
input color  InpTextColor       = clrWhite;            // Couleur du texte
input int    InpFontSize        = 10;                  // Taille de police

//--- Variables Globales
double lastTriggerPrice = 0;                // Dernier prix ayant déclenché une action
CTrade trade;                               // Instance de la classe CTrade pour les opérations
datetime lastBarTime = 0;                   // Temps d'ouverture de la dernière bougie traitée
string lastMoveType = "Aucun";              // Type du dernier mouvement détecté
int currentFrame = 0;                       // Index de la frame actuelle

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
   CreateBackgroundImage();
   CreateDashboard();

   // Démarrage du timer seulement si l'utilisateur souhaite une animation (>1 frame)
   if(InpFrameCount > 1)
   {
      EventSetMillisecondTimer(InpAnimationMs);
   }

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Arrêt du timer
   EventKillTimer();
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
//| Timer function pour l'animation                                  |
//+------------------------------------------------------------------+
void OnTimer()
{
   if(InpFrameCount <= 1) return;

   currentFrame++;
   if(currentFrame >= InpFrameCount) currentFrame = 0;

   string name = UI_PREFIX + "Background";
   string fileName = "\\Images\\" + InpImagePrefix + IntegerToString(currentFrame) + ".bmp";

   ObjectSetString(0, name, OBJPROP_BMPFILE, fileName);
}

//+------------------------------------------------------------------+
//| Création du tableau de bord graphique                            |
//+------------------------------------------------------------------+
void CreateDashboard()
{
   int x = 10, y = 30, w = 300, h = 180;
   CreateRectLabel("MainBg", x, y, w, h, InpDashboardBg);
   CreateLabel("Title", x+5, y+5, "--- EA SCALPING M1 REVERSAL ---", InpHeaderColor, 12);

   int row = y + 30;
   CreateLabel("L_Threshold", x+10, row, "Seuil de mouvement:", InpTextColor); row+=20;
   CreateLabel("L_LastMove", x+10, row, "Dernier mouvement:", InpTextColor); row+=20;
   CreateLabel("L_TriggerPrice", x+10, row, "Prix déclencheur:", InpTextColor); row+=20;
   CreateLabel("L_Positions", x+10, row, "Positions (B/S):", InpTextColor); row+=20;
   CreateLabel("L_Total", x+10, row, "Total positions:", InpTextColor); row+=20;
   CreateLabel("L_Spread", x+10, row, "Spread (Max):", InpTextColor);

   row = y + 30;
   int valX = x + 180;
   CreateLabel("V_Threshold", valX, row, "", clrLightBlue); row+=20;
   CreateLabel("V_LastMove", valX, row, "", clrOrange); row+=20;
   CreateLabel("V_TriggerPrice", valX, row, "", clrWhite); row+=20;
   CreateLabel("V_Positions", valX, row, "", clrWhite); row+=20;
   CreateLabel("V_Total", valX, row, "", clrWhite); row+=20;
   CreateLabel("V_Spread", valX, row, "", clrWhite);
}

void UpdateDashboard()
{
   ObjectSetString(0, UI_PREFIX+"V_Threshold", OBJPROP_TEXT, DoubleToString(PriceMoveThreshold, _Digits));
   ObjectSetString(0, UI_PREFIX+"V_LastMove", OBJPROP_TEXT, lastMoveType);
   ObjectSetString(0, UI_PREFIX+"V_TriggerPrice", OBJPROP_TEXT, DoubleToString(lastTriggerPrice, _Digits));
   int buy = CountBuyPositions(); int sell = CountSellPositions();
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

void CreateBackgroundImage()
{
   string name = UI_PREFIX + "Background";
   if(ObjectFind(0, name) < 0) ObjectCreate(0, name, OBJ_BITMAP_LABEL, 0, 0, 0);

   // Chargement de l'image de base (frame 0)
   string fileName = "\\Images\\" + InpImagePrefix + "0.bmp";
   ObjectSetString(0, name, OBJPROP_BMPFILE, fileName);

   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, 0);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, 0);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}

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
   ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
}

void ResetAtNewBar()
{
   datetime times[]; ArraySetAsSeries(times, true);
   if(CopyTime(_Symbol, PERIOD_M1, 0, 1, times) <= 0) return;
   if(times[0] > lastBarTime)
   {
      lastBarTime = times[0];
      CloseAllPositions();
      double pricesOpen[], pricesClose[]; ArraySetAsSeries(pricesOpen, true); ArraySetAsSeries(pricesClose, true);
      if(CopyOpen(_Symbol, PERIOD_M1, 1, 1, pricesOpen) > 0 && CopyClose(_Symbol, PERIOD_M1, 1, 1, pricesClose) > 0)
      {
         if(SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) <= MaxSpread)
         {
            if(pricesClose[0] > pricesOpen[0]) trade.Buy(LotSize, _Symbol);
            else if(pricesClose[0] < pricesOpen[0]) trade.Sell(LotSize, _Symbol);
         }
         lastTriggerPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         lastMoveType = "Reset Bougie";
      }
   }
}

void CheckPriceMoveAndFlip()
{
   double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double diff = currentPrice - lastTriggerPrice;
   if(MathAbs(diff) >= PriceMoveThreshold)
   {
      bool actionTaken = false;
      if(diff <= -PriceMoveThreshold) { lastMoveType = "Baisse"; CloseOldestPosition(POSITION_TYPE_BUY); if(CountBuyPositions()+CountSellPositions()<MaxTotalPositions && SymbolInfoInteger(_Symbol, SYMBOL_SPREAD)<=MaxSpread) if(trade.Sell(LotSize, _Symbol)) actionTaken = true; actionTaken = true; }
      else if(diff >= PriceMoveThreshold) { lastMoveType = "Hausse"; CloseOldestPosition(POSITION_TYPE_SELL); if(CountBuyPositions()+CountSellPositions()<MaxTotalPositions && SymbolInfoInteger(_Symbol, SYMBOL_SPREAD)<=MaxSpread) if(trade.Buy(LotSize, _Symbol)) actionTaken = true; actionTaken = true; }
      if(actionTaken) lastTriggerPrice = currentPrice;
   }
}

void CloseAllPositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--) { ulong ticket = PositionGetTicket(i); if(PositionSelectByTicket(ticket)) if(PositionGetInteger(POSITION_MAGIC) == MagicNumber && PositionGetString(POSITION_SYMBOL) == _Symbol) trade.PositionClose(ticket); }
}

void CloseOldestPosition(ENUM_POSITION_TYPE type)
{
   ulong oldestTicket = 0; long oldestTime = 0;
   for(int i = 0; i < PositionsTotal(); i++) { ulong ticket = PositionGetTicket(i); if(PositionSelectByTicket(ticket)) if(PositionGetInteger(POSITION_MAGIC) == MagicNumber && PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_TYPE) == type) { long posTime = PositionGetInteger(POSITION_TIME_MSC); if(oldestTicket == 0 || posTime < oldestTime) { oldestTime = posTime; oldestTicket = ticket; } } }
   if(oldestTicket != 0) trade.PositionClose(oldestTicket);
}

int CountBuyPositions()
{
   int count = 0; for(int i = 0; i < PositionsTotal(); i++) { ulong ticket = PositionGetTicket(i); if(PositionSelectByTicket(ticket)) if(PositionGetInteger(POSITION_MAGIC) == MagicNumber && PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) count++; } return count;
}

int CountSellPositions()
{
   int count = 0; for(int i = 0; i < PositionsTotal(); i++) { ulong ticket = PositionGetTicket(i); if(PositionSelectByTicket(ticket)) if(PositionGetInteger(POSITION_MAGIC) == MagicNumber && PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) count++; } return count;
}
