//+------------------------------------------------------------------+
//|                                        XAUUSD_SMC_Scalper.mq5   |
//|                               Copyright 2025, AlgoAct           |
//|                        https://lordgaruda.github.io/AlgoAct/    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, AlgoAct"
#property link      "https://lordgaruda.github.io/AlgoAct/"
#property version   "1.01"
#property description "XAUUSD Auto Scalper - Stratégie Smart Money Concepts (SMC)"
#property strict

/*
   STRATÉGIE SMC (Smart Money Concepts)
   ------------------------------------
   Cet EA automatise la détection de :
   1. CHoCH (Change of Character) : Détection de retournement de structure.
   2. FVG (Fair Value Gap) : Identification des déséquilibres de prix.
   3. Order Blocks (OB) : Zones d'intérêt institutionnel.
   4. Gestion dynamique du risque via ATR et Trailing Stop.
*/

#include <Trade\Trade.mqh>

//--- Inputs de la stratégie
input group "=== Paramètres Stratégie ==="
input string InpSymbol              = "XAUUSD";      // Symbole (Optimisé pour l'Or)
input ENUM_TIMEFRAMES InpTimeFrame  = PERIOD_M15;    // Unité de temps (M15 recommandée)
input double InpLotSize             = 0.01;          // Taille de lot fixe (si risque désactivé)
input int    InpMagicNumber         = 789123;        // Magic Number
input double InpRiskRewardRatio     = 2.0;           // Ratio Risque/Récompense
input bool   InpUseTrailingStop     = true;          // Utiliser le Trailing Stop
input double InpTrailingStopDist    = 50.0;          // Distance du Trailing (pips)

input group "=== Paramètres SMC ==="
input int    InpCHoCHLookback       = 50;            // Analyse structure (bougies)
input int    InpFVGMinSizePips      = 5;             // Taille min. du gap (pips)
input int    InpOBLookback          = 20;            // Recherche d'Order Block (bougies)
input double InpFVGEntryPercent     = 50.0;          // Entrée à % du FVG (ex: 50% equilibrium)

input group "=== Gestion du Risque ==="
input double InpMaxRiskPercent      = 2.0;           // Risque max par trade (%)
input double InpStopLossPips        = 100.0;         // Stop Loss fixe (pips)
input bool   InpUseATRStopLoss      = true;          // Utiliser ATR pour le SL
input int    InpATRPeriod           = 14;            // Période ATR
input double InpATRMultiplier       = 2.0;           // Multiplicateur ATR

input group "=== Filtre Horaire ==="
input int    InpStartHour           = 8;             // Heure de début
input int    InpEndHour             = 18;            // Heure de fin
input bool   InpTradeOnFriday       = false;         // Trader le vendredi ?

//--- Variables Globales
CTrade trade;
int atrHandle;
datetime lastTradeTime = 0;

//--- Structure de données SMC
struct SMC_Data {
    bool isBullishCHoCH;
    bool isBearishCHoCH;
    double fvgUpperLevel;
    double fvgLowerLevel;
    double fvgMidLevel;
    double orderBlockLevel;
    bool hasFVG;
    bool hasOrderBlock;
    datetime chochTime;
    int tradeDirection; // 1 = Buy, -1 = Sell, 0 = None
};

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    trade.SetExpertMagicNumber(InpMagicNumber);

    if(InpSymbol != "XAUUSD" && InpSymbol != _Symbol) {
        Print("Attention: Cet EA est optimisé pour XAUUSD.");
    }

    atrHandle = iATR(InpSymbol, InpTimeFrame, InpATRPeriod);
    if(atrHandle == INVALID_HANDLE) {
        Print("Erreur: Échec de création de l'indicateur ATR");
        return(INIT_FAILED);
    }

    Print("XAUUSD SMC Scalper initialisé avec succès");
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    if(atrHandle != INVALID_HANDLE)
        IndicatorRelease(atrHandle);
    Print("XAUUSD SMC Scalper arrêté.");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    if(!IsTradingTime()) return;

    if(HasOpenPosition())
    {
        ManageOpenPosition();
        return;
    }

    SMC_Data smcData;
    AnalyzeSMCStructure(smcData);

    // Vérification des signaux d'entrée
    if(smcData.tradeDirection != 0 && smcData.hasFVG && smcData.hasOrderBlock)
    {
        ExecuteScalpTrade(smcData);
    }
}

