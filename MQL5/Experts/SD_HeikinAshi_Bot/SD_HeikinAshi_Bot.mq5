//+------------------------------------------------------------------+
//|                                         SD_HeikinAshi_Bot.mq5    |
//|                                  Copyright 2024, Trading Robot   |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Trading Robot"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

// Inclusion de la classe de trading
#include <Trade\Trade.mqh>

//--- PARAMÈTRES D'ENTRÉE
input group "=== Paramètres de Trading ==="
input double   InpRiskPercent     = 1.0;      // Risque par trade (%)
input int      InpMaxPositions    = 10;       // Maximum de positions simultanées
input int      InpMagicNumber     = 123456;   // Nombre magique
input int      InpStopLoss        = 300;      // Stop Loss fixe (points) si non calculé
input int      InpTakeProfit      = 600;      // Take Profit fixe (points) si non calculé

input group "=== Heikin Ashi & Supertrend ==="
input int      InpATRPeriod       = 5;        // Période ATR pour Supertrend
input double   InpATRMultiplier   = 1.5;      // Multiplicateur ATR pour Supertrend
input int      InpEMAPeriod       = 9;        // Période EMA

input group "=== Zones S&D ==="
input int      InpSwingLength     = 10;       // Longueur Pivot High/Low
input double   InpBoxWidth        = 2.5;      // Largeur de la zone S&D (multiplicateur ATR)

input group "=== Dashboard ==="
input color    InpTextCol         = clrWhite; // Couleur du texte
input int      InpFontSize        = 10;       // Taille de la police

//--- VARIABLES GLOBALES
CTrade         trade;            // Objet de trading
int            handleEMA;        // Handle pour l'indicateur EMA
int            handleATR;        // Handle pour l'indicateur ATR
double         bufferEMA[];      // Buffer pour EMA
double         bufferATR[];      // Buffer pour ATR

// Structures pour les bougies Heikin Ashi
struct HeikinAshiCandle
{
   double open;
   double high;
   double low;
   double close;
};

HeikinAshiCandle HA;             // Bougie HA actuelle
HeikinAshiCandle HA_Prev;        // Bougie HA précédente

int            trend_dir = 0;    // Tendance actuelle (1: Achat, -1: Vente)
double         up_band = 0;      // Bande supérieure Supertrend
double         dn_band = 0;      // Bande inférieure Supertrend
datetime       last_bar_time = 0; // Temps de la dernière bougie traitée
datetime       last_pivot_time = 0; // Temps du dernier pivot ajouté

// Structures pour les zones S&D
struct ZoneSD
{
   double top;
   double bottom;
   double poi;
   datetime startTime;
   bool isSupply;
   bool isMitigated;
};

ZoneSD supplyZones[];
ZoneSD demandZones[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // Initialisation de l'objet de trading
   trade.SetExpertMagicNumber(InpMagicNumber);

   // Initialisation des indicateurs
   handleEMA = iMA(_Symbol, _Period, InpEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   handleATR = iATR(_Symbol, _Period, InpATRPeriod);

   if(handleEMA == INVALID_HANDLE || handleATR == INVALID_HANDLE)
   {
      Print("Erreur lors de la création des indicateurs");
      return(INIT_FAILED);
   }

   // Configuration des tableaux
   ArraySetAsSeries(bufferEMA, true);
   ArraySetAsSeries(bufferATR, true);

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Nettoyage des objets graphiques
   ObjectsDeleteAll(0, "DB_");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Mise à jour des données
   if(CopyBuffer(handleEMA, 0, 0, 2, bufferEMA) <= 0) return;
   if(CopyBuffer(handleATR, 0, 0, 2, bufferATR) <= 0) return;

   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, _Period, 0, 100, rates) < 100) return;

   // Vérification de nouvelle bougie
   bool is_new_bar = (rates[0].time != last_bar_time);
   if(is_new_bar) last_bar_time = rates[0].time;

   // 1. CALCUL HEIKIN ASHI
   UpdateHeikinAshi(rates, is_new_bar);

   // 2. CALCUL SUPERTREND
   UpdateSupertrend(bufferATR[1]);

   // 3. MISE À JOUR DES ZONES S&D
   UpdateSDZones(rates, bufferATR[0]);

   // 4. LOGIQUE DE TRADING
   ManageTrades();

   // 5. MISE À JOUR DU DASHBOARD
   UpdateDashboard();
}

