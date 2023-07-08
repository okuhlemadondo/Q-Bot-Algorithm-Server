//+--------------------------------------------------------------+
//|     DWX_server_MT5.mq4
//|     @author: Darwinex Labs (www.darwinex.com)
//|
//|     Copyright (c) 2017-2021, Darwinex. All rights reserved.
//|
//|     Licensed under the BSD 3-Clause License, you may not use this file except
//|     in compliance with the License.
//|
//|     You may obtain a copy of the License at:
//|     https://opensource.org/licenses/BSD-3-Clause
//+--------------------------------------------------------------+
#property copyright "Copyright 2017-2021, Darwinex Labs."
#property link      "https://www.darwinex.com/"
#property version   "1.0"
#property strict

/*

- IMPORTANT: check if ORDER_TIME_GTC will still use expiration date. or do we need ORDER_TIME_SPECIFIED?

mql:
- do we need start/endIdentifier? if we use json, it should automatically give an error if not complete.

python:
- dont save  TimeGMT() in every file. we can just use time modified in python.
- maxTryOpenSeconds  (in python): if the file exists for 10 seconds (cant create a new one), return an error. maybe use multiple files for commands?

*/
#include <Math\Stat\Math.mqh>
#include<Trade\Trade.mqh>
#include<Trade\PositionInfo.mqh>
//--- object for performing trade operations
CTrade  trade;
CPositionInfo pi;
//--- input parameters

input int      number_of_ticks=1000;
input int      points_indent=10;
input int      PERIOD = 3000;
input int      PERIOD2 = 6000;
input int      PERIOD3 = 12000;
input int      PERIOD4 = 24000;
input int      PERIOD5 = 48000;
input double LOTSIZE = 15;
input double ratio = 7;

//--- indicator buffers
double         BidBuffer[];
double         AskBuffer[];
double         SMBidBuffer[];
double         SMAskBuffer[];

//misc arrays and variables

double B[];
double A[];
double B2[];
double A2[];
double B3[];
double A3[];
double B4[];
double A4[];
double B5[];
double A5[];

double acopy[];
double bcopy[];
double acopy2[];
double bcopy2[];
double acopy3[];
double bcopy3[];
double acopy4[];
double bcopy4[];
double acopy5[];
double bcopy5[];

double Bm[];
double Am[];
double Bm2[];
double Am2[];
double Bm3[];
double Am3[];
double Bm4[];
double Am4[];
double Bm5[];
double Am5[];

double FBm[];
double FAm[];
double FBm2[];
double FAm2[];
double FBm3[];
double FAm3[];
double FBm4[];
double FAm4[];
double FBm5[];
double FAm5[];

double amcopy[];
double bmcopy[];
double amcopy2[];
double bmcopy2[];
double amcopy3[];
double bmcopy3[];
double amcopy4[];
double bmcopy4[];
double amcopy5[];
double bmcopy5[];

double weight1[];
double weight2[];
double weight3[];
double weight4[];
double weight5[];

double aweight1[];
double aweight2[];
double aweight3[];
double aweight4[];
double aweight5[];

double bweight1[];
double bweight2[];
double bweight3[];
double bweight4[];
double bweight5[];

double Cweight1[];
double Cweight2[];
double Cweight3[];
double Cweight4[];
double Cweight5[];

double faweight1[];
double faweight2[];
double faweight3[];
double faweight4[];
double faweight5[];

double fbweight1[];
double fbweight2[];
double fbweight3[];
double fbweight4[];
double fbweight5[];


double Amcomb1[];
double Amcomb2[];
double Amcomb3[];
double Amcomb4[];
double Amcomb5[];
double Bmcomb1[];
double Bmcomb2[];
double Bmcomb3[];
double Bmcomb4[];
double Bmcomb5[];

double fAmcomb1[];
double fAmcomb2[];
double fAmcomb3[];
double fAmcomb4[];
double fAmcomb5[];
double fBmcomb1[];
double fBmcomb2[];
double fBmcomb3[];
double fBmcomb4[];
double fBmcomb5[];

double min1 = -86;
double min2 = -113;
double min3 = -148;
double min4 = -181;
double min5 = -227;

double max1 = 86;
double max2 = 113;
double max3 = 148;
double max4 = 181;
double max5 = 227;

double price_ask[4];
double price_bid[4];
double asknn[4];
double bidnn[4];

double e = PERIOD-150;
double e2 = PERIOD2-150;
double e3 = PERIOD3-150;
double e4 = PERIOD4-150;
double e5 = PERIOD5-150;
double f = -11;
int g = 4;
double buypow[3];
string symb = "Volatility 75 (1s) Index";
input string t0 = "--- General Parameters ---";
// if the timer is too small, we might have problems accessing the files from python (mql will write to file every update time).
input int MILLISECOND_TIMER = 25;

input int numLastMessages = 50;
input string t1 = "If true, it will open charts for bar data symbols, ";
input string t2 = "which reduces the delay on a new bar.";
input bool openChartsForBarData = true;
input bool openChartsForHistoricData = true;
input string t3 = "--- Trading Parameters ---";
input int MaximumOrders = 1;
input double MaximumLotSize = 0.01;
input int SlippagePoints = 3;
input int lotSizeDigits = 2;
input bool asyncMode = false;

int maxCommandFiles = 50;
int maxNumberOfCharts = 100;

long lastMessageMillis = 0;
long lastUpdateMillis = GetTickCount(), lastUpdateOrdersMillis = GetTickCount();

string startIdentifier = "<:";
string endIdentifier = ":>";
string delimiter = "|";
string folderName = "DWX";
string filePathOrders = folderName + "/DWX_Orders.txt";
string filePathMessages = folderName + "/DWX_Messages.txt";
string filePathMarketData = folderName + "/DWX_Market_Data.txt";
string filePathBarData = folderName + "/DWX_Bar_Data.txt";
string filePathHistoricData = folderName + "/DWX_Historic_Data.txt";
string filePathHistoricTrades = folderName + "/DWX_Historic_Trades.txt";
string filePathCommandsPrefix = folderName + "/DWX_Commands_";
string filePathASKNNPrefix = folderName + "/DWX_ASKNN_";
string filePathBIDNNPrefix = folderName + "/DWX_BIDNN_";
string filePathASKPrefix = folderName + "/DWX_ASK_";
string filePathBIDPrefix = folderName + "/DWX_BID_";
string filePathTRPrefix = folderName + "/DWX_TR_";

string lastOrderText = "", lastMarketDataText = "", lastMessageText = "";

struct MESSAGE
  {
   long              millis;
   string            message;
  };

MESSAGE lastMessages[];

string MarketDataSymbols[];

/**
 * Class definition for an specific instrument: the tuple (symbol,timeframe)
 */
class Instrument
  {
public:

   //--------------------------------------------------------------
   /** Instrument constructor */
                     Instrument() { _symbol = ""; _name = ""; _timeframe = PERIOD_CURRENT; _lastPubTime =0;}

   //--------------------------------------------------------------
   /** Getters */
   string            symbol()    { return _symbol; }
   ENUM_TIMEFRAMES   timeframe() { return _timeframe; }
   string            name()      { return _name; }
   datetime          getLastPublishTimestamp() { return _lastPubTime; }
   /** Setters */
   void              setLastPublishTimestamp(datetime tmstmp) { _lastPubTime = tmstmp; }

   //--------------------------------------------------------------
   /** Setup instrument with symbol and timeframe descriptions
   *  @param argSymbol Symbol
   *  @param argTimeframe Timeframe
   */
   void              setup(string argSymbol, string argTimeframe)
     {
      _symbol = argSymbol;
      _timeframe = StringToTimeFrame(argTimeframe);
      _name  = _symbol + "_" + argTimeframe;
      _lastPubTime = 0;
      SymbolSelect(_symbol, true);
      if(openChartsForBarData)
        {
         OpenChartIfNotOpen(_symbol, _timeframe);
         Sleep(200);  // sleep to allow time to open the chart and update the data.
        }
     }

   //--------------------------------------------------------------
   /** Get last N MqlRates from this instrument (symbol-timeframe)
   *  @param rates Receives last 'count' rates
   *  @param count Number of requested rates
   *  @return Number of returned rates
   */
   int               GetRates(MqlRates& rates[], int count)
     {
      // ensures that symbol is setup
      if(StringLen(_symbol) > 0)
        {
         return CopyRates(_symbol, _timeframe, 1, count, rates);
        }
      return 0;
     }

protected:
   string            _name;                //!< Instrument descriptive name
   string            _symbol;              //!< Symbol
   ENUM_TIMEFRAMES   _timeframe;  //!< Timeframe
   datetime          _lastPubTime;     //!< Timestamp of the last published OHLC rate. Default = 0 (1 Jan 1970)
  };