//+------------------------------------------------------------------+
//| Analyse de la structure SMC                                      |
//+------------------------------------------------------------------+
void AnalyzeSMCStructure(SMC_Data &data)
{
    ZeroMemory(data);

    // 1. Analyse Haussière
    data.isBullishCHoCH = DetectBullishCHoCH();
    if(data.isBullishCHoCH)
    {
        data.hasFVG = DetectBullishFVG(data.fvgUpperLevel, data.fvgLowerLevel);
        if(data.hasFVG)
        {
            data.fvgMidLevel = (data.fvgUpperLevel + data.fvgLowerLevel) / 2.0;
            data.hasOrderBlock = DetectBearishOrderBlock(data.fvgHighTemp(), data.orderBlockLevel);
            if(data.hasOrderBlock) data.tradeDirection = 1;
        }
    }

    // 2. Analyse Baissière (si pas de setup haussier)
    if(data.tradeDirection == 0)
    {
        data.isBearishCHoCH = DetectBearishCHoCH();
        if(data.isBearishCHoCH)
        {
            data.hasFVG = DetectBearishFVG(data.fvgUpperLevel, data.fvgLowerLevel);
            if(data.hasFVG)
            {
                data.fvgMidLevel = (data.fvgUpperLevel + data.fvgLowerLevel) / 2.0;
                data.hasOrderBlock = DetectBullishOrderBlock(data.fvgLowTemp(), data.orderBlockLevel);
                if(data.hasOrderBlock) data.tradeDirection = -1;
            }
        }
    }
}

//--- Helpers de détection (Simplifiés pour la correction)
bool DetectBullishCHoCH()
{
    double high[], low[], close[];
    ArraySetAsSeries(high, true); ArraySetAsSeries(low, true); ArraySetAsSeries(close, true);
    if(CopyHigh(InpSymbol, InpTimeFrame, 0, InpCHoCHLookback, high) < InpCHoCHLookback) return false;
    if(CopyLow(InpSymbol, InpTimeFrame, 0, InpCHoCHLookback, low) < InpCHoCHLookback) return false;

    double recentHigh = high[ArrayMaximum(high, 5, 20)];
    return (close[0] > recentHigh); // Brisure de structure au-dessus du dernier sommet
}

bool DetectBearishCHoCH()
{
    double high[], low[], close[];
    ArraySetAsSeries(high, true); ArraySetAsSeries(low, true); ArraySetAsSeries(close, true);
    if(CopyLow(InpSymbol, InpTimeFrame, 0, InpCHoCHLookback, low) < InpCHoCHLookback) return false;

    double recentLow = low[ArrayMinimum(low, 5, 20)];
    return (close[0] < recentLow); // Brisure de structure en dessous du dernier creux
}

bool DetectBullishFVG(double &fvgH, double &fvgL)
{
    double high[], low[];
    ArraySetAsSeries(high, true); ArraySetAsSeries(low, true);
    if(CopyHigh(InpSymbol, InpTimeFrame, 0, 10, high) < 10) return false;
    if(CopyLow(InpSymbol, InpTimeFrame, 0, 10, low) < 10) return false;

    for(int i=1; i<8; i++) {
        if(low[i] > high[i+2]) { // Bougie i+1 a laissé un gap entre i et i+2
            fvgH = low[i]; fvgL = high[i+2];
            return true;
        }
    }
    return false;
}

bool DetectBearishFVG(double &fvgH, double &fvgL)
{
    double high[], low[];
    ArraySetAsSeries(high, true); ArraySetAsSeries(low, true);
    if(CopyHigh(InpSymbol, InpTimeFrame, 0, 10, high) < 10) return false;
    if(CopyLow(InpSymbol, InpTimeFrame, 0, 10, low) < 10) return false;

    for(int i=1; i<8; i++) {
        if(high[i] < low[i+2]) {
            fvgL = high[i]; fvgH = low[i+2];
            return true;
        }
    }
    return false;
}

bool DetectBearishOrderBlock(double fvgLimit, double &obLevel)
{
    double high[], low[], open[], close[];
    ArraySetAsSeries(high, true); ArraySetAsSeries(open, true); ArraySetAsSeries(close, true);
    CopyHigh(InpSymbol, InpTimeFrame, 0, InpOBLookback, high);
    CopyOpen(InpSymbol, InpTimeFrame, 0, InpOBLookback, open);
    CopyClose(InpSymbol, InpTimeFrame, 0, InpOBLookback, close);

    for(int i=1; i<InpOBLookback; i++) {
        if(close[i] < open[i] && (high[i]-low[i]) > 0) {
            obLevel = high[i];
            return (obLevel > fvgLimit);
        }
    }
    return false;
}