//+------------------------------------------------------------------+
//| Calcule les bougies Heikin Ashi                                  |
//+------------------------------------------------------------------+
void UpdateHeikinAshi(const MqlRates &rates[], bool is_new_bar)
{
   static HeikinAshiCandle HA_Bar_Prev; // HA de la bougie précédente close

   // HA Close = (Open+High+Low+Close)/4
   HA.close = (rates[0].open + rates[0].high + rates[0].low + rates[0].close) / 4.0;

   // HA Open = (Prev_HA_Open + Prev_HA_Close)/2
   if(HA_Bar_Prev.open == 0)
      HA.open = (rates[0].open + rates[0].close) / 2.0;
   else
      HA.open = (HA_Bar_Prev.open + HA_Bar_Prev.close) / 2.0;

   HA.high = MathMax(rates[0].high, MathMax(HA.open, HA.close));
   HA.low = MathMin(rates[0].low, MathMin(HA.open, HA.close));

   // Si nouvelle bougie, on archive la précédente
   if(is_new_bar)
   {
      // Calcul de la bougie close index 1
      HA_Bar_Prev.close = (rates[1].open + rates[1].high + rates[1].low + rates[1].close) / 4.0;
      if(HA_Prev.open == 0)
         HA_Bar_Prev.open = (rates[1].open + rates[1].close) / 2.0;
      else
         HA_Bar_Prev.open = (HA_Prev.open + HA_Prev.close) / 2.0;

      HA_Prev = HA_Bar_Prev;
   }
}

//+------------------------------------------------------------------+
//| Calcule le Supertrend                                            |
//+------------------------------------------------------------------+
void UpdateSupertrend(double atr)
{
   double src = HA.close;
   double up = src - (InpATRMultiplier * atr);
   double dn = src + (InpATRMultiplier * atr);

   static double up1 = 0, dn1 = 0;
   static int prev_trend = 1;

   // Logique de calcul similaire à Pine Script
   up = (HA_Prev.close > up1) ? MathMax(up, up1) : up;
   dn = (HA_Prev.close < dn1) ? MathMin(dn, dn1) : dn;

   if(trend_dir == -1 && HA.close > dn1) trend_dir = 1;
   else if(trend_dir == 1 && HA.close < up1) trend_dir = -1;
   else if(trend_dir == 0) trend_dir = 1; // Initialisation

   up1 = up;
   dn1 = dn;
}

//+------------------------------------------------------------------+
//| Mise à jour des zones de Supply & Demand                         |
//+------------------------------------------------------------------+
void UpdateSDZones(const MqlRates &rates[], double atr)
{
   // Recherche de Pivot High / Low
   int idx = InpSwingLength;
   bool isPH = true;
   bool isPL = true;

   // On ne vérifie qu'une seule fois par bar-pivot potentiel
   if(rates[idx].time == last_pivot_time) return;

   for(int i=1; i<=InpSwingLength; i++)
   {
      if(rates[idx].high < rates[idx+i].high || rates[idx].high < rates[idx-i].high) isPH = false;
      if(rates[idx].low > rates[idx+i].low || rates[idx].low > rates[idx-i].low) isPL = false;
   }

   double buffer = atr * (InpBoxWidth / 10.0);

   if(isPH)
   {
      last_pivot_time = rates[idx].time;
      int n = ArraySize(supplyZones);
      ArrayResize(supplyZones, n + 1);
      supplyZones[n].top = rates[idx].high;
      supplyZones[n].bottom = rates[idx].high - buffer;
      supplyZones[n].poi = (supplyZones[n].top + supplyZones[n].bottom) / 2.0;
      supplyZones[n].startTime = rates[idx].time;
      supplyZones[n].isSupply = true;
      supplyZones[n].isMitigated = false;
   }

   if(isPL)
   {
      last_pivot_time = rates[idx].time;
      int n = ArraySize(demandZones);
      ArrayResize(demandZones, n + 1);
      demandZones[n].bottom = rates[idx].low;
      demandZones[n].top = rates[idx].low + buffer;
      demandZones[n].poi = (demandZones[n].top + demandZones[n].bottom) / 2.0;
      demandZones[n].startTime = rates[idx].time;
      demandZones[n].isSupply = false;
      demandZones[n].isMitigated = false;
   }

   // Vérification de la mitigation
   for(int i=0; i<ArraySize(supplyZones); i++)
   {
      if(!supplyZones[i].isMitigated && rates[0].close > supplyZones[i].top)
         supplyZones[i].isMitigated = true;
   }
   for(int i=0; i<ArraySize(demandZones); i++)
   {
      if(!demandZones[i].isMitigated && rates[0].close < demandZones[i].bottom)
         demandZones[i].isMitigated = true;
   }
}

