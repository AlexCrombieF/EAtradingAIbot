#property strict

#define NO_ERROR              1
#define AT_LEAST_ONE_FAILED   2

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum ModeStops
  {
   a = 1, //Stop all orders of this direction
   s = 2, //Carry on the basket till it will be closed
   n = 3, //Do not open new cranks anymore
  };
  
enum ModeClose
  {
   cldir  = 1, //Close orders of one direction
   all    = 2, //Close all orders
  }; 
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum Corner
  {
   left  = 0, //Left side
   right = 1, //Right side
  };

input  string Takeprofitsettings   = "Takeprofit settings -================";   //====================================-
extern int    Maintakeprofit       = 10;                                        //Take-profit value for orders/grid, pips.
extern bool   Useaverageprofit     = true;                                      //Use average take-profit
                                                                                //if you put false in previous parameter, next settings will not impact on take-profit
extern bool   Usedynamictakeprofit = true;                                      //Use dynamic take-profit
extern int    StepdynamicTP        = 3;                                         //Which crank starts dynamic take-profit
extern double K_TPDecrease         = 1;                                         //Take-profit multiplier
extern int    MinTakeProfit        = 1;                                         //Minimum value of take-profit
                                                                                //Breakeven is working only for Useaverageprofit=true
extern bool   Breakevenclose       = true;                                      //Put value of take-profit to breakeven
extern int    StepforBE            = 10;                                        //Which crank starts to use breakeven rule

input  string Stepsettings         = "step settings -======================";   //===============================- Grid
extern double FirstStep            = 20;                                        //The value of first step, pips
extern bool   Stepfromvolatility   = false;                                     //Calculation of the first step by volatility
extern int    PeriodVolatility_1   = 20;                                        //Amount of days for volatility calculation
extern double K_Stepvol            = 0.5;                                       //Multiplier for the first step 
extern bool   Dynamicstep          = true;                                      //Use dynamic grid step
extern int    Stepincreasestep     = 1;                                         //Which crank starts dynamic step
extern double K_Stepincrease       = 1;                                         //Step multiplier
extern int    Maxcountstepsbuy     = 10;                                        //Maximum amount of cranks in the buy basket
extern int    Maxcountstepsell     = 10;                                        //Maximum amount of cranks in the sell basket
extern int    Tick_Memory          = 100;                                       //Maximum amount of ticks cached
extern double Deviation            = 1.5;
extern bool   Neutralizer          = True;
extern double Pips_Threshold       = 100.0;
extern double Aux_Threshold        = 100.0;

input  string Volumesettings       = "orders volume -======================";   //========================- Settings of
extern bool   Money_Management     = true;
extern double Margin_Percent       = 2.0;
extern double Lot_Size             = 0.01;                                      //Lots amount for first order in grid
extern double Multiplier           = 2;                                         //Volume multiplier
extern int    Multipusestep        = 1;                                         //Which crank starts apply volume multiplier

input  string FirstOrderSettings   = "for the first order -================";   //=======- Settings of entry conditions
extern bool   CCIFiltre            = true;                                      //Use CCI-indicator for entry
extern int    Period_CCI           = 50;                                        //Period CCI on the current chart

input  string ManuallySettings     = "manual intervention -================";   //=======================- Settings for
extern bool   Allowbuy             = true;                                      //Permission for buy orders
extern bool   Allowsell            = true;                                      //Permission for sell orders
extern ModeStops Stopmode_2        = s;                                         //Variant of orders stops
extern bool   StopTradesLevel      = false;                                     //Stop trading after crossing of critical level
extern ModeStops Stopmode_3        = s;                                         //Variant of order stops after crossing of critical levels
extern double BuyStopLevel         = 0;                                         //Critical levels for stop of buy orders
extern double SellStopLevel        = 0;                                         //Critical levels for stop of sell orders
                                                                                //parameters below do not impact on the first order in the basket
extern double ManualstepBuy        = 0;                                         //Forced basket step size for buy orders
extern double ManuallotBuy         = 0;                                         //Forced orders lot for the next buy orders
extern double ManualstepSell       = 0;                                         //Forced basket step size for sell orders
extern double ManuallotSell        = 0;                                         //Forced orders lot for the next sell orders

input  string Exitvolatility       = "increment of volatility -============";   //===================- Exit settings by
extern bool   Usefiltrevolat       = true;                                      //Use the volatility filter
extern int    Periodvolatility_2   = 20;                                        //Period for volatility calculation
extern double Lineofvolatility     = 1;                                         //Multiplier for critical volatility
extern ModeClose Stopmode_4        = all;                                       //Variant for orders closing

input  string AdditionalSettings   = "settings -===========================";   //=========================- Additional
extern int    Magic_Buy            = 8989;                                      //Advisor Buy Magic number
extern int    Magic_Sell           = 8990;                                      //Advisor Sell Magic number
extern int    Magic_Aux            = 8991;                                      //Advisor Aux Magic number
extern bool   ECNflag              = false;                                     //Flag for ECN accounts
extern int    Slippage             = 3;                                         //Pips slippage
extern int    Retry                = 5;

input  string InfoPanelSettings    = "panel settings -=====================";   //========================- Information
extern bool   Showinfopanel        = true;                                      //Show info-panel
extern Corner Side                 = right;                                     //Info-panel location on the chart
extern color  Textcolor            = clrNavy;                                   //Info-panel text color
extern color  Backgroundcolor      = clrGainsboro;                              //Info-panel background color
extern bool   Showcriticallevels   = true;                                      //"Show the critical levels
extern color  Levelscolorbuy       = clrMediumBlue;                             //Critical level line color for buy orders
extern color  Levelscolorsell      = clrOrangeRed;                              //Critical level line color for sell orders

int MaxPos=Maxcountstepsbuy;

datetime lastopentime;
double CCI_1,CCI_2,lastbuyprice,lastsellprice,step,nextlot,lastTP;
bool check,AlertMaxStepsBuy=false,AlertMaxStepsSell=false,AllowafterlevelBuy=true,AllowafterlevelSell=true,Flagsellinfo=false,Flagbuyinfo=false,
MarginAgreed=true,Popupmargininfobuy=false,Popupmargininfosell=false,Stoptrading=false,Allowbuylevel=true,Allowselllevel=true,Alertsellvolat=false,Alertbuyvolat=false;
int ticket,lastticket;

// Input data for info-panel //
string currency           = Symbol();                               //Currency pair
double depositpercent     = 0;                                      //Percentage of the whole deposit
double depositvalue       = 0;                                      //Risk deposit
double depositloadpersent = 0;                                      //Current risk deposit load
double firstorderlot      = 0;                                      //Volume of the first orders.

string allowbuy           = "";                                     //Buy orders are allowed
int    currentstepbuy     = 0;                                      //Current crank for buy basket
double sumlotbuy          = 0;                                      //Total volume of buy orders, lots
int    maxstepsbuy        = Maxcountstepsbuy;                       //Accepted crank amount for buy orders
double buybasketprofit    = 0;                                      //Total profit of opened buy orders
double buystepvalue       = 0;                                      //Current grid step
double nextpricebuy       = 0;                                      //Next order open price
double nextlotbuy         = 0;                                      //Volume of the next buy order

string allowsell          = "";                                     //Sell orders are allowed
int    currentstepsell    = 0;                                      //Current crank for sell basket
double sumlotsell         = 0;                                      //Total volume of sell orders, lots
int    maxstepssell       = Maxcountstepsell;                       //Accepted crank amount for sell orders
double sellbasketprofit   = 0;                                      //Total profit of opened sell orders
double sellstepvalue      = 0;                                      //Current grid step
double nextpricesell      = 0;                                      //Next order open price
double nextlotsell        = 0;                                      //Volume of the next sell order

//--

