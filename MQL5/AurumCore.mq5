//+------------------------------------------------------------------+
//|                                                  AurumCore.mq5 |
//|                                              Aurum Core (DEMO) |
//+------------------------------------------------------------------+
#property copyright "Franco"
#property version   "0.2"
#property strict
#property description "EA de démonstration basé sur le croisement de moyennes mobiles (EMA)."

/*
   CORE (DEMO) EDITION - Version Corrigée
   --------------------------------------
   - Correction du repainting : Utilisation des bougies clôturées (index 1 et 2).
   - Amélioration de la gestion des positions.
   - Traduction des commentaires en français.
*/

#include <Trade/Trade.mqh>

//--- Inputs
input group "=== CORE (DEMO) Settings ==="
input int      InpMagicNumber      = 123456;      // Magic Number
input double   InpLots             = 0.01;        // Taille du lot
input int      InpSlippagePoints   = 30;          // Slippage (points)
input int      InpMaxSpreadPoints  = 40;          // Spread maximum (points)
input bool     InpAllowTrading     = false;       // Autoriser le trading

input group "=== Strategy (DEMO) ==="
input ENUM_TIMEFRAMES InpTf        = PERIOD_M5;   // Unité de temps
input int      InpFastMaPeriod     = 20;          // Période EMA Rapide
input int      InpSlowMaPeriod     = 50;          // Période EMA Lente
input int      InpMaShift          = 0;           // Shift MA
input ENUM_MA_METHOD InpMaMethod   = MODE_EMA;    // Méthode MA
input ENUM_APPLIED_PRICE InpPrice  = PRICE_CLOSE; // Prix appliqué

//--- Globals
CTrade g_trade;
int g_fast_ma_handle = INVALID_HANDLE;
int g_slow_ma_handle = INVALID_HANDLE;
datetime g_last_bar_time = 0;

//+------------------------------------------------------------------+
//| Vérification du Spread                                           |
//+------------------------------------------------------------------+
static bool SpreadOk(const string symbol, const int max_spread_points)
{
   const int spread_points = (int)SymbolInfoInteger(symbol, SYMBOL_SPREAD);
   return (spread_points >= 0 && spread_points <= max_spread_points);
}

//+------------------------------------------------------------------+
//| Détection d'une nouvelle bougie                                  |
//+------------------------------------------------------------------+
static bool IsNewBar(const string symbol, const ENUM_TIMEFRAMES tf)
{
   datetime t = iTime(symbol, tf, 0);
   if(t == 0) return false;
   if(t != g_last_bar_time)
   {
      g_last_bar_time = t;
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Fermeture des positions spécifiques à cet EA                     |
//+------------------------------------------------------------------+
static void CloseAllPositionsForThisEA(const string symbol, const long magic)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      const ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;

      if(PositionGetString(POSITION_SYMBOL) == symbol && PositionGetInteger(POSITION_MAGIC) == magic)
      {
         g_trade.PositionClose(ticket);
      }
   }
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   g_trade.SetExpertMagicNumber(InpMagicNumber);
   g_trade.SetDeviationInPoints(InpSlippagePoints);

   // Initialisation des indicateurs
   g_fast_ma_handle = iMA(_Symbol, InpTf, InpFastMaPeriod, InpMaShift, InpMaMethod, InpPrice);
   g_slow_ma_handle = iMA(_Symbol, InpTf, InpSlowMaPeriod, InpMaShift, InpMaMethod, InpPrice);

   if(g_fast_ma_handle == INVALID_HANDLE || g_slow_ma_handle == INVALID_HANDLE)
   {
      Print("CORE(DEMO): Erreur de création des handles MA");
      return INIT_FAILED;
   }

   Print("CORE(DEMO) EA initialisé. Trading autorisé ? ", InpAllowTrading ? "OUI" : "NON");
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(g_fast_ma_handle != INVALID_HANDLE) IndicatorRelease(g_fast_ma_handle);
   if(g_slow_ma_handle != INVALID_HANDLE) IndicatorRelease(g_slow_ma_handle);

   // Sécurité : Fermer les positions lors de la suppression
   if(reason == REASON_REMOVE || reason == REASON_CLOSE || reason == REASON_ACCOUNT || reason == REASON_PROGRAM)
      CloseAllPositionsForThisEA(_Symbol, InpMagicNumber);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Vérifications de base
   if(!InpAllowTrading) return;
   if(!SpreadOk(_Symbol, InpMaxSpreadPoints)) return;
   if(!IsNewBar(_Symbol, InpTf)) return;

   // Vérification si une position est déjà ouverte pour cet EA
   bool position_exists = false;
   for(int i = 0; i < PositionsTotal(); i++)
   {
      const ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == InpMagicNumber)
         {
            position_exists = true;
            break;
         }
      }
   }
   if(position_exists) return;

   // Récupération des données MA (3 dernières bougies pour index 1 et 2)
   double fast_buf[3];
   double slow_buf[3];

   if(CopyBuffer(g_fast_ma_handle, 0, 0, 3, fast_buf) != 3) return;
   if(CopyBuffer(g_slow_ma_handle, 0, 0, 3, slow_buf) != 3) return;

   // Correction : Utilisation des bougies 1 et 2 pour éviter le repainting
   // fast_buf[2] = bougie 0 (en cours) -> NE PAS UTILISER
   // fast_buf[1] = bougie 1 (précédente clôturée)
   // fast_buf[0] = bougie 2 (avant-dernière clôturée)

   // Croisement haussier : Rapide était sous Lente et vient de passer au-dessus
   const bool cross_up = (fast_buf[0] <= slow_buf[0]) && (fast_buf[1] > slow_buf[1]);
   // Croisement baissier : Rapide était au-dessus de Lente et vient de passer en dessous
   const bool cross_dn = (fast_buf[0] >= slow_buf[0]) && (fast_buf[1] < slow_buf[1]);

   if(cross_up)
   {
      Print("CORE(DEMO): Signal d'achat détecté");
      g_trade.Buy(InpLots, _Symbol);
   }
   else if(cross_dn)
   {
      Print("CORE(DEMO): Signal de vente détecté");
      g_trade.Sell(InpLots, _Symbol);
   }
}
