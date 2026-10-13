//+------------------------------------------------------------------+
//| EA_MM_Crossover_SLTP_v1.06.mq5                                   |
//+------------------------------------------------------------------+
#property copyright "Adaptado por [Seu Nome/Assistente Virtual]"
#property link      "https://www.mql5.com"
#property version   "1.06"
#property description "Cruzamento de MM com SL/TP e reversão"

#include <Trade\Trade.mqh>
#include "..\Include\Estrategia.mqh"
#include "..\Include\Desempenho.mqh"

//--- Mesma avaliacao do ARIMA_GARCH_EA (Selic, buy-and-hold, Sharpe...),
//--- para os tres modelos serem comparados com a mesma regua.
#property tester_file "selic_diaria.csv"
#property tester_file "proventos_PETR4.csv"
#property tester_file "proventos_VALE3.csv"
#property tester_file "proventos_USIM5.csv"
#property tester_file "proventos_POMO4.csv"

CTrade Trade;
CDesempenho g_desempenho;
bool g_no_testador = false;

input group "Parâmetros das Médias Móveis"
input int                RapidaMM_Periodo   = 10;
input ENUM_MA_METHOD     RapidaMM_Metodo    = MODE_SMA;
input ENUM_APPLIED_PRICE RapidaMM_Preco     = PRICE_CLOSE;
input int                RapidaMM_Shift     = 0;

input int                DevagarMM_Periodo  = 20;
input ENUM_MA_METHOD     DevagarMM_Metodo   = MODE_SMA;
input ENUM_APPLIED_PRICE DevagarMM_Preco    = PRICE_CLOSE;
input int                DevagarMM_Shift    = 0;

input group "Parâmetros de Negociação"
input double             Volume_Fixo_Input  = 1.0; 
input int                StopLoss_Points    = 50;
input int                TakeProfit_Points  = 100;
input ulong              MagicNumber        = 12349; 
input int                Slippage_Points    = 10;
input bool               TradeOnNewBarOnly  = true;
input double             Fracao_Capital     = 0.0;    // >0: volume = fracao do patrimonio (ignora Volume_Fixo_Input)
input bool               SomenteCompra      = false;  // Sinal de venda apenas zera a compra (sem venda a descoberto)

input group "Avaliação (Strategy Tester)"
input double             Custo_Por_Lado     = 0.0003; // Custo B3 por execucao (fracao do valor negociado)
input string             Arquivo_Proventos  = "proventos_PETR4.csv"; // Proventos por data-ex (so avaliacao)
input string             Rotulo             = "";     // Nome da curva diaria exportada (vazio = nao exporta)

int      h_RapidaMM;
int      h_DevagarMM;
datetime gl_TimeUltimaBarraProcessada = 0;
int      gl_DigitsPrice;
double   g_VolumeOperacional; 