// Array of instruments whose rates will be published if Publish_MarketRates = True. It is initialized at OnInit() and
// can be updated through TRACK_RATES request from client peers.
Instrument BarDataInstruments[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {

   ArrayResize(A,PERIOD,0);
   ArrayResize(B,PERIOD,0);
   ArrayResize(Am,PERIOD,0);
   ArrayResize(Bm,PERIOD,0);
   ArrayResize(FAm,PERIOD,0);
   ArrayResize(FBm,PERIOD,0);

   ArrayResize(A2,PERIOD2,0);
   ArrayResize(B2,PERIOD2,0);
   ArrayResize(Am2,PERIOD2,0);
   ArrayResize(Bm2,PERIOD2,0);
   ArrayResize(FAm2,PERIOD2,0);
   ArrayResize(FBm2,PERIOD2,0);

   ArrayResize(A3,PERIOD3,0);
   ArrayResize(B3,PERIOD3,0);
   ArrayResize(Am3,PERIOD3,0);
   ArrayResize(Bm3,PERIOD3,0);
   ArrayResize(FAm3,PERIOD3,0);
   ArrayResize(FBm3,PERIOD3,0);

   ArrayResize(A4,PERIOD4,0);
   ArrayResize(B4,PERIOD4,0);
   ArrayResize(Am4,PERIOD4,0);
   ArrayResize(Bm4,PERIOD4,0);
   ArrayResize(FAm4,PERIOD4,0);
   ArrayResize(FBm4,PERIOD4,0);

   ArrayResize(A5,PERIOD5,0);
   ArrayResize(B5,PERIOD5,0);
   ArrayResize(Am5,PERIOD5,0);
   ArrayResize(Bm5,PERIOD5,0);
   ArrayResize(FAm5,PERIOD5,0);
   ArrayResize(FBm5,PERIOD5,0);

   ArrayResize(weight1,PERIOD,0);
   ArrayResize(weight2,PERIOD2,0);
   ArrayResize(weight3,PERIOD3,0);
   ArrayResize(weight4,PERIOD4,0);
   ArrayResize(weight5,PERIOD5,0);

   ArrayResize(Amcomb1,PERIOD,0);
   ArrayResize(Amcomb2,PERIOD2,0);
   ArrayResize(Amcomb3,PERIOD3,0);
   ArrayResize(Amcomb4,PERIOD4,0);
   ArrayResize(Amcomb5,PERIOD5,0);

   ArrayResize(Bmcomb1,PERIOD,0);
   ArrayResize(Bmcomb2,PERIOD2,0);
   ArrayResize(Bmcomb3,PERIOD3,0);
   ArrayResize(Bmcomb4,PERIOD4,0);
   ArrayResize(Bmcomb5,PERIOD5,0);

   ArrayResize(fAmcomb1,PERIOD,0);
   ArrayResize(fAmcomb2,PERIOD2,0);
   ArrayResize(fAmcomb3,PERIOD3,0);
   ArrayResize(fAmcomb4,PERIOD4,0);
   ArrayResize(fAmcomb5,PERIOD5,0);

   ArrayResize(fBmcomb1,PERIOD,0);
   ArrayResize(fBmcomb2,PERIOD2,0);
   ArrayResize(fBmcomb3,PERIOD3,0);
   ArrayResize(fBmcomb4,PERIOD4,0);
   ArrayResize(fBmcomb5,PERIOD5,0);

   ArrayResize(aweight1,PERIOD,0);
   ArrayResize(aweight2,PERIOD2,0);
   ArrayResize(aweight3,PERIOD3,0);
   ArrayResize(aweight4,PERIOD4,0);
   ArrayResize(aweight5,PERIOD5,0);

   ArrayResize(bweight1,PERIOD,0);
   ArrayResize(bweight2,PERIOD2,0);
   ArrayResize(bweight3,PERIOD3,0);
   ArrayResize(bweight4,PERIOD4,0);
   ArrayResize(bweight5,PERIOD5,0);
   EventSetMillisecondTimer(100);
   if(!EventSetMillisecondTimer(100))
     {
      Print("() returned an error: ", ErrorDescription(GetLastError()));
      return INIT_FAILED;
     }

   ResetFolder();
   ArrayResize(lastMessages, numLastMessages);

//trade.SetAsyncMode(asyncMode);
//trade.SetDeviationInPoints(SlippagePoints);  // (int)(slippagePips*_pipInPoints)
//trade.SetTypeFilling(ORDER_FILLING_RETURN);  // will fill the complete order, there are also FOK and IOC modes: ORDER_FILLING_FOK, ORDER_FILLING_IOC.
// trade.LogLevel(LOG_LEVEL_ERRORS);  // else it will print a lot on tester.
// trade.SetExpertMagicNumber(magicNumber);

   return INIT_SUCCEEDED;
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

   EventKillTimer();

   ResetFolder();
  }

//+------------------------------------------------------------------+
//| Expert timer function                                            |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| Expert tick function                                            |
//+------------------------------------------------------------------+
void OnTick()
  {
   /*
      Use this OnTick() function to send market data to subscribed client.
   */

   lastUpdateMillis = GetTickCount();
   CheckSubCommands();
//CheckCommands();
//CheckOpenOrders();
   CheckMarketData();

//CheckBarData();

   static ulong ticks=0;
//---

   if(ticks==0)
     {
      ArrayInitialize(AskBuffer,0);
      ArrayInitialize(BidBuffer,0);
      ArrayInitialize(SMAskBuffer,0);
      ArrayInitialize(SMBidBuffer,0);
     }

//TICK STORAGE ARRAY

//---


   int timeSCALE = PERIOD;
   int timeSCALE2 = PERIOD2;
   int timeSCALE3 = PERIOD3;
   int timeSCALE4 = PERIOD4;
   int timeSCALE5 = PERIOD5;

   double per = PERIOD;
   double per2 = PERIOD2;
   double per3 = PERIOD3;
   double per4 = PERIOD4;
   double per5 = PERIOD5;

   double coeff1 = 10/per;
   double coeff2 = 10/per2;
   double coeff3 = 10/per3;
   double coeff4 = 10/per4;
   double coeff5 = 10/per5;

   for(int i = 0; i < PERIOD-1; i++)
     {
      weight1[i] = (exp(1)-1)/(MathPow(exp(1),coeff1*i));
     }

   for(int i = 0; i < PERIOD2-1; i++)
     {
      weight2[i] = (exp(1)-1)/(MathPow(exp(1),coeff2*i));
     }

   for(int i = 0; i < PERIOD3-1; i++)
     {
      weight3[i] = (exp(1)-1)/(MathPow(exp(1),coeff3*i));
     }

   for(int i = 0; i < PERIOD4-1; i++)
     {
      weight4[i] = (exp(1)-1)/(MathPow(exp(1),coeff4*i));
     }

   for(int i = 0; i < PERIOD5-1; i++)
     {
      weight5[i] = (exp(1)-1)/(MathPow(exp(1),coeff5*i));
     }

//TICK STORAGE ARRAY

   for(int i = PERIOD-1; i > 0; i--)
     {
      B[i] = B[i-1];
      A[i] = A[i-1];
      B[0] = SymbolInfoDouble(Symbol(),SYMBOL_BID);
      A[0] = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
     }

   for(int i = PERIOD2-1; i > 0; i--)
     {
      B2[i] = B2[i-1];
      A2[i] = A2[i-1];
      B2[0] = SymbolInfoDouble(Symbol(),SYMBOL_BID);
      A2[0] = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
     }

   for(int i = PERIOD3-1; i > 0; i--)
     {
      B3[i] = B3[i-1];
      A3[i] = A3[i-1];
      B3[0] = SymbolInfoDouble(Symbol(),SYMBOL_BID);
      A3[0] = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
     }

   for(int i = PERIOD4-1; i > 0; i--)
     {
      B4[i] = B4[i-1];
      A4[i] = A4[i-1];
      B4[0] = SymbolInfoDouble(Symbol(),SYMBOL_BID);
      A4[0] = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
     }

   for(int i = PERIOD5-1; i > 0; i--)
     {
      B5[i] = B5[i-1];
      A5[i] = A5[i-1];
      B5[0] = SymbolInfoDouble(Symbol(),SYMBOL_BID);
      A5[0] = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
     }

   double achange = A[0]-A[2];
   double bchange = B[0]-B[2];
   double spreadd = A[0]-B[0];

   CopyArr();

//Multiplying each tick by the weights (a=ask; b=bid)

   for(int i = PERIOD-2; i >= 0; i--)
     {
      Amcomb1[i] = acopy[i]*Cweight1[i];
      Bmcomb1[i] = bcopy[i]*Cweight1[i];
     }

   for(int i = PERIOD2-2; i >= 0; i--)
     {
      Amcomb2[i] = acopy2[i]*Cweight2[i];
      Bmcomb2[i] = bcopy2[i]*Cweight2[i];
     }

   for(int i = PERIOD3-2; i >= 0; i--)
     {
      Amcomb3[i] = acopy3[i]*Cweight3[i];
      Bmcomb3[i] = bcopy3[i]*Cweight3[i];
     }

   for(int i = PERIOD4-2; i >= 0; i--)
     {
      Amcomb4[i] = acopy4[i]*Cweight4[i];
      Bmcomb4[i] = bcopy4[i]*Cweight4[i];
     }

   for(int i = PERIOD5-2; i >= 0; i--)
     {
      Amcomb5[i] = acopy5[i]*Cweight5[i];
      Bmcomb5[i] = bcopy5[i]*Cweight5[i];
     }

   for(int i = 4; i > 0; i--)
     {
      Am[i] = Am[i-1];
      Am2[i] = Am2[i-1];
      Am3[i] = Am3[i-1];
      Am4[i] = Am4[i-1];
      Am5[i] = Am5[i-1];

      Bm[i] = Bm[i-1];
      Bm2[i] = Bm2[i-1];
      Bm3[i] = Bm3[i-1];
      Bm4[i] = Bm4[i-1];
      Bm5[i] = Bm5[i-1];

      Am[0] = MathSum(Amcomb1)*(1/MathSum(Cweight1));
      Am2[0] = MathSum(Amcomb2)*(1/MathSum(Cweight2));
      Am3[0] = MathSum(Amcomb3)*(1/MathSum(Cweight3));
      Am4[0] = MathSum(Amcomb4)*(1/MathSum(Cweight4));
      Am5[0] = MathSum(Amcomb5)*(1/MathSum(Cweight5));

      Bm[0] = MathSum(Bmcomb1)*(1/MathSum(Cweight1));
      Bm2[0] = MathSum(Bmcomb2)*(1/MathSum(Cweight2));
      Bm3[0] = MathSum(Bmcomb3)*(1/MathSum(Cweight3));
      Bm4[0] = MathSum(Bmcomb4)*(1/MathSum(Cweight4));
      Bm5[0] = MathSum(Bmcomb5)*(1/MathSum(Cweight5));
     }

//actual filter

   double da = ((((A[0]-Am[0]) - min1)*2)/(max1-min1))-1;
   double da2 = ((((A[0]-Am2[0]) - min2)*2)/(max2-min2))-1;
   double da3 = ((((A[0]-Am3[0]) - min3)*2)/(max3-min3))-1;
   double da4 = ((((A[0]-Am4[0]) - min4)*2)/(max4-min4))-1;
   double da5 = ((((A[0]-Am5[0]) - min5)*2)/(max5-min5))-1;

   double db = ((((B[0]-Bm[0]) - min1)*2)/(max1-min1))-1;
   double db2 = ((((B[0]-Bm2[0]) - min2)*2)/(max2-min2))-1;
   double db3 = ((((B[0]-Bm3[0]) - min3)*2)/(max3-min3))-1;
   double db4 = ((((B[0]-Bm4[0]) - min4)*2)/(max4-min4))-1;
   double db5 = ((((B[0]-Bm5[0]) - min5)*2)/(max5-min5))-1;


   double aper = PERIOD-((MathPow(exp(1),(f*MathPow(da,g))))/(1/e));
   double aper2 = PERIOD2-((MathPow(exp(1),(f*MathPow(da2,g))))/(1/e2));
   double aper3 = PERIOD3-((MathPow(exp(1),(f*MathPow(da3,g))))/(1/e3));
   double aper4 = PERIOD4-((MathPow(exp(1),(f*MathPow(da4,g))))/(1/e4));
   double aper5 = PERIOD5-((MathPow(exp(1),(f*MathPow(da5,g))))/(1/e5));

   double bper = PERIOD-((MathPow(exp(1),(f*MathPow(db,g))))/(1/e));
   double bper2 = PERIOD2-((MathPow(exp(1),(f*MathPow(db2,g))))/(1/e2));
   double bper3 = PERIOD3-((MathPow(exp(1),(f*MathPow(db3,g))))/(1/e3));
   double bper4 = PERIOD4-((MathPow(exp(1),(f*MathPow(db4,g))))/(1/e4));
   double bper5 = PERIOD5-((MathPow(exp(1),(f*MathPow(db5,g))))/(1/e5));

   double acoeff1 = 10/aper;
   double acoeff2 = 10/aper2;
   double acoeff3 = 10/aper3;
   double acoeff4 = 10/aper4;
   double acoeff5 = 10/aper5;

   double bcoeff1 = 10/bper;
   double bcoeff2 = 10/bper2;
   double bcoeff3 = 10/bper3;
   double bcoeff4 = 10/bper4;
   double bcoeff5 = 10/bper5;

   for(int i = PERIOD-1; i >= 0; i--)
     {
      aweight1[i] = (exp(1)-1)/(MathPow(exp(1),acoeff1*i));
      bweight1[i] = (exp(1)-1)/(MathPow(exp(1),bcoeff1*i));
     }

   for(int i = PERIOD2-1; i >= 0; i--)
     {
      aweight2[i] = (exp(1)-1)/(MathPow(exp(1),acoeff2*i));
      bweight2[i] = (exp(1)-1)/(MathPow(exp(1),bcoeff2*i));
     }

   for(int i = PERIOD3-1; i >= 0; i--)
     {
      aweight3[i] = (exp(1)-1)/(MathPow(exp(1),acoeff3*i));
      bweight3[i] = (exp(1)-1)/(MathPow(exp(1),bcoeff3*i));
     }

   for(int i = PERIOD4-1; i >= 0; i--)
     {
      aweight4[i] = (exp(1)-1)/(MathPow(exp(1),acoeff4*i));
      bweight4[i] = (exp(1)-1)/(MathPow(exp(1),bcoeff4*i));
     }

   for(int i = PERIOD5-1; i >= 0; i--)
     {
      aweight5[i] = (exp(1)-1)/(MathPow(exp(1),acoeff5*i));
      bweight5[i] = (exp(1)-1)/(MathPow(exp(1),bcoeff5*i));
     }


//Multiplying each tick by the weights (a=ask; b=bid)

   for(int i = 0; i < PERIOD-1; i++)
     {
      fAmcomb1[i] = acopy[i]*faweight1[i];
      fBmcomb1[i] = bcopy[i]*fbweight1[i];
     }

   for(int i = 0; i < PERIOD2-1; i++)
     {
      fAmcomb2[i] = acopy2[i]*faweight2[i];
      fBmcomb2[i] = bcopy2[i]*fbweight2[i];
     }

   for(int i = 0; i < PERIOD3-1; i++)
     {
      fAmcomb3[i] = acopy3[i]*faweight3[i];
      fBmcomb3[i] = bcopy3[i]*fbweight3[i];
     }

   for(int i = 0; i < PERIOD4-1; i++)
     {
      fAmcomb4[i] = acopy4[i]*faweight4[i];
      fBmcomb4[i] = bcopy4[i]*fbweight4[i];
     }

   for(int i = 0; i < PERIOD5-1; i++)
     {
      fAmcomb5[i] = acopy5[i]*faweight5[i];
      fBmcomb5[i] = bcopy5[i]*fbweight5[i];
     }


   for(int i = 4; i > 0; i--)
     {
      FAm[i] = FAm[i-1];
      FAm2[i] = FAm2[i-1];
      FAm3[i] = FAm3[i-1];
      FAm4[i] = FAm4[i-1];
      FAm5[i] = FAm5[i-1];

      FBm[i] = FBm[i-1];
      FBm2[i] = FBm2[i-1];
      FBm3[i] = FBm3[i-1];
      FBm4[i] = FBm4[i-1];
      FBm5[i] = FBm5[i-1];

      FAm[0] = MathSum(fAmcomb1)*(1/MathSum(faweight1));
      FAm2[0] = MathSum(fAmcomb2)*(1/MathSum(faweight2));
      FAm3[0] = MathSum(fAmcomb3)*(1/MathSum(faweight3));
      FAm4[0] = MathSum(fAmcomb4)*(1/MathSum(faweight4));
      FAm5[0] = MathSum(fAmcomb5)*(1/MathSum(faweight5));

      FBm[0] = MathSum(fBmcomb1)*(1/MathSum(faweight1));
      FBm2[0] = MathSum(fBmcomb2)*(1/MathSum(faweight2));
      FBm3[0] = MathSum(fBmcomb3)*(1/MathSum(faweight3));
      FBm4[0] = MathSum(fBmcomb4)*(1/MathSum(faweight4));
      FBm5[0] = MathSum(fBmcomb5)*(1/MathSum(faweight5));
     }

   ticks++;
//Print(ticks);

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer()
  {


   CheckASKNN();
   CheckBIDNN();
   CheckASK();
   CheckBID();
   TradeNow();
//Print("time");
// update prices regularly in case there was no tick within X milliseconds (for non-chart symbols).
//if (GetTickCount() >= lastUpdateMillis + MILLISECOND_TIMER) OnTick();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TradeNow()
  {
   for(int i=0; i<maxCommandFiles; i++)
     {
      string filePath = filePathTRPrefix + IntegerToString(i) + ".txt";
      if(!FileIsExist(filePath))
         return;
      int handle = FileOpen(filePath, FILE_READ|FILE_TXT|FILE_ANSI);  // FILE_COMMON |
      if(handle == -1)
         return;
      if(handle == 0)
         return;

      string text = "";
      while(!FileIsEnding(handle))
         text += FileReadString(handle);
      FileClose(handle);
      FileDelete(filePath);

      // make sure that the file content is complete.
      int length = StringLen(text);
      if(StringSubstr(text, 0, 2) != startIdentifier)
        {
         SendError("WRONG_FORMAT_START_IDENTIFIER", "Start identifier not found for command: " + text);
         return;
        }

      if(StringSubstr(text, length-2, 2) != endIdentifier)
        {
         SendError("WRONG_FORMAT_END_IDENTIFIER", "End identifier not found for command: " + text);
         return;
        }
      text = StringSubstr(text, 2, length-4);

      ushort uSep = StringGetCharacter(delimiter, 0);
      string data[];
      int splits = StringSplit(text, uSep, data);

      if(splits != 2)
        {
         SendError("WRONG_FORMAT_COMMAND", "Wrong format for command: " + text);
         return;
        }

      string command = data[0];
      if(command == "TR")
        {

     //    Print("time ", asknn[0]," ",bidnn[0]," ",price_ask[0]," ",price_bid[0]," ",SymbolInfoDouble(Symbol(),SYMBOL_ASK)," ",SymbolInfoDouble(Symbol(),SYMBOL_BID));
         static ulong t = 0;

         t++;

         if((t > 50000)&&(price_ask[0] == SymbolInfoDouble(Symbol(),SYMBOL_ASK)))
           {
            GO();
           }

        }
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void GO()
  {
   string time = TimeToString(TimeCurrent(),TIME_SECONDS);
   if(time == "00:00:00")
     {
      for(int i = 2; i > 0; i--)
        {
         buypow[i] = buypow[i-1];
         buypow[0] = AccountInfoDouble(ACCOUNT_BALANCE);
        }
      Comment("Buying power is now ",buypow[0]," as it was ",buypow[2]," 24 hours ago");
     }


   double MarginInit = SymbolInfoDouble(Symbol(),SYMBOL_MARGIN_INITIAL);
   double MarginMaint = SymbolInfoDouble(Symbol(),SYMBOL_MARGIN_MAINTENANCE);
   double MM = SymbolInfoMarginRate(Symbol(),ORDER_TYPE_BUY,MarginInit,MarginMaint);
   double w = 0.5/MarginInit;
   double ask = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
   double bid = SymbolInfoDouble(Symbol(),SYMBOL_BID);
   double LOTSIZEbuy = MathRound(((((buypow[0]/ratio)*1000)*w)/ask)/5,2);
   double LOTSIZEsell = MathRound(((((buypow[0]/ratio)*1000)*w)/bid)/5,2);


   Print(" margin init: ", MarginInit," margin maint: ",MarginMaint," MM: ",MM," w: ",w," Buy lots: ",LOTSIZEbuy," Sell lots: ",LOTSIZEsell);


   if(LOTSIZEbuy > SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX))
     {
      LOTSIZEbuy = SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX)/10;
     }

   if(LOTSIZEbuy < SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN))
     {
      LOTSIZEbuy = SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN);
     }

   if(LOTSIZEsell > SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX))
     {
      LOTSIZEsell = SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX)/10;
     }

   if(LOTSIZEsell < SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN))
     {
      LOTSIZEsell = SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN);
     }