int Vektors_TF = 5;
int Stability_Period=5;
int Period_1=3;
int Period_2=14;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(Digits()==3 || Digits()==5)
     {
      Maintakeprofit *= 10;
      MinTakeProfit  *= 10;
      FirstStep      *= 10;
      Slippage       *= 10;
      ManualstepBuy  *= 10;
      ManualstepSell *= 10;
     }

   if(Maintakeprofit<=0)
      Alert("Wrong take-profit! It has to be more than zero!");
   if(FirstStep<=0 && (Stepfromvolatility==false || PeriodVolatility_1<=0 || K_Stepvol<=0))
      Alert("Wrong step parameters!!! All parameters for the first step have to be more than zero!");
   if(Usefiltrevolat==true && Periodvolatility_2<=0)
      Alert("Wrong parameters for exit with increment of volatility!! Multiplier has to be more than zero!");
   if(Lot_Size<=0)
      Alert("Wrong volume parameters!! Lot has to be more than zero!");
   if(CCIFiltre==true && Period_CCI<=1)
      Alert("Wrong period of CCI indicator!!!");
   if(Usedynamictakeprofit==true && (StepdynamicTP<=0 || K_TPDecrease<=0))
      Alert("Wrong parameters for dynamic take-profit!! Step and multiplier have to be more than zero!!");
   if(Multiplier<=0)
      Alert("Wrong volume multiplier!! It has to be more than zero!");

   if(Showcriticallevels==true) //Draw critical levels
     {
      if (BuyStopLevel>0)
        {
         ObjectCreate("StopBuyLevel",OBJ_HLINE,0,0,NormalizeDouble(BuyStopLevel,Digits()));
         ObjectSet("StopBuyLevel",OBJPROP_COLOR,Levelscolorbuy);
         ObjectSet("StopBuyLevel",OBJPROP_STYLE,STYLE_DASHDOTDOT);
         ObjectSet("StopBuyLevel",OBJPROP_WIDTH,1);
         ObjectSetText("StopBuyLevel","Critical level for BUY orders",8,"Calibri",clrBlack);
        }
        if (SellStopLevel>0)
        {
         ObjectCreate("StopSellLevel",OBJ_HLINE,0,0,NormalizeDouble(SellStopLevel,Digits()));
         ObjectSet("StopSellLevel",OBJPROP_COLOR,Levelscolorsell);
         ObjectSet("StopSellLevel",OBJPROP_STYLE,STYLE_DASHDOTDOT);
         ObjectSet("StopSellLevel",OBJPROP_WIDTH,1);
         ObjectSetText("StopSellLevel","Critical level for SELL orders",8,"Calibri",clrBlack);
        }
     }

   if(Showinfopanel==true)
     {
      ObjectCreate("Background",OBJ_LABEL,0,0,0);                        
      ObjectSetText("Background","g",160,"Webdings",Backgroundcolor);
      ObjectSet("Background",OBJPROP_CORNER,Side);
      ObjectSet("Background",OBJPROP_XDISTANCE,0);
      ObjectSet("Background",OBJPROP_YDISTANCE,20);

      ObjectCreate("Background_2",OBJ_LABEL,0,0,0);                        
      ObjectSetText("Background_2","g",160,"Webdings",Backgroundcolor);
      ObjectSet("Background_2",OBJPROP_CORNER,Side);
      ObjectSet("Background_2",OBJPROP_XDISTANCE,0);
      ObjectSet("Background_2",OBJPROP_YDISTANCE,315);
      
      ObjectCreate("Background_3",OBJ_LABEL,0,0,0);                        
      ObjectSetText("Background_3","g",160,"Webdings",Backgroundcolor);
      ObjectSet("Background_3",OBJPROP_CORNER,Side);
      ObjectSet("Background_3",OBJPROP_XDISTANCE,0);
      ObjectSet("Background_3",OBJPROP_YDISTANCE,150);

      ObjectCreate("Info_1",OBJ_LABEL,0,0,0);                              
      ObjectSetText("Info_1",currency+"   SyTurn",14,"Stencil",Textcolor);
      ObjectSet("Info_1",OBJPROP_CORNER,Side);
      ObjectSet("Info_1",OBJPROP_XDISTANCE,15);
      ObjectSet("Info_1",OBJPROP_YDISTANCE,30);

      ObjectCreate("Info_2",OBJ_LABEL,0,0,0);
      ObjectSetText("Info_2","________________",14,"Arial",Textcolor);
      ObjectSet("Info_2",OBJPROP_CORNER,Side);
      ObjectSet("Info_2",OBJPROP_XDISTANCE,9);
      ObjectSet("Info_2",OBJPROP_YDISTANCE,32);

      ObjectCreate("Info_3",OBJ_LABEL,0,0,0);
      ObjectSetText("Info_3","Power:  ",10,"Calibri",Textcolor);
      ObjectSet("Info_3",OBJPROP_CORNER,Side);
      ObjectSet("Info_3",OBJPROP_XDISTANCE,10);
      ObjectSet("Info_3",OBJPROP_YDISTANCE,60);

      ObjectCreate("Info_4",OBJ_LABEL,0,0,0);
      ObjectSetText("Info_4","Neutralizer BUY:  OFF",10,"Calibri",Textcolor);
      ObjectSet("Info_4",OBJPROP_CORNER,Side);
      ObjectSet("Info_4",OBJPROP_XDISTANCE,10);
      ObjectSet("Info_4",OBJPROP_YDISTANCE,80);

      ObjectCreate("Info_5",OBJ_LABEL,0,0,0);
      ObjectSetText("Info_5","Neutralizer SELL:  OFF",10,"Calibri",Textcolor);
      ObjectSet("Info_5",OBJPROP_CORNER,Side);
      ObjectSet("Info_5",OBJPROP_XDISTANCE,10);
      ObjectSet("Info_5",OBJPROP_YDISTANCE,100);

      firstorderlot=Findfirstordervolume();
      ObjectCreate("Info_6",OBJ_LABEL,0,0,0);
      ObjectSetText("Info_6","First orders volume:  "+DoubleToString(firstorderlot,2),10,"Calibri",Textcolor);
      ObjectSet("Info_6",OBJPROP_CORNER,Side);
      ObjectSet("Info_6",OBJPROP_XDISTANCE,10);
      ObjectSet("Info_6",OBJPROP_YDISTANCE,120);

      ObjectCreate("Info_7",OBJ_LABEL,0,0,0);
      ObjectSetText("Info_7","________________",14,"Arial",Textcolor);
      ObjectSet("Info_7",OBJPROP_CORNER,Side);
      ObjectSet("Info_7",OBJPROP_XDISTANCE,9);
      ObjectSet("Info_7",OBJPROP_YDISTANCE,120);

      ObjectCreate("Info_8",OBJ_LABEL,0,0,0);
      ObjectSetText("Info_8","BUY BASKET PARAMETERS",8,"Arial Black",Textcolor);
      ObjectSet("Info_8",OBJPROP_CORNER,Side);
      ObjectSet("Info_8",OBJPROP_XDISTANCE,10);
      ObjectSet("Info_8",OBJPROP_YDISTANCE,150);

      if(Allowbuy==false)
        {
         switch(Stopmode_2)
           {
            case a: allowbuy = "Buy orders are forbidden!"; break;
            case s: allowbuy = "New baskets are forbidden!"; break;
            case n: allowbuy = "New crank is forbidden!"; break;
           }
        }
      else allowbuy="Buy orders are allowed!";

      ObjectCreate("Info_9",OBJ_LABEL,0,0,0);
      ObjectSetText("Info_9",allowbuy,10,"Calibri",Textcolor);
      ObjectSet("Info_9",OBJPROP_CORNER,Side);
      ObjectSet("Info_9",OBJPROP_XDISTANCE,10);
      ObjectSet("Info_9",OBJPROP_YDISTANCE,170);

      ObjectCreate("Info_10",OBJ_LABEL,0,0,0);
      ObjectSetText("Info_10","Current crank: "+DoubleToString(currentstepbuy,0),10,"Calibri",Textcolor);
      ObjectSet("Info_10",OBJPROP_CORNER,Side);
      ObjectSet("Info_10",OBJPROP_XDISTANCE,10);
      ObjectSet("Info_10",OBJPROP_YDISTANCE,190);

      ObjectCreate("Info_11",OBJ_LABEL,0,0,0);
      ObjectSetText("Info_11","Total volume, lots: "+DoubleToString(sumlotbuy,2),10,"Calibri",Textcolor);
      ObjectSet("Info_11",OBJPROP_CORNER,Side);
      ObjectSet("Info_11",OBJPROP_XDISTANCE,10);
      ObjectSet("Info_11",OBJPROP_YDISTANCE,210);

      ObjectCreate("Info_12",OBJ_LABEL,0,0,0);
      ObjectSetText("Info_12","Accepted cranks amount: "+IntegerToString(maxstepsbuy),10,"Calibri",Textcolor);
      ObjectSet("Info_12",OBJPROP_CORNER,Side);
      ObjectSet("Info_12",OBJPROP_XDISTANCE,10);
      ObjectSet("Info_12",OBJPROP_YDISTANCE,230);

      ObjectCreate("Info_13",OBJ_LABEL,0,0,0);
      ObjectSetText("Info_13","Total profit of opened: "+DoubleToString(buybasketprofit,1),10,"Calibri",Textcolor);
      ObjectSet("Info_13",OBJPROP_CORNER,Side);
      ObjectSet("Info_13",OBJPROP_XDISTANCE,10);
      ObjectSet("Info_13",OBJPROP_YDISTANCE,250);

      ObjectCreate("Info_14",OBJ_LABEL,0,0,0);
      ObjectSetText("Info_14","Current grid step: "+DoubleToString(buystepvalue,1)+"p.",10,"Calibri",Textcolor);
      ObjectSet("Info_14",OBJPROP_CORNER,Side);
      ObjectSet("Info_14",OBJPROP_XDISTANCE,10);
      ObjectSet("Info_14",OBJPROP_YDISTANCE,270);

      ObjectCreate("Info_15",OBJ_LABEL,0,0,0);
      ObjectSetText("Info_15","Next order open price: "+DoubleToString(nextpricebuy,Digits()),10,"Calibri",Textcolor);
      ObjectSet("Info_15",OBJPROP_CORNER,Side);
      ObjectSet("Info_15",OBJPROP_XDISTANCE,10);
      ObjectSet("Info_15",OBJPROP_YDISTANCE,290);

      ObjectCreate("Info_16",OBJ_LABEL,0,0,0);
      ObjectSetText("Info_16","Next order volume: "+DoubleToString(nextlotbuy,2),10,"Calibri",Textcolor);
      ObjectSet("Info_16",OBJPROP_CORNER,Side);
      ObjectSet("Info_16",OBJPROP_XDISTANCE,10);
      ObjectSet("Info_16",OBJPROP_YDISTANCE,310);

      ObjectCreate("Info_17",OBJ_LABEL,0,0,0);
      ObjectSetText("Info_17","________________",14,"Arial",Textcolor);
      ObjectSet("Info_17",OBJPROP_CORNER,Side);
      ObjectSet("Info_17",OBJPROP_XDISTANCE,9);
      ObjectSet("Info_17",OBJPROP_YDISTANCE,310);

      ObjectCreate("Info_18",OBJ_LABEL,0,0,0);
      ObjectSetText("Info_18","SELL BASKET PARAMETERS",8,"Arial Black",Textcolor);
      ObjectSet("Info_18",OBJPROP_CORNER,Side);
      ObjectSet("Info_18",OBJPROP_XDISTANCE,10);
      ObjectSet("Info_18",OBJPROP_YDISTANCE,340);

      if(Allowsell==false)
        {
         switch(Stopmode_2)
           {
            case a: allowsell = "Sell orders are forbidden!"; break;
            case s: allowsell = "New baskets are forbidden!"; break;
            case n: allowsell = "New crank is forbidden!"; break;
           }
        }
      else allowsell="Sell orders are allowed!";

      ObjectCreate("Info_19",OBJ_LABEL,0,0,0);
      ObjectSetText("Info_19",allowsell,10,"Calibri",Textcolor);
      ObjectSet("Info_19",OBJPROP_CORNER,Side);
      ObjectSet("Info_19",OBJPROP_XDISTANCE,10);
      ObjectSet("Info_19",OBJPROP_YDISTANCE,360);

      ObjectCreate("Info_20",OBJ_LABEL,0,0,0);
      ObjectSetText("Info_20","Current crank: "+DoubleToString(currentstepsell,0),10,"Calibri",Textcolor);
      ObjectSet("Info_20",OBJPROP_CORNER,Side);
      ObjectSet("Info_20",OBJPROP_XDISTANCE,10);
      ObjectSet("Info_20",OBJPROP_YDISTANCE,380);

      ObjectCreate("Info_21",OBJ_LABEL,0,0,0);
      ObjectSetText("Info_21","Total volume, lots: "+DoubleToString(sumlotsell,2),10,"Calibri",Textcolor);
      ObjectSet("Info_21",OBJPROP_CORNER,Side);
      ObjectSet("Info_21",OBJPROP_XDISTANCE,10);
      ObjectSet("Info_21",OBJPROP_YDISTANCE,400);

      ObjectCreate("Info_22",OBJ_LABEL,0,0,0);
      ObjectSetText("Info_22","Accepted cranks amount: "+IntegerToString(maxstepssell),10,"Calibri",Textcolor);
      ObjectSet("Info_22",OBJPROP_CORNER,Side);
      ObjectSet("Info_22",OBJPROP_XDISTANCE,10);
      ObjectSet("Info_22",OBJPROP_YDISTANCE,420);

      ObjectCreate("Info_23",OBJ_LABEL,0,0,0);
      ObjectSetText("Info_23","Total profit opened: "+DoubleToString(sellbasketprofit,1),10,"Calibri",Textcolor);
      ObjectSet("Info_23",OBJPROP_CORNER,Side);
      ObjectSet("Info_23",OBJPROP_XDISTANCE,10);
      ObjectSet("Info_23",OBJPROP_YDISTANCE,440);

      ObjectCreate("Info_24",OBJ_LABEL,0,0,0);
      ObjectSetText("Info_24","Current grid step: "+DoubleToString(sellstepvalue,1)+"p.",10,"Calibri",Textcolor);
      ObjectSet("Info_24",OBJPROP_CORNER,Side);
      ObjectSet("Info_24",OBJPROP_XDISTANCE,10);
      ObjectSet("Info_24",OBJPROP_YDISTANCE,460);

      ObjectCreate("Info_25",OBJ_LABEL,0,0,0);
      ObjectSetText("Info_25","Next order open price: "+DoubleToString(nextpricesell,Digits()),10,"Calibri",Textcolor);
      ObjectSet("Info_25",OBJPROP_CORNER,Side);
      ObjectSet("Info_25",OBJPROP_XDISTANCE,10);
      ObjectSet("Info_25",OBJPROP_YDISTANCE,480);

      ObjectCreate("Info_26",OBJ_LABEL,0,0,0);
      ObjectSetText("Info_26","Next order volume: "+DoubleToString(nextlotsell,2),10,"Calibri",Textcolor);
      ObjectSet("Info_26",OBJPROP_CORNER,Side);
      ObjectSet("Info_26",OBJPROP_XDISTANCE,10);
      ObjectSet("Info_26",OBJPROP_YDISTANCE,500);
     }

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  if (Showinfopanel==true)
  {
   ObjectDelete("StopBuyLevel");
   ObjectDelete("StopSellLevel");
   ObjectDelete("Background");
   ObjectDelete("Background_2");
   ObjectDelete("Background_3");
   ObjectDelete("Info_1");
   ObjectDelete("Info_2");
   ObjectDelete("Info_3");
   ObjectDelete("Info_4");
   ObjectDelete("Info_5");
   ObjectDelete("Info_6");
   ObjectDelete("Info_7");
   ObjectDelete("Info_8");
   ObjectDelete("Info_9");
   ObjectDelete("Info_10");
   ObjectDelete("Info_11");
   ObjectDelete("Info_12");
   ObjectDelete("Info_13");
   ObjectDelete("Info_14");
   ObjectDelete("Info_15");
   ObjectDelete("Info_16");
   ObjectDelete("Info_17");
   ObjectDelete("Info_18");
   ObjectDelete("Info_19");
   ObjectDelete("Info_20");
   ObjectDelete("Info_21");
   ObjectDelete("Info_22");
   ObjectDelete("Info_23");
   ObjectDelete("Info_24");
   ObjectDelete("Info_25");
   ObjectDelete("Info_26");
   }
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {

int n=1;

if(_Digits==3 || _Digits==5)
  n=10;

//--

int p=0;
static int Tick_Count=0, Ready=0;
static double Current_Price=0;
double Tick_Base[], Tick_Base_Temp[];

ArraySetAsSeries(Tick_Base, True);
ArraySetAsSeries(Tick_Base_Temp, True);
ArrayResize(Tick_Base, Tick_Memory);
ArrayResize(Tick_Base_Temp, Tick_Memory);

if(Current_Price!=Bid)
  {
  Tick_Count++;
  if(Tick_Count>Tick_Memory-1)
    {
    Tick_Count=0;
    Ready=1;
    }
  for(p=Tick_Memory-1; p>=0; p--)
    {
    Tick_Base_Temp[p]=Tick_Base[p];
    }
  for(p=Tick_Memory-1; p>=1; p--)
    {
    Tick_Base[p]=Tick_Base_Temp[p-1];
    }
  Tick_Base[0]=Bid;
  Current_Price=Bid;
  }

double BB_Upper_Tick=0;
double BB_Lower_Tick=0;

BB_Upper_Tick=NormalizeDouble(iBandsOnArray(Tick_Base, 0, Tick_Memory, Deviation, 0, MODE_UPPER, 0), _Digits);
BB_Lower_Tick=NormalizeDouble(iBandsOnArray(Tick_Base, 0, Tick_Memory, Deviation, 0, MODE_LOWER, 0), _Digits);

static int Trigger_BB=0;
int BB_Signal=0;

if(iClose(Symbol(),Period(),2)>BB_Upper_Tick)
  Trigger_BB=1;
  
if(iClose(Symbol(),Period(),2)<BB_Lower_Tick)
  Trigger_BB=-1;

if(Trigger_BB!=0 && iClose(Symbol(),Period(),1)>BB_Lower_Tick && iClose(Symbol(),Period(),1)<BB_Upper_Tick)
  {
  if(Trigger_BB>0)
    BB_Signal=-1;
  if(Trigger_BB<0)
    BB_Signal=1;
  Trigger_BB=0;
  }

//--

int Sell_Signal=0, Buy_Signal=0;
int ADX_Norm=0;

//-- Moving Averages

double ADX_TF1=iADX(_Symbol,_Period,14,PRICE_CLOSE,0,0);
double ADX_TF2=iADX(_Symbol,5,14,PRICE_CLOSE,0,0);
double ADX_TF3=iADX(_Symbol,15,14,PRICE_CLOSE,0,0);

int Multiplicator=0;

//-- ADX

double ADX_Norm_TF1=iADX(Symbol(),1440,18,0,0,1);

if(ADX_Norm_TF1<=30)
  Multiplicator=2;

if(ADX_Norm_TF1>30 && ADX_Norm_TF1<60)
  Multiplicator=3;  

if(ADX_Norm_TF1>=60)
  Multiplicator=1;

//-- Moving Averages

double MA_High_P1 = iMA(Symbol(),Period(),Period_1*Multiplicator,0,1,2,1);
double MA_Low_P1 = iMA(Symbol(),Period(),Period_1*Multiplicator,0,1,3,1);
double MA_High_P2 = iMA(Symbol(),Period(),Period_2*Multiplicator,0,1,2,1);
double MA_Low_P2 = iMA(Symbol(),Period(),Period_2*Multiplicator,0,1,3,1);

//-- SAR

double SAR_T1=iSAR(Symbol(),Period(),0.02,0.2,1);
double SAR_T2=iSAR(Symbol(),Period(),0.02,0.2,2);
double SAR_T3=iSAR(Symbol(),Period(),0.02,0.2,3);

int SAR=0;

if(SAR_T1>High[1] && SAR_T2>High[2] && SAR_T3>High[3])
  SAR=-1;
if(SAR_T1<Low[1] && SAR_T2<Low[2] && SAR_T3<Low[3])
  SAR=1;

//-- MACD

double MACD_Main_H=iMACD(Symbol(),Period(),12,26,9,PRICE_OPEN,0,0);
double MACD_Signal_H=iMACD(Symbol(),Period(),12,26,9,PRICE_OPEN,1,0);

double MACD_Main_L=iMACD(Symbol(),Period(),12,26,9,PRICE_CLOSE,0,0);
double MACD_Signal_L=iMACD(Symbol(),Period(),12,26,9,PRICE_CLOSE,1,0);

int MACD=0;

if(MACD_Main_H>MACD_Signal_H && MACD_Main_L>MACD_Signal_L)
  MACD=1;
  
if(MACD_Main_H<MACD_Signal_H && MACD_Main_L<MACD_Signal_L)
  MACD=-1;

//-- EMA

double EMA_5=iMA(Symbol(),Period(),50,0,MODE_EMA,PRICE_CLOSE,0);
double EMA_10=iMA(Symbol(),Period(),200,0,MODE_EMA,PRICE_CLOSE,0);

int EMA=0;

if(EMA_5>EMA_10)
  EMA=1;
if(EMA_5<EMA_10)
  EMA=-1;

//-- Triggering Decision

if(ADX_TF1>40 && ADX_TF2<40 && ADX_TF3<40)
  ADX_Norm=1;

if(EMA==-1 && MACD==-1 && SAR==-1 && iLow(Symbol(),Period(),1)<MA_Low_P2 && BB_Signal==-1)
  Buy_Signal=1;
if(EMA==1 && MACD==1 && SAR==1 && iHigh(Symbol(),Period(),1)>MA_High_P1 && BB_Signal==1)
  Sell_Signal=1;

//--

int Pos_Open=0, h=0;
int Sell_Position=0, Buy_Position=0, Aux_Position=0, Sell_Loser=0, Buy_Loser=0, Sell_Winner=0, Buy_Winner=0, Aux_Direction=0;
int a=-1, b=-1, c=0;
static int Neutralize=0;
static int Repopulate=0;
static int Counting=0;
double Profit_Buy=0, Profit_Sell=0, Profit_Temp=0, Profit_Aux=0, Aux_Lots_Cached=0;
double Buy_Loss=0, Sell_Loss=0, Buy_Profit=0, Sell_Profit=0, Aux_Profit=0;
double Buy_Open_Price_Cached=0, Sell_Open_Price_Cached=10000;
double Buy_Loss_Array[][2], Buy_Profit_Array[][2], Sell_Loss_Array[][2], Sell_Profit_Array[][2], Aux_Array[][2], Aux_Array_Target[][2];

if(ArraySize(Buy_Loss_Array)!=MaxPos*4)
  ArrayResize(Buy_Loss_Array,MaxPos*4);
if(ArraySize(Buy_Profit_Array)!=MaxPos*4)
  ArrayResize(Buy_Profit_Array,MaxPos*4);
if(ArraySize(Sell_Loss_Array)!=MaxPos*4)
  ArrayResize(Sell_Loss_Array,MaxPos*4);
if(ArraySize(Sell_Profit_Array)!=MaxPos*4)
  ArrayResize(Sell_Profit_Array,MaxPos*4);
if(ArraySize(Aux_Array)!=MaxPos*4)
  ArrayResize(Aux_Array,MaxPos*4);
if(ArraySize(Aux_Array_Target)!=MaxPos*4)
  ArrayResize(Aux_Array_Target,MaxPos*4);

for(h=OrdersTotal()-1;h>=0;h--)
  {
    if(OrderSelect(h,SELECT_BY_POS,MODE_TRADES)==true)
      {
        if(OrderMagicNumber()==Magic_Buy || OrderMagicNumber()==Magic_Sell || OrderMagicNumber()==Magic_Aux)
         {      
           
           if(OrderMagicNumber()==Magic_Sell)
           {  
           Pos_Open++;
           Sell_Position++;
           Profit_Temp = OrderProfit()+OrderCommission()+OrderSwap();
           if(Profit_Temp<0)
             {
             Sell_Loser++;
             Sell_Loss += Profit_Temp;
             }
           if(Profit_Temp>=0)
             {
             Sell_Winner++;
             Sell_Profit += Profit_Temp;
             }
           Profit_Sell += Profit_Temp;
           } 
           
           if(OrderMagicNumber()==Magic_Buy)
           { 
           Pos_Open++;
           Buy_Position++;
           Profit_Temp = OrderProfit()+OrderCommission()+OrderSwap();
           if(Profit_Temp<0)
             {
             Buy_Loser++;
             Buy_Loss += Profit_Temp;
             }
           if(Profit_Temp>=0)
             {
             Buy_Winner++;
             Buy_Profit += Profit_Temp;
             }
           Profit_Buy += Profit_Temp;
           }
           
           if(OrderMagicNumber()==Magic_Aux)
           {
           Pos_Open++;
           Aux_Position++;
           Profit_Temp = OrderProfit()+OrderCommission()+OrderSwap();
           Profit_Aux += Profit_Temp;
           //if(OrderLots()>Aux_Lots_Cached)
           Aux_Lots_Cached += OrderLots();
           if(OrderType()==OP_BUY)
             {
             if(OrderOpenPrice()>Buy_Open_Price_Cached)
               Buy_Open_Price_Cached=OrderOpenPrice();
             Aux_Direction=1;
             }
           if(OrderType()==OP_SELL)
             {
             if(OrderOpenPrice()<Sell_Open_Price_Cached)
               Sell_Open_Price_Cached=OrderOpenPrice();
             Aux_Direction=-1;
             }
           }           
           
         }
      }
  }

if(Counting!=Aux_Position)
  {
  a=-1;
  b=-1;
  Counting=Aux_Position;
  }

if(Neutralize!=0 && Aux_Position==0)
  {
  Neutralize=0;
  Repopulate=1;
  Print("Neutralization over !");
  }

double Profit=0;
double Buy_Loss_Cached=0, Sell_Loss_Cached=0, Buy_Profit_Cached=0, Sell_Profit_Cached=0;
int Worst_Buy_Position=0, Worst_Sell_Position=0, Best_Buy_Position=0, Best_Sell_Position=0;
double Worst_Buy_Price=0, Worst_Sell_Price=0, Best_Buy_Price=0, Best_Sell_Price=0;
int i=0, pos=0, v=-1, w=-1, x=-1, y=-1, z=-1;
int index=0, Aux_Position_Ticket=0;
static int Temp_Stop=0;

ResetOrderArray(Buy_Loss_Array, Buy_Profit_Array, Sell_Loss_Array, Sell_Profit_Array, Aux_Array);

static datetime Time_Cached;
static int WSP_Cached=0, WBP_Cached=0;
static int d=0, e=0;

if(Repopulate==1)
  {
  ResetOrderArrayTarget(Aux_Array_Target);
  while(Aux_Array_Target[c][0]!=0 || Aux_Array_Target[c][1]!=0)
    {
    c++;
    }
  d=0;
  e=0;
  Repopulate=0;
  }

Profit = Profit_Buy + Profit_Sell + Profit_Aux;

if(Neutralize==0 && (Buy_Position>=MathFloor(MaxPos/2) || Sell_Position>=MathFloor(MaxPos/2)) && Neutralizer==1)
{
for(pos=OrdersTotal()-1; pos>=0; pos--)
  {
  if(OrderSelect(pos, SELECT_BY_POS, MODE_TRADES)==True)
    {
    
    if(OrderMagicNumber()==Magic_Buy)
    {
    Profit_Temp = OrderProfit()+OrderCommission()+OrderSwap();
    
    if(0>Profit_Temp)
      {
      Buy_Loss_Cached=NormalizeDouble(Profit_Temp,2);
      Worst_Buy_Position=OrderTicket();
      Worst_Buy_Price=OrderOpenPrice();
      w++;
      Buy_Loss_Array[w][0]=Worst_Buy_Position;
      Buy_Loss_Array[w][1]=Buy_Loss_Cached;
      if(Sell_Signal==1 && d<Buy_Position
      && CountBuyOrders()==Buy_Loser && CountBuyPips()/CountBuyOrders()<-Pips_Threshold)
        {
         
        ArraySort(Aux_Array_Target, WHOLE_ARRAY, 0, MODE_DESCEND);
        index=ArrayBsearch(Aux_Array_Target, Worst_Buy_Position, WHOLE_ARRAY, 0, MODE_DESCEND);
        
        if(Aux_Array_Target[index][0]!=Worst_Buy_Position)
        {

        a=index;
        
        while(Aux_Array_Target[a][0]!=0 && !IsStopped())
          {
          a++;
          }
        
        d++;
        Counting++;
        
        Aux_Array_Target[a][0]=Worst_Buy_Position;
        Aux_Array_Target[a][1]=0;
        if(Neutralize==0)
          Print("Neutralization starting... Pips : " + DoubleToString(CountBuyPips()/CountBuyOrders(),2));
        Time_Cached=OrderLaunch("SELL", Aux_Array_Target, a, OrderLots(), CountBuyOrders());
        Temp_Stop=1;
        Neutralize=-1;
        }
        
        }
      
      }
    
    if(0<Profit_Temp)
      {
      Buy_Profit_Cached=NormalizeDouble(Profit_Temp,2);
      Best_Buy_Position=OrderTicket();
      Best_Buy_Price=OrderOpenPrice();
      x++;
      Buy_Profit_Array[x][0]=Best_Buy_Position;
      Buy_Profit_Array[x][1]=Buy_Profit_Cached;

      }
    }
    
    if(OrderMagicNumber()==Magic_Sell)
    {
    Profit_Temp = OrderProfit()+OrderCommission()+OrderSwap();
    
    if(0>Profit_Temp)
      {
      Sell_Loss_Cached=NormalizeDouble(Profit_Temp,2);
      Worst_Sell_Position=OrderTicket();
      Worst_Sell_Price=OrderOpenPrice();
      y++;
      Sell_Loss_Array[y][0]=Worst_Sell_Position;
      Sell_Loss_Array[y][1]=Sell_Loss_Cached;
      if(Buy_Signal==1 && e<Sell_Position
      && CountSellOrders()==Sell_Loser && CountSellPips()/CountSellOrders()<-Pips_Threshold)
        {
        
        ArraySort(Aux_Array_Target, WHOLE_ARRAY, 0, MODE_DESCEND);
        index=ArrayBsearch(Aux_Array_Target, Worst_Sell_Position, WHOLE_ARRAY, 0, MODE_DESCEND);
        
        if(Aux_Array_Target[index][0]!=Worst_Sell_Position)
        {
        
        b=index;
        
        while(Aux_Array_Target[b][0]!=0 && !IsStopped())
          {
          b++;
          }
        
        e++;
        Counting++;
        
        Aux_Array_Target[b][0]=Worst_Sell_Position;
        Aux_Array_Target[b][1]=0;

        if(Neutralize==0)
          Print("Neutralization starting... Pips : " + DoubleToString(CountSellPips()/CountSellOrders(),2));
        Time_Cached=OrderLaunch("BUY", Aux_Array_Target, b, OrderLots(), CountSellOrders());
        Temp_Stop=1;
        Neutralize=1;
        }
        
        }

      }
    
    if(0<Profit_Temp)
      {
      Sell_Profit_Cached=NormalizeDouble(Profit_Temp,2);
      Best_Sell_Position=OrderTicket();
      Best_Sell_Price=OrderOpenPrice();
      z++;
      Sell_Profit_Array[z][0]=Best_Sell_Position;
      Sell_Profit_Array[z][1]=Sell_Profit_Cached;

      }
    }
    
    if(OrderMagicNumber()==Magic_Aux)
      {
      Profit_Temp = OrderProfit()+OrderCommission()+OrderSwap();
      
      Aux_Profit=NormalizeDouble(Profit_Temp,2);
      Aux_Position_Ticket=OrderTicket();
      v++;
      Aux_Array[v][0]=Aux_Position_Ticket;
      Aux_Array[v][1]=Aux_Profit;
      Aux_Profit += Profit_Temp;
      }
    
    }
  }
}

int u=0;
string Order_Ticket_Proxy;
double Temp_Loss=0, Temp_Win=0, Temp_Equal=0, Temp_Aux=0;
double Loss_Cached=0, Aux_Cached=0, Loss_Sell_Cached=10000, Loss_Buy_Cached=10000;
string Loss_Buy_Ticket_Cached, Loss_Sell_Ticket_Cached, Loss_Ticket_Cached, Win_Ticket_Cached, Aux_Ticket_Cached;

if(Neutralize!=0 && Aux_Position!=0 && Profit_Aux>=0)
  {
  if((Aux_Direction==1 && Sell_Position==0) || (Aux_Direction==-1 && Buy_Position==0))
    {
    for(i=OrdersTotal()-1; i>=0; i--)
      {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)==True)
        if(OrderMagicNumber()==Magic_Aux)
          CloseSelected(IntegerToString(OrderTicket()), Retry);
      }
    Alert("Closing all Aux Positions");
    }
  }

