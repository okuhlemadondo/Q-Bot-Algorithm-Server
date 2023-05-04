//+------------------------------------------------------------------+
//|                            Q-Bot Server [Volatility 75 (1s)].mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <Math\Stat\Math.mqh>
#include <Trade\Trade.mqh>
CTrade trade;

input int      number_of_ticks=1000;
input int      points_indent=10;
input int      PERIOD = 3000;
input int      PERIOD2 = 6000;
input int      PERIOD3 = 12000;
input int      PERIOD4 = 24000;
input int      PERIOD5 = 48000;
input double LOTSIZE = 15;
input double RATIO = 7;

double B[], A[], B1[], A1[], B2[], A2[], B3[], A3[], B4[], A4[], B5[], A5[];
double acopy[], bcopy[], acopy2[], bcopy2[], acopy3[], bcopy3[], acopy4[], bcopy4[], acopy5[], bcopy5[];
double Bm[], Am[], Bm2[], Am2[], Bm3[], Am3[], Bm4[], Am4[], Bm5[], Am5[];
double FBm[], FAm[], FBm2[], FAm2[], FBm3[], FAm3[], FBm4[], FAm4[], FBm5[], FAm5[];
double amcopy[], bmcopy[], amcopy2[], bmcopy2[], amcopy3[], bmcopy3[], amcopy4[], bmcopy4[], amcopy5[], bmcopy5[];
double weight1[], weight2[], weight3[], weight4[], weight5[];
double aweight1[], aweight2[], aweight3[], aweight4[], aweight5[];
double bweight1[], bweight2[], bweight3[], bweight4[], bweight5[];
double Cweight1[], Cweight2[], Cweight3[], Cweight4[], Cweight5[];
double faweight1[], faweight2[], faweight3[], faweight4[], faweight5[];
double fbweight1[], fbweight2[], fbweight3[], fbweight4[], fbweight5[];
double Amcomb1[], Amcomb2[], Amcomb3[], Amcomb4[], Amcomb5[], Bmcomb1[], Bmcomb2[], Bmcomb3[], Bmcomb4[], Bmcomb5[];
double fAmcomb1[], fAmcomb2[], fAmcomb3[], fAmcomb4[], fAmcomb5[], fBmcomb1[], fBmcomb2[], fBmcomb3[], fBmcomb4[], fBmcomb5[];

double e = PERIOD-50, e2 = PERIOD2-50, e3 = PERIOD3-50, e4 = PERIOD4-50, e5 = PERIOD5-50, f = -0.001;
int g = 4;
double p[5], q[5], r[5], s[5], t[5];
double buypow[3];
string SYM = "Volatility 75 (1s) Index";

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   ArrayResize(A1,PERIOD,0);
   ArrayResize(B1,PERIOD,0);
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

   ArrayResize(A,PERIOD5,0);
   ArrayResize(B,PERIOD5,0);
   
   ArrayResize(weight1,PERIOD+2,0);
   ArrayResize(weight2,PERIOD2+2,0);
   ArrayResize(weight3,PERIOD3+2,0);
   ArrayResize(weight4,PERIOD4+2,0);
   ArrayResize(weight5,PERIOD5+2,0);

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
//--
   return(INIT_SUCCEEDED);
  }