//outputs for buy condition (FILTER 1)
   if(asknn[0] > FAm[0]-price_ask[0])
     {
      if(asknn[2] <= FAm[2]-price_ask[2])
        {
          int bf1 = 0;

          for(int i = PositionsTotal()-1; i>=0; i--)
             {
               ulong ticket = PositionGetTicket(i);
               long PositionMagic = PositionGetInteger(POSITION_MAGIC);

               if(PositionMagic == 111111)
                 {
                  bf1 = 1;
                 }
             }
           if (bf1 == 0)
         {
         for(int i = 1; i > 0; i--)
           {

            MqlTradeRequest request= {};
            MqlTradeResult  result= {};

            request.action   =TRADE_ACTION_DEAL;                     // type of trade operation
            request.symbol   =Symbol();                              // symbol
            request.volume   =LOTSIZEbuy;  // volume
            request.type     =ORDER_TYPE_BUY;                        // order type
            request.price    =SymbolInfoDouble(Symbol(),SYMBOL_ASK); // price for opening
            request.deviation=0;                                     // allowed deviation from the price
            request.magic    =111111;                                // MagicNumber of the order
            //--- send the request
            if(!OrderSend(request,result))
               PrintFormat("OrderSend error %d",GetLastError());     // if unable to send the request, output the error code
            //--- information about the operation
            PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);

            for(int i = PositionsTotal()-1; i>=0; i--)
              {
               ulong ticket = PositionGetTicket(i);
               long PositionMagic = PositionGetInteger(POSITION_MAGIC);

               if(PositionMagic == 111000)
                 {
                  trade.PositionClose(ticket);
                 }
              }
           }
        }
     }
   }
