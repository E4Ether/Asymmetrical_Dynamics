
#property copyright "Asymmetrical Dynamics"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade/Trade.mqh>
CTrade trade;

input double Lots = 0.01;
input    ENUM_TIMEFRAMES Timeframe = PERIOD_CURRENT;
input int AveragingPeriod = 14;
input int AveragingShift = 0;
input ENUM_MA_METHOD AveragingType = MODE_SMA;
input int BuyLinePeriod=14;
input int atrPeriod = 14;
input double Multiplier = 1.5;

int totalBars;
ulong posTicket;  
int indicatorHandle;
int atrHandle;
int fastMa;
int slowMa;
int buyMarker;

int OnInit(){
   totalBars = iBars(_Symbol,Timeframe);
   
   indicatorHandle = iCustom(_Symbol,Timeframe,"Confirmation Indicator.ex5",AveragingPeriod,AveragingShift,AveragingType,BuyLinePeriod);
   if(indicatorHandle == INVALID_HANDLE){
      PrintFormat("Error %i", GetLastError());
   }
   atrHandle = iATR(_Symbol,Timeframe,atrPeriod);
   if(atrHandle == INVALID_HANDLE){
      PrintFormat("Error %i", GetLastError());
   }
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason){
   IndicatorRelease(indicatorHandle);
   IndicatorRelease(atrHandle);
}   

void OnTick(){  
   // create your own array of the bars closing
   // the problem is the buffers are working on tick timimg we need bar timing
   // could we just declare greenLast or redLast as a static double?  it worked for the bid pricing and getting the "last bid" so would it work here? questions for chris
   
   int bars = iBars(_Symbol,Timeframe);
   bool barClosed = totalBars != bars;
   if(barClosed){
      totalBars = bars;
      
      double red[];      
      CopyBuffer(indicatorHandle,MAIN_LINE,1,3,red);
      ArraySetAsSeries(red,true);
   
      double green[];
      CopyBuffer(indicatorHandle,SIGNAL_LINE,1,3,green);
      ArraySetAsSeries(green,true);
      
      double atr[];
      CopyBuffer(atrHandle,0,0,1,atr);
      
      double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      ask = NormalizeDouble(ask,_Digits);
      
      double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
      bid = NormalizeDouble(bid,_Digits);
      
      double closePrice = iClose(_Symbol,Timeframe,1);
      double closePrice1 = iClose(_Symbol,Timeframe,2);
      
      bool buyCondition = green[1] >= red[1] && green[2] < red[2]; 
      if(buyCondition){
         //if(posTicket > 0){
            if(PositionSelectByTicket(posTicket)){
               if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
                  if(trade.PositionClose(posTicket)){
                     Print("Sell Order Was Succefully Closed Due to Buy Condition");
                  }                  
               }
            }
         //}
         double sl = ask - (atr[0] * Multiplier);
         sl = NormalizeDouble(sl,_Digits);
         
         double tp = ask + (atr[0] * Multiplier);
         tp = NormalizeDouble(tp,_Digits);
         
         //if(posTicket <= 0){
            uint resultCode = trade.ResultRetcode();       
            if(trade.Buy(Lots,_Symbol,ask,sl,tp) && resultCode == TRADE_RETCODE_DONE){       
               posTicket = trade.ResultOrder();  //Sending a buy order with trade.Buy and then getting the result and making posTicket = trade.ResultOrder to get the position ticket and thats what allows to pull the type with poisitiongetinteger
            }else{
               Print(__FUNCTION__,": error ",GetLastError(),", retcode = ",resultCode);
            }
         //}   
      }      
      bool sellCondition = green[1] <= red[1] && green[2] > red[2];
      if(sellCondition){
         //if(posTicket > 0){
            if(PositionSelectByTicket(posTicket)){
               if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
                  if(trade.PositionClose(posTicket)){
                     Print("Buy Order Was Succefully Closed Due to Sell Condition");
                  }                                                      
               }
            }
         //}
         double sl = bid + (atr[0] * Multiplier);
         sl = NormalizeDouble(sl,_Digits);
         
         double tp = bid - (atr[0] * Multiplier);
         tp = NormalizeDouble(tp,_Digits);

         //if(posTicket <= 0){ 
            uint resultCode = trade.ResultRetcode();       
            if(trade.Sell(Lots,_Symbol,bid,sl,tp) && resultCode  == TRADE_RETCODE_DONE){            
               posTicket = trade.ResultOrder(); 
               Print(__FUNCTION__,": error ",GetLastError(),", retcode = ",resultCode);
            }            
         //}
      }
      Comment("\nRed Line [0] ",red[0],
               "\nGreen Line [0] ", green[0],
               "\nRed Line last [1] ",red[1],
               "\nGreen Line last [1] ", green[1],
               "\nATR Value [0]", atr[0]);
               
      Print("\nRed Line [1] ",red[1],
      "\nGreen Line [1] ", green[1],
      "\nRed Line last [2] ",red[2],
      "\nGreen Line last [2] ", green[2],
      "\nbuy condition ", green[1] > red[1],
      "\nSell condition ",green[1] < red[1]);              
   }

}   


  
   
   
   
   
  
