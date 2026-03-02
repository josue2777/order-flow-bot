//+------------------------------------------------------------------+
//|                            Universal_TrendBreak_Trauma.mq5       |
//|                               Copyright 2025, AlgoAct           |
//|                        https://lordgaruda.github.io/AlgoAct/    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, AlgoAct"
#property link      "https://lordgaruda.github.io/AlgoAct/"
#property version   "1.02"
#property description "Universal Trend Line Break + Trauma + RSI Strategy"
#property description "Adapté pour tous les marchés (Or, Forex, Crypto, Indices)"
#property strict

#include <Trade\Trade.mqh>

//--- Inputs
input group "=== Paramètres Stratégie ==="
input ENUM_TIMEFRAMES InpTimeFrame  = PERIOD_H1;    // Unité de temps
input int    InpMagicNumber         = 789456;        // Magic Number

input group "=== RSI (Sortie) ==="
input int    InpRSI_Period          = 14;
input double InpRSI_Overbought      = 70.0;
input double InpRSI_Oversold        = 30.0;

input group "=== Trauma (EMA) ==="
input int    InpTrauma_Period       = 21;           // Période EMA

input group "=== Détection Trend Line ==="
input int    InpTrendLookback       = 50;           // Analyse sur X bougies
input double InpBreakTolerance      = 0.0002;       // Tolérance de cassure (relative)

input group "=== Gestion du Risque ==="
input double InpLotSize             = 0.01;
input bool   InpUseDynamicLots      = false;
input double InpRiskPercent         = 2.0;
input double InpStopLossPips        = 100.0;        // SL en pips
input double InpTakeProfitPips      = 200.0;        // TP en pips

//--- Variables Globales
CTrade trade;
int rsiHandle, emaHandle;
datetime lastBarTime = 0;

struct TrendLine {
    double slope;
    double startPrice;
    int startIndex;
    bool isValid;
};

TrendLine resLine, supLine;

//+------------------------------------------------------------------+
//| Initialisation                                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    trade.SetExpertMagicNumber(InpMagicNumber);

    rsiHandle = iRSI(_Symbol, InpTimeFrame, InpRSI_Period, PRICE_CLOSE);
    emaHandle = iMA(_Symbol, InpTimeFrame, InpTrauma_Period, 0, MODE_EMA, PRICE_CLOSE);

    if(rsiHandle == INVALID_HANDLE || emaHandle == INVALID_HANDLE) return(INIT_FAILED);

    ZeroMemory(resLine);
    ZeroMemory(supLine);

    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Deinitialisation                                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    IndicatorRelease(rsiHandle);
    IndicatorRelease(emaHandle);
}

//+------------------------------------------------------------------+
//| Tick function                                                    |
//+------------------------------------------------------------------+
void OnTick()
{
    // Travail sur clôture de bougie pour la stabilité
    datetime currentBarTime = iTime(_Symbol, InpTimeFrame, 0);
    if(currentBarTime == lastBarTime) return;
    lastBarTime = currentBarTime;

    if(PositionSelect(_Symbol)) {
        ManageOpenPosition();
        return;
    }

    UpdateTrendLines();
    CheckSignals();
}

//+------------------------------------------------------------------+
//| Mise à jour des lignes de tendance                              |
//+------------------------------------------------------------------+
void UpdateTrendLines()
{
    double high[], low[];
    ArraySetAsSeries(high, true); ArraySetAsSeries(low, true);

    // On analyse les bougies clôturées (index 1 à InpTrendLookback)
    if(CopyHigh(_Symbol, InpTimeFrame, 1, InpTrendLookback, high) < InpTrendLookback) return;
    if(CopyLow(_Symbol, InpTimeFrame, 1, InpTrendLookback, low) < InpTrendLookback) return;

    // Resistance (Highs) : On cherche deux sommets
    int h1 = ArrayMaximum(high, 20, 30); // Sommet le plus ancien
    int h2 = ArrayMaximum(high, 0, 15);  // Sommet le plus récent

    if(h1 > h2 && h1 != -1 && h2 != -1) {
        resLine.slope = (high[h2] - high[h1]) / (h1 - h2);
        resLine.startPrice = high[h1];
        resLine.startIndex = h1 + 1; // Index par rapport à la bougie actuelle (0)
        resLine.isValid = true;
    } else resLine.isValid = false;

    // Support (Lows) : On cherche deux creux
    int l1 = ArrayMinimum(low, 20, 30);
    int l2 = ArrayMinimum(low, 0, 15);

    if(l1 > l2 && l1 != -1 && l2 != -1) {
        supLine.slope = (low[l2] - low[l1]) / (l1 - l2);
        supLine.startPrice = low[l1];
        supLine.startIndex = l1 + 1;
        supLine.isValid = true;
    } else supLine.isValid = false;
}