//outputs for sell condition (FILTER 1)

   if(bidnn[0] < FBm[0]-price_bid[0])
     {
      if(bidnn[2] >= FBm[2]-price_bid[2])
        {
          int sf1 = 0;

          for(int i = PositionsTotal()-1; i>=0; i--)
             {
               ulong ticket = PositionGetTicket(i);
               long PositionMagic = PositionGetInteger(POSITION_MAGIC);

               if(PositionMagic == 111000)
                 {
                  sf1 = 1;
                 }
             }
           if (sf1 == 0)
         {
         for(int i = 1; i > 0; i--)
           {
            MqlTradeRequest request= {};
            MqlTradeResult  result= {};

            request.action   =TRADE_ACTION_DEAL;                     // type of trade operation
            request.symbol   =Symbol();                              // symbol
            request.volume   =LOTSIZEsell;  // volume
            request.type     =ORDER_TYPE_SELL;                       // order type
            request.price    =SymbolInfoDouble(Symbol(),SYMBOL_BID); // price for opening
            request.deviation=0;                                     // allowed deviation from the price
            request.magic    =111000;                                // MagicNumber of the order
            //--- send the request
            if(!OrderSend(request,result))
               PrintFormat("OrderSend error %d",GetLastError());     // if unable to send the request, output the error code
            //--- information about the operation
            PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);

            for(int i = PositionsTotal()-1; i>=0; i--)
              {
               ulong ticket = PositionGetTicket(i);
               long PositionMagic = PositionGetInteger(POSITION_MAGIC);
               if(PositionMagic == 111111)
                 {
                  trade.PositionClose(ticket);
                 }
              }
           }
        }
     }
}

//outputs for buy condition (FILTER 2)

   if(asknn[0] > FAm2[0]-price_ask[0])
     {
      if(asknn[2] <= FAm2[2]-price_ask[2])
        {
          int bf2 = 0;

          for(int i = PositionsTotal()-1; i>=0; i--)
             {
               ulong ticket = PositionGetTicket(i);
               long PositionMagic = PositionGetInteger(POSITION_MAGIC);

               if(PositionMagic == 222111)
                 {
                  bf2 = 1;
                 }
             }
           if (bf2 == 0)
         {
         for(int i = 1; i > 0; i--)
           {
            MqlTradeRequest request= {};
            MqlTradeResult  result= {};

            request.action   =TRADE_ACTION_DEAL;                     // type of trade operation
            request.symbol   =Symbol();                              // symbol
            request.volume   =LOTSIZEbuy;                     // volume
            request.type     =ORDER_TYPE_BUY;                        // order type
            request.price    =SymbolInfoDouble(Symbol(),SYMBOL_ASK); // price for opening
            request.deviation=0;                                     // allowed deviation from the price
            request.magic    =222111;                                // MagicNumber of the order
            //--- send the request
            if(!OrderSend(request,result))
               PrintFormat("OrderSend error %d",GetLastError());     // if unable to send the request, output the error code
            //--- information about the operation
            PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
            for(int i = PositionsTotal()-1; i>=0; i--)
              {
               ulong ticket = PositionGetTicket(i);
               long PositionMagic = PositionGetInteger(POSITION_MAGIC);
               if(PositionMagic == 222000)
                 {
                  trade.PositionClose(ticket);
                 }
              }
           }
        }
     }
}
//outputs for sell condition (FILTER 2)

   if(bidnn[0] < FBm2[0]-price_bid[0])
     {
      if(bidnn[2] >= FBm2[2]-price_bid[2])
        {
          int sf2 = 0;

          for(int i = PositionsTotal()-1; i>=0; i--)
             {
               ulong ticket = PositionGetTicket(i);
               long PositionMagic = PositionGetInteger(POSITION_MAGIC);

               if(PositionMagic == 222000)
                 {
                   sf2 = 1;
                 }
             }
           if (sf2 == 0)
         {
         for(int i = 1; i > 0; i--)
           {
            MqlTradeRequest request= {};
            MqlTradeResult  result= {};

            request.action   =TRADE_ACTION_DEAL;                     // type of trade operation
            request.symbol   =Symbol();                              // symbol
            request.volume   =LOTSIZEsell;                     // volume
            request.type     =ORDER_TYPE_SELL;                       // order type
            request.price    =SymbolInfoDouble(Symbol(),SYMBOL_BID); // price for opening
            request.deviation=0;                                     // allowed deviation from the price
            request.magic    =222000;                                // MagicNumber of the order
            //--- send the request
            if(!OrderSend(request,result))
               PrintFormat("OrderSend error %d",GetLastError());     // if unable to send the request, output the error code
            //--- information about the operation
            PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
            for(int i = PositionsTotal()-1; i>=0; i--)
              {
               ulong ticket = PositionGetTicket(i);
               long PositionMagic = PositionGetInteger(POSITION_MAGIC);
               if(PositionMagic == 222111)
                 {
                  trade.PositionClose(ticket);
                 }
              }
           }
        }
     }
}

//outputs for buy condition (FILTER 3)

   if(asknn[0] > FAm3[0]-price_ask[0])
     {
      if(asknn[2] <= FAm3[2]-price_ask[2])
        {
          int bf3 = 0;

          for(int i = PositionsTotal()-1; i>=0; i--)
             {
               ulong ticket = PositionGetTicket(i);
               long PositionMagic = PositionGetInteger(POSITION_MAGIC);

               if(PositionMagic == 333111)
                 {
                   bf3 = 1;
                 }
             }
           if (bf3 == 0)
         {
         for(int i = 1; i > 0; i--)
           {
            MqlTradeRequest request= {};
            MqlTradeResult  result= {};

            request.action   =TRADE_ACTION_DEAL;                     // type of trade operation
            request.symbol   =Symbol();                              // symbol
            request.volume   =LOTSIZEbuy;                     // volume
            request.type     =ORDER_TYPE_BUY;                        // order type
            request.price    =SymbolInfoDouble(Symbol(),SYMBOL_ASK); // price for opening
            request.deviation=0;                                     // allowed deviation from the price
            request.magic    =333111;                                // MagicNumber of the order
            //--- send the request
            if(!OrderSend(request,result))
               PrintFormat("OrderSend error %d",GetLastError());     // if unable to send the request, output the error code
            //--- information about the operation
            PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
            for(int i = PositionsTotal()-1; i>=0; i--)
              {
               ulong ticket = PositionGetTicket(i);
               long PositionMagic = PositionGetInteger(POSITION_MAGIC);
               if(PositionMagic == 333000)
                 {
                  trade.PositionClose(ticket);
                 }
              }
           }
        }
     }
}
//outputs for sell condition (FILTER 3)

   if(bidnn[0] < FBm3[0]-price_bid[0])
     {
      if(bidnn[2] >= FBm3[2]-price_bid[2])
        {
          int sf3 = 0;

          for(int i = PositionsTotal()-1; i>=0; i--)
             {
               ulong ticket = PositionGetTicket(i);
               long PositionMagic = PositionGetInteger(POSITION_MAGIC);

               if(PositionMagic == 333000)
                 {
                   sf3 = 1;
                 }
             }
           if (sf3 == 0)
         {
         for(int i = 1; i > 0; i--)
           {
            MqlTradeRequest request= {};
            MqlTradeResult  result= {};

            request.action   =TRADE_ACTION_DEAL;                     // type of trade operation
            request.symbol   =Symbol();                              // symbol
            request.volume   =LOTSIZEsell;                     // volume
            request.type     =ORDER_TYPE_SELL;                       // order type
            request.price    =SymbolInfoDouble(Symbol(),SYMBOL_BID); // price for opening
            request.deviation=0;                                     // allowed deviation from the price
            request.magic    =333000;                                // MagicNumber of the order
            //--- send the request
            if(!OrderSend(request,result))
               PrintFormat("OrderSend error %d",GetLastError());     // if unable to send the request, output the error code
            //--- information about the operation
            PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
            for(int i = PositionsTotal()-1; i>=0; i--)
              {
               ulong ticket = PositionGetTicket(i);
               long PositionMagic = PositionGetInteger(POSITION_MAGIC);
               if(PositionMagic == 333111)
                 {
                  trade.PositionClose(ticket);
                 }
              }
           }
        }
     }
  }
