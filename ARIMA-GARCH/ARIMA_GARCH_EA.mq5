//+------------------------------------------------------------------+
//|                                              ARIMA_GARCH_EA.mq5  |
//|                    Expert Advisor ARIMA-GARCH                    |
//|                                                                  |
//|           Trabalho de Graduação - FATEC Indaiatuba (ADS)        |
//|       Tema: Previsão e Análise de Tendências em Ativos          |
//|                                                                  |
//|  Combina:                                                        |
//|    - ARIMA(p,d,q) para previsão de tendência (média)           |
//|    - GARCH(p,q) para modelagem de volatilidade (variância)      |
//+------------------------------------------------------------------+

#property copyright "TG - FATEC Indaiatuba (ADS)"
#property link      "https://www.fatec.sp.gov.br"
#property version   "1.00"
#property description "Expert Advisor ARIMA-GARCH para negociação automatizada"
#property description "Combina ARIMA (tendencia) + GARCH (volatilidade)"
#property description "Pronto para backtesting no Strategy Tester"

#include "GARCH.mq5"
#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//| PARAMETROS DE ENTRADA                                            |
//+------------------------------------------------------------------+

input group "=== Modelo ARIMA(p,d,q) ==="
input int    ARIMA_p                = 1;
input int    ARIMA_d                = 1;
input int    ARIMA_q                = 1;
input int    Janela_Dados           = 100;
input int    Iteracoes_ARIMA        = 200;
input double Taxa_Aprendizado       = 0.001;

input group "=== Modelo GARCH(p,q) ==="
input int    GARCH_p                = 1;
input int    GARCH_q                = 1;
input int    Iteracoes_GARCH        = 200;

input group "=== Estrategia de Trading (Filter + Volatility Targeting) ==="
input double Volume_Fixo            = 10.0;
input int    StopLoss_Points        = 100;
input int    TakeProfit_Points      = 200;
input double Limiar_Volatilidade    = 0.02;
input bool   UsarVolatilityTargeting = true;
input bool   OnlyOnNewBar           = true;
input bool   ShowDiagnostics        = true;

input group "=== Sistema ==="
input ulong  MagicNumber            = 20260324;
input int    Slippage               = 10;

//+------------------------------------------------------------------+
//| VARIAVEIS GLOBAIS                                                |
//+------------------------------------------------------------------+

CTrade Trade;
GARCH* garch_model = NULL;

double gl_phi[];
double gl_theta[];
double gl_constante = 0.0;
double gl_residuos[];

int    gl_DigitsPrice;
double gl_VolumeOperacional;

//+------------------------------------------------------------------+
//| INICIALIZACAO                                                    |
//+------------------------------------------------------------------+

