//+------------------------------------------------------------------+
//| MediasMoveis2.mq5                                                |
//| TG - FATEC Indaiatuba (ADS). Cruzamento de medias moveis 10/20   |
//| de Almeida (2016), reproduzido: compra quando a rapida cruza a   |
//| lenta para cima, vende quando cruza para baixo. Mesma avaliacao  |
//| do ARIMA_GARCH_EA, para os modelos serem comparados com a mesma  |
//| regua.                                                           |
//+------------------------------------------------------------------+
#property copyright "TG - FATEC Indaiatuba (ADS)"
#property version   "2.00"
#property tester_file "selic_diaria.csv"
#property tester_file "proventos_PETR4.csv"
#property tester_file "proventos_VALE3.csv"
#property tester_file "proventos_USIM5.csv"
#property tester_file "proventos_POMO4.csv"

#include "..\Include\Negociacao.mqh"
#include "..\Include\Desempenho.mqh"

input group "Medias moveis"
input int                RapidaMM_Periodo   = 10;
input ENUM_MA_METHOD     RapidaMM_Metodo    = MODE_SMA;
input ENUM_APPLIED_PRICE RapidaMM_Preco     = PRICE_CLOSE;
input int                RapidaMM_Shift     = 0;
input int                DevagarMM_Periodo  = 20;
input ENUM_MA_METHOD     DevagarMM_Metodo   = MODE_SMA;
input ENUM_APPLIED_PRICE DevagarMM_Preco    = PRICE_CLOSE;
input int                DevagarMM_Shift    = 0;

input group "Negociacao"
input double             Volume_Fixo_Input  = 1.0;      // Volume fixo (acoes)
input int                StopLoss_Points    = 50;       // Stop Loss em pontos (0 = sem)
input int                TakeProfit_Points  = 100;      // Take Profit em pontos (0 = sem)
input ulong              MagicNumber        = 12349;
input int                Slippage_Points    = 10;
input bool               TradeOnNewBarOnly  = true;     // Operar so na abertura da barra
input double             Fracao_Capital     = 0.0;      // > 0: volume = fracao do patrimonio
input bool               SomenteCompra      = false;    // Sinal de venda so zera a compra

input group "Avaliacao (Strategy Tester)"
input double             Custo_Por_Lado     = 0.0003;   // Custo B3 por execucao (fracao do valor)
input string             Arquivo_Proventos  = "proventos_PETR4.csv"; // Proventos por data-ex
input string             Rotulo             = "";       // Nome das metricas e da curva (vazio = nao grava)

CNegociacao g_negociacao;
CDesempenho g_desempenho;
bool        g_no_testador = false;

int      g_media_rapida;
int      g_media_lenta;
int      g_casas_decimais;
double   g_volume_fixo;