//+------------------------------------------------------------------+
int OnInit()
{
   g_VolumeOperacional = Volume_Fixo_Input; 

   h_RapidaMM = iMA(_Symbol, _Period, RapidaMM_Periodo, RapidaMM_Shift, RapidaMM_Metodo, RapidaMM_Preco);
   if(h_RapidaMM == INVALID_HANDLE) return(INIT_FAILED);

   h_DevagarMM = iMA(_Symbol, _Period, DevagarMM_Periodo, DevagarMM_Shift, DevagarMM_Metodo, DevagarMM_Preco);
   if(h_DevagarMM == INVALID_HANDLE) return(INIT_FAILED);
   
   Trade.SetExpertMagicNumber(MagicNumber);
   Trade.SetDeviationInPoints(Slippage_Points);
   Trade.SetTypeFillingBySymbol(_Symbol);
   
   gl_DigitsPrice = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   
   double min_volume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double max_volume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step_volume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   if(g_VolumeOperacional < min_volume) g_VolumeOperacional = min_volume;
   if(g_VolumeOperacional > max_volume) g_VolumeOperacional = max_volume;
   
   if(step_volume > 0) {
      double remainder = MathMod(g_VolumeOperacional, step_volume);
      if(MathAbs(remainder) > 1e-10) { 
          g_VolumeOperacional = MathRound(g_VolumeOperacional / step_volume) * step_volume;
          int volume_digits = 0;
          if(step_volume < 1.0 && step_volume > 0) {
            string step_str = DoubleToString(step_volume, 8);
            int dot_pos = StringFind(step_str, ".");
            if(dot_pos != -1) volume_digits = StringLen(step_str) - dot_pos - 1;
          }
          g_VolumeOperacional = NormalizeDouble(g_VolumeOperacional, volume_digits);
      }
   }
   if(g_VolumeOperacional < min_volume) g_VolumeOperacional = min_volume;

   g_no_testador = (bool)MQLInfoInteger(MQL_TESTER);
   if(g_no_testador)
   {
      g_desempenho.Definir(_Symbol, MagicNumber, Custo_Por_Lado);
      if(!g_desempenho.CarregarSelic("selic_diaria.csv"))
         Print("AVISO: selic_diaria.csv nao encontrado - caixa parado rendera 0");
      if(!g_desempenho.CarregarProventos(Arquivo_Proventos))
         Print("AVISO: ", Arquivo_Proventos, " nao encontrado - camada de proventos = 0");
   }

   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(h_RapidaMM != INVALID_HANDLE) IndicatorRelease(h_RapidaMM);
   if(h_DevagarMM != INVALID_HANDLE) IndicatorRelease(h_DevagarMM);
}
//+------------------------------------------------------------------+
ENUM_POSITION_TYPE ObterTipoPosicaoAtual() {
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        ulong ticket = PositionGetTicket(i);
        if(ticket > 0 && PositionSelectByTicket(ticket)) {
            if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
               PositionGetInteger(POSITION_MAGIC) == MagicNumber) {
                return (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            }
        }
    }
    return (ENUM_POSITION_TYPE)-1; 
}
//+------------------------------------------------------------------+
bool FecharPosicaoAtual(ENUM_POSITION_TYPE tipoPosicaoParaFechar) {
    if (tipoPosicaoParaFechar == POSITION_TYPE_BUY || tipoPosicaoParaFechar == POSITION_TYPE_SELL) {
        for(int i = PositionsTotal() - 1; i >= 0; i--) {
            ulong ticket = PositionGetTicket(i);
            if(ticket > 0 && PositionSelectByTicket(ticket)) {
                if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
                   PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
                   PositionGetInteger(POSITION_TYPE) == tipoPosicaoParaFechar) {
                    
                    if(Trade.PositionClose(ticket, Slippage_Points)) { 
                        return true;
                    } else {
                        return false;
                    }
                }
            }
        }
    }
    return true; 
}
//+------------------------------------------------------------------+
double VolumeAtual(const double preco)
{
   if(Fracao_Capital <= 0.0) return g_VolumeOperacional;
   return VolumePorCapital(_Symbol, Fracao_Capital, preco);
}
//+------------------------------------------------------------------+
void OnTick()
{
   //--- Registro na abertura de cada barra, antes de qualquer ordem
   static datetime barraRegistrada = 0;
   datetime barraAtual = (datetime)SeriesInfoInteger(_Symbol, _Period, SERIES_LASTBAR_DATE);
   if(g_no_testador && barraAtual != barraRegistrada)
   {
      barraRegistrada = barraAtual;
      g_desempenho.RegistrarAgora(barraAtual);
   }

   if(TradeOnNewBarOnly)
   {
      static datetime prevTime = 0;
      datetime currentTime = (datetime)SeriesInfoInteger(_Symbol, _Period, SERIES_LASTBAR_DATE);
      if(currentTime == prevTime) return;
      prevTime = currentTime;
   }

   double arr_temp[1];
   double maRapidaAnterior, maLentaAnterior, maRapidaAntesDoCruzamento, maLentaAntesDoCruzamento;

   if(CopyBuffer(h_RapidaMM, 0, 1, 1, arr_temp) != 1) return; maRapidaAnterior = arr_temp[0];
   if(CopyBuffer(h_DevagarMM, 0, 1, 1, arr_temp) != 1) return; maLentaAnterior  = arr_temp[0];
   if(CopyBuffer(h_RapidaMM, 0, 2, 1, arr_temp) != 1) return; maRapidaAntesDoCruzamento = arr_temp[0];
   if(CopyBuffer(h_DevagarMM, 0, 2, 1, arr_temp) != 1) return; maLentaAntesDoCruzamento  = arr_temp[0];

   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick) || tick.ask == 0 || tick.bid == 0) return;
   double askPrice = tick.ask;
   double bidPrice = tick.bid;

   ENUM_POSITION_TYPE tipoPosicaoAtual = ObterTipoPosicaoAtual();

   bool condicaoCompra = maRapidaAnterior > maLentaAnterior && maRapidaAntesDoCruzamento <= maLentaAntesDoCruzamento;
   if(condicaoCompra)
   {
      if(tipoPosicaoAtual == POSITION_TYPE_SELL) { 
          if(!FecharPosicaoAtual(POSITION_TYPE_SELL)) return; 
          Sleep(1);
          tipoPosicaoAtual = ObterTipoPosicaoAtual(); 
      }

      if(tipoPosicaoAtual != POSITION_TYPE_BUY) { 
          double sl = 0, tp = 0;
          double stop_level_points = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
          double min_distance_sl_tp = stop_level_points * _Point;
          
          if(StopLoss_Points > 0) {
              sl = NormalizeDouble(askPrice - StopLoss_Points * _Point, gl_DigitsPrice);
              if (min_distance_sl_tp > 0 && askPrice - sl < min_distance_sl_tp) {
                 sl = NormalizeDouble(askPrice - min_distance_sl_tp, gl_DigitsPrice);
              }
              if (sl >= askPrice) sl = 0; 
          }
          if(TakeProfit_Points > 0) {
              tp = NormalizeDouble(askPrice + TakeProfit_Points * _Point, gl_DigitsPrice);
              if (min_distance_sl_tp > 0 && tp - askPrice < min_distance_sl_tp) {
                 tp = NormalizeDouble(askPrice + min_distance_sl_tp, gl_DigitsPrice);
              }
              if (tp <= askPrice && TakeProfit_Points > 0) tp = 0;
          }
          
          Trade.Buy(VolumeAtual(askPrice), _Symbol, askPrice, sl, tp, "Compra MM Rev");
      }
      return; 
   }

   bool condicaoVenda = maRapidaAnterior < maLentaAnterior && maRapidaAntesDoCruzamento >= maLentaAntesDoCruzamento;
   if(condicaoVenda)
   {
      if(tipoPosicaoAtual == POSITION_TYPE_BUY) { 
          if(!FecharPosicaoAtual(POSITION_TYPE_BUY)) return;
          Sleep(1);
          tipoPosicaoAtual = ObterTipoPosicaoAtual(); 
      }
      if(SomenteCompra) return;
      
      if(tipoPosicaoAtual != POSITION_TYPE_SELL) { 
          double sl = 0, tp = 0;
          double stop_level_points = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
          double min_distance_sl_tp = stop_level_points * _Point;

          if(StopLoss_Points > 0) {
              sl = NormalizeDouble(bidPrice + StopLoss_Points * _Point, gl_DigitsPrice);
              if (min_distance_sl_tp > 0 && sl - bidPrice < min_distance_sl_tp) {
                 sl = NormalizeDouble(bidPrice + min_distance_sl_tp, gl_DigitsPrice);
              }
              if (sl <= bidPrice) sl = 0; 
          }
          if(TakeProfit_Points > 0) {
              tp = NormalizeDouble(bidPrice - TakeProfit_Points * _Point, gl_DigitsPrice);
              if (min_distance_sl_tp > 0 && bidPrice - tp < min_distance_sl_tp) {
                 tp = NormalizeDouble(bidPrice - min_distance_sl_tp, gl_DigitsPrice);
              }
              if (tp >= bidPrice && TakeProfit_Points > 0) tp = 0;
          }

          Trade.Sell(VolumeAtual(bidPrice), _Symbol, bidPrice, sl, tp, "Venda MM Rev");
      }
      return;
   }
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Fim do teste: metricas contra a Selic e o buy-and-hold           |
//+------------------------------------------------------------------+
double OnTester()
{
   g_desempenho.RegistrarAgora(TimeCurrent());

   ResultadoDesempenho r;
   if(!g_desempenho.Calcular(r)) return 0.0;

   g_desempenho.Imprimir(r);

   string cab = "modelo;MM_rapida;MM_lenta;StopLoss;TakeProfit;Volume_Fixo;Fracao_Capital;SomenteCompra";
   string val = StringFormat("MM;%d;%d;%d;%d;%.0f;%.2f;%d", RapidaMM_Periodo, DevagarMM_Periodo,
                             StopLoss_Points, TakeProfit_Points, g_VolumeOperacional,
                             Fracao_Capital, SomenteCompra);
   g_desempenho.Gravar(Rotulo, cab, val, r);
   return r.excesso * 100.0;
}
//+------------------------------------------------------------------+