//+------------------------------------------------------------------+
//| Gestionnaire de Trading                                          |
//+------------------------------------------------------------------+
void ManageTrades()
{
   // 1. Fermeture des trades contre-tendance
   CloseContraryTrades();

   // 2. Vérification du nombre maximum de positions
   int total_positions = CountMagicPositions();
   if(total_positions >= InpMaxPositions) return;

   // 3. Détection des signaux
   bool buy_signal = (trend_dir == 1 && HA.close > bufferEMA[0]);
   bool sell_signal = (trend_dir == -1 && HA.close < bufferEMA[0]);

   // Simple filtre pour ne pas empiler trop vite (une position par bougie HA)
   static datetime last_trade_time = 0;
   if(last_bar_time == last_trade_time) return;

   if(buy_signal)
   {
      double sl_price = HA.low - 100 * _Point;
      double sl_dist_points = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - sl_price) / _Point;
      if(sl_dist_points <= 0) sl_dist_points = InpStopLoss;

      double lot = CalculateLot(InpRiskPercent, sl_dist_points);
      double tp = SymbolInfoDouble(_Symbol, SYMBOL_ASK) + (sl_dist_points * _Point) * 2.0;

      if(trade.Buy(lot, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_ASK), sl_price, tp, "SD HA Buy"))
         last_trade_time = last_bar_time;
   }
   else if(sell_signal)
   {
      double sl_price = HA.high + 100 * _Point;
      double sl_dist_points = (sl_price - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point;
      if(sl_dist_points <= 0) sl_dist_points = InpStopLoss;

      double lot = CalculateLot(InpRiskPercent, sl_dist_points);
      double tp = SymbolInfoDouble(_Symbol, SYMBOL_BID) - (sl_dist_points * _Point) * 2.0;

      if(trade.Sell(lot, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_BID), sl_price, tp, "SD HA Sell"))
         last_trade_time = last_bar_time;
   }
}

//+------------------------------------------------------------------+
//| Compte les positions ouvertes par cet EA                         |
//+------------------------------------------------------------------+
int CountMagicPositions()
{
   int count = 0;
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
      {
         if(PositionGetInteger(POSITION_MAGIC) == InpMagicNumber)
            count++;
      }
   }
   return count;
}

//+------------------------------------------------------------------+
//| Ferme les positions qui sont contre la tendance actuelle         |
//+------------------------------------------------------------------+
void CloseContraryTrades()
{
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
      {
         if(PositionGetInteger(POSITION_MAGIC) == InpMagicNumber)
         {
            ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            if((type == POSITION_TYPE_BUY && trend_dir == -1) ||
               (type == POSITION_TYPE_SELL && trend_dir == 1))
            {
               trade.PositionClose(ticket);
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Calcule la taille du lot basée sur le risque et le SL réel       |
//+------------------------------------------------------------------+
double CalculateLot(double riskPercent, double slPoints)
{
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount = balance * (riskPercent / 100.0);
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

   if(tickValue == 0 || tickSize == 0 || slPoints <= 0) return 0.01;

   // On utilise le tick value pour calculer le risque monétaire par point
   double lot = riskAmount / (slPoints * (tickValue / tickSize) * _Point);

   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   lot = MathFloor(lot / lotStep) * lotStep;

   if(lot < minLot) lot = minLot;
   if(lot > maxLot) lot = maxLot;

   return lot;
}

//+------------------------------------------------------------------+
//| Mise à jour du Dashboard                                         |
//+------------------------------------------------------------------+
void UpdateDashboard()
{
   string name = "DB_Back";
   if(ObjectFind(0, name) < 0)
   {
      ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, 10);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, 10);
      ObjectSetInteger(0, name, OBJPROP_XSIZE, 200);
      ObjectSetInteger(0, name, OBJPROP_YSIZE, 150);
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR, clrBlack);
      ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   }

   CreateLabel("DB_Title", "SD HEIKIN ASHI BOT", 20, 20, 12, clrGold);
   CreateLabel("DB_Trend", "Tendance: " + (trend_dir == 1 ? "ACHAT" : "VENTE"), 20, 45, 10, (trend_dir == 1 ? clrLime : clrRed));
   CreateLabel("DB_Equity", "Équité: " + DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2), 20, 65, 10, InpTextCol);
   CreateLabel("DB_Positions", "Positions: " + IntegerToString(PositionsTotal()) + " / " + IntegerToString(InpMaxPositions), 20, 85, 10, InpTextCol);
   CreateLabel("DB_Telegram", "Telegram: @mrexpert_ai", 20, 115, 9, clrCyan);
}

//+------------------------------------------------------------------+
//| Crée ou met à jour un label                                      |
//+------------------------------------------------------------------+
void CreateLabel(string name, string text, int x, int y, int size, color col)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);

   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, size);
   ObjectSetInteger(0, name, OBJPROP_COLOR, col);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
}