int OnInit()
  {
   g_media_rapida = iMA(_Symbol, _Period, RapidaMM_Periodo, RapidaMM_Shift, RapidaMM_Metodo, RapidaMM_Preco);
   g_media_lenta  = iMA(_Symbol, _Period, DevagarMM_Periodo, DevagarMM_Shift, DevagarMM_Metodo, DevagarMM_Preco);
   if(g_media_rapida == INVALID_HANDLE || g_media_lenta == INVALID_HANDLE)
      return(INIT_FAILED);

   g_negociacao.Configurar(_Symbol, MagicNumber, Slippage_Points);
   g_casas_decimais = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   g_volume_fixo = VolumeFixoDoSimbolo(Volume_Fixo_Input);

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

void OnDeinit(const int reason)
  {
   IndicatorRelease(g_media_rapida);
   IndicatorRelease(g_media_lenta);
  }

//--- Volume dentro do minimo e do maximo do simbolo, arredondado ao passo
double VolumeFixoDoSimbolo(double volume)
  {
   double minimo = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maximo = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double passo  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   if(volume < minimo) volume = minimo;
   if(volume > maximo) volume = maximo;
   if(passo > 0 && MathAbs(MathMod(volume, passo)) > 1e-10)
     {
      volume = MathRound(volume / passo) * passo;
      volume = NormalizeDouble(volume, (passo < 1.0) ? 8 : 0);
     }
   if(volume < minimo) volume = minimo;
   return(volume);
  }

double VolumeDaOrdem(const double preco)
  {
   if(Fracao_Capital <= 0.0)
      return(g_volume_fixo);
   return(VolumePorCapital(_Symbol, Fracao_Capital, preco));
  }

void OnTick()
  {
   //--- Registro na abertura de cada barra, antes de qualquer ordem
   static datetime barra_registrada = 0;
   datetime barra = (datetime)SeriesInfoInteger(_Symbol, _Period, SERIES_LASTBAR_DATE);
   if(g_no_testador && barra != barra_registrada)
     {
      barra_registrada = barra;
      g_desempenho.RegistrarAgora(barra);
     }

   if(TradeOnNewBarOnly)
     {
      static datetime barra_operada = 0;
      if(barra == barra_operada)
         return;
      barra_operada = barra;
     }

   //--- Medias da ultima barra fechada (1) e da anterior (2)
   double valor[1];
   if(CopyBuffer(g_media_rapida, 0, 1, 1, valor) != 1) return;
   double rapida_agora = valor[0];
   if(CopyBuffer(g_media_lenta, 0, 1, 1, valor) != 1) return;
   double lenta_agora = valor[0];
   if(CopyBuffer(g_media_rapida, 0, 2, 1, valor) != 1) return;
   double rapida_antes = valor[0];
   if(CopyBuffer(g_media_lenta, 0, 2, 1, valor) != 1) return;
   double lenta_antes = valor[0];

   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick) || tick.ask == 0 || tick.bid == 0)
      return;

   ENUM_POSITION_TYPE posicao = g_negociacao.PosicaoAtual();
   double distancia_minima = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;

   if(rapida_agora > lenta_agora && rapida_antes <= lenta_antes)
     {
      if(posicao == POSITION_TYPE_SELL)
        {
         if(!g_negociacao.Fechar(POSITION_TYPE_SELL))
            return;
         Sleep(1);
         posicao = g_negociacao.PosicaoAtual();
        }
      if(posicao != POSITION_TYPE_BUY)
        {
         double preco = tick.ask, stop_loss = 0, take_profit = 0;
         if(StopLoss_Points > 0)
           {
            stop_loss = NormalizeDouble(preco - StopLoss_Points * _Point, g_casas_decimais);
            if(distancia_minima > 0 && preco - stop_loss < distancia_minima)
               stop_loss = NormalizeDouble(preco - distancia_minima, g_casas_decimais);
            if(stop_loss >= preco) stop_loss = 0;
           }
         if(TakeProfit_Points > 0)
           {
            take_profit = NormalizeDouble(preco + TakeProfit_Points * _Point, g_casas_decimais);
            if(distancia_minima > 0 && take_profit - preco < distancia_minima)
               take_profit = NormalizeDouble(preco + distancia_minima, g_casas_decimais);
            if(take_profit <= preco) take_profit = 0;
           }
         g_negociacao.Comprar(VolumeDaOrdem(preco), preco, stop_loss, take_profit, "Compra MM Rev");
        }
      return;
     }

   if(rapida_agora < lenta_agora && rapida_antes >= lenta_antes)
     {
      if(posicao == POSITION_TYPE_BUY)
        {
         if(!g_negociacao.Fechar(POSITION_TYPE_BUY))
            return;
         Sleep(1);
         posicao = g_negociacao.PosicaoAtual();
        }
      if(SomenteCompra)
         return;
      if(posicao != POSITION_TYPE_SELL)
        {
         double preco = tick.bid, stop_loss = 0, take_profit = 0;
         if(StopLoss_Points > 0)
           {
            stop_loss = NormalizeDouble(preco + StopLoss_Points * _Point, g_casas_decimais);
            if(distancia_minima > 0 && stop_loss - preco < distancia_minima)
               stop_loss = NormalizeDouble(preco + distancia_minima, g_casas_decimais);
            if(stop_loss <= preco) stop_loss = 0;
           }
         if(TakeProfit_Points > 0)
           {
            take_profit = NormalizeDouble(preco - TakeProfit_Points * _Point, g_casas_decimais);
            if(distancia_minima > 0 && preco - take_profit < distancia_minima)
               take_profit = NormalizeDouble(preco - distancia_minima, g_casas_decimais);
            if(take_profit >= preco) take_profit = 0;
           }
         g_negociacao.Vender(VolumeDaOrdem(preco), preco, stop_loss, take_profit, "Venda MM Rev");
        }
     }
  }

//--- Fim do teste: metricas contra a Selic e a compra e manutencao
double OnTester()
  {
   g_desempenho.RegistrarAgora(TimeCurrent());

   ResultadoDesempenho resultado;
   if(!g_desempenho.Calcular(resultado))
      return(0.0);

   g_desempenho.Imprimir(resultado);
   string cabecalho = "modelo;MM_rapida;MM_lenta;StopLoss;TakeProfit;Volume_Fixo;Fracao_Capital;SomenteCompra";
   string valores = StringFormat("MM;%d;%d;%d;%d;%.0f;%.2f;%d", RapidaMM_Periodo, DevagarMM_Periodo,
                                 StopLoss_Points, TakeProfit_Points, g_volume_fixo, Fracao_Capital, SomenteCompra);
   g_desempenho.Gravar(Rotulo, cabecalho, valores, resultado);
   return(resultado.excesso * 100.0);
  }