if(Neutralize!=0 && (Aux_Profit+Loss_Sell_Cached>=0 || Aux_Profit+Loss_Buy_Cached>=0))
  {

  Loss_Buy_Cached=0;
  Loss_Sell_Cached=0;
  Aux_Cached=0;
  
  ArraySort(Buy_Loss_Array, WHOLE_ARRAY, 0, MODE_ASCEND);
  ArraySort(Sell_Loss_Array, WHOLE_ARRAY, 0, MODE_ASCEND);
  ArraySort(Aux_Array, WHOLE_ARRAY, 0, MODE_DESCEND);  
  
  for(u=0; u<MaxPos*4; u++)
    {
    Temp_Loss=Buy_Loss_Array[u][1];
    if(Temp_Loss<Loss_Buy_Cached)
      {
      Loss_Buy_Cached=Temp_Loss;
      Loss_Buy_Ticket_Cached=DoubleToStr(Buy_Loss_Array[u][0],0);
      }

    Temp_Loss=Sell_Loss_Array[u][1];
    if(Temp_Loss<Loss_Sell_Cached)
      {
      Loss_Sell_Cached=Temp_Loss;
      Loss_Sell_Ticket_Cached=DoubleToStr(Sell_Loss_Array[u][0],0);
      }
    
    Temp_Aux=Aux_Array[u][1];
    if(Temp_Aux>Aux_Cached)
      {
      Aux_Cached=Temp_Aux;
      Aux_Ticket_Cached=DoubleToStr(Aux_Array[u][0],0);
      }
    }
    
  if(OrderSelect(StrToInteger(Aux_Ticket_Cached), SELECT_BY_TICKET, MODE_TRADES)==True)
      if(OrderMagicNumber()==Magic_Aux)
      {
      Aux_Profit=OrderProfit()+OrderCommission()+OrderSwap();
      Order_Ticket_Proxy=IntegerToString(OrderTicket());
      if(OrderType()==OP_BUY && Aux_Profit+Loss_Sell_Cached>=0)
        {
        CloseSelected(Loss_Sell_Ticket_Cached, Retry);
        CloseSelected(Order_Ticket_Proxy, Retry);
        }
      if(OrderType()==OP_SELL && Aux_Profit+Loss_Buy_Cached>=0)
        {
        CloseSelected(Loss_Buy_Ticket_Cached, Retry);
        CloseSelected(Order_Ticket_Proxy, Retry);
        }
      }
  }