//+-----------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+-----------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
//---

   static int ticks=0;

   MqlTick last_tick;

   int timeSCALE = PERIOD, timeSCALE2 = PERIOD2, timeSCALE3 = PERIOD3, timeSCALE4 = PERIOD4, timeSCALE5 = PERIOD5;
   double per = PERIOD, per2 = PERIOD2, per3 = PERIOD3, per4 = PERIOD4, per5 = PERIOD5;
   double coeff1 = 10/per, coeff2 = 10/per2, coeff3 = 10/per3, coeff4 = 10/per4, coeff5 = 10/per5;
   
   //WEIGHT ARRAYS
   
   for(int i = 2; i < PERIOD+2; i++)
     {
      weight1[i] = (exp(1)-1)/(MathPow(exp(1),coeff1*i));
     }

   for(int i = 2; i < PERIOD2+2; i++)
     {
      weight2[i] = (exp(1)-1)/(MathPow(exp(1),coeff2*i));
     }

   for(int i = 2; i < PERIOD3+2; i++)
     {
      weight3[i] = (exp(1)-1)/(MathPow(exp(1),coeff3*i));
     }

   for(int i = 2; i < PERIOD4+2; i++)
     {
      weight4[i] = (exp(1)-1)/(MathPow(exp(1),coeff4*i));
     }

   for(int i = 2; i < PERIOD5+2; i++)
     {
      weight5[i] = (exp(1)-1)/(MathPow(exp(1),coeff5*i));
     }
     
   ArrayCopy(Cweight1,weight1,0,2,PERIOD);
   ArrayCopy(Cweight2,weight2,0,2,PERIOD2);
   ArrayCopy(Cweight3,weight3,0,2,PERIOD3);
   ArrayCopy(Cweight4,weight4,0,2,PERIOD4);
   ArrayCopy(Cweight5,weight5,0,2,PERIOD5);

   //TICK STORAGE ARRAYS
   
   for(int i = PERIOD5-1; i > 0; i--)
     {
      B[i] = B[i-1];
      A[i] = A[i-1];
      B[0] = SymbolInfoDouble(Symbol(),SYMBOL_BID);
      A[0] = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
     }
     
   ArrayCopy(A1,A,0,1,PERIOD);
   ArrayCopy(A2,A,0,1,PERIOD2);
   ArrayCopy(A3,A,0,1,PERIOD3);
   ArrayCopy(A4,A,0,1,PERIOD4);
   ArrayCopy(A5,A,0,1,PERIOD5);
   
   ArrayCopy(B1,B,0,1,PERIOD);
   ArrayCopy(B2,B,0,1,PERIOD2);
   ArrayCopy(B3,B,0,1,PERIOD3);
   ArrayCopy(B4,B,0,1,PERIOD4);
   ArrayCopy(B5,B,0,1,PERIOD5);
   
   double achange = A1[0]-A[2], bchange = B1[0]-B[2], spreadd = A1[0]-B1[0];
   
   //Multiplying each tick by the weights (a=ask; b=bid)
/*
   for(int i = PERIOD-2; i >= 0; i--)
     {
      Amcomb1[i] = A1[i]*Cweight1[i];
      Bmcomb1[i] = B1[i]*Cweight1[i];
     }

   for(int i = PERIOD2-2; i >= 1; i--)
     {
      Amcomb2[i] = A2[i]*Cweight2[i];
      Bmcomb2[i] = B2[i]*Cweight2[i];
     }

   for(int i = PERIOD3-2; i >= 1; i--)
     {
      Amcomb3[i] = A3[i]*Cweight3[i];
      Bmcomb3[i] = B3[i]*Cweight3[i];
     }

   for(int i = PERIOD4-2; i >= 1; i--)
     {
      Amcomb4[i] = A4[i]*Cweight4[i];
      Bmcomb4[i] = B4[i]*Cweight4[i];
     }

   for(int i = PERIOD5-2; i >= 1; i--)
     {
      Amcomb5[i] = A5[i]*Cweight5[i];
      Bmcomb5[i] = B5[i]*Cweight5[i];
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

   double da = A[0]-Am[0], da2 = A[0]-Am2[0], da3 = A[0]-Am3[0], da4 = A[0]-Am4[0], da5 = A[0]-Am5[0];
   double db = B[0]-Bm[0], db2 = B[0]-Bm2[0], db3 = B[0]-Bm3[0], db4 = B[0]-Bm4[0], db5 = B[0]-Bm5[0];

   double aper = PERIOD-((MathPow(exp(1),(f*MathPow(da,g))))/(1/e)), aper2 = PERIOD2-((MathPow(exp(1),(f*MathPow(da2,g))))/(1/e2));
   double aper3 = PERIOD3-((MathPow(exp(1),(f*MathPow(da3,g))))/(1/e3)), aper4 = PERIOD4-((MathPow(exp(1),(f*MathPow(da4,g))))/(1/e4));
   double aper5 = PERIOD5-((MathPow(exp(1),(f*MathPow(da5,g))))/(1/e5));
   
   double bper = PERIOD-((MathPow(exp(1),(f*MathPow(db,g))))/(1/e)), bper2 = PERIOD2-((MathPow(exp(1),(f*MathPow(db2,g))))/(1/e2));
   double bper3 = PERIOD3-((MathPow(exp(1),(f*MathPow(db3,g))))/(1/e3)), bper4 = PERIOD4-((MathPow(exp(1),(f*MathPow(db4,g))))/(1/e4));
   double bper5 = PERIOD5-((MathPow(exp(1),(f*MathPow(db5,g))))/(1/e5));

   double acoeff1 = 10/aper, acoeff2 = 10/aper2, acoeff3 = 10/aper3, acoeff4 = 10/aper4, acoeff5 = 10/aper5;
   double bcoeff1 = 10/bper, bcoeff2 = 10/bper2, bcoeff3 = 10/bper3, bcoeff4 = 10/bper4, bcoeff5 = 10/bper5;
   
   
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


   for(int i = 100; i > 0; i--)
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
*/
    ticks++;
    
   Print(ArraySize(weight1), " ",weight1[2]," ",ArraySize(weight3), " ",ArraySize(weight4)," ",ArraySize(weight5));
  }
