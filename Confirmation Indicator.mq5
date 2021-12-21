//+------------------------------------------------------------------+
//|                                                    EthersJMA.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Asymmetric Dynamics"
#property link      "Asymmetric Dynamics.com"
#property version   "1.00"
 
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots 2

//--- Plot Moving Average
#property indicator_label1 "Moving Average"
#property indicator_type1 DRAW_LINE
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

//--- Plot Williams % R
#property indicator_label2 "Williams % R"
#property indicator_type2 DRAW_LINE
#property indicator_color2  clrLime
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

//--- Moving Average Input Parameters
input int MovingAveragePeriod = 21;                        // Moving Average Period
input int MovingAverageShift = 0;                          // Moving Average shift
input ENUM_MA_METHOD MovingAverageMode = MODE_SMA;         // Moving Average Type 

//--- Williams % R Parameters
input int WilliamsPeriod=14; // Williams Period

//--- Indicator Buffer Arrays
double movingAverageBuffer[];
double williamsBuffer[];
int handleMovingAverage;
int handleWilliams;
int maxPeriod;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit(){
//--- Indicator buffers mapping   
   SetIndexBuffer(0,movingAverageBuffer,INDICATOR_DATA);  
   SetIndexBuffer(1,williamsBuffer,INDICATOR_DATA);    
//-- Setting a max period to start calculating the Moving Average and the Williams 
   maxPeriod = (int) MathMax(MovingAveragePeriod,WilliamsPeriod);
//-- Creating the handles    
   handleWilliams = iWPR(_Symbol,_Period,WilliamsPeriod);
   handleMovingAverage = iMA(_Symbol,_Period,MovingAveragePeriod,MovingAverageShift,MovingAverageMode,handleWilliams);
//-- Creating the plot index to draw the indicators
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,maxPeriod);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,maxPeriod);
      
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason){
   if(handleMovingAverage != INVALID_HANDLE) 
      IndicatorRelease(handleMovingAverage);
   if(handleWilliams != INVALID_HANDLE) 
      IndicatorRelease(handleWilliams);   
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,                               // rates_total number of available bars in history at the current tick
                const int prev_calculated,                           // prev_Calculated is number of bars calculated from the previous ticks
                const int begin,                                     // begin is the index value for the frist bar in history
                const double &price[]){                              // price[] is an Array that is the applied price such as the close or open or HLC of the indicator
//---Checking if MT5 stopped the indicator
   if(IsStopped())
      return(0);
   if(rates_total < maxPeriod)
      return(0);
//---Checking that the moving average and the williams have all been calculated
   if(BarsCalculated(handleMovingAverage) < rates_total)
      return(0);
   if(BarsCalculated(handleWilliams) < rates_total)
      return(0);  
      
   int copyBars = 0;
   if(prev_calculated > rates_total || prev_calculated <=0){
      copyBars = rates_total;   
   }
   else{
      copyBars = rates_total - prev_calculated;
      if(prev_calculated > 0) copyBars++;
   }
   if(CopyBuffer(handleMovingAverage,0,0,copyBars,movingAverageBuffer) <= 0)
      return(0);
   if(CopyBuffer(handleWilliams,0,0,copyBars,williamsBuffer) <= 0)
      return(0);                      
//--- return value of prev_calculated for next call
   return(rates_total);
}
//+------------------------------------------------------------------+