int OnInit()
{
   Print("ARIMA-GARCH EA inicializado");
   Print("ARIMA(", ARIMA_p, ",", ARIMA_d, ",", ARIMA_q, ") + GARCH(", GARCH_p, ",", GARCH_q, ")");
   Print("Simbolo: ", _Symbol, " | Volume: ", Volume_Fixo, " lotes");

   if(ARIMA_p < 0 || ARIMA_q < 0 || ARIMA_d < 0 || ARIMA_d > 2)
   {
      Print("ERRO: Parametros ARIMA invalidos");
      return INIT_FAILED;
   }

   if(GARCH_p < 0 || GARCH_q < 0)
   {
      Print("ERRO: Parametros GARCH invalidos");
      return INIT_FAILED;
   }

   ArrayResize(gl_phi, ARIMA_p);
   ArrayResize(gl_theta, ARIMA_q);
   ArrayInitialize(gl_phi, 0.0);
   ArrayInitialize(gl_theta, 0.0);

   garch_model = new GARCH(GARCH_p, GARCH_q);

   Trade.SetExpertMagicNumber(MagicNumber);
   Trade.SetDeviationInPoints(Slippage);
   Trade.SetTypeFillingBySymbol(_Symbol);

   gl_DigitsPrice = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   gl_VolumeOperacional = AjustarVolume(Volume_Fixo);

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| DESINICIALIZACAO                                                 |
//+------------------------------------------------------------------+

void OnDeinit(const int reason)
{
   if(garch_model != NULL)
      delete garch_model;
}

//+------------------------------------------------------------------+
//| LOGICA PRINCIPAL - A CADA TICK                                   |
//+------------------------------------------------------------------+

void OnTick()
{
   if(OnlyOnNewBar)
   {
      static datetime ultimaBarra = 0;
      datetime barraAtual = (datetime)SeriesInfoInteger(_Symbol, _Period, SERIES_LASTBAR_DATE);
      if(barraAtual == ultimaBarra) return;
      ultimaBarra = barraAtual;
   }

   double precos[];
   int copiados = CopyClose(_Symbol, _Period, 0, Janela_Dados + 1, precos);
   if(copiados < Janela_Dados + 1)
   {
      Print("Dados insuficientes");
      return;
   }

   //--- PASSO 1: ARIMA ---
   double serie_diff[];
   Diferenciar(precos, serie_diff, ARIMA_d);

   int tamanho_serie = ArraySize(serie_diff);
   if(tamanho_serie < ARIMA_p + ARIMA_q + 20)
      return;

   EstimarCoeficientesCSS(serie_diff);
   CalcularResiduos(serie_diff, gl_residuos);

   double previsao_diff = PreverProximoValor(serie_diff, gl_residuos);
   double preco_previsto = ReverterDiferenciacao(precos, previsao_diff, ARIMA_d);
   double preco_atual = precos[ArraySize(precos) - 1];

   //--- PASSO 2: GARCH ---
   if(garch_model != NULL)
   {
      garch_model.Fit(gl_residuos, Iteracoes_GARCH, 0.001);

      double vol_forecast[];
      if(!garch_model.ForecastVolatility(1, vol_forecast))
         return;

      double volatilidade = vol_forecast[0];

      //--- PASSO 3: GERAR SINAL COM FILTER ---
      int sinal = 0;
      double volume_ajustado = gl_VolumeOperacional;

      // FILTER: Só opera se volatilidade abaixo do limiar
      if(volatilidade <= Limiar_Volatilidade)
      {
         // Sinal de direção: ARIMA prevê subida ou queda?
         double mudanca = preco_previsto - preco_atual;

         if(mudanca > 0)
            sinal = 1;  // Compra
         else if(mudanca < 0)
            sinal = -1; // Venda

         // VOLATILITY TARGETING: Ajusta volume inversamente à volatilidade
         if(UsarVolatilityTargeting && volatilidade > 0)
         {
            volume_ajustado = gl_VolumeOperacional / (1.0 + volatilidade * 100);
            volume_ajustado = MathMax(gl_VolumeOperacional * 0.1, volume_ajustado);
         }
      }

      if(ShowDiagnostics)
      {
         Print("--- ARIMA-GARCH ---");
         Print("Preco atual: ", DoubleToString(preco_atual, gl_DigitsPrice));
         Print("Preco previsto: ", DoubleToString(preco_previsto, gl_DigitsPrice));
         Print("Volatilidade GARCH: ", DoubleToString(volatilidade, 6));
         Print("Limiar volatilidade: ", DoubleToString(Limiar_Volatilidade, 6));

         if(volatilidade > Limiar_Volatilidade)
            Print("STATUS: Volatilidade alta - SEM OPERACOES");
         else
         {
            if(sinal == 1) Print("SINAL: COMPRA");
            else if(sinal == -1) Print("SINAL: VENDA");
            else Print("SINAL: NEUTRO");
            if(UsarVolatilityTargeting)
               Print("Volume ajustado: ", DoubleToString(volume_ajustado, 2), " lotes");
         }
      }

      //--- PASSO 4: EXECUTAR ---
      if(sinal != 0)
      {
         MqlTick tick;
         if(!SymbolInfoTick(_Symbol, tick))
            return;

         ENUM_POSITION_TYPE posicao = ObterPosicao();

         if(sinal == 1)
         {
            if(posicao == POSITION_TYPE_SELL)
               FecharPosicao(POSITION_TYPE_SELL);

            if(posicao != POSITION_TYPE_BUY)
            {
               double sl = (StopLoss_Points > 0) ? NormalizeDouble(tick.ask - StopLoss_Points * _Point, gl_DigitsPrice) : 0;
               double tp = (TakeProfit_Points > 0) ? NormalizeDouble(tick.ask + TakeProfit_Points * _Point, gl_DigitsPrice) : 0;
               Trade.Buy(volume_ajustado, _Symbol, tick.ask, sl, tp, "ARIMA-GARCH BUY");
            }
         }
         else if(sinal == -1)
         {
            if(posicao == POSITION_TYPE_BUY)
               FecharPosicao(POSITION_TYPE_BUY);

            if(posicao != POSITION_TYPE_SELL)
            {
               double sl = (StopLoss_Points > 0) ? NormalizeDouble(tick.bid + StopLoss_Points * _Point, gl_DigitsPrice) : 0;
               double tp = (TakeProfit_Points > 0) ? NormalizeDouble(tick.bid - TakeProfit_Points * _Point, gl_DigitsPrice) : 0;
               Trade.Sell(volume_ajustado, _Symbol, tick.bid, sl, tp, "ARIMA-GARCH SELL");
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| FUNCOES ARIMA                                                    |
//+------------------------------------------------------------------+

void Diferenciar(const double &original[], double &resultado[], int ordem)
{
   int n = ArraySize(original);
   ArrayResize(resultado, n);
   ArrayCopy(resultado, original);

   for(int d = 0; d < ordem; d++)
   {
      int tam = ArraySize(resultado);
      double temp[];
      ArrayResize(temp, tam - 1);

      for(int i = 0; i < tam - 1; i++)
         temp[i] = resultado[i + 1] - resultado[i];

      ArrayResize(resultado, tam - 1);
      ArrayCopy(resultado, temp);
   }
}

void EstimarCoeficientesCSS(const double &serie[])
{
   int n = ArraySize(serie);
   int inicio = MathMax(ARIMA_p, ARIMA_q);

   if(inicio >= n - 1) return;

   ArrayInitialize(gl_phi, 0.0);
   ArrayInitialize(gl_theta, 0.0);
   gl_constante = 0.0;

   double epsilon[];
   ArrayResize(epsilon, n);
   ArrayInitialize(epsilon, 0.0);

   for(int iter = 0; iter < Iteracoes_ARIMA; iter++)
   {
      double lr = Taxa_Aprendizado / (1.0 + 0.001 * iter);

      for(int t = inicio; t < n; t++)
      {
         double previsao = gl_constante;

         for(int i = 0; i < ARIMA_p; i++)
            if(t - 1 - i >= 0)
               previsao += gl_phi[i] * serie[t - 1 - i];

         for(int j = 0; j < ARIMA_q; j++)
            if(t - 1 - j >= 0)
               previsao += gl_theta[j] * epsilon[t - 1 - j];

         epsilon[t] = serie[t] - previsao;
      }

      double grad_c = 0.0;
      double grad_phi[];
      double grad_theta[];
      ArrayResize(grad_phi, ARIMA_p);
      ArrayResize(grad_theta, ARIMA_q);
      ArrayInitialize(grad_phi, 0.0);
      ArrayInitialize(grad_theta, 0.0);

      int contagem = 0;
      for(int t = inicio; t < n; t++)
      {
         double e = epsilon[t];
         grad_c -= e;

         for(int i = 0; i < ARIMA_p; i++)
            if(t - 1 - i >= 0)
               grad_phi[i] -= e * serie[t - 1 - i];

         for(int j = 0; j < ARIMA_q; j++)
            if(t - 1 - j >= 0)
               grad_theta[j] -= e * epsilon[t - 1 - j];

         contagem++;
      }

      if(contagem > 0)
      {
         double inv_n = 1.0 / contagem;
         grad_c *= inv_n;
         for(int i = 0; i < ARIMA_p; i++) grad_phi[i] *= inv_n;
         for(int j = 0; j < ARIMA_q; j++) grad_theta[j] *= inv_n;
      }

      gl_constante -= lr * grad_c;
      for(int i = 0; i < ARIMA_p; i++)
         gl_phi[i] -= lr * grad_phi[i];
      for(int j = 0; j < ARIMA_q; j++)
         gl_theta[j] -= lr * grad_theta[j];

      for(int i = 0; i < ARIMA_p; i++)
         gl_phi[i] = MathMax(-2.0, MathMin(2.0, gl_phi[i]));
      for(int j = 0; j < ARIMA_q; j++)
         gl_theta[j] = MathMax(-2.0, MathMin(2.0, gl_theta[j]));
   }
}

void CalcularResiduos(const double &serie[], double &residuos[])
{
   int n = ArraySize(serie);
   int inicio = MathMax(ARIMA_p, ARIMA_q);

   ArrayResize(residuos, n);
   ArrayInitialize(residuos, 0.0);

   for(int t = inicio; t < n; t++)
   {
      double previsao = gl_constante;

      for(int i = 0; i < ARIMA_p; i++)
         if(t - 1 - i >= 0)
            previsao += gl_phi[i] * serie[t - 1 - i];

      for(int j = 0; j < ARIMA_q; j++)
         if(t - 1 - j >= 0)
            previsao += gl_theta[j] * residuos[t - 1 - j];

      residuos[t] = serie[t] - previsao;
   }
}

double PreverProximoValor(const double &serie[], const double &residuos[])
{
   int n = ArraySize(serie);
   double previsao = gl_constante;

   for(int i = 0; i < ARIMA_p; i++)
   {
      int idx = n - 1 - i;
      if(idx >= 0)
         previsao += gl_phi[i] * serie[idx];
   }

   for(int j = 0; j < ARIMA_q; j++)
   {
      int idx = n - 1 - j;
      if(idx >= 0)
         previsao += gl_theta[j] * residuos[idx];
   }

   return previsao;
}

double ReverterDiferenciacao(const double &precos_originais[], double previsao_diff, int ordem)
{
   int n = ArraySize(precos_originais);

   if(ordem == 0)
      return previsao_diff;

   if(ordem == 1)
      return precos_originais[n - 1] + previsao_diff;

   if(ordem == 2)
   {
      double diff1_ultimo = precos_originais[n - 1] - precos_originais[n - 2];
      double nova_diff1 = diff1_ultimo + previsao_diff;
      return precos_originais[n - 1] + nova_diff1;
   }

   return precos_originais[n - 1] + previsao_diff;
}

//+------------------------------------------------------------------+
//| FUNCOES AUXILIARES                                               |
//+------------------------------------------------------------------+

ENUM_POSITION_TYPE ObterPosicao()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && PositionSelectByTicket(ticket))
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
            PositionGetInteger(POSITION_MAGIC) == MagicNumber)
            return (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      }
   }
   return (ENUM_POSITION_TYPE)-1;
}

bool FecharPosicao(ENUM_POSITION_TYPE tipo)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && PositionSelectByTicket(ticket))
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
            PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
            PositionGetInteger(POSITION_TYPE) == tipo)
         {
            Trade.PositionClose(ticket, Slippage);
            return true;
         }
      }
   }
   return true;
}

double AjustarVolume(double volume_desejado)
{
   double min_vol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double max_vol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step_vol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   if(volume_desejado < min_vol) volume_desejado = min_vol;
   if(volume_desejado > max_vol) volume_desejado = max_vol;

   if(step_vol > 0)
      volume_desejado = MathRound(volume_desejado / step_vol) * step_vol;

   return NormalizeDouble(volume_desejado, 2);
}

//+------------------------------------------------------------------+