bool DetectBullishOrderBlock(double fvgLimit, double &obLevel)
{
    double high[], low[], open[], close[];
    ArraySetAsSeries(low, true); ArraySetAsSeries(open, true); ArraySetAsSeries(close, true);
    CopyLow(InpSymbol, InpTimeFrame, 0, InpOBLookback, low);
    CopyOpen(InpSymbol, InpTimeFrame, 0, InpOBLookback, open);
    CopyClose(InpSymbol, InpTimeFrame, 0, InpOBLookback, close);

    for(int i=1; i<InpOBLookback; i++) {
        if(close[i] > open[i]) {
            obLevel = low[i];
            return (obLevel < fvgLimit);
        }
    }
    return false;
}

//+------------------------------------------------------------------+
//| Exécution du trade SMC                                          |
//+------------------------------------------------------------------+
void ExecuteScalpTrade(SMC_Data &data)
{
    bool isBuy = (data.tradeDirection == 1);
    double price = isBuy ? SymbolInfoDouble(InpSymbol, SYMBOL_ASK) : SymbolInfoDouble(InpSymbol, SYMBOL_BID);
    double sl = CalculateStopLoss(data.fvgMidLevel, isBuy);
    double tp = CalculateTakeProfit(data.fvgMidLevel, sl, data.orderBlockLevel, isBuy);

    double lot = CalculatePositionSize(data.fvgMidLevel, sl);
    string comment = "SMC_Scalp_" + (isBuy ? "BUY" : "SELL");

    if(isBuy) trade.Buy(lot, InpSymbol, price, sl, tp, comment);
    else      trade.Sell(lot, InpSymbol, price, sl, tp, comment);
}

double CalculateStopLoss(double entry, bool isBuy)
{
    if(InpUseATRStopLoss) {
        double atr[]; ArraySetAsSeries(atr, true);
        if(CopyBuffer(atrHandle, 0, 0, 1, atr) == 1)
            return isBuy ? entry - (atr[0]*InpATRMultiplier) : entry + (atr[0]*InpATRMultiplier);
    }
    double dist = InpStopLossPips * SymbolInfoDouble(InpSymbol, SYMBOL_POINT) * 10;
    return isBuy ? entry - dist : entry + dist;
}

double CalculateTakeProfit(double entry, double sl, double ob, bool isBuy)
{
    double risk = MathAbs(entry - sl);
    return isBuy ? entry + (risk * InpRiskRewardRatio) : entry - (risk * InpRiskRewardRatio);
}

double CalculatePositionSize(double entry, double sl)
{
    double riskAmt = AccountInfoDouble(ACCOUNT_BALANCE) * (InpMaxRiskPercent / 100.0);
    double tickVal = SymbolInfoDouble(InpSymbol, SYMBOL_TRADE_TICK_VALUE);
    double dist = MathAbs(entry - sl) / SymbolInfoDouble(InpSymbol, SYMBOL_POINT);
    double lot = riskAmt / (dist * tickVal);

    double minL = SymbolInfoDouble(InpSymbol, SYMBOL_VOLUME_MIN);
    double maxL = SymbolInfoDouble(InpSymbol, SYMBOL_VOLUME_MAX);
    return MathMax(minL, MathMin(maxL, NormalizeDouble(lot, 2)));
}

void ManageOpenPosition()
{
    if(!InpUseTrailingStop || !PositionSelect(InpSymbol)) return;

    double price = PositionGetDouble(POSITION_PRICE_CURRENT);
    double sl = PositionGetDouble(POSITION_SL);
    double dist = InpTrailingStopDist * SymbolInfoDouble(InpSymbol, SYMBOL_POINT) * 10;

    if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
        if(price - PositionGetDouble(POSITION_PRICE_OPEN) > dist) {
            double newSL = NormalizeDouble(price - dist, _Digits);
            if(newSL > sl) trade.PositionModify(InpSymbol, newSL, PositionGetDouble(POSITION_TP));
        }
    } else {
        if(PositionGetDouble(POSITION_PRICE_OPEN) - price > dist) {
            double newSL = NormalizeDouble(price + dist, _Digits);
            if(sl == 0 || newSL < sl) trade.PositionModify(InpSymbol, newSL, PositionGetDouble(POSITION_TP));
        }
    }
}

bool HasOpenPosition() { return PositionSelect(InpSymbol); }

bool IsTradingTime()
{
    MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
    if(!InpTradeOnFriday && dt.day_of_week == 5 && dt.hour > 16) return false;
    return (dt.hour >= InpStartHour && dt.hour < InpEndHour);
}

//--- Fonctions techniques pour la structure de données
double SMC_Data::fvgHighTemp() { return fvgUpperLevel; }
double SMC_Data::fvgLowTemp()  { return fvgLowerLevel; }