double Lot_Size_Empowered=0;
int Order_Number=0;

if(((Neutralize==1 && Sell_Position==0 && Sell_Signal!=0) || (Neutralize==-1 && Buy_Position==0 && Buy_Signal!=0)) && Profit_Aux<0)
  {

   if(Neutralize==1 && Sell_Position==0 && Sell_Signal!=0 && Buy_Open_Price_Cached-Aux_Threshold*Aux_Position*n*_Point>Bid)
     {
     Lot_Size_Empowered=NormalizeDouble(Aux_Lots_Cached*Aux_Position,2);
     if(CheckVolumeValue(Lot_Size_Empowered)==True && CheckMoneyForTrade(_Symbol, Lot_Size_Empowered, OP_SELL)==True)
     {
     for(i=0; i<Retry; i++)
          {
          RefreshRates();
          Order_Number=-1;
          Order_Number=OrderSend(_Symbol,OP_SELL,Lot_Size_Empowered,MarketInfo(_Symbol,MODE_BID),Slippage,0,0,NULL,Magic_Aux,0,Gold);
          if(Order_Number>0)
            break;
          }
     }
     Print("RPG SELL - Mode ON = ", Buy_Open_Price_Cached, ". Aux Direction = ", Aux_Direction);
     Temp_Stop=1;
     Neutralize=2;
     }
   
   if(Neutralize==-1 && Buy_Position==0 && Buy_Signal!=0 && Sell_Open_Price_Cached+Aux_Threshold*Aux_Position*n*_Point<Ask)
     {
     Lot_Size_Empowered=NormalizeDouble(Aux_Lots_Cached*Aux_Position,2);
     if(CheckVolumeValue(Lot_Size_Empowered)==True && CheckMoneyForTrade(_Symbol, Lot_Size_Empowered, OP_BUY)==True)
     {
     for(i=0; i<Retry; i++)
          {
          RefreshRates();
          Order_Number=-1;
          Order_Number=OrderSend(_Symbol,OP_BUY,Lot_Size_Empowered,MarketInfo(_Symbol,MODE_ASK),Slippage,0,0,NULL,Magic_Aux,0,Gold);
          if(Order_Number>0)
            break;
          }
     }
     Print("RPG BUY - Mode ON = ", Sell_Open_Price_Cached, ". Aux Direction = ", Aux_Direction);
     Temp_Stop=1;
     Neutralize=-2;
     }
   
  }

if(Neutralize!=0 && Profit>=0)
  {
  while (CloseAll() == AT_LEAST_ONE_FAILED)
   {
      Sleep(1000);
   }
  }

if(Temp_Stop==1)
  {
  if(Buy_Signal==0 && Sell_Signal==0)
    Temp_Stop=0;
  Sell_Signal=0;
  Buy_Signal=0;
  }

//--

static int ticker=0;

   if(DayOfWeek()==0 || (DayOfWeek()==1 && Hour()==0) || DayOfWeek()==6 || (DayOfWeek()==5 && Hour()==23) || Stoptrading==true)
     {
      if(Showinfopanel==true)
        {
         allowbuy="Trade is stopped!";
         allowsell="Trade is stopped!";
         ObjectSetText("Info_9",allowbuy,10,"Calibri",Textcolor);
         ObjectSetText("Info_19",allowsell,10,"Calibri",Textcolor);
        }
      return;                                             //Do nothing at weekend first and last hour of trade
     }
     
   if(StopTradesLevel==true) //Here we check crossing price and critical levels
     {
      if(Ask<BuyStopLevel)
         AllowafterlevelBuy=false;
      else AllowafterlevelBuy=true;
      if(Bid>SellStopLevel)
         AllowafterlevelSell=false;
      else AllowafterlevelSell=true;
     }
     
   if(Showinfopanel==true)
      UpdateBasketStatus();                                //Update data for info-panel
      
   //if(lastopentime!=Time[0]) //Opening new orders is in the new candle
   //  {
      if (Usefiltrevolat==true)                                                             //If we have limitation of sharp change
      {
         CheckPriceSpeed();
      }
      CCI_1 = iCCI(Symbol(), 0, Period_CCI, PRICE_CLOSE, 1);
      CCI_2 = iCCI(Symbol(), 0, Period_CCI, PRICE_CLOSE, 2);
      if(CountBuyOrders()==0 && Allowbuy==true && AllowafterlevelBuy==true && Allowbuylevel==true && Buy_Signal==1 && Neutralize<2) //Here we define a conditions for the first buy orders
        {
         AlertMaxStepsBuy=false;
         if(CCIFiltre==false)
            OpenFirstOrder(OP_BUY);
         else
           {
            if(CCI_1>0 && CCI_2<0)
               OpenFirstOrder(OP_BUY);
           }
        }
      if(CountSellOrders()==0 && Allowsell==true && AllowafterlevelSell==true && Allowselllevel==true && Sell_Signal==1 && Neutralize>-2) //Here we define a conditions for the first sell orders
        {
         AlertMaxStepsSell=false;
         if(CCIFiltre==false)
            OpenFirstOrder(OP_SELL);
         else
           {
            if(CCI_1<0 && CCI_2>0)
               OpenFirstOrder(OP_SELL);
           }
        }
   //   lastopentime=Time[0];
   //  }

   if(CountBuyOrders()>0 && (Allowbuy==true || Stopmode_2==s) && (AllowafterlevelBuy==true || Stopmode_3==s) && Buy_Signal==1 && Neutralize<2) //Here we define a conditions for the next buy orders
     {
      lastticket=0;
      lastbuyprice=Findlastprice(OP_BUY);
      step=FindStepSize(OP_BUY);
      nextlot=DetermineLot(lastticket);
      if(Ask<(lastbuyprice-step))
        {
         MarginAgreed=CheckMoneyForTrade(_Symbol,nextlot,OP_BUY);
         if(MarginAgreed==true)
           {
            lastTP=FindLastTP(OP_BUY);
            OpenNewLevel(lastTP,nextlot,OP_BUY);
            Print("Pips Delta BUY = ",DoubleToString(CountBuyPips()/CountBuyOrders(),2));
           }
        }
      if(Showinfopanel==true && step!=100000)
        {
         if(Digits()==3 || Digits()==5)
            buystepvalue=step/10/Point();
         else buystepvalue=step/Point();
         nextpricebuy=lastbuyprice-step;
         nextlotbuy=nextlot;
        }
     }
   if(CountSellOrders()>0 && (Allowsell==true || Stopmode_2==s) && (AllowafterlevelSell==true || Stopmode_3==s) && Sell_Signal==1 && Neutralize>-2) //Here we define a conditions for the next sell orders
     {
      lastticket=0;
      lastsellprice=Findlastprice(OP_SELL);
      step=FindStepSize(OP_SELL);
      nextlot=DetermineLot(lastticket);
      if(Bid>(lastsellprice+step))
        {
         MarginAgreed=CheckMoneyForTrade(_Symbol,nextlot,OP_SELL);
         if(MarginAgreed==true)
           {
            lastTP=FindLastTP(OP_SELL);
            OpenNewLevel(lastTP,nextlot,OP_SELL);
            Print("Pips Delta SELL = ", DoubleToString(CountSellPips()/CountSellOrders(),2));
           }
        }
      if(Showinfopanel==true && step!=100000)
        {
         if(Digits()==3 || Digits()==5)
            sellstepvalue=step/10/Point();
         else sellstepvalue=step/Point();
         nextpricesell=lastsellprice+step;
         nextlotsell=nextlot;
        }
     }
   if(Allowbuy==false && Stopmode_2==a && CountBuyOrders()>0)
      Closedirection(OP_BUY);
   if(Allowsell==false && Stopmode_2==a && CountSellOrders()>0)
      Closedirection(OP_SELL);
   if(AllowafterlevelBuy==false && Stopmode_3==a && CountBuyOrders()>0)
     {
      Closedirection(OP_BUY);
      Allowbuylevel=false;
      Print("Price is lower than critical level! Buy orders are prohibited!");
      Alert("Price is lower than critical level! Buy orders are prohibited!");
     }
   if(AllowafterlevelSell==false && Stopmode_3==a && CountSellOrders()>0)
     {
      Closedirection(OP_SELL);
      Allowselllevel=false;
      Print("Price is higher than critical level! Sell orders are prohibited!");
      Alert("Price is higher than critical level! Sell orders are prohibited!");
     }
   if(Showinfopanel==true)
      {
      ticker++;
      if(ticker>10)
        ticker=1;
      UpdateInfoWindow(ticker, Neutralize);
      }
  }
//+------------------------------------------------------------------+
//| Function of price speed calculation for the last day             |
//+------------------------------------------------------------------+
void CheckPriceSpeed()
  {
     double urgentlevel, pricediffer;
     int number;
     switch (Period())                                                             //because speed of price for one day defines in the new candle of chart
     {
        case PERIOD_M1:  number=1441; break;
        case PERIOD_M5:  number=289;  break;
        case PERIOD_M15: number=97;   break;
        case PERIOD_M30: number=49;   break;
        case PERIOD_H1:  number=25;   break;
        case PERIOD_H4:  number=7;    break;
        default:         number=2;    break;
     }
     urgentlevel = Volatility(Periodvolatility_2)*Lineofvolatility;
     pricediffer = Close[1]-Close[number];
     if (urgentlevel<MathAbs(pricediffer))
     {
        if (Stopmode_4==all)
        {
           UrgentCloseOrders();
           Print("SyTurn stops trade, due to volatility exceeding threshold!");
           Alert("SyTurn stops trade, due to volatility exceeding threshold!");
           Allowsell=false;
           Allowbuy=false;
           Stoptrading=true;
           if (Showinfopanel==true)
           {
              Flagsellinfo=true;
              Flagbuyinfo=true;
           }
        }
        else
        {
           if (pricediffer>0)
           {
              if (CountSellOrders()>0)
                  Closedirection(OP_SELL);
              if (Alertsellvolat==false)
              {
                 Print("SyTurn stops sell orders, due to volatility exceeding threshold!");
                 Alert("SyTurn stops sell orders, due to volatility exceeding threshold!");
                 Alertsellvolat=true;
              }
              Allowsell=false;
              if (Showinfopanel==true)
                  Flagsellinfo=true;
           }
           if (pricediffer<0)
           {
              if (CountBuyOrders()>0)
                  Closedirection(OP_BUY);
              if (Alertbuyvolat==false)
              {
                 Print("SyTurn stops buy orders, due to volatility exceeding threshold!");
                 Alert("SyTurn stops buy orders, due to volatility exceeding threshold!");
                 Alertbuyvolat=true;
              }
              Allowbuy=false;
              if (Showinfopanel==true)
                  Flagbuyinfo=true;
           }
        }
     }
  }
