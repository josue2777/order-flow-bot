//+------------------------------------------------------------------+
//|                                        Universal_SMC_Scalper.mq5 |
//|                               Copyright 2025, AlgoAct           |
//|                        https://lordgaruda.github.io/AlgoAct/    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, AlgoAct"
#property link      "https://lordgaruda.github.io/AlgoAct/"
#property version   "1.02"
#property description "Universal Auto Scalper - Stratégie Smart Money Concepts (SMC)"
#property description "Adapté pour tous les marchés via Strategy Tester"
#property strict

/*
   STRATÉGIE SMC (Smart Money Concepts) UNIVERSELLE
   -----------------------------------------------
   Version optimisée pour le Strategy Tester et compatible tous symboles.
*/

#include <Trade\Trade.mqh>

//--- Inputs de la stratégie
input group "=== Paramètres Stratégie ==="
input ENUM_TIMEFRAMES InpTimeFrame  = PERIOD_M15;    // Unité de temps
input double InpLotSize             = 0.01;          // Taille de lot fixe
input int    InpMagicNumber         = 789123;        // Magic Number
input double InpRiskRewardRatio     = 2.0;           // Ratio Risque/Récompense
input bool   InpUseTrailingStop     = true;          // Utiliser le Trailing Stop
input double InpTrailingStopPips    = 50.0;          // Distance Trailing (en pips)

input group "=== Paramètres SMC ==="
input int    InpCHoCHLookback       = 50;            // Analyse structure (bougies)
input int    InpFVGMinSizePips      = 2;             // Taille min. du gap (pips)
input int    InpOBLookback          = 20;            // Recherche d'Order Block (bougies)

input group "=== Gestion du Risque ==="
input bool   InpUseDynamicRisk      = true;          // Risque dynamique (%)
input double InpMaxRiskPercent      = 2.0;           // Risque max par trade (%)
input double InpStopLossPips        = 100.0;         // Stop Loss fixe (pips)
input bool   InpUseATRStopLoss      = true;          // Utiliser ATR pour le SL
input int    InpATRPeriod           = 14;            // Période ATR
input double InpATRMultiplier       = 2.0;           // Multiplicateur ATR

input group "=== Filtre Horaire ==="
input int    InpStartHour           = 0;             // Heure de début
input int    InpEndHour             = 23;            // Heure de fin
input bool   InpTradeOnFriday       = true;          // Trader le vendredi ?

//--- Variables Globales
CTrade trade;
int atrHandle;

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
    int tradeDirection; // 1 = Buy, -1 = Sell, 0 = None
};

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    trade.SetExpertMagicNumber(InpMagicNumber);

    atrHandle = iATR(_Symbol, InpTimeFrame, InpATRPeriod);
    if(atrHandle == INVALID_HANDLE) {
        Print("Erreur: Échec de création de l'indicateur ATR");
        return(INIT_FAILED);
    }

    Print("Universal SMC Scalper initialisé sur ", _Symbol);
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    IndicatorRelease(atrHandle);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    if(!IsTradingTime()) return;

    if(PositionSelect(_Symbol))
    {
        ManageOpenPosition();
        return;
    }

    SMC_Data smcData;
    AnalyzeSMCStructure(smcData);

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
    if(DetectBullishCHoCH())
    {
        data.isBullishCHoCH = true;
        if(DetectBullishFVG(data.fvgUpperLevel, data.fvgLowerLevel))
        {
            data.hasFVG = true;
            data.fvgMidLevel = (data.fvgUpperLevel + data.fvgLowerLevel) / 2.0;
            if(DetectBearishOrderBlock(data.fvgUpperLevel, data.orderBlockLevel))
            {
                data.hasOrderBlock = true;
                data.tradeDirection = 1;
            }
        }
    }

    // 2. Analyse Baissière (si pas de setup haussier)
    if(data.tradeDirection == 0 && DetectBearishCHoCH())
    {
        data.isBearishCHoCH = true;
        if(DetectBearishFVG(data.fvgUpperLevel, data.fvgLowerLevel))
        {
            data.hasFVG = true;
            data.fvgMidLevel = (data.fvgUpperLevel + data.fvgLowerLevel) / 2.0;
            if(DetectBullishOrderBlock(data.fvgLowerLevel, data.orderBlockLevel))
            {
                data.hasOrderBlock = true;
                data.tradeDirection = -1;
            }
        }
    }
}

//--- Helpers de détection
bool DetectBullishCHoCH()
{
    double high[], close[];
    ArraySetAsSeries(high, true); ArraySetAsSeries(close, true);
    if(CopyHigh(_Symbol, InpTimeFrame, 0, InpCHoCHLookback, high) < InpCHoCHLookback) return false;
    if(CopyClose(_Symbol, InpTimeFrame, 0, 2, close) < 2) return false;

    int hh_idx = ArrayMaximum(high, 5, 20);
    if(hh_idx < 0) return false;
    return (close[0] > high[hh_idx]);
}