//outputs for buy condition (FILTER 4)

   if(asknn[0] > FAm4[0]-price_ask[0])
     {
      if(asknn[2] <= FAm4[2]-price_ask[2])
        {
          int bf4 = 0;

          for(int i = PositionsTotal()-1; i>=0; i--)
             {
               ulong ticket = PositionGetTicket(i);
               long PositionMagic = PositionGetInteger(POSITION_MAGIC);

               if(PositionMagic == 444111)
                 {
                   bf4 = 1;
                 }
             }
           if (bf4 == 0)
         {
         for(int i = 1; i > 0; i--)
           {
            MqlTradeRequest request= {};
            MqlTradeResult  result= {};

            request.action   =TRADE_ACTION_DEAL;                     // type of trade operation
            request.symbol   =Symbol();                              // symbol
            request.volume   =LOTSIZEbuy;                     // volume
            request.type     =ORDER_TYPE_BUY;                        // order type
            request.price    =SymbolInfoDouble(Symbol(),SYMBOL_ASK); // price for opening
            request.deviation=0;                                     // allowed deviation from the price
            request.magic    =444111;                                // MagicNumber of the order
            //--- send the request
            if(!OrderSend(request,result))
               PrintFormat("OrderSend error %d",GetLastError());     // if unable to send the request, output the error code
            //--- information about the operation
            PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
            for(int i = PositionsTotal()-1; i>=0; i--)
              {
               ulong ticket = PositionGetTicket(i);
               long PositionMagic = PositionGetInteger(POSITION_MAGIC);
               if(PositionMagic == 444000)
                 {
                  trade.PositionClose(ticket);
                 }
              }
           }
        }
     }
  }
//outputs for sell condition (FILTER 4)

   if(bidnn[0] < FBm4[0]-price_bid[0])
     {
      if(bidnn[2] >= FBm4[2]-price_bid[2])
        {
          int sf4 = 0;

          for(int i = PositionsTotal()-1; i>=0; i--)
             {
               ulong ticket = PositionGetTicket(i);
               long PositionMagic = PositionGetInteger(POSITION_MAGIC);

               if(PositionMagic == 444000)
                 {
                   sf4 = 1;
                 }
             }
           if (sf4 == 0)
         {
         for(int i = 1; i > 0; i--)
           {
            MqlTradeRequest request= {};
            MqlTradeResult  result= {};

            request.action   =TRADE_ACTION_DEAL;                     // type of trade operation
            request.symbol   =Symbol();                              // symbol
            request.volume   =LOTSIZEsell;                     // volume
            request.type     =ORDER_TYPE_SELL;                       // order type
            request.price    =SymbolInfoDouble(Symbol(),SYMBOL_BID); // price for opening
            request.deviation=0;                                     // allowed deviation from the price
            request.magic    =444000;                                // MagicNumber of the order
            //--- send the request
            if(!OrderSend(request,result))
               PrintFormat("OrderSend error %d",GetLastError());     // if unable to send the request, output the error code
            //--- information about the operation
            PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
            for(int i = PositionsTotal()-1; i>=0; i--)
              {
               ulong ticket = PositionGetTicket(i);
               long PositionMagic = PositionGetInteger(POSITION_MAGIC);
               if(PositionMagic == 444111)
                 {
                  trade.PositionClose(ticket);
                 }
              }
           }
        }
     }
  }
//outputs for buy condition (FILTER 5)

   if(asknn[0] > FAm5[0]-price_ask[0])
     {
      if(asknn[2] <= FAm5[2]-price_ask[2])
        {
          int bf5 = 0;

          for(int i = PositionsTotal()-1; i>=0; i--)
             {
               ulong ticket = PositionGetTicket(i);
               long PositionMagic = PositionGetInteger(POSITION_MAGIC);

               if(PositionMagic == 555111)
                 {
                   bf5 = 1;
                 }
             }
           if (bf5 == 0)
         {
         for(int i = 1; i > 0; i--)
           {
            MqlTradeRequest request= {};
            MqlTradeResult  result= {};

            request.action   =TRADE_ACTION_DEAL;                     // type of trade operation
            request.symbol   =Symbol();                              // symbol
            request.volume   =LOTSIZEbuy;                     // volume
            request.type     =ORDER_TYPE_BUY;                        // order type
            request.price    =SymbolInfoDouble(Symbol(),SYMBOL_ASK); // price for opening
            request.deviation=0;                                     // allowed deviation from the price
            request.magic    =555111;                                // MagicNumber of the order
            //--- send the request
            if(!OrderSend(request,result))
               PrintFormat("OrderSend error %d",GetLastError());     // if unable to send the request, output the error code
            //--- information about the operation
            PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
            for(int i = PositionsTotal()-1; i>=0; i--)
              {
               ulong ticket = PositionGetTicket(i);
               long PositionMagic = PositionGetInteger(POSITION_MAGIC);
               if(PositionMagic == 555000)
                 {
                  trade.PositionClose(ticket);
                 }
              }
           }
        }
     }
  }