//+------------------------------------------------------------------+
//| Function of all one-direction-orders forced closure              |
//+------------------------------------------------------------------+
void Closedirection(int ordertype)
  {
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderSymbol()==Symbol() && (OrderMagicNumber()==Magic_Buy || OrderMagicNumber()==Magic_Sell) && OrderType()==ordertype)
           {
            if(OrderType()==OP_BUY)
               OrderClosex(OP_BUY, OrderTicket(),OrderLots(),Bid,Slippage,clrBlack);
            if(OrderType()==OP_SELL)
               OrderClosex(OP_SELL, OrderTicket(),OrderLots(),Ask,Slippage,clrBlack);
           }
        }
     }
  }
//+------------------------------------------------------------------+
//| Function of all orders closing when critical drawdown            |
//+------------------------------------------------------------------+
void UrgentCloseOrders()
  {
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderSymbol()==Symbol() && (OrderMagicNumber()==Magic_Buy || OrderMagicNumber()==Magic_Sell))
           {
            if(OrderType()==OP_BUY)
               OrderClosex(OP_BUY, OrderTicket(),OrderLots(),Bid,Slippage,clrBlack);
            if(OrderType()==OP_SELL)
               OrderClosex(OP_SELL, OrderTicket(),OrderLots(),Ask,Slippage,clrBlack);
           }
        }
     }
   return;
  }

//+------------------------------------------------------------------+
//| Function of previous grid step calculation                       |
//+------------------------------------------------------------------+
double FindLastStep(int OTYPE)
  {
   double nowprice=0,oldstep=0;
   if(OTYPE==OP_BUY)
      nowprice=1000000;
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderSymbol()==Symbol() && (OrderMagicNumber()==Magic_Buy || OrderMagicNumber()==Magic_Sell) && OrderType()==OTYPE)
           {
            if(OrderTicket()!=lastticket)
              {
               if(OrderType()==OP_BUY)
                 {
                  if(nowprice>OrderOpenPrice()) //Here we find the last grid order price
                     nowprice=OrderOpenPrice();
                 }
               if(OrderType()==OP_SELL)
                 {
                  if(nowprice<OrderOpenPrice())
                     nowprice=OrderOpenPrice();
                 }
              }
           }
        }
     }
   if(OrderSelect(lastticket,SELECT_BY_TICKET,MODE_TRADES))
      oldstep=MathAbs(nowprice-OrderOpenPrice());                                   //step is a difference of open prices of last and penultimate orders
   return(oldstep);
  }
//+------------------------------------------------------------------+
//| Function of new cranks opening                                   |
//+------------------------------------------------------------------+
void OpenNewLevel(double previousTP,double LOT,int Type)
  {
   double currentTPlevel,currentTP;
   int Level, Ticket;
   currentTP=previousTP;

   if(Type==OP_BUY)
     {
      Level=CountBuyOrders();
      if(Useaverageprofit==false) //if take-profites are constant
        {
         if(Usedynamictakeprofit==true) //in case of dynamic take-profit
            currentTP=FindDynamicTP(Level,previousTP);
         RefreshRates();
         currentTPlevel=NormalizeDouble(Ask+currentTP,Digits());
         if (ECNflag==false)
             OrderSendx(Symbol(),OP_BUY,LOT,Ask,Slippage,0,currentTPlevel,"SyTurn",Magic_Buy,0,clrBlue);
         else
         {
             Ticket = OrderSendx(Symbol(),OP_BUY,LOT,Ask,Slippage,0,0,"SyTurn",Magic_Buy,0,clrBlue);
             if (Ticket>0 && OrderSelect(Ticket, SELECT_BY_TICKET, MODE_TRADES))
                OrderModifyx(Ticket, OrderOpenPrice(), 0, currentTPlevel, 0, clrNONE);
         }
        }
      else                                              //in case of necessity of average basket take-profit
        {
         if(Usedynamictakeprofit==true)
            currentTP=FindDynamicTP(Level,previousTP);     //if take-profit is dynamic
         if(Breakevenclose==true)
           {                                                  //in case of breakevenflag
            if(Level>=StepforBE)
               currentTP=0;
           }
         RefreshRates();
         OrderSendx(Symbol(),OP_BUY,LOT,Ask,Slippage,0,0,"SyTurn",Magic_Buy,0,clrBlue);    //opening without take-profites
         ModifyBasketOrders(OP_BUY,currentTP);
        }
     }

   if(Type==OP_SELL)
     {
      Level=CountSellOrders();
      if(Useaverageprofit==false) //if take-profites are constant
        {
         if(Usedynamictakeprofit==true) //in case of dynamic take-profit
            currentTP=FindDynamicTP(Level,previousTP);
         RefreshRates();
         currentTPlevel=NormalizeDouble(Bid-currentTP,Digits());
         if(ECNflag==false)
             OrderSendx(Symbol(),OP_SELL,LOT,Bid,Slippage,0,currentTPlevel,"SyTurn",Magic_Sell,0,clrRed);
         else
         {
             Ticket = OrderSendx(Symbol(),OP_SELL,LOT,Bid,Slippage,0,0,"SyTurn",Magic_Sell,0,clrRed);
             if (Ticket>0 && OrderSelect(Ticket, SELECT_BY_TICKET, MODE_TRADES))
                OrderModifyx(Ticket, OrderOpenPrice(), 0, currentTPlevel, 0, clrNONE);
         }
        }
      else                                              //in case of necessity of average basket take-profit
        {
         if(Usedynamictakeprofit==true)
            currentTP=FindDynamicTP(Level,previousTP);     //if take-profit is dynamic
         if(Breakevenclose==true)
           {                                                  //in case of breakevenflag
            if(Level>=StepforBE)
               currentTP=0;
           }
         RefreshRates();
         OrderSendx(Symbol(),OP_SELL,LOT,Bid,Slippage,0,0,"SyTurn",Magic_Sell,0,clrRed);    //opening without take-profites
         ModifyBasketOrders(OP_SELL,currentTP);
        }
     }
  }
//+------------------------------------------------------------------+
//| Modification of baskets orders                                   |
//+------------------------------------------------------------------+
void ModifyBasketOrders(int o_type,double tpvalue)
  {
   double avgprice   = 0,
   order_lots = 0;
   double price=0,tp=0;
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderSymbol()==Symbol() && (OrderMagicNumber()==Magic_Buy || OrderMagicNumber()==Magic_Sell) && OrderType()==o_type)
           {
            price+=OrderOpenPrice()*OrderLots();
            order_lots+=OrderLots();
           }
        }
     }
   avgprice=NormalizeDouble(price/order_lots,Digits());                             //find average weghted price

   if(o_type==OP_BUY)
      tp=NormalizeDouble(avgprice+tpvalue,Digits());                             //plus take-profit value
   if(o_type==OP_SELL)
      tp=NormalizeDouble(avgprice-tpvalue,Digits());

   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderSymbol()==Symbol() && (OrderMagicNumber()==Magic_Buy || OrderMagicNumber()==Magic_Sell) && OrderType()==o_type)
            OrderModifyx(OrderTicket(),OrderOpenPrice(),0,tp,0,clrNONE);                    //orders modification one by one
        }
     }
  }
//+------------------------------------------------------------------+
//| Dynamic change of take-profit                                    |
//+------------------------------------------------------------------+
double FindDynamicTP(int Stage,double TPbefore)
  {
   double findTP=TPbefore;
   if(Stage>=StepdynamicTP)
     {
      findTP=TPbefore*K_TPDecrease;
      if(findTP<MinTakeProfit*Point()) //if we did not identify conditions about dynamic take-profit, return the same
         findTP=MinTakeProfit*Point();
     }
   return(findTP);
  }
//+------------------------------------------------------------------+
//| Find the value of previous take-profit                           |
//+------------------------------------------------------------------+
double FindLastTP(int Modetrade)
  {
   double avgprice=0,order_lots=0;
   double price=0,take_profit=-1;

   if(Useaverageprofit==false) //we find all take-profits according last orders tickets
     {
      if(OrderSelect(lastticket,SELECT_BY_TICKET,MODE_TRADES))
        {
         if(OrderType()==OP_BUY)
           {
            take_profit=OrderTakeProfit()-OrderOpenPrice();
            return(take_profit);
           }
         if(OrderType()==OP_SELL)
           {
            take_profit=OrderOpenPrice()-OrderTakeProfit();
            return(take_profit);
           }
        }
     }
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderSymbol()==Symbol() && (OrderMagicNumber()==Magic_Buy || OrderMagicNumber()==Magic_Sell) && OrderType()==Modetrade)
           {
            price+=OrderOpenPrice()*OrderLots();
            order_lots+=OrderLots();
           }
        }
     }
   avgprice=NormalizeDouble(price/order_lots,Digits());
   if(OrderSelect(lastticket,SELECT_BY_TICKET,MODE_TRADES))
      take_profit=MathAbs(OrderTakeProfit()-avgprice);
   return(take_profit);
  }
//+------------------------------------------------------------------+
//| Next order lot calculation                                       |
//+------------------------------------------------------------------+
double DetermineLot(int previousticket)
  {
   double lastlot=0,lot_next;
   int level,lasttype=2;
   double lot_step=MarketInfo(Symbol(),MODE_LOTSTEP);
   double lot_max=MarketInfo(Symbol(), MODE_MAXLOT);

   if(OrderSelect(previousticket,SELECT_BY_TICKET,MODE_TRADES))
     {
      lastlot=OrderLots();
      lasttype=OrderType();
     }
   if(lasttype==OP_BUY)
     {
      if(ManuallotBuy>0) //in case of manual lot
        {
         lot_next=MathFloor(ManuallotBuy/lot_step)*lot_step;
         if (lot_next>lot_max)
            lot_next=lot_max;
         return(lot_next);
        }
      level=CountBuyOrders();
      if(level>=Multipusestep) //if amount of orders is more than starts amount, take multiplier
        {
         lot_next=MathFloor((lastlot*Multiplier)/lot_step)*lot_step;
         if (lot_next>lot_max)
            lot_next=lot_max;
         return(lot_next);
        }
     }
   if(lasttype==OP_SELL)
     {
      if(ManuallotSell>0)
        {
         lot_next=MathFloor(ManuallotSell/lot_step)*lot_step;
         if (lot_next>lot_max)
            lot_next=lot_max;
         return(lot_next);
        }
      level=CountSellOrders();
      if(level>=Multipusestep)
        {
         lot_next=MathFloor((lastlot*Multiplier)/lot_step)*lot_step;
         if (lot_next>lot_max)
            lot_next=lot_max;
         return(lot_next);
        }
     }
   return(lastlot);
  }
//+------------------------------------------------------------------+
//| Opened buy orders calculation                                    |
//+------------------------------------------------------------------+
int CountBuyOrders()
  {
   int count= 0;
   for(int i=0; i<OrdersTotal(); i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderSymbol()==Symbol() && (OrderMagicNumber()==Magic_Buy) && OrderType()==OP_BUY)
            count++;
        }
     }
   if(Showinfopanel==true)
      currentstepbuy=count;
   return(count);
  }
  
double CountBuyPips()
  {
  double pips=0, lots_total=0, pips_weighted=0;
  int k = 1;
  if(_Digits==3 || _Digits==5)
    k=10;
  else
    k=1;
  for(int i=0; i<OrdersTotal(); i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderSymbol()==Symbol() && (OrderMagicNumber()==Magic_Buy) && OrderType()==OP_BUY)
           {
           pips_weighted += ((OrderOpenPrice()-Bid)/k/_Point)/OrderLots();
           lots_total += OrderLots();
           }
        }
     }
  pips = pips_weighted*lots_total;
  if(pips<=0)
    pips=MathAbs(pips);
  if(pips>0)
    pips=0-pips;
  return(pips);
  }
//+------------------------------------------------------------------+
//| Opened buy orders calculation                                    |
//+------------------------------------------------------------------+
int CountSellOrders()
  {
   int count= 0;
   for(int i=0; i<OrdersTotal(); i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderSymbol()==Symbol() && (OrderMagicNumber()==Magic_Sell) && OrderType()==OP_SELL)
            count++;
        }
     }
   if(Showinfopanel==true)
      currentstepsell=count;
   return(count);
  }
  
double CountSellPips()
  {
  double pips=0, lots_total=0, pips_weighted=0;
  int k = 1;
  if(_Digits==3 || _Digits==5)
    k=10;
  else
    k=1;
  for(int i=0; i<OrdersTotal(); i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderSymbol()==Symbol() && (OrderMagicNumber()==Magic_Sell) && OrderType()==OP_SELL)
           {
           pips_weighted += ((OrderOpenPrice()-Ask)/k/_Point)/OrderLots();
           lots_total += OrderLots(); 
           }
        }
     }
  pips = pips_weighted*lots_total;    
  return(pips);
  }