//+------------------------------------------------------------------+
//| Vérification des signaux                                         |
//+------------------------------------------------------------------+
void CheckSignals()
{
    double close[]; ArraySetAsSeries(close, true);
    if(CopyClose(_Symbol, InpTimeFrame, 0, 2, close) < 2) return;

    double trauma[]; ArraySetAsSeries(trauma, true);
    if(CopyBuffer(emaHandle, 0, 0, 1, trauma) < 1) return;

    double currentPrice = close[0];
    double traumaVal = trauma[0];

    // Calcul du prix théorique des lignes à l'index 0
    // Prix(i) = PrixInitial + Slope * (IndexInitial - i)
    double resPrice = resLine.startPrice + (resLine.slope * resLine.startIndex);
    double supPrice = supLine.startPrice + (supLine.slope * supLine.startIndex);

    // SIGNAL ACHAT : Prix > Trauma ET Cassure Résistance (vers le haut)
    if(resLine.isValid && currentPrice > traumaVal)
    {
        // On vérifie que la bougie précédente était sous la ligne et que l'actuelle est au-dessus
        double prevResPrice = resLine.startPrice + (resLine.slope * (resLine.startIndex + 1));
        if(close[1] <= prevResPrice && currentPrice > resPrice + (InpBreakTolerance * currentPrice))
        {
            ExecuteTrade(POSITION_TYPE_BUY);
            return;
        }
    }

    // SIGNAL VENTE : Prix < Trauma ET Cassure Support (vers le bas)
    if(supLine.isValid && currentPrice < traumaVal)
    {
        double prevSupPrice = supLine.startPrice + (supLine.slope * (supLine.startIndex + 1));
        if(close[1] >= prevSupPrice && currentPrice < supPrice - (InpBreakTolerance * currentPrice))
        {
            ExecuteTrade(POSITION_TYPE_SELL);
            return;
        }
    }
}

//+------------------------------------------------------------------+
//| Exécution des trades                                             |
//+------------------------------------------------------------------+
void ExecuteTrade(ENUM_POSITION_TYPE type)
{
    double price = (type == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double slDist = InpStopLossPips * GetPipValue();
    double tpDist = InpTakeProfitPips * GetPipValue();

    double sl = (type == POSITION_TYPE_BUY) ? price - slDist : price + slDist;
    double tp = (type == POSITION_TYPE_BUY) ? price + tpDist : price - tpDist;

    double lot = InpLotSize;
    if(InpUseDynamicLots) {
        double balance = AccountInfoDouble(ACCOUNT_BALANCE);
        double risk = balance * (InpRiskPercent/100.0);
        double tickVal = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
        if(slDist > 0) lot = risk / (slDist / _Point * tickVal);
    }

    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    lot = NormalizeDouble(MathMax(minLot, MathMin(maxLot, lot)), 2);

    trade.PositionOpen(_Symbol, type, lot, price, sl, tp, "Universal_TrendBreak");
}

//+------------------------------------------------------------------+
//| Gestion de la position (Sortie RSI)                              |
//+------------------------------------------------------------------+
void ManageOpenPosition()
{
    double rsi[]; ArraySetAsSeries(rsi, true);
    if(CopyBuffer(rsiHandle, 0, 0, 1, rsi) < 1) return;

    long type = PositionGetInteger(POSITION_TYPE);

    if(type == POSITION_TYPE_BUY && rsi[0] >= InpRSI_Overbought) trade.PositionClose(_Symbol);
    else if(type == POSITION_TYPE_SELL && rsi[0] <= InpRSI_Oversold) trade.PositionClose(_Symbol);
}

double GetPipValue()
{
    int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    if(digits == 3 || digits == 5) return _Point * 10;
    return _Point;
}