//outputs for sell condition (FILTER 5)

   if(bidnn[0] < FBm5[0]-price_bid[0])
     {
      if(bidnn[2] >= FBm5[2]-price_bid[2])
        {
          int sf5 = 0;

          for(int i = PositionsTotal()-1; i>=0; i--)
             {
               ulong ticket = PositionGetTicket(i);
               long PositionMagic = PositionGetInteger(POSITION_MAGIC);

               if(PositionMagic == 555000)
                 {
                   sf5 = 1;
                 }
             }
           if (sf5 == 0)
         {
         for(int i = 1; i > 0; i--)
           {
            MqlTradeRequest request= {};
            MqlTradeResult  result= {};

            request.action   =TRADE_ACTION_DEAL;                     // type of trade operation
            request.symbol   =Symbol();                              // symbol
            request.volume   =LOTSIZEsell;                     // volume
            request.type     =ORDER_TYPE_SELL;                       // order type
            request.price    =SymbolInfoDouble(Symbol(),SYMBOL_BID); // price for opening
            request.deviation=0;                                     // allowed deviation from the price
            request.magic    =555000;                                // MagicNumber of the order
            //--- send the request
            if(!OrderSend(request,result))
               PrintFormat("OrderSend error %d",GetLastError());     // if unable to send the request, output the error code
            //--- information about the operation
            PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
            for(int i = PositionsTotal()-1; i>=0; i--)
              {
               ulong ticket = PositionGetTicket(i);
               long PositionMagic = PositionGetInteger(POSITION_MAGIC);
               if(PositionMagic == 555111)
                 {
                  trade.PositionClose(ticket);
                 }
              }
           }
        }
     }
  }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckSubCommands()
  {
   for(int i=0; i<maxCommandFiles; i++)
     {
      string filePath = filePathCommandsPrefix + IntegerToString(i) + ".txt";
      if(!FileIsExist(filePath))
         return;
      int handle = FileOpen(filePath, FILE_READ|FILE_TXT|FILE_ANSI);  // FILE_COMMON |
      if(handle == -1)
         return;
      if(handle == 0)
         return;

      string text = "";
      while(!FileIsEnding(handle))
         text += FileReadString(handle);
      FileClose(handle);
      FileDelete(filePath);

      // make sure that the file content is complete.
      int length = StringLen(text);
      if(StringSubstr(text, 0, 2) != startIdentifier)
        {
         SendError("WRONG_FORMAT_START_IDENTIFIER", "Start identifier not found for command: " + text);
         return;
        }

      if(StringSubstr(text, length-2, 2) != endIdentifier)
        {
         SendError("WRONG_FORMAT_END_IDENTIFIER", "End identifier not found for command: " + text);
         return;
        }
      text = StringSubstr(text, 2, length-4);

      ushort uSep = StringGetCharacter(delimiter, 0);
      string data[];
      int splits = StringSplit(text, uSep, data);

      if(splits != 2)
        {
         SendError("WRONG_FORMAT_COMMAND", "Wrong format for command: " + text);
         return;
        }

      string command = data[0];
      if(command == "SUBSCRIBE_SYMBOLS")
        {
         Print(data[1]);
         SubscribeSymbols(data[1]);
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckASKNN()
  {
   for(int i=0; i<maxCommandFiles; i++)
     {
      string filePath = filePathASKNNPrefix + IntegerToString(i) + ".txt";
      if(!FileIsExist(filePath))
         return;
      int handle = FileOpen(filePath, FILE_READ|FILE_TXT|FILE_ANSI);  // FILE_COMMON |
      if(handle == -1)
         return;
      if(handle == 0)
         return;

      string text = "";
      while(!FileIsEnding(handle))
         text += FileReadString(handle);
      FileClose(handle);
      FileDelete(filePath);

      // make sure that the file content is complete.
      int length = StringLen(text);
      if(StringSubstr(text, 0, 2) != startIdentifier)
        {
         SendError("WRONG_FORMAT_START_IDENTIFIER", "Start identifier not found for command: " + text);
         return;
        }

      if(StringSubstr(text, length-2, 2) != endIdentifier)
        {
         SendError("WRONG_FORMAT_END_IDENTIFIER", "End identifier not found for command: " + text);
         return;
        }
      text = StringSubstr(text, 2, length-4);

      ushort uSep = StringGetCharacter(delimiter, 0);
      string data[];
      int splits = StringSplit(text, uSep, data);

      if(splits != 2)
        {
         SendError("WRONG_FORMAT_COMMAND", "Wrong format for command: " + text);
         return;
        }

      string command = data[0];
      if(command == "ASK_NN_OUTPUT")
        {
         AskNNOutputs(data[1]);
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckBIDNN()
  {
   for(int i=0; i<maxCommandFiles; i++)
     {
      string filePath = filePathBIDNNPrefix + IntegerToString(i) + ".txt";
      if(!FileIsExist(filePath))
         return;
      int handle = FileOpen(filePath, FILE_READ|FILE_TXT|FILE_ANSI);  // FILE_COMMON |
      if(handle == -1)
         return;
      if(handle == 0)
         return;

      string text = "";
      while(!FileIsEnding(handle))
         text += FileReadString(handle);
      FileClose(handle);
      FileDelete(filePath);

      // make sure that the file content is complete.
      int length = StringLen(text);
      if(StringSubstr(text, 0, 2) != startIdentifier)
        {
         SendError("WRONG_FORMAT_START_IDENTIFIER", "Start identifier not found for command: " + text);
         return;
        }

      if(StringSubstr(text, length-2, 2) != endIdentifier)
        {
         SendError("WRONG_FORMAT_END_IDENTIFIER", "End identifier not found for command: " + text);
         return;
        }
      text = StringSubstr(text, 2, length-4);

      ushort uSep = StringGetCharacter(delimiter, 0);
      string data[];
      int splits = StringSplit(text, uSep, data);

      if(splits != 2)
        {
         SendError("WRONG_FORMAT_COMMAND", "Wrong format for command: " + text);
         return;
        }

      string command = data[0];
      if(command == "BID_NN_OUTPUT")
        {
         BidNNOutputs(data[1]);
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckASK()
  {
   for(int i=0; i<maxCommandFiles; i++)
     {
      string filePath = filePathASKPrefix + IntegerToString(i) + ".txt";
      if(!FileIsExist(filePath))
         return;
      int handle = FileOpen(filePath, FILE_READ|FILE_TXT|FILE_ANSI);  // FILE_COMMON |
      if(handle == -1)
         return;
      if(handle == 0)
         return;

      string text = "";
      while(!FileIsEnding(handle))
         text += FileReadString(handle);
      FileClose(handle);
      FileDelete(filePath);

      // make sure that the file content is complete.
      int length = StringLen(text);
      if(StringSubstr(text, 0, 2) != startIdentifier)
        {
         SendError("WRONG_FORMAT_START_IDENTIFIER", "Start identifier not found for command: " + text);
         return;
        }

      if(StringSubstr(text, length-2, 2) != endIdentifier)
        {
         SendError("WRONG_FORMAT_END_IDENTIFIER", "End identifier not found for command: " + text);
         return;
        }
      text = StringSubstr(text, 2, length-4);

      ushort uSep = StringGetCharacter(delimiter, 0);
      string data[];
      int splits = StringSplit(text, uSep, data);

      if(splits != 2)
        {
         SendError("WRONG_FORMAT_COMMAND", "Wrong format for command: " + text);
         return;
        }

      string command = data[0];
      if(command == "ASK")
        {
         Asks(data[1]);
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckBID()
  {
   for(int i=0; i<maxCommandFiles; i++)
     {
      string filePath = filePathBIDPrefix + IntegerToString(i) + ".txt";
      if(!FileIsExist(filePath))
         return;
      int handle = FileOpen(filePath, FILE_READ|FILE_TXT|FILE_ANSI);  // FILE_COMMON |
      if(handle == -1)
         return;
      if(handle == 0)
         return;

      string text = "";
      while(!FileIsEnding(handle))
         text += FileReadString(handle);
      FileClose(handle);
      FileDelete(filePath);

      // make sure that the file content is complete.
      int length = StringLen(text);
      if(StringSubstr(text, 0, 2) != startIdentifier)
        {
         SendError("WRONG_FORMAT_START_IDENTIFIER", "Start identifier not found for command: " + text);
         return;
        }

      if(StringSubstr(text, length-2, 2) != endIdentifier)
        {
         SendError("WRONG_FORMAT_END_IDENTIFIER", "End identifier not found for command: " + text);
         return;
        }
      text = StringSubstr(text, 2, length-4);

      ushort uSep = StringGetCharacter(delimiter, 0);
      string data[];
      int splits = StringSplit(text, uSep, data);

      if(splits != 2)
        {
         SendError("WRONG_FORMAT_COMMAND", "Wrong format for command: " + text);
         return;
        }

      string command = data[0];
      if(command == "BID")
        {
         Bids(data[1]);
        }
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void AskNNOutputs(double ASKNNStr)
  {
   for(int i = 3; i > 0; i--)
     {
      asknn[i] = asknn[i-1];

      asknn[0] = ASKNNStr;
     }
   //Print(" ",asknn[0]," ",asknn[1]," ", asknn[2]," ",SymbolInfoDouble(Symbol(),SYMBOL_ASK));
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void BidNNOutputs(double BIDNNStr)
  {
   for(int i = 3; i > 0; i--)
     {
      bidnn[i] = bidnn[i-1];
      bidnn[0] = BIDNNStr;
     }
   //Print(" ",bidnn[0]," ",bidnn[1]," ",bidnn[2]," ",SymbolInfoDouble(Symbol(),SYMBOL_BID));
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Asks(double ASKStr)
  {
   for(int i = 3; i > 0; i--)
     {
      price_ask[i] = price_ask[i-1];

      price_ask[0] = ASKStr;
     }
   //Print(" ",price_ask[0]," ",price_ask[1]," ", price_ask[2]," ",SymbolInfoDouble(Symbol(),SYMBOL_ASK));
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Bids(double BIDStr)
  {
   for(int i = 3; i > 0; i--)
     {
      price_bid[i] = price_bid[i-1];
      price_bid[0] = BIDStr;
     }
   //Print(" ",price_bid[0]," ",price_bid[1]," ",price_bid[2]," ",SymbolInfoDouble(Symbol(),SYMBOL_BID));
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int NumOrders()
  {

   int n = 0;

   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket))
         continue;
      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY || PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
        {
         n++;
        }
     }
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      ulong ticket = OrderGetTicket(i);
      if(!OrderSelect(ticket))
         continue;
      if(OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_BUY_LIMIT || OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_SELL_LIMIT
         || OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_BUY_STOP || OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_SELL_STOP)
        {
         n++;
        }
     }
   return n;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SubscribeSymbols(string symbolsStr)
  {

   string sep = ",";
   ushort uSep = StringGetCharacter(sep, 0);
   string data[];
   int splits = StringSplit(symbolsStr, uSep, data);

   if(ArraySize(data) == 0)
     {
      ArrayResize(MarketDataSymbols, 0);
      SendInfo("Unsubscribed from all tick data because of empty symbol list.");
      return;
     }

   string successSymbols = "", errorSymbols = "";
   for(int i=0; i<ArraySize(data); i++)
     {
      if(SymbolSelect(data[i], true))
        {
         ArrayResize(MarketDataSymbols, i+1);
         MarketDataSymbols[i] = data[i];
         successSymbols += data[i] + ", ";
        }
      else
        {
         errorSymbols += data[i] + ", ";
        }
     }

   if(StringLen(errorSymbols) > 0)
     {
      SendError("SUBSCRIBE_SYMBOL", "Could not subscribe to symbols: " + StringSubstr(errorSymbols, 0, StringLen(errorSymbols)-2));
     }
   if(StringLen(successSymbols) > 0)
     {
      SendInfo("Successfully subscribed to: " + StringSubstr(successSymbols, 0, StringLen(successSymbols)-2));
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SubscribeSymbolsBarData(string dataStr)
  {

   string sep = ",";
   ushort uSep = StringGetCharacter(sep, 0);
   string data[];
   int splits = StringSplit(dataStr, uSep, data);

   if(ArraySize(data) == 0)
     {
      ArrayResize(BarDataInstruments, 0);
      SendInfo("Unsubscribed from all bar data because of empty symbol list.");
      return;
     }

   if(ArraySize(data) < 2 || ArraySize(data) % 2 != 0)
     {
      SendError("BAR_DATA_WRONG_FORMAT", "Wrong format to subscribe to bar data: " + dataStr);
      return;
     }

// Format: SYMBOL_1,TIMEFRAME_1,SYMBOL_2,TIMEFRAME_2,...,SYMBOL_N,TIMEFRAME_N
   string errorSymbols = "";

   int numInstruments = ArraySize(data)/2;

   for(int s=0; s<numInstruments; s++)
     {

      if(SymbolSelect(data[2*s], true))
        {

         ArrayResize(BarDataInstruments, s+1);

         BarDataInstruments[s].setup(data[2*s], data[(2*s)+1]);

        }
      else
        {
         errorSymbols += "'" + data[2*s] + "', ";
        }
     }

   if(StringLen(errorSymbols) > 0)
      errorSymbols = "[" + StringSubstr(errorSymbols, 0, StringLen(errorSymbols)-2) + "]";

   if(StringLen(errorSymbols) == 0)
     {
      SendInfo("Successfully subscribed to bar data: " + dataStr);
      CheckBarData();
     }
   else
     {
      SendError("SUBSCRIBE_BAR_DATA", "Could not subscribe to bar data for: " + errorSymbols);
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void GetHistoricData(string dataStr)
  {

   string sep = ",";
   ushort uSep = StringGetCharacter(sep, 0);
   string data[];
   int splits = StringSplit(dataStr, uSep, data);

   if(ArraySize(data) != 4)
     {
      SendError("HISTORIC_DATA_WRONG_FORMAT", "Wrong format for GET_HISTORIC_DATA command: " + dataStr);
      return;
     }

   string symbol = data[0];
   ENUM_TIMEFRAMES timeFrame = StringToTimeFrame(data[1]);
   datetime dateStart = (datetime)StringToInteger(data[2]);
   datetime dateEnd = (datetime)StringToInteger(data[3]);

   if(StringLen(symbol) == 0)
     {
      SendError("HISTORIC_DATA_SYMBOL", "Could not read symbol: " + dataStr);
      return;
     }

   if(!SymbolSelect(symbol, true))
     {
      SendError("HISTORIC_DATA_SELECT_SYMBOL", "Could not select symbol " + symbol + " in market watch. Error: " + ErrorDescription(GetLastError()));
     }

   if(openChartsForHistoricData)
     {
      // if just opnened sleep to give MT4 some time to fetch the data.
      if(OpenChartIfNotOpen(symbol, timeFrame))
         Sleep(200);
     }

   MqlRates rates_array[];

// Get prices
   int rates_count = 0;

// Handling ERR_HISTORY_WILL_UPDATED (4066) and ERR_NO_HISTORY_DATA (4073) errors.
// For non-chart symbols and time frames MT4 often needs a few requests until the data is available.
// But even after 10 requests it can happen that it is not available. So it is best to have the charts open.
   for(int i=0; i<10; i++)
     {
      // if (numBars > 0)
      //    rates_count = CopyRates(symbol, timeFrame, startPos, numBars, rates_array);
      rates_count = CopyRates(symbol, timeFrame, dateStart, dateEnd, rates_array);
      int errorCode = GetLastError();
      // Print("errorCode: ", errorCode);
      if(rates_count > 0 || (errorCode != 4066 && errorCode != 4073))
         break;
      Sleep(200);
     }

   if(rates_count <= 0)
     {
      SendError("HISTORIC_DATA", "Could not get historic data for " + symbol + "_" + data[1] + ": " + ErrorDescription(GetLastError()));
      return;
     }

   bool first = true;
   string text = "{\"" + symbol + "_" + TimeFrameToString(timeFrame) + "\": {";

   for(int i=0; i<rates_count; i++)
     {

      if(first)
        {
         double daysDifference = ((double)MathAbs(rates_array[i].time - dateStart)) / (24 * 60 * 60);
         if((timeFrame == PERIOD_MN1 && daysDifference > 33) || (timeFrame == PERIOD_W1 && daysDifference > 10) || (timeFrame < PERIOD_W1 && daysDifference > 3))
           {
            SendInfo(StringFormat("The difference between requested start date and returned start date is relatively large (%.1f days). Maybe the data is not available on MetaTrader.", daysDifference));
           }
         // Print(dateStart, " | ", rates_array[i].time, " | ", daysDifference);
        }
      else
        {
         text += ", ";
        }

      // maybe use integer instead of time string? IntegerToString(rates_array[i].time)
      text += StringFormat("\"%s\": {\"open\": %.5f, \"high\": %.5f, \"low\": %.5f, \"close\": %.5f, \"tick_volume\": %.5f}",
                           TimeToString(rates_array[i].time),
                           rates_array[i].open,
                           rates_array[i].high,
                           rates_array[i].low,
                           rates_array[i].close,
                           rates_array[i].tick_volume);

      first = false;
     }

   text += "}}";
   for(int i=0; i<5; i++)
     {
      if(WriteToFile(filePathHistoricData, text))
         break;
      Sleep(100);
     }
   SendInfo(StringFormat("Successfully read historic data for %s_%s.", symbol, data[1]));
  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckMarketData()
  {

   bool first = true;
   string text = "{";
   for(int i=0; i<ArraySize(MarketDataSymbols); i++)
     {

      MqlTick lastTick;

      if(SymbolInfoTick(MarketDataSymbols[i], lastTick))
        {

         if(!first)
            text += ", ";

         text += StringFormat("\"%s\": {\"bid\": %.5f, \"bf1\": %.5f, \"bf2\": %.5f, \"bf3\": %.5f, \"bf4\": %.5f, \"bf5\": %.5f, \"ask\": %.5f, \"af1\": %.5f, \"af2\": %.5f, \"af3\": %.5f, \"af4\": %.5f, \"af5\": %.5f, \"tick_value\": %.5f}",
                              MarketDataSymbols[i],
                              SymbolInfoDouble(Symbol(),SYMBOL_BID),
                              FBm[0]-SymbolInfoDouble(Symbol(),SYMBOL_BID),
                              FBm2[0]-SymbolInfoDouble(Symbol(),SYMBOL_BID),
                              FBm3[0]-SymbolInfoDouble(Symbol(),SYMBOL_BID),
                              FBm4[0]-SymbolInfoDouble(Symbol(),SYMBOL_BID),
                              FBm5[0]-SymbolInfoDouble(Symbol(),SYMBOL_BID),
                              SymbolInfoDouble(Symbol(),SYMBOL_ASK),
                              FAm[0]-SymbolInfoDouble(Symbol(),SYMBOL_ASK),
                              FAm2[0]-SymbolInfoDouble(Symbol(),SYMBOL_ASK),
                              FAm3[0]-SymbolInfoDouble(Symbol(),SYMBOL_ASK),
                              FAm4[0]-SymbolInfoDouble(Symbol(),SYMBOL_ASK),
                              FAm5[0]-SymbolInfoDouble(Symbol(),SYMBOL_ASK),
                              SymbolInfoDouble(MarketDataSymbols[i], SYMBOL_TRADE_TICK_VALUE));

         first = false;
        }
      else
        {
         // text += "{\"symbol\": \"" + MarketDataSymbols[i] + "\", \"bid\": \"ERROR\", \"ask\": \"ERROR\"}";
         SendError("GET_BID_ASK", "Could not get bid/ask for " + MarketDataSymbols[i] + ". Last error: " + ErrorDescription(GetLastError()));
        }
     }

   text += "}";

// only write to file if there was a change.
   if(text == lastMarketDataText)
      return;



   if(WriteToFile(filePathMarketData, text))
     {
      lastMarketDataText = text;
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckBarData()
  {

// Python clients can also subscribe to a rates feed for each tracked instrument

   bool newData = false;
   string text = "{";

   for(int s = 0; s < ArraySize(BarDataInstruments); s++)
     {

      MqlRates curr_rate[];

      int count = BarDataInstruments[s].GetRates(curr_rate, 1);
      // if last rate is returned and its timestamp is greater than the last published...
      if(count > 0 && curr_rate[0].time > BarDataInstruments[s].getLastPublishTimestamp())
        {

         string rates = StringFormat("\"%s\": {\"time\": \"%s\", \"open\": %f, \"high\": %f, \"low\": %f, \"close\": %f, \"tick_volume\":%d}, ",
                                     BarDataInstruments[s].name(),
                                     TimeToString(curr_rate[0].time),
                                     curr_rate[0].open,
                                     curr_rate[0].high,
                                     curr_rate[0].low,
                                     curr_rate[0].close,
                                     curr_rate[0].tick_volume);
         text += rates;
         newData = true;

         // updates the timestamp
         BarDataInstruments[s].setLastPublishTimestamp(curr_rate[0].time);

        }
     }
   if(!newData)
      return;

   text = StringSubstr(text, 0, StringLen(text)-2) + "}";
   for(int i=0; i<5; i++)
     {
      if(WriteToFile(filePathBarData, text))
         break;
      Sleep(100);
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_TIMEFRAMES StringToTimeFrame(string tf)
  {
// Standard timeframes
   if(tf == "M1")
      return PERIOD_M1;
   if(tf == "M5")
      return PERIOD_M5;
   if(tf == "M15")
      return PERIOD_M15;
   if(tf == "M30")
      return PERIOD_M30;
   if(tf == "H1")
      return PERIOD_H1;
   if(tf == "H4")
      return PERIOD_H4;
   if(tf == "D1")
      return PERIOD_D1;
   if(tf == "W1")
      return PERIOD_W1;
   if(tf == "MN1")
      return PERIOD_MN1;
   return -1;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string TimeFrameToString(ENUM_TIMEFRAMES tf)
  {
// Standard timeframes
   switch(tf)
     {
      case PERIOD_M1:
         return "M1";
      case PERIOD_M5:
         return "M5";
      case PERIOD_M15:
         return "M15";
      case PERIOD_M30:
         return "M30";
      case PERIOD_H1:
         return "H1";
      case PERIOD_H4:
         return "H4";
      case PERIOD_D1:
         return "D1";
      case PERIOD_W1:
         return "W1";
      case PERIOD_MN1:
         return "MN1";
      default:
         return "UNKNOWN";
     }
  }


// counts the number of orders with a given magic number. currently not used.
int NumOpenOrdersWithMagic(int magic)
  {
   int n = 0;
   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket) || PositionGetInteger(POSITION_MAGIC) != magic)
         continue;
      n++;
     }
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      ulong ticket = OrderGetTicket(i);
      if(!OrderSelect(ticket) || OrderGetInteger(ORDER_MAGIC) != magic)
         continue;
      n++;
     }
   return n;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckOpenOrders()
  {

   bool first = true;
   string text = StringFormat("{\"account_info\": {\"name\": \"%s\", \"number\": %d, \"currency\": \"%s\", \"leverage\": %d, \"free_margin\": %f, \"balance\": %f, \"equity\": %f}, \"orders\": {",
                              AccountInfoString(ACCOUNT_NAME), AccountInfoInteger(ACCOUNT_LOGIN), AccountInfoString(ACCOUNT_CURRENCY), AccountInfoInteger(ACCOUNT_LEVERAGE), AccountInfoDouble(ACCOUNT_MARGIN_FREE), AccountInfoDouble(ACCOUNT_BALANCE), AccountInfoDouble(ACCOUNT_EQUITY));

   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket))
         continue;

      if(!first)
         text += ", ";

      // , \"commission\": %.2f
      text += StringFormat("\"%d\": {\"magic\": %d, \"symbol\": \"%s\", \"lots\": %.2f, \"type\": \"%s\", \"open_price\": %.5f, \"open_time\": \"%s\", \"SL\": %.5f, \"TP\": %.5f, \"pnl\": %.2f, \"swap\": %.2f, \"comment\": \"%s\"}",
                           ticket,
                           PositionGetInteger(POSITION_MAGIC),
                           PositionGetString(POSITION_SYMBOL),
                           PositionGetDouble(POSITION_VOLUME),
                           OrderTypeToString((int)PositionGetInteger(POSITION_TYPE)),
                           PositionGetDouble(POSITION_PRICE_OPEN),
                           TimeToString(PositionGetInteger(POSITION_TIME), TIME_DATE|TIME_SECONDS),
                           PositionGetDouble(POSITION_SL),
                           PositionGetDouble(POSITION_TP),
                           PositionGetDouble(POSITION_PROFIT),
                           // PositionGetDouble(POSITION_COMMISSION),  // commission only exists for deals DEAL_COMMISSION.
                           PositionGetDouble(POSITION_SWAP),
                           PositionGetString(POSITION_COMMENT));

      first = false;
     }

   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      ulong ticket = OrderGetTicket(i);
      if(!OrderSelect(ticket))
         continue;

      if(!first)
         text += ", ";

      text += StringFormat("\"%d\": {\"magic\": %d, \"symbol\": \"%s\", \"lots\": %.2f, \"type\": \"%s\", \"open_price\": %.5f, \"open_time\": \"%s\", \"SL\": %.5f, \"TP\": %.5f, \"pnl\": %.2f, \"swap\": %.2f, \"comment\": \"%s\"}",
                           ticket,
                           OrderGetInteger(ORDER_MAGIC),
                           OrderGetString(ORDER_SYMBOL),
                           OrderGetDouble(ORDER_VOLUME_CURRENT),
                           OrderTypeToString((int)OrderGetInteger(ORDER_TYPE)),
                           OrderGetDouble(ORDER_PRICE_OPEN),
                           TimeToString(OrderGetInteger(ORDER_TIME_SETUP), TIME_DATE|TIME_SECONDS),
                           OrderGetDouble(ORDER_SL),
                           OrderGetDouble(ORDER_TP),
                           0,  // there is no profit for orders, but we still want to keep the same format for all.
                           // OrderGetDouble(ORDER_COMMISSION),  // commission only exists for deals DEAL_COMMISSION.
                           0,  // there is no swap for orders, but we still want to keep the same format for all.
                           OrderGetString(ORDER_COMMENT));

      first = false;
     }
   text += "}}";

// if there are open positions, it will almost always be different because of open profit/loss.
// update at least once per second in case there was a problem during writing.
   if(text == lastOrderText && GetTickCount() < lastUpdateOrdersMillis + 1000)
      return;
   if(WriteToFile(filePathOrders, text))
     {
      lastUpdateOrdersMillis = GetTickCount();
      lastOrderText = text;
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool WriteToFile(string filePath, string text)
  {
   int handle = FileOpen(filePath, FILE_WRITE|FILE_TXT|FILE_ANSI);  // FILE_COMMON |
   if(handle == -1)
      return false;
// even an empty string writes two bytes (line break).
   uint numBytesWritten = FileWrite(handle, text);
   FileClose(handle);
   return numBytesWritten > 0;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SendError(string errorType, string errorDescription)
  {
   Print("ERROR: " + errorType + " | " + errorDescription);
   string message = StringFormat("{\"type\": \"ERROR\", \"time\": \"%s %s\", \"error_type\": \"%s\", \"description\": \"%s\"}",
                                 TimeToString(TimeGMT(), TIME_DATE), TimeToString(TimeGMT(), TIME_SECONDS), errorType, errorDescription);
   SendMessage(message);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SendInfo(string message)
  {
   Print("INFO: " + message);
   message = StringFormat("{\"type\": \"INFO\", \"time\": \"%s %s\", \"message\": \"%s\"}",
                          TimeToString(TimeGMT(), TIME_DATE), TimeToString(TimeGMT(), TIME_SECONDS), message);
   SendMessage(message);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SendMessage(string message)
  {

   for(int i=ArraySize(lastMessages)-1; i>=1; i--)
     {
      lastMessages[i] = lastMessages[i-1];
     }

   lastMessages[0].millis = GetTickCount();
// to make sure that every message has a unique number.
   if(lastMessages[0].millis <= lastMessageMillis)
      lastMessages[0].millis = lastMessageMillis+1;
   lastMessageMillis = lastMessages[0].millis;
   lastMessages[0].message = message;

   bool first = true;
   string text = "{";
   for(int i=ArraySize(lastMessages)-1; i>=0; i--)
     {
      if(StringLen(lastMessages[i].message) == 0)
         continue;
      if(!first)
         text += ", ";
      text += "\"" + IntegerToString(lastMessages[i].millis) + "\": " + lastMessages[i].message;
      first = false;
     }
   text += "}";

   if(text == lastMessageText)
      return;
   if(WriteToFile(filePathMessages, text))
      lastMessageText = text;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool OpenChartIfNotOpen(string symbol, ENUM_TIMEFRAMES timeFrame)
  {

// long currentChartID = ChartID();
   long chartID = ChartFirst();

   for(int i=0; i<maxNumberOfCharts; i++)
     {
      if(StringLen(ChartSymbol(chartID)) > 0)
        {
         if(ChartSymbol(chartID) == symbol && ChartPeriod(chartID) == timeFrame)
           {
            Print(StringFormat("Chart already open (%s, %s).", symbol, TimeFrameToString(timeFrame)));
            return false;
           }
        }
      chartID = ChartNext(chartID);
      if(chartID == -1)
         break;
     }
// open chart if not yet opened.
   long id = ChartOpen(symbol, timeFrame);
   if(id > 0)
     {
      Print(StringFormat("Chart opened (%s, %s).", symbol, TimeFrameToString(timeFrame)));
      return true;
     }
   else
     {
      SendError("OPEN_CHART", StringFormat("Could not open chart (%s, %s).", symbol, TimeFrameToString(timeFrame)));
      return false;
     }
  }


// use string so that we can have the same in MT5.
string OrderTypeToString(int orderType)
  {
   if(orderType == POSITION_TYPE_BUY)
      return "buy";
   if(orderType == POSITION_TYPE_SELL)
      return "sell";
   if(orderType == ORDER_TYPE_BUY_LIMIT)
      return "buylimit";
   if(orderType == ORDER_TYPE_SELL_LIMIT)
      return "selllimit";
   if(orderType == ORDER_TYPE_BUY_STOP)
      return "buystop";
   if(orderType == ORDER_TYPE_SELL_STOP)
      return "sellstop";
   return "unknown";
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int StringToOrderType(string orderTypeStr)
  {
   if(orderTypeStr == "buy")
      return POSITION_TYPE_BUY;
   if(orderTypeStr == "sell")
      return POSITION_TYPE_SELL;
   if(orderTypeStr == "buylimit")
      return ORDER_TYPE_BUY_LIMIT;
   if(orderTypeStr == "selllimit")
      return ORDER_TYPE_SELL_LIMIT;
   if(orderTypeStr == "buystop")
      return ORDER_TYPE_BUY_STOP;
   if(orderTypeStr == "sellstop")
      return ORDER_TYPE_SELL_STOP;
   return -1;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ResetFolder()
  {
//FolderDelete(folderName);  // does not always work.
   FolderCreate(folderName);
   FileDelete(filePathMarketData);
   FileDelete(filePathBarData);
   FileDelete(filePathHistoricData);
   FileDelete(filePathOrders);
   FileDelete(filePathMessages);
   for(int i=0; i<maxCommandFiles; i++)
     {
      FileDelete(filePathCommandsPrefix + IntegerToString(i) + ".txt");
     }
  }


// todo: add a list of error descriptions for MT5.
string ErrorDescription(int errorCode)
  {
   return "ErrorCode: " + IntegerToString(errorCode);
  }


MqlTick tick;
double bid(string symbol)
  {
   if(SymbolInfoTick(symbol, tick))
      return tick.bid;
   return SymbolInfoDouble(symbol, SYMBOL_BID);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double ask(string symbol)
  {
   if(SymbolInfoTick(symbol, tick))
      return tick.ask;
   return SymbolInfoDouble(symbol, SYMBOL_ASK);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void printArray(string &arr[])
  {
   if(ArraySize(arr) == 0)
      Print("{}");
   string printStr = "{";
   int i;
   for(i=0; i<ArraySize(arr); i++)
     {
      if(i == ArraySize(arr)-1)
         printStr += arr[i];
      else
         printStr += arr[i] + ", ";
     }
   Print(printStr + "}");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CopyArr()
  {
   ArrayCopy(acopy,A,0,0,WHOLE_ARRAY);
   ArrayCopy(bcopy,B,0,0,WHOLE_ARRAY);
   ArrayRemove(acopy,0,1);
   ArrayRemove(bcopy,0,1);

   ArrayCopy(acopy2,A2,0,0,WHOLE_ARRAY);
   ArrayCopy(bcopy2,B2,0,0,WHOLE_ARRAY);
   ArrayRemove(acopy2,0,1);
   ArrayRemove(bcopy2,0,1);

   ArrayCopy(acopy3,A3,0,0,WHOLE_ARRAY);
   ArrayCopy(bcopy3,B3,0,0,WHOLE_ARRAY);
   ArrayRemove(acopy3,0,1);
   ArrayRemove(bcopy3,0,1);

   ArrayCopy(acopy4,A4,0,0,WHOLE_ARRAY);
   ArrayCopy(bcopy4,B4,0,0,WHOLE_ARRAY);
   ArrayRemove(acopy4,0,1);
   ArrayRemove(bcopy4,0,1);

   ArrayCopy(acopy5,A5,0,0,WHOLE_ARRAY);
   ArrayCopy(bcopy5,B5,0,0,WHOLE_ARRAY);
   ArrayRemove(acopy5,0,1);
   ArrayRemove(bcopy5,0,1);


   ArrayCopy(Cweight1,weight1,0,0,WHOLE_ARRAY);
   ArrayCopy(Cweight2,weight2,0,0,WHOLE_ARRAY);
   ArrayCopy(Cweight3,weight3,0,0,WHOLE_ARRAY);
   ArrayCopy(Cweight4,weight4,0,0,WHOLE_ARRAY);
   ArrayCopy(Cweight5,weight5,0,0,WHOLE_ARRAY);

   ArrayCopy(faweight1,aweight1,0,0,WHOLE_ARRAY);
   ArrayCopy(faweight2,aweight2,0,0,WHOLE_ARRAY);
   ArrayCopy(faweight3,aweight3,0,0,WHOLE_ARRAY);
   ArrayCopy(faweight4,aweight4,0,0,WHOLE_ARRAY);
   ArrayCopy(faweight5,aweight5,0,0,WHOLE_ARRAY);

   ArrayCopy(fbweight1,bweight1,0,0,WHOLE_ARRAY);
   ArrayCopy(fbweight2,bweight2,0,0,WHOLE_ARRAY);
   ArrayCopy(fbweight3,bweight3,0,0,WHOLE_ARRAY);
   ArrayCopy(fbweight4,bweight4,0,0,WHOLE_ARRAY);
   ArrayCopy(fbweight5,bweight5,0,0,WHOLE_ARRAY);


   ArrayRemove(Cweight1,ArrayRange(weight1,0)-1,1);
   ArrayRemove(Cweight2,ArrayRange(weight2,0)-1,1);
   ArrayRemove(Cweight3,ArrayRange(weight3,0)-1,1);
   ArrayRemove(Cweight4,ArrayRange(weight4,0)-1,1);
   ArrayRemove(Cweight5,ArrayRange(weight5,0)-1,1);

   ArrayRemove(faweight1,ArrayRange(aweight1,0)-1,1);
   ArrayRemove(faweight2,ArrayRange(aweight2,0)-1,1);
   ArrayRemove(faweight3,ArrayRange(aweight3,0)-1,1);
   ArrayRemove(faweight4,ArrayRange(aweight4,0)-1,1);
   ArrayRemove(faweight5,ArrayRange(aweight5,0)-1,1);

   ArrayRemove(fbweight1,ArrayRange(bweight1,0)-1,1);
   ArrayRemove(fbweight2,ArrayRange(bweight2,0)-1,1);
   ArrayRemove(fbweight3,ArrayRange(bweight3,0)-1,1);
   ArrayRemove(fbweight4,ArrayRange(bweight4,0)-1,1);
   ArrayRemove(fbweight5,ArrayRange(bweight5,0)-1,1);
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