//+------------------------------------------------------------------+
//| Opening firs order in the grid                                   |
//+------------------------------------------------------------------+
void OpenFirstOrder(int OTYPE)
  {
   double firstlot=0,firstTP=0,lot_min=0;
   int Ticket=0;
   //lot_min=MarketInfo(Symbol(),MODE_MINLOT);
   //double lot_step=MarketInfo(Symbol(),MODE_LOTSTEP);
   //firstlot=(RiskDeposit/Howmuchmoney)*FirstLot;                                 //define lot according moneymanagement
   //if(OTYPE==OP_BUY && ManuallotBuy>0)
   //   firstlot=ManuallotBuy;
   //if(OTYPE==OP_SELL && ManuallotSell>0)
   //   firstlot=ManuallotSell;
   //firstlot=MathFloor(firstlot/lot_step)*lot_step;

   //if(firstlot<lot_min)
   //   firstlot=lot_min;
   
int LotsDigit=0;
double MinLots=0, MaxLots=0, AcFrMar=0, Step=0, One_Lot=0;

MinLots=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
MaxLots=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);

if(Money_Management==False)
   {
   firstlot=Lot_Size;
   }

if(Money_Management==True)
   {
   One_Lot=MarketInfo(_Symbol,MODE_MARGINREQUIRED);
   
   Step=MarketInfo(_Symbol,MODE_LOTSTEP);
   
   AcFrMar=NormalizeDouble(AccountFreeMargin(),2);
   
   firstlot=MathFloor(AcFrMar*Margin_Percent/100/One_Lot/Step)*Step;
   
   }
   
if(firstlot>MaxLots)
  firstlot=MaxLots;
if(firstlot<MinLots)
  firstlot=MinLots;
      
   if(OTYPE==OP_BUY)
     {
      firstTP=NormalizeDouble(Ask+Maintakeprofit*Point(),Digits());
      if (ECNflag==true)
      {
         Ticket = OrderSendx(Symbol(),OTYPE,firstlot,Ask,Slippage,0,0,"SyTurn first trade",Magic_Buy,0,clrBlue);
         if (Ticket>0 && OrderSelect(Ticket, SELECT_BY_TICKET, MODE_TRADES))
            OrderModifyx(Ticket, OrderOpenPrice(), 0, firstTP, 0, clrNONE);
      }
      else OrderSendx(Symbol(),OTYPE,firstlot,Ask,Slippage,0,firstTP,"SyTurn first trade",Magic_Buy,0,clrBlue);
     }
   if(OTYPE==OP_SELL)
     {
      firstTP=NormalizeDouble(Bid-Maintakeprofit*Point(),Digits());
      if (ECNflag==true)
      {
         Ticket = OrderSendx(Symbol(),OTYPE,firstlot,Bid,Slippage,0,0,"SyTurn first trade",Magic_Sell,0,clrRed);
         if (Ticket>0 && OrderSelect(Ticket, SELECT_BY_TICKET, MODE_TRADES))
            OrderModifyx(Ticket, OrderOpenPrice(), 0, firstTP, 0, clrNONE);
      }
      else OrderSendx(Symbol(),OTYPE,firstlot,Bid,Slippage,0,firstTP,"SyTurn first trade",Magic_Sell,0,clrRed);
     }
  }
//+------------------------------------------------------------------+
//| Finding last open price                                          |
//+------------------------------------------------------------------+
double Findlastprice(int otype)
  {
   double oldopenprice=0;
   int    oldticket;

   ticket=0;

   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderSymbol()==Symbol() && (OrderMagicNumber()==Magic_Buy || OrderMagicNumber()==Magic_Sell) && OrderType()==otype)
           {
            oldticket=OrderTicket();
            if(oldticket>ticket)
              {
               oldopenprice=OrderOpenPrice();
               ticket=oldticket;
              }
           }
        }
     }
   lastticket=ticket;                                          //we've got the last order ticket, which will be used in the next calculations
   return(oldopenprice);
  }
//+------------------------------------------------------------------+
//| Find the value of the urrent step                                |
//+------------------------------------------------------------------+
double FindStepSize(int OType)
  {
   int stage;
   double stepsize;
   if(OType==OP_BUY) //find the step of buy orders
     {
      if(ManualstepBuy>0) //in case of manual step - each next step will be equal this value
        {
         stepsize=ManualstepBuy*Point();
         return(stepsize);
        }
      stage=CountBuyOrders();                               //current crank is amount of open buy orders
      if(stage==1) //if oder in the basket is first
        {
         if(Stepfromvolatility==true) //if step identifying is calculated by volatility
           {
            stepsize=Volatility(PeriodVolatility_1)*K_Stepvol;
            return(stepsize);
           }
         else                                                //if there is no volatility flag, step is equal to first step
           {
            stepsize=FirstStep*Point();
            return(stepsize);
           }
        }
      if(stage>1 && stage<Maxcountstepsbuy)
        {
         stepsize=FindLastStep(OP_BUY);
         if(Dynamicstep==true)
           {
            if(stage>=Stepincreasestep)
              {
               stepsize=stepsize*K_Stepincrease;
               return(stepsize);
              }
           }
         return(stepsize);
        }
      if(stage>=Maxcountstepsbuy)
        {
         if(Showinfopanel==true)
         {
            allowbuy="Reached maximum crank!";
            buystepvalue=0;
            nextpricebuy=0;
            nextlotbuy=0;
         }
         if(AlertMaxStepsBuy==false)
           {
            Alert("Reached maximum crank in the buy basket!!");
            Print("Reached maximum crank in the buy basket!!");
            AlertMaxStepsBuy=true;
           }
        }

     }
   if(OType==OP_SELL) //find the step of sell orders
     {
      if(ManualstepSell>0) //in case of manual step - each next step will be equal this value
        {
         stepsize=ManualstepSell*Point();
         return(stepsize);
        }
      stage=CountSellOrders();                           //current crank is amount of open buy orders
      if(stage==1) //if oder in the basket is first
        {
         if(Stepfromvolatility==true) //if step identifying is calculated by volatility
           {
            stepsize=Volatility(PeriodVolatility_1)*K_Stepvol;
            return(stepsize);
           }
         else                                              //if there is no volatility flag, step is equal to first step
           {
            stepsize=FirstStep*Point();
            return(stepsize);
           }
        }
      if(stage>1 && stage<Maxcountstepsbuy)
        {
         stepsize=FindLastStep(OP_SELL);
         if(Dynamicstep==true)
           {
            if(stage>=Stepincreasestep)
              {
               stepsize=stepsize*K_Stepincrease;
               return(stepsize);
              }
           }
         return(stepsize);
        }
      if(stage>=Maxcountstepsell)
        {
         if(Showinfopanel==true)
         {
            allowsell="Reached maximum crank!";
            sellstepvalue=0;
            nextpricesell=0;
            nextlotsell=0;
         }
         if(AlertMaxStepsSell==false)
           {
            Alert("Reached maximum crank in the sell basket!!");
            Print("Reached maximum crank in the sell basket!!");
            AlertMaxStepsSell=true;
           }
        }

     }

   return(100000);
  }
//+--------------------------------------------------------------------------+
//| Function of volatility calculation depending of day bars amount          |
//+--------------------------------------------------------------------------+
double Volatility(int period)
  {
   double Differ[];
   ArrayResize(Differ,period+1,1);
   double diff1,
   diff=0;
   int i,
   count=0;
   for(i=1; i<=period; i++) //fill the array
      Differ[i]=iHigh(Symbol(),PERIOD_D1,i)-iLow(Symbol(),PERIOD_D1,i);     //Calculate the value of day candles

   for(i=1; i<=period; i++)
     {
      diff+=Differ[i];
      count++;
     }
   diff1=diff/count;                                            //volatility without current candle

   return(diff1);
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//  Several functions below are for info-panel
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void UpdateInfoWindow(int Ticker, int Neutralize)
  {
   //depositpercent = RiskDeposit*100/AccountBalance();
   //depositloadpersent=FindCurrentLoad();
   firstorderlot=Findfirstordervolume();
   if(Allowbuylevel==false)
   {
      allowbuy="Buy orders are forbidden!";
      buystepvalue=0;
      nextpricebuy=0;
      nextlotbuy=0;
   }
   if(Allowselllevel==false)
   {
      allowsell="Sell orders are forbidden!";     
      sellstepvalue=0;
      nextpricesell=0;
      nextlotsell=0; 
   }                                           
                                                                                                                //update all parameters of info-panel
   if(Ticker==1)
     ObjectSetText("Info_3","Power:  |",10,"Calibri",Textcolor);
   if(Ticker==2)
     ObjectSetText("Info_3","Power:  ||",10,"Calibri",Textcolor);
   if(Ticker==3)
     ObjectSetText("Info_3","Power:  |||",10,"Calibri",Textcolor);
   if(Ticker==4)
     ObjectSetText("Info_3","Power:  ||||",10,"Calibri",Textcolor);
   if(Ticker==5)
     ObjectSetText("Info_3","Power:  |||||",10,"Calibri",Textcolor);
   if(Ticker==6)
     ObjectSetText("Info_3","Power:  ||||||",10,"Calibri",Textcolor);
   if(Ticker==7)
     ObjectSetText("Info_3","Power:  |||||||",10,"Calibri",Textcolor);
   if(Ticker==8)
     ObjectSetText("Info_3","Power:  ||||||||",10,"Calibri",Textcolor);
   if(Ticker==9)
     ObjectSetText("Info_3","Power:  |||||||||",10,"Calibri",Textcolor);
   if(Ticker==10)
     ObjectSetText("Info_3","Power:  ||||||||||",10,"Calibri",Textcolor);
   if(Neutralize==0)
     {
     ObjectSetText("Info_4","Neutralizer BUY:  OFF"+DoubleToString(depositpercent,1)+"%",10,"Calibri",Textcolor);
     ObjectSetText("Info_5","Neutralizer SELL:  OFF"+DoubleToString(depositloadpersent,1)+"%",10,"Calibri",Textcolor);
     }
   if(Neutralize>0)
     {
     ObjectSetText("Info_4","Neutralizer BUY:  ON"+DoubleToString(depositpercent,1)+"%",10,"Calibri",Textcolor);
     ObjectSetText("Info_5","Neutralizer SELL:  OFF"+DoubleToString(depositloadpersent,1)+"%",10,"Calibri",Textcolor);
     }
   if(Neutralize<0)
     {
     ObjectSetText("Info_4","Neutralizer BUY:  OFF"+DoubleToString(depositpercent,1)+"%",10,"Calibri",Textcolor);
     ObjectSetText("Info_5","Neutralizer SELL:  ON"+DoubleToString(depositloadpersent,1)+"%",10,"Calibri",Textcolor);
     }
   
   ObjectSetText("Info_6","First orders volume:  "+DoubleToString(firstorderlot,2),10,"Calibri",Textcolor);
   
   ObjectSetText("Info_9",allowbuy,10,"Calibri",Textcolor);
   ObjectSetText("Info_10","Current crank: "+DoubleToString(currentstepbuy,0),10,"Calibri",Textcolor);
   ObjectSetText("Info_11","Total volume, lots: "+DoubleToString(sumlotbuy,2),10,"Calibri",Textcolor);
   ObjectSetText("Info_13","Total profit of opened: "+DoubleToString(buybasketprofit,1),10,"Calibri",Textcolor);
   ObjectSetText("Info_14","Current grid step: "+DoubleToString(buystepvalue,1)+"p.",10,"Calibri",Textcolor);
   ObjectSetText("Info_15","Next order open price: "+DoubleToString(nextpricebuy,Digits()),10,"Calibri",Textcolor);
   ObjectSetText("Info_16","Next order volume: "+DoubleToString(nextlotbuy,2),10,"Calibri",Textcolor);
   
   ObjectSetText("Info_19",allowsell,10,"Calibri",Textcolor);
   ObjectSetText("Info_20","Current crank: "+DoubleToString(currentstepsell,0),10,"Calibri",Textcolor);
   ObjectSetText("Info_21","Total volume, lots: "+DoubleToString(sumlotsell,2),10,"Calibri",Textcolor);
   ObjectSetText("Info_23","Total profit of opened: "+DoubleToString(sellbasketprofit,1),10,"Calibri",Textcolor);
   ObjectSetText("Info_24","Current grid step: "+DoubleToString(sellstepvalue,1)+"p.",10,"Calibri",Textcolor);
   ObjectSetText("Info_25","Next order open price: "+DoubleToString(nextpricesell,Digits()),10,"Calibri",Textcolor);
   ObjectSetText("Info_26","Next order volume: "+DoubleToString(nextlotsell,2),10,"Calibri",Textcolor);
  }
//+--------------------------------------------------------------------------+
//| Define start status                                                      |
//+--------------------------------------------------------------------------+
void UpdateBasketStatus()
  {
   if(Allowbuy==false)
     {
      switch(Stopmode_2)
        {
         case a: allowbuy = "Buy orders are forbidden!"; 
                 buystepvalue=0;
                 nextpricebuy=0;
                 nextlotbuy=0;
                 break;
         case s: allowbuy = "New baskets are forbidden!"; break;
         case n: allowbuy = "New crank is forbidden!"; 
                 buystepvalue=0;
                 nextpricebuy=0;
                 nextlotbuy=0;
                 break;
        }
      if (Flagbuyinfo==true)
      {
         allowbuy = "Volatility level is exceeded!";
         buystepvalue=0;
         nextpricebuy=0;
         nextlotbuy=0;
      }
     }
   else allowbuy="Buy orders are allowed!";
   if(Allowsell==false)
     {
      switch(Stopmode_2)
        {
         case a: allowsell = "Sell orders are forbidden!"; 
                 sellstepvalue=0;
                 nextpricesell=0;
                 nextlotsell=0;
                 break;
         case s: allowsell = "New baskets are forbidden!"; break;
         case n: allowsell = "New crank is forbidden!"; 
                 sellstepvalue=0;
                 nextpricesell=0;
                 nextlotsell=0;
                 break;
        }
      if (Flagsellinfo==true)
      {
         allowsell = "Volatility level is exceeded!";
         sellstepvalue=0;
         nextpricesell=0;
         nextlotsell=0;
      }
     }
   else allowsell="Sell orders are allowed!";
   if(AllowafterlevelBuy==false)
     {
      switch(Stopmode_3)
        {
         case s: allowbuy = "New baskets are forbidden!"; break;
         case n: allowbuy = "New crank is forbidden!"; 
                 buystepvalue=0;
                 nextpricebuy=0;
                 nextlotbuy=0;
                 break;
        }
     }
   if(AllowafterlevelSell==false)
     {
      switch(Stopmode_3)
        {
         case s: allowsell = "New baskets are forbidden!"; break;
         case n: allowsell = "New crank is forbidden!"; 
                 sellstepvalue=0;
                 nextpricesell=0;
                 nextlotsell=0;
                 break;
        }
     }
   if (CountBuyOrders()==0)
   {
      buystepvalue=0;
      nextpricebuy=0;
      nextlotbuy=0;
   }
   if (CountSellOrders()==0)
   {
      sellstepvalue=0;
      nextpricesell=0;
      nextlotsell=0;
   }
  }
//+--------------------------------------------------------------------------+
//| Calculation of the first basket order                                    |
//+--------------------------------------------------------------------------+
double Findfirstordervolume()
{

int LotsDigit=0;
double firstlot=0, MinLots=0, MaxLots=0, AcFrMar=0, Step=0, One_Lot=0;

MinLots=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
MaxLots=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);

if(Money_Management==False)
   {
   firstlot=Lot_Size;
   }

if(Money_Management==True)
   {
   One_Lot=MarketInfo(_Symbol,MODE_MARGINREQUIRED);
   
   Step=MarketInfo(_Symbol,MODE_LOTSTEP);
   
   AcFrMar=NormalizeDouble(AccountFreeMargin(),2);
   
   firstlot=MathFloor(AcFrMar*Margin_Percent/100/One_Lot/Step)*Step;
   
   }
   
if(firstlot>MaxLots)
  firstlot=MaxLots;
if(firstlot<MinLots)
  firstlot=MinLots;
  
return(firstlot);

}

