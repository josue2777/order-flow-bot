// Scalping M1 Multi-Position Reversal EA – Trigger sur mouvement de prix (0.20 Gold & adaptatif) + Reset Bougie M1
// Version optimisée pour espacement léger selon le marché – Février 2026

#property strict
#property copyright "Copyright 2026"
#property version   "1.00"
#property description "EA de scalping M1 basé sur le mouvement du prix et reset à chaque nouvelle bougie."

//--- Includes
#include <Trade\Trade.mqh>

//--- Inputs
input double PriceMoveThreshold = 0.20;     // 0.20 pour Gold, 0.00020 pour EURUSD 5 digits, 5.0 pour BTCUSDT
input double LotSize = 0.01;                // Taille des lots
input int MaxTotalPositions = 20;           // Limite de positions cumulées
input ulong MagicNumber = 20260228;         // Identifiant unique des positions
input double MaxSpread = 30.0;              // Spread maximum en points

//--- Variables Globales
double lastTriggerPrice = 0;                // Dernier prix ayant déclenché une action
CTrade trade;                               // Instance de la classe CTrade pour les opérations
datetime lastBarTime = 0;                   // Temps d'ouverture de la dernière bougie traitée
string lastMoveType = "Aucun";              // Type du dernier mouvement détecté

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

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Nettoyage du commentaire sur le graphique
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

   // 3. Affichage des informations sur le graphique
   string message = "--- EA Scalping M1 Multi-Position ---\n";
   message += "Seuil actuel: " + DoubleToString(PriceMoveThreshold, _Digits) + "\n";
   message += "Dernier mouvement: " + lastMoveType + "\n";
   message += "Dernier prix déclencheur: " + DoubleToString(lastTriggerPrice, _Digits) + "\n";
   message += "Positions BUY: " + IntegerToString(CountBuyPositions()) + "\n";
   message += "Positions SELL: " + IntegerToString(CountSellPositions()) + "\n";
   message += "Total positions: " + IntegerToString(CountBuyPositions() + CountSellPositions()) + " / " + IntegerToString(MaxTotalPositions) + "\n";
   message += "Spread actuel: " + IntegerToString((int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD)) + " (Max: " + DoubleToString(MaxSpread, 0) + ")";

   Comment(message);
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
      // Détection d'une nouvelle bougie
      lastBarTime = times[0];

      Print("Nouvelle bougie M1 détectée. Fermeture de toutes les positions.");

      // Fermer TOUTES les positions
      CloseAllPositions();

      // Analyse de la bougie précédente
      double pricesOpen[], pricesClose[];
      ArraySetAsSeries(pricesOpen, true);
      ArraySetAsSeries(pricesClose, true);

      if(CopyOpen(_Symbol, PERIOD_M1, 1, 1, pricesOpen) > 0 && CopyClose(_Symbol, PERIOD_M1, 1, 1, pricesClose) > 0)
      {
         double openPrev = pricesOpen[0];
         double closePrev = pricesClose[0];

         // Vérification du spread
         if(SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) > MaxSpread)
         {
            Print("Spread trop élevé pour ouvrir la position initiale de la bougie.");
         }
         else
         {
            // Ouvrir BUY si Close > Open, sinon SELL
            if(closePrev > openPrev)
            {
               if(trade.Buy(LotSize, _Symbol))
                  Print("Ouverture BUY initiale (Close > Open)");
            }
            else if(closePrev < openPrev)
            {
               if(trade.Sell(LotSize, _Symbol))
                  Print("Ouverture SELL initiale (Close < Open)");
            }
         }

         // Mise à jour du prix de déclenchement après le reset (même si trade échoue)
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

   // Si le mouvement dépasse le seuil
   if(MathAbs(diff) >= PriceMoveThreshold)
   {
      bool actionTaken = false;

      if(diff <= -PriceMoveThreshold) // Le prix a baissé
      {
         lastMoveType = "Baisse";
         Print("Baisse détectée (", diff, "). Tentative d'action.");

         // Fermeture 1 BUY la plus ancienne
         CloseOldestPosition(POSITION_TYPE_BUY);

         // Limite de positions avant ouverture
         if(CountBuyPositions() + CountSellPositions() < MaxTotalPositions)
         {
            // Vérification du spread
            if(SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) <= MaxSpread)
            {
               if(trade.Sell(LotSize, _Symbol))
                  actionTaken = true;
            }
            else Print("Spread trop élevé pour SELL.");
         }
         else Print("Limite de positions atteinte.");

         // On considère l'action comme traitée pour ce seuil
         actionTaken = true;
      }
      else if(diff >= PriceMoveThreshold) // Le prix a monté
      {
         lastMoveType = "Hausse";
         Print("Hausse détectée (", diff, "). Tentative d'action.");

         // Fermeture 1 SELL la plus ancienne
         CloseOldestPosition(POSITION_TYPE_SELL);

         // Limite de positions avant ouverture
         if(CountBuyPositions() + CountSellPositions() < MaxTotalPositions)
         {
            // Vérification du spread
            if(SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) <= MaxSpread)
            {
               if(trade.Buy(LotSize, _Symbol))
                  actionTaken = true;
            }
            else Print("Spread trop élevé pour BUY.");
         }
         else Print("Limite de positions atteinte.");

         // On considère l'action comme traitée pour ce seuil
         actionTaken = true;
      }

      if(actionTaken)
      {
         lastTriggerPrice = currentPrice;
      }
   }
}

//+------------------------------------------------------------------+
//| Fermer toutes les positions ouvertes par cet EA                  |
//+------------------------------------------------------------------+
void CloseAllPositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
      {
         if(PositionGetInteger(POSITION_MAGIC) == MagicNumber && PositionGetString(POSITION_SYMBOL) == _Symbol)
         {
            trade.PositionClose(ticket);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Fermer la position la plus ancienne d'un type donné              |
//+------------------------------------------------------------------+
void CloseOldestPosition(ENUM_POSITION_TYPE type)
{
   ulong oldestTicket = 0;
   long oldestTime = 0;

   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
      {
         if(PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
            PositionGetString(POSITION_SYMBOL) == _Symbol &&
            PositionGetInteger(POSITION_TYPE) == type)
         {
            long posTime = PositionGetInteger(POSITION_TIME_MSC);
            if(oldestTicket == 0 || posTime < oldestTime)
            {
               oldestTime = posTime;
               oldestTicket = ticket;
            }
         }
      }
   }

   if(oldestTicket != 0)
   {
      if(trade.PositionClose(oldestTicket))
         Print("Fermeture position ancienne ticket #", oldestTicket);
   }
}

//+------------------------------------------------------------------+
//| Compter le nombre de positions BUY                               |
//+------------------------------------------------------------------+
int CountBuyPositions()
{
   int count = 0;
   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
      {
         if(PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
            PositionGetString(POSITION_SYMBOL) == _Symbol &&
            PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
         {
            count++;
         }
      }
   }
   return count;
}

//+------------------------------------------------------------------+
//| Compter le nombre de positions SELL                              |
//+------------------------------------------------------------------+
int CountSellPositions()
{
   int count = 0;
   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
      {
         if(PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
            PositionGetString(POSITION_SYMBOL) == _Symbol &&
            PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
         {
            count++;
         }
      }
   }
   return count;
}