bool DetectBearishCHoCH()
{
    double low[], close[];
    ArraySetAsSeries(low, true); ArraySetAsSeries(close, true);
    if(CopyLow(_Symbol, InpTimeFrame, 0, InpCHoCHLookback, low) < InpCHoCHLookback) return false;
    if(CopyClose(_Symbol, InpTimeFrame, 0, 2, close) < 2) return false;

    int ll_idx = ArrayMinimum(low, 5, 20);
    if(ll_idx < 0) return false;
    return (close[0] < low[ll_idx]);
}

bool DetectBullishFVG(double &fvgH, double &fvgL)
{
    double high[], low[];
    ArraySetAsSeries(high, true); ArraySetAsSeries(low, true);
    if(CopyHigh(_Symbol, InpTimeFrame, 1, 10, high) < 10) return false;
    if(CopyLow(_Symbol, InpTimeFrame, 1, 10, low) < 10) return false;

    double minGap = InpFVGMinSizePips * GetPipValue();
    for(int i=0; i<8; i++) {
        if(low[i] > high[i+2] + minGap) {
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
    if(CopyHigh(_Symbol, InpTimeFrame, 1, 10, high) < 10) return false;
    if(CopyLow(_Symbol, InpTimeFrame, 1, 10, low) < 10) return false;

    double minGap = InpFVGMinSizePips * GetPipValue();
    for(int i=0; i<8; i++) {
        if(high[i] < low[i+2] - minGap) {
            fvgL = high[i]; fvgH = low[i+2];
            return true;
        }
    }
    return false;
}

bool DetectBearishOrderBlock(double fvgLimit, double &obLevel)
{
    double high[], open[], close[];
    ArraySetAsSeries(high, true); ArraySetAsSeries(open, true); ArraySetAsSeries(close, true);
    if(CopyHigh(_Symbol, InpTimeFrame, 1, InpOBLookback, high) < InpOBLookback) return false;
    if(CopyOpen(_Symbol, InpTimeFrame, 1, InpOBLookback, open) < InpOBLookback) return false;
    if(CopyClose(_Symbol, InpTimeFrame, 1, InpOBLookback, close) < InpOBLookback) return false;

    for(int i=0; i<InpOBLookback; i++) {
        if(close[i] < open[i]) {
            obLevel = high[i];
            return (obLevel > fvgLimit);
        }
    }
    return false;
}

bool DetectBullishOrderBlock(double fvgLimit, double &obLevel)
{
    double low[], open[], close[];
    ArraySetAsSeries(low, true); ArraySetAsSeries(open, true); ArraySetAsSeries(close, true);
    if(CopyLow(_Symbol, InpTimeFrame, 1, InpOBLookback, low) < InpOBLookback) return false;
    if(CopyOpen(_Symbol, InpTimeFrame, 1, InpOBLookback, open) < InpOBLookback) return false;
    if(CopyClose(_Symbol, InpTimeFrame, 1, InpOBLookback, close) < InpOBLookback) return false;

    for(int i=0; i<InpOBLookback; i++) {
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
    double price = isBuy ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);

    double slDist = InpUseATRStopLoss ? GetATR() * InpATRMultiplier : InpStopLossPips * GetPipValue();
    double sl = isBuy ? price - slDist : price + slDist;

    double risk = MathAbs(price - sl);
    double tp = isBuy ? price + (risk * InpRiskRewardRatio) : price - (risk * InpRiskRewardRatio);

    double lot = InpLotSize;
    if(InpUseDynamicRisk) {
        double riskAmt = AccountInfoDouble(ACCOUNT_BALANCE) * (InpMaxRiskPercent / 100.0);
        double tickVal = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
        if(risk > 0) lot = riskAmt / (risk / _Point * tickVal);
    }

    lot = NormalizeDouble(MathMax(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN), MathMin(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX), lot)), 2);

    trade.PositionOpen(_Symbol, isBuy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, lot, price, sl, tp, "SMC_Universal");
}

void ManageOpenPosition()
{
    if(!InpUseTrailingStop || !PositionSelect(_Symbol)) return;

    double price = PositionGetDouble(POSITION_PRICE_CURRENT);
    double sl = PositionGetDouble(POSITION_SL);
    double dist = InpTrailingStopPips * GetPipValue();

    if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
        if(price - PositionGetDouble(POSITION_PRICE_OPEN) > dist) {
            double newSL = NormalizeDouble(price - dist, _Digits);
            if(newSL > sl) trade.PositionModify(_Symbol, newSL, PositionGetDouble(POSITION_TP));
        }
    } else {
        if(PositionGetDouble(POSITION_PRICE_OPEN) - price > dist) {
            double newSL = NormalizeDouble(price + dist, _Digits);
            if(sl == 0 || newSL < sl) trade.PositionModify(_Symbol, newSL, PositionGetDouble(POSITION_TP));
        }
    }
}

bool IsTradingTime()
{
    MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
    if(!InpTradeOnFriday && dt.day_of_week == 5 && dt.hour > 16) return false;
    return (dt.hour >= InpStartHour && dt.hour < InpEndHour);
}

double GetPipValue() { return (_Digits == 3 || _Digits == 5) ? _Point * 10 : _Point; }

double GetATR()
{
    double buffer[]; ArraySetAsSeries(buffer, true);
    if(CopyBuffer(atrHandle, 0, 0, 1, buffer) == 1) return buffer[0];
    return 0;
}