//+------------------------------------------------------------------+
//| Error handler for opening orders                                 |
//+------------------------------------------------------------------+
int OrderSendx(string symbolx, int cmdx, double volumex, double pricex, int slippagex, double stoplossx, double takeprofitx, 
               string commentx, int magicx, datetime expirationx, color arrow_colorx)
  {
     int err = 0;
     bool exit_loop = false; 
     int ticketx = -1;
     int retry = 10;
     int cnt   = 0;
     if(CheckVolumeValue(volumex)==True && CheckMoneyForTrade(symbolx, volumex, cmdx)==True)
     {
     while (!exit_loop)
     {
        ticketx = OrderSend(symbolx, cmdx, volumex, pricex, slippagex, stoplossx, takeprofitx, commentx, magicx, expirationx, arrow_colorx);
        err = GetLastError();
        
        switch(err)
        {
               case ERR_NO_ERROR:           
                    exit_loop = true;
                    return(ticketx);
               case ERR_SERVER_BUSY:
               case ERR_NO_CONNECTION:
               case ERR_INVALID_PRICE:
               case ERR_TRADE_TIMEOUT:
               case ERR_OFF_QUOTES:
               case ERR_BROKER_BUSY:
               case ERR_TRADE_CONTEXT_BUSY:
                    cnt++;
                    break;
               case ERR_PRICE_CHANGED:
               case ERR_REQUOTE:
                    RefreshRates();
                    cnt++;
                    continue;
               default:
                    exit_loop = true;
                    break;      
        }
        if (cnt>retry)
        {
           exit_loop = true;
           Print("SyTurn Opening error after ", cnt, " attempts");
        }
        if (err != ERR_NO_ERROR)
            Print("SyTurn Error of opening - ", ErrorDescription(err));
        if (!exit_loop)
        {
            Sleep(3000);
            RefreshRates();
            if (cmdx==OP_SELL)
               pricex=Bid;
            if (cmdx==OP_BUY)
               pricex=Ask;
        }
        
     }
     return(ticketx);
     }
     else
     return(0);
  }

//+------------------------------------------------------------------+
//| Error handler for modifications of orders                        |
//+------------------------------------------------------------------+
bool OrderModifyx(int ticketx, double pricex, double stoplossx, double takeprofitx, datetime expirationx, color arrow_colorx)
  {
     int err = 0;
     bool exit_loop = false; 
     bool answer = false;
     int retry = 10;
     int cnt   = 0;
     
     while (!exit_loop)
     {
        answer = OrderModify(ticketx, pricex, stoplossx, takeprofitx, expirationx, arrow_colorx);
        err = GetLastError();
        
        switch(err)
        {
               case ERR_NO_ERROR:           
                    exit_loop = true;
                    return(answer);
               case ERR_SERVER_BUSY:
               case ERR_NO_CONNECTION:
               case ERR_INVALID_PRICE:
               case ERR_TRADE_TIMEOUT:
               case ERR_OFF_QUOTES:
               case ERR_BROKER_BUSY:
               case ERR_TRADE_CONTEXT_BUSY:
                    cnt++;
                    break;
               default:
                    exit_loop = true;
                    break;      
        }
        if (cnt>retry)
        {
           exit_loop = true;
           Print("SyTurn Modification error after ", cnt, " attempts");
        }
        if (err != ERR_NO_ERROR)
            Print("SyTurn Error of modification - ", ErrorDescription(err));
        if (!exit_loop)
        {
            Sleep(5000);
            RefreshRates();
        }
        
     }
     return(answer);
  }

//+------------------------------------------------------------------+
//| Error handler for closing of orders                              |
//+------------------------------------------------------------------+
bool OrderClosex(int cmdx, int ticketx, double lotsx, double pricex, int slippagex, color arrow_colorx)
  {
     int err = 0;
     bool exit_loop = false; 
     bool answer = false;
     int retry = 10;
     int cnt   = 0;
     
     while (!exit_loop)
     {
        answer = OrderClose(ticketx, lotsx, pricex, slippagex, arrow_colorx);
        err = GetLastError();
        
        switch(err)
        {
               case ERR_NO_ERROR:           
                    exit_loop = true;
                    return(answer);
               case ERR_SERVER_BUSY:
               case ERR_NO_CONNECTION:
               case ERR_INVALID_PRICE:
               case ERR_TRADE_TIMEOUT:
               case ERR_OFF_QUOTES:
               case ERR_BROKER_BUSY:
               case ERR_TRADE_CONTEXT_BUSY:
                    cnt++;
                    break;
               case ERR_PRICE_CHANGED:
               case ERR_REQUOTE:
                    RefreshRates();
                    cnt++;
                    continue;
               default:
                    exit_loop = true;
                    break;      
        }
        if (cnt>retry)
        {
           exit_loop = true;
           Print("SyTurn Closing error after ", cnt, " attempts");
        }
        if (err != ERR_NO_ERROR)
            Print("SyTurn Error of closing - ", ErrorDescription(err));
        if (!exit_loop)
        {
            Sleep(5000);
            RefreshRates();
            if (cmdx==OP_SELL)
               pricex=Ask;
            if (cmdx==OP_BUY)
               pricex=Bid;
        }
        
     }
     return(answer);
  }

//+------------------------------------------------------------------+
//| Errors description function                                      |
//+------------------------------------------------------------------+
string ErrorDescription(int error) 
  {
   string error_string;
   switch(error)
     {
      case 0:   error_string="no error";                                                   break;
      case 1:   error_string="no error, trade conditions not changed";                     break;
      case 2:   error_string="common error";                                               break;
      case 3:   error_string="invalid trade parameters";                                   break;
      case 4:   error_string="trade server is busy";                                       break;
      case 5:   error_string="old version of the client terminal";                         break;
      case 6:   error_string="no connection with trade server";                            break;
      case 7:   error_string="not enough rights";                                          break;
      case 8:   error_string="too frequent requests";                                      break;
      case 9:   error_string="malfunctional trade operation (never returned error)";       break;
      case 64:  error_string="account disabled";                                           break;
      case 65:  error_string="invalid account";                                            break;
      case 128: error_string="trade timeout";                                              break;
      case 129: error_string="invalid price";                                              break;
      case 130: error_string="invalid stops";                                              break;
      case 131: error_string="invalid trade volume";                                       break;
      case 132: error_string="market is closed";                                           break;
      case 133: error_string="trade is disabled";                                          break;
      case 134: error_string="not enough money";                                           break;
      case 135: error_string="price changed";                                              break;
      case 136: error_string="off quotes";                                                 break;
      case 137: error_string="broker is busy (never returned error)";                      break;
      case 138: error_string="requote";                                                    break;
      case 139: error_string="order is locked";                                            break;
      case 140: error_string="long positions only allowed";                                break;
      case 141: error_string="too many requests";                                          break;
      case 145: error_string="modification denied because order is too close to market";   break;
      case 146: error_string="trade context is busy";                                      break;
      case 147: error_string="expirations are denied by broker";                           break;
      case 148: error_string="amount of open and pending orders has reached the limit";    break;
      case 149: error_string="hedging is prohibited";                                      break;
      case 150: error_string="prohibited by FIFO rules";                                   break;
      case 4000: error_string="no error (never generated code)";                           break;
      case 4001: error_string="wrong function pointer";                                    break;
      case 4002: error_string="array index is out of range";                               break;
      case 4003: error_string="no memory for function call stack";                         break;
      case 4004: error_string="recursive stack overflow";                                  break;
      case 4005: error_string="not enough stack for parameter";                            break;
      case 4006: error_string="no memory for parameter string";                            break;
      case 4007: error_string="no memory for temp string";                                 break;
      case 4008: error_string="non-initialized string";                                    break;
      case 4009: error_string="non-initialized string in array";                           break;
      case 4010: error_string="no memory for array\' string";                              break;
      case 4011: error_string="too long string";                                           break;
      case 4012: error_string="remainder from zero divide";                                break;
      case 4013: error_string="zero divide";                                               break;
      case 4014: error_string="unknown command";                                           break;
      case 4015: error_string="wrong jump (never generated error)";                        break;
      case 4016: error_string="non-initialized array";                                     break;
      case 4017: error_string="dll calls are not allowed";                                 break;
      case 4018: error_string="cannot load library";                                       break;
      case 4019: error_string="cannot call function";                                      break;
      case 4020: error_string="expert function calls are not allowed";                     break;
      case 4021: error_string="not enough memory for temp string returned from function";  break;
      case 4022: error_string="system is busy (never generated error)";                    break;
      case 4023: error_string="dll-function call critical error";                          break;
      case 4024: error_string="internal error";                                            break;
      case 4025: error_string="out of memory";                                             break;
      case 4026: error_string="invalid pointer";                                           break;
      case 4027: error_string="too many formatters in the format function";                break;
      case 4028: error_string="parameters count is more than formatters count";            break;
      case 4029: error_string="invalid array";                                             break;
      case 4030: error_string="no reply from chart";                                       break;
      case 4050: error_string="invalid function parameters count";                         break;
      case 4051: error_string="invalid function parameter value";                          break;
      case 4052: error_string="string function internal error";                            break;
      case 4053: error_string="some array error";                                          break;
      case 4054: error_string="incorrect series array usage";                              break;
      case 4055: error_string="custom indicator error";                                    break;
      case 4056: error_string="arrays are incompatible";                                   break;
      case 4057: error_string="global variables processing error";                         break;
      case 4058: error_string="global variable not found";                                 break;
      case 4059: error_string="function is not allowed in testing mode";                   break;
      case 4060: error_string="function is not confirmed";                                 break;
      case 4061: error_string="send mail error";                                           break;
      case 4062: error_string="string parameter expected";                                 break;
      case 4063: error_string="integer parameter expected";                                break;
      case 4064: error_string="double parameter expected";                                 break;
      case 4065: error_string="array as parameter expected";                               break;
      case 4066: error_string="requested history data is in update state";                 break;
      case 4067: error_string="internal trade error";                                      break;
      case 4068: error_string="resource not found";                                        break;
      case 4069: error_string="resource not supported";                                    break;
      case 4070: error_string="duplicate resource";                                        break;
      case 4071: error_string="cannot initialize custom indicator";                        break;
      case 4072: error_string="cannot load custom indicator";                              break;
      case 4073: error_string="no history data";                                           break;
      case 4074: error_string="not enough memory for history data";                        break;
      case 4075: error_string="not enough memory for indicator";                           break;
      case 4099: error_string="end of file";                                               break;
      case 4100: error_string="some file error";                                           break;
      case 4101: error_string="wrong file name";                                           break;
      case 4102: error_string="too many opened files";                                     break;
      case 4103: error_string="cannot open file";                                          break;
      case 4104: error_string="incompatible access to a file";                             break;
      case 4105: error_string="no order selected";                                         break;
      case 4106: error_string="unknown symbol";                                            break;
      case 4107: error_string="invalid price parameter for trade function";                break;
      case 4108: error_string="invalid ticket";                                            break;
      case 4109: error_string="trade is not allowed in the expert properties";             break;
      case 4110: error_string="longs are not allowed in the expert properties";            break;
      case 4111: error_string="shorts are not allowed in the expert properties";           break;
      case 4200: error_string="object already exists";                                     break;
      case 4201: error_string="unknown object property";                                   break;
      case 4202: error_string="object does not exist";                                     break;
      case 4203: error_string="unknown object type";                                       break;
      case 4204: error_string="no object name";                                            break;
      case 4205: error_string="object coordinates error";                                  break;
      case 4206: error_string="no specified subwindow";                                    break;
      case 4207: error_string="graphical object error";                                    break;
      case 4210: error_string="unknown chart property";                                    break;
      case 4211: error_string="chart not found";                                           break;
      case 4212: error_string="chart subwindow not found";                                 break;
      case 4213: error_string="chart indicator not found";                                 break;
      case 4220: error_string="symbol select error";                                       break;
      case 4250: error_string="notification error";                                        break;
      case 4251: error_string="notification parameter error";                              break;
      case 4252: error_string="notifications disabled";                                    break;
      case 4253: error_string="notification send too frequent";                            break;
      case 4260: error_string="ftp server is not specified";                               break;
      case 4261: error_string="ftp login is not specified";                                break;
      case 4262: error_string="ftp connect failed";                                        break;
      case 4263: error_string="ftp connect closed";                                        break;
      case 4264: error_string="ftp change path error";                                     break;
      case 4265: error_string="ftp file error";                                            break;
      case 4266: error_string="ftp error";                                                 break;
      default:   error_string="unknown error";
     }
   return(error_string);
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

double APR_Walked(string mode, int j) {

double DayHigh;
double DayLow;
double DayRange;
double DayRangeLine[];
double Retracement[];
double Poin;

int NewSize = Stability_Period*3;
  //----  Checking the change of the zero bar
  if(ArraySize(DayRangeLine) < NewSize)
    {
      //---- Set the direct indexing direction in the array 
      ArraySetAsSeries(DayRangeLine, false);
      //---- Change the size of the emulated indicator buffers 
      ArrayResize(DayRangeLine, NewSize);  
      //---- Set the reverse indexing direction in the array 
      ArraySetAsSeries(DayRangeLine, true); 
    }
    
  if(ArraySize(Retracement) < NewSize)
    {
      //---- Set the direct indexing direction in the array 
      ArraySetAsSeries(Retracement, false);
      //---- Change the size of the emulated indicator buffers 
      ArrayResize(Retracement, NewSize);  
      //---- Set the reverse indexing direction in the array 
      ArraySetAsSeries(Retracement, true); 
    }

Poin = Point;
	//Checking for unconvetional Point digits number
   if ((Point == 0.00001) || (Point == 0.001)  || (Point == 0.01)  || (Point == 0.1))
   {
      Poin *= 10;
   }

string Date_Raw;
datetime Date_Filtered;
int Bar_Shift_From_DayStart, Bars_To_Screen, Bar_Shift_High, Bar_Shift_Low;
 
for(int i=0; i<=MathFloor(Stability_Period*1.5); i++)
      {
         Date_Raw=TimeToStr(iTime(_Symbol, Vektors_TF, i),TIME_DATE);
         Date_Filtered=StrToTime(Date_Raw);
         Bar_Shift_From_DayStart=iBarShift(_Symbol, Vektors_TF, Date_Filtered);
         Bars_To_Screen=Bar_Shift_From_DayStart-i;
         if(Bars_To_Screen==0)
           {
           DayRangeLine[i]=0;
           continue;
           }
         Bar_Shift_High = iHighest(_Symbol, Vektors_TF, MODE_HIGH, Bars_To_Screen, i);
         Bar_Shift_Low = iLowest(_Symbol, Vektors_TF, MODE_LOW, Bars_To_Screen, i);
         DayHigh = iHigh(_Symbol, Vektors_TF, Bar_Shift_High);
         DayLow = iLow(_Symbol, Vektors_TF, Bar_Shift_Low);
         DayRange = (DayHigh-DayLow)/Poin;
         DayRangeLine[i] = DayRange;
      
      }

if(mode=="Line")
  {
  return(DayRangeLine[j]);
  }
  
return(0);  

}

//---

int CloseAll()
{ 
   bool rv = NO_ERROR;
   int numOfOrders = OrdersTotal();
   int FirstOrderType = 0;
   int index = 0;
   bool Selection;
   
   for (index = 0; index < OrdersTotal(); index++)   
     {
       Selection=OrderSelect(index, SELECT_BY_POS, MODE_TRADES);
       if (OrderSymbol() == Symbol()) 
       {
         FirstOrderType = OrderType();
         break;
       }
     }   
         
   for(index = numOfOrders - 1; index >= 0; index--)
   {
      Selection=OrderSelect(index, SELECT_BY_POS, MODE_TRADES);
      
      if (OrderSymbol() == Symbol())
      switch (OrderType())
      {
         case OP_BUY: 
            if (!OrderClose(OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_BID), Slippage, Red))
               rv = AT_LEAST_ONE_FAILED;
            break;

         case OP_SELL:
            if (!OrderClose(OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_ASK), Slippage, Red))
               rv = AT_LEAST_ONE_FAILED;
            break;

         case OP_BUYLIMIT: 
         case OP_SELLLIMIT:
         case OP_BUYSTOP: 
         case OP_SELLSTOP:
            if (!OrderDelete(OrderTicket()))
               rv = AT_LEAST_ONE_FAILED;
            break;
      }
   }

   return(rv);
}

//--

bool CheckVolumeValue(double volume)
  {
//--- minimal allowed volume for trade operations
   double min_volume=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN);
   if(volume<min_volume)
     {
      //description=StringFormat("Volume is less than the minimal allowed SYMBOL_VOLUME_MIN=%.2f",min_volume);
      return(false);
     }

//--- maximal allowed volume of trade operations
   double max_volume=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX);
   if(volume>max_volume)
     {
      //description=StringFormat("Volume is greater than the maximal allowed SYMBOL_VOLUME_MAX=%.2f",max_volume);
      return(false);
     }

//--- get minimal step of volume changing
   double volume_step=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_STEP);

   int ratio=(int)MathRound(volume/volume_step);
   if(MathAbs(ratio*volume_step-volume)>0.0000001)
     {
      //description=StringFormat("Volume is not a multiple of the minimal step SYMBOL_VOLUME_STEP=%.2f, the closest correct volume is %.2f",
                               //volume_step,ratio*volume_step);
      return(false);
     }
   //description="Correct volume value";
   return(true);
  }

//--

bool CheckMoneyForTrade(string symb,double lots,int type)
  {
   double free_margin=AccountFreeMarginCheck(symb,type, lots);
   //-- if there is not enough money
   if(free_margin<0)
     {
      string oper=(type==OP_BUY)? "Buy":"Sell";
      //fPrint("Not enough money for ", oper," ",lots, " ", symb, " Error code=",GetLastError());
      return(false);
     }
   //--- checking successful
   return(true);
  }

//--

bool CheckStopLoss_Takeprofit(ENUM_ORDER_TYPE type, double SL, double TP)
  {
//--- get the SYMBOL_TRADE_STOPS_LEVEL level
   int stops_level=(int)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL);
//---
   bool SL_check=false,TP_check=false;
//--- check only two order types
   switch(type)
     {
      //--- Buy operation
      case  ORDER_TYPE_BUY:
        {
         //--- check the StopLoss
         SL_check=(Bid-SL>stops_level*_Point);
         if(SL==0)
           SL_check=True;
         //--- check the TakeProfit
         TP_check=(TP-Bid>stops_level*_Point);
         if(TP==0)
           TP_check=True;
         //--- return the result of checking
         return(SL_check&&TP_check);
        }
      //--- Sell operation
      case  ORDER_TYPE_SELL:
        {
         //--- check the StopLoss
         SL_check=(SL-Ask>stops_level*_Point);
         if(SL==0)
           SL_check=True;
         //--- check the TakeProfit
         TP_check=(Ask-TP>stops_level*_Point);
         if(TP==0)
           TP_check=True;
         //--- return the result of checking
         return(TP_check&&SL_check);
        }
      break;
     }
//--- a slightly different function is required for pending orders
   return false;
  }

//--

void ResetOrderArray(double &Buy_Loss_Array[][],double &Buy_Profit_Array[][],double &Sell_Loss_Array[][],double &Sell_Profit_Array[][], double &Aux_Array[][]) {
   
 for(int h=0; h<2; h++)  
   for(int k=0; k<MaxPos*4; k++)
      {
      Buy_Loss_Array[k][h]=0;
      Buy_Profit_Array[k][h]=0;
      Sell_Loss_Array[k][h]=0;
      Sell_Profit_Array[k][h]=0;
      Aux_Array[k][h]=0;
      }

}
//--

void ResetOrderArrayTarget(double &Aux_Array_Target[][]) {
   
 for(int h=0; h<2; h++)  
   for(int k=0; k<MaxPos*4; k++)
      {
      Aux_Array_Target[k][h]=0;
      }

}

//--

datetime OrderLaunch(string Action, double &Aux_Array_Target[][], int a, double Vol, int Order_Count)

{

//-- Point Value

int k=0;

if(Digits==5 || Digits==3)
  k=10;
else
  k=1;

//-- Opening Process

int i=0, j=0;
bool Order_Modificator=False;
int Order_Number=0;
datetime Time_Cached=0;

  if(Action=="SELL")
    {
    for(j=a; j>=0; j--)
      {
      if(Aux_Array_Target[j][1]==0 && Aux_Array_Target[j][0]!=0)
        {
        if(OrderSelect(StrToInteger(DoubleToString(Aux_Array_Target[j][0],0)), SELECT_BY_TICKET)==True)
        {
        if(CheckVolumeValue(OrderLots()*Order_Count)==True && CheckMoneyForTrade(_Symbol, OrderLots()*Order_Count, OP_SELL)==True)
        {
        for(i=0; i<Retry; i++)
          {
          RefreshRates();
          Order_Number=OrderSend(_Symbol,OP_SELL,OrderLots()*Order_Count,MarketInfo(_Symbol,MODE_BID),Slippage,0,0,NULL,Magic_Aux,0,Gold);
          if(Order_Number>0)
            {
            Aux_Array_Target[j][1]=1;  
            break;
            }
          }
        }
        }
        }
      }
    }  

  if(Action=="BUY")
    {
    for(j=a; j>=0; j--)
      {
      if(Aux_Array_Target[j][1]==0 && Aux_Array_Target[j][0]!=0)
        {
        if(OrderSelect(StrToInteger(DoubleToString(Aux_Array_Target[j][0],0)), SELECT_BY_TICKET)==True)
        {
        if(CheckVolumeValue(OrderLots()*Order_Count)==True && CheckMoneyForTrade(_Symbol, OrderLots()*Order_Count, OP_BUY)==True)
        {
        for(i=0; i<Retry; i++)
          {
          RefreshRates();
          Order_Number=-1;
          Order_Number=OrderSend(_Symbol,OP_BUY,OrderLots()*Order_Count,MarketInfo(_Symbol,MODE_ASK),Slippage,0,0,NULL,Magic_Aux,0,Gold);
          if(Order_Number>0)
            {
            Aux_Array_Target[j][1]=1;  
            break;
            }
          }
        }
        }
        }
      }
    }
    
  Time_Cached=iTime(_Symbol, _Period, 0);
  return(Time_Cached);
  
}

//--

bool CloseSelected(string TickeT, int _Retry)
  {
  
  bool Closing_Order=False;
  
  RefreshRates();
  
  if(OrderSelect(StrToInteger(TickeT),SELECT_BY_TICKET,MODE_TRADES)==True)
    {
    if(OrderMagicNumber()==Magic_Buy)
      if(OrderType()==OP_BUY)
        for(int i=0; i<_Retry; i++)
          {
          Closing_Order=OrderClose(OrderTicket(),OrderLots(),MarketInfo(_Symbol,MODE_BID),0,Red);
          if(Closing_Order==True)
            break;
          }
    if(OrderMagicNumber()==Magic_Sell)
      if(OrderType()==OP_SELL)
        for(int i=0; i<_Retry; i++)
          {
          Closing_Order=OrderClose(OrderTicket(),OrderLots(),MarketInfo(_Symbol,MODE_ASK),0,Red);
          if(Closing_Order==True)
            break;
          }
    if(OrderMagicNumber()==Magic_Aux)
      {
      if(OrderType()==OP_BUY)
        for(int i=0; i<_Retry; i++)
          {
          Closing_Order=OrderClose(OrderTicket(),OrderLots(),MarketInfo(_Symbol,MODE_BID),0,Red);
          if(Closing_Order==True)
            break;
          }
      if(OrderType()==OP_SELL)
        for(int i=0; i<_Retry; i++)
          {
          Closing_Order=OrderClose(OrderTicket(),OrderLots(),MarketInfo(_Symbol,MODE_ASK),0,Red);
          if(Closing_Order==True)
            break;
          }
      }
      
    return(True);
    }
  else
    return(False);
  
  }
