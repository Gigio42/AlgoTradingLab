//+------------------------------------------------------------------+
//|                                              ARIMA_GARCH_EA.mq5  |
//|                            Trabalho de Graduacao - FATEC Indaiatuba|
//|                Previsao e Analise de Tendencias em Ativos         |
//+------------------------------------------------------------------+
//|                                                                  |
//|  UM UNICO EA PARA OS DOIS MODELOS                                |
//|                                                                  |
//|    UsarGARCH = false  ->  ARIMA puro                             |
//|    UsarGARCH = true   ->  ARIMA-GARCH                            |
//|                                                                  |
//|  Os dois modos compartilham exatamente o mesmo codigo de         |
//|  previsao, a mesma janela de dados e a mesma logica de           |
//|  execucao de ordens. A UNICA diferenca e o GARCH decidir se a    |
//|  operacao acontece e com qual volume. Isso e proposital: numa    |
//|  comparacao entre os dois modelos, nenhuma diferenca de          |
//|  implementacao pode ser confundida com efeito do GARCH.          |
//|                                                                  |
//|  DIVISAO DE PAPEIS                                               |
//|    ARIMA -> direcao (media condicional)                          |
//|    GARCH -> risco   (variancia condicional)                      |
//|  O GARCH NUNCA gera sinal de compra ou venda. Ele so veta ou     |
//|  redimensiona o que o ARIMA propos.                              |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "TG - FATEC Indaiatuba (ADS)"
#property link      "https://www.fatec.sp.gov.br"
#property version   "2.00"
#property description "ARIMA(p,d,q) + GARCH(p,q) para negociacao automatizada"
#property description "ARIMA estimado por Hannan-Rissanen (MQO exato)"
#property description "GARCH estimado por maxima verossimilhanca com restricoes"
#property description "Ordens (p,d,q) selecionadas por ADF + AIC"
#property description "UsarGARCH=false roda o modelo ARIMA puro"

#include <Trade\Trade.mqh>
#include "..\Include\Arima.mqh"
#include "..\Include\Garch.mqh"
#include "..\Include\SelecaoModelo.mqh"
#include "..\Include\Estrategia.mqh"

//+------------------------------------------------------------------+
//| Transformacao aplicada ao preco antes de modelar                 |
//+------------------------------------------------------------------+
//|                                                                  |
//|  LOG-PRECO e o padrao, e a escolha importa MUITO:                |
//|                                                                  |
//|  Com log-preco e d=1, a serie modelada vira o LOG-RETORNO. Com   |
//|  isso a volatilidade do GARCH sai adimensional — 0,02 significa  |
//|  "2% ao dia" para qualquer ativo, em qualquer faixa de preco,    |
//|  em qualquer ano. Os limiares ficam interpretaveis e             |
//|  comparaveis com a literatura.                                   |
//|                                                                  |
//|  Com PRECO puro, a volatilidade sai em reais. Um limiar de 0,02  |
//|  significaria "2 centavos de desvio-padrao diario", o que para   |
//|  PETR4 (desvio tipico de ~R$ 0,50) bloquearia 100% das           |
//|  operacoes. Era exatamente esse o defeito da versao anterior     |
//|  deste EA.                                                       |
//|                                                                  |
//|  Use PRECO apenas se souber o que esta fazendo e recalibrar      |
//|  todos os limiares para a escala do ativo.                       |
//|                                                                  |
//+------------------------------------------------------------------+
enum ENUM_TRANSFORMACAO
  {
   TRANSF_LOG_PRECO = 0,   // Log-preco (recomendado: limiares em %)
   TRANSF_PRECO = 1        // Preco bruto (limiares na moeda do ativo)
  };

enum ENUM_MODO_ORDENS
  {
   ORDENS_AUTOMATICO = 0,  // Automatico: d por ADF, (p,q) por AIC
   ORDENS_MANUAL = 1       // Manual: usa os valores informados abaixo
  };

//+------------------------------------------------------------------+
//| PARAMETROS DE ENTRADA                                            |
//+------------------------------------------------------------------+

input group "=== Modelo ==="
input bool               UsarGARCH            = true;              // Usar GARCH (false = ARIMA puro)
input ENUM_TRANSFORMACAO Transformacao        = TRANSF_LOG_PRECO;  // Transformacao da serie
input ENUM_MODO_ORDENS   ModoOrdens           = ORDENS_AUTOMATICO; // Como definir (p,d,q)

input group "=== Ordens manuais ==="
input int                ARIMA_p              = 1;                 // p (AR)
input int                ARIMA_d              = 1;                 // d (diferenciacao)
input int                ARIMA_q              = 1;                 // q (MA)

input group "=== Ordens automaticas ==="
input int                Max_p                = 4;                 // p maximo na busca em grade
input int                Max_q                = 4;                 // q maximo na busca em grade
input int                Max_d                = 2;                 // d maximo no ADF sequencial
input int                Janela_Selecao       = 500;               // Barras usadas para selecionar as ordens
input int                Barras_Entre_Reselecao = 0;               // Reavaliar ordens a cada N barras (0 = so no inicio)
input bool               IncluirConstante     = true;              // Incluir constante (drift) no ARIMA

input group "=== Estimacao a cada barra ==="
input int                Janela_Estimacao     = 250;               // Barras da janela movel de estimacao
input int                GARCH_p              = 1;                 // Ordem ARCH
input int                GARCH_q              = 1;                 // Ordem GARCH
input int                Iteracoes_GARCH      = 300;               // Iteracoes maximas do otimizador

input group "=== Estrategia de uso do GARCH ==="
input ENUM_ESTRATEGIA_GARCH Estrategia        = EST_FILTRO_VOLATILIDADE; // Como o GARCH entra na decisao
input ENUM_MODO_LIMIAR   ModoLimiar           = LIMIAR_PERCENTIL;  // Como definir o limiar de volatilidade
input double             Limiar_Absoluto      = 0.020;             // Limiar absoluto (log-retorno: 0.02 = 2%/dia)
input double             Limiar_Percentil     = 70.0;              // Percentil da vol historica (0-100)
input double             Vol_Alvo             = 0.015;             // Volatilidade alvo do targeting
input double             K_Confianca          = 0.50;              // Desvios-padrao exigidos (intervalo de confianca)
input double             Limiar_Sinal         = 0.0005;            // Previsao minima para operar (0.0005 = 0,05%)

input group "=== Negociacao ==="
input double             Volume_Base          = 100;               // Volume base (acoes/lotes)
input double             Frac_Volume_Min      = 0.25;              // Volume minimo (fracao do base)
input double             Frac_Volume_Max      = 2.00;              // Volume maximo (fracao do base)
input int                StopLoss_Points      = 0;                 // Stop Loss em pontos (0 = sem SL)
input int                TakeProfit_Points    = 0;                 // Take Profit em pontos (0 = sem TP)
input bool               PermitirReversao     = true;              // Fechar posicao oposta ao inverter o sinal

input group "=== Sistema ==="
input ulong              MagicNumber          = 20260803;          // Numero magico
input int                Slippage             = 10;                // Desvio maximo em pontos
input bool               Diagnostico          = false;             // Log detalhado a cada barra
input bool               RelatorioInicial     = true;              // Imprimir ADF + grade AIC no inicio

//+------------------------------------------------------------------+
//| ESTADO GLOBAL                                                    |
//+------------------------------------------------------------------+

CTrade   g_trade;
CArima   g_arima;
CGarch   g_garch;

int      g_p = 1, g_d = 1, g_q = 1;   // ordens em uso
int      g_digits;
double   g_ponto;
datetime g_ultima_barra = 0;
int      g_barras_desde_selecao = 0;
bool     g_ordens_definidas = false;

//--- Contadores para o resumo final
long     g_barras_processadas = 0;
long     g_sinais_arima = 0;
long     g_bloqueios_garch = 0;
long     g_ordens_enviadas = 0;
long     g_falhas_ajuste = 0;

//+------------------------------------------------------------------+
//| Carrega a serie ja transformada                                  |
//+------------------------------------------------------------------+
//|                                                                  |
//|  Comeca na barra 1, NAO na barra 0. A barra 0 ainda esta se      |
//|  formando: seu fechamento muda a cada tick. Usa-la faria o       |
//|  modelo ser estimado sobre um dado que sera outro daqui a        |
//|  pouco, e no backtest produz resultados que nao se reproduzem    |
//|  ao vivo.                                                        |
//|                                                                  |
//|  Saida em ordem cronologica: indice 0 = barra mais antiga.       |
//|                                                                  |
//+------------------------------------------------------------------+
bool CarregarSerie(const int quantidade, double &saida[])
  {
   double fechamento[];
   int copiados = CopyClose(_Symbol, _Period, 1, quantidade, fechamento);

   if(copiados < quantidade)
      return(false);

   ArrayResize(saida, copiados);

   for(int i = 0; i < copiados; i++)
     {
      if(Transformacao == TRANSF_LOG_PRECO)
        {
         if(fechamento[i] <= 0.0)
            return(false);
         saida[i] = MathLog(fechamento[i]);
        }
      else
         saida[i] = fechamento[i];
     }

   return(true);
  }

//+------------------------------------------------------------------+
//| Seleciona as ordens (p,d,q) por ADF + AIC                        |
//+------------------------------------------------------------------+
bool SelecionarOrdens(const bool imprimir)
  {
   double serie[];
   int janela = MathMax(Janela_Selecao, Janela_Estimacao);

   if(!CarregarSerie(janela, serie))
     {
      Print("Selecao de ordens: historico insuficiente (", janela, " barras)");
      return(false);
     }

   ResultadoSelecao res;
   string relatorio = "";

   //--- Precos tem media diferente de zero, entao o ADF roda com
   //--- constante. Manter a constante tambem nas diferencas e a
   //--- escolha conservadora (o ativo pode ter drift).
   bool ok = SelecionarModelo(serie, Max_d, Max_p, Max_q,
                              IncluirConstante, ADF_CONSTANTE,
                              res, relatorio);

   if(imprimir)
     {
      Print("=========================================================");
      Print(" SELECAO AUTOMATICA DE ORDENS - ", _Symbol, " ", EnumToString(_Period));
      Print(" Janela: ", janela, " barras | Transformacao: ",
            (Transformacao == TRANSF_LOG_PRECO) ? "log-preco" : "preco");
      Print("=========================================================");
      //--- O relatorio vem com quebras de linha; imprime em blocos
      string linhas[];
      int n = StringSplit(relatorio, '\n', linhas);
      for(int i = 0; i < n; i++)
         if(StringLen(linhas[i]) > 0)
            Print(linhas[i]);
      Print("=========================================================");
     }

   if(!ok)
      return(false);

   g_p = res.p;
   g_d = res.d;
   g_q = res.q;
   g_ordens_definidas = true;
   g_barras_desde_selecao = 0;

   return(true);
  }

//+------------------------------------------------------------------+
//| INICIALIZACAO                                                    |
//+------------------------------------------------------------------+
int OnInit()
  {
   g_digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   g_ponto  = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   g_trade.SetExpertMagicNumber(MagicNumber);
   g_trade.SetDeviationInPoints(Slippage);
   g_trade.SetTypeFillingBySymbol(_Symbol);

   //--- Validacoes basicas
   if(Janela_Estimacao < 80)
     {
      Print("ERRO: Janela_Estimacao muito pequena (minimo 80 barras)");
      return(INIT_PARAMETERS_INCORRECT);
     }

   if(Frac_Volume_Min <= 0.0 || Frac_Volume_Max < Frac_Volume_Min)
     {
      Print("ERRO: Fracoes de volume inconsistentes");
      return(INIT_PARAMETERS_INCORRECT);
     }

   if(ModoLimiar == LIMIAR_PERCENTIL &&
      (Limiar_Percentil <= 0.0 || Limiar_Percentil >= 100.0))
     {
      Print("ERRO: Limiar_Percentil deve estar entre 0 e 100");
      return(INIT_PARAMETERS_INCORRECT);
     }

   //--- Define as ordens
   if(ModoOrdens == ORDENS_MANUAL)
     {
      g_p = MathMax(0, ARIMA_p);
      g_d = MathMax(0, MathMin(2, ARIMA_d));
      g_q = MathMax(0, ARIMA_q);
      g_ordens_definidas = true;
     }
   else
     {
      //--- Se o historico ainda nao carregou, tentamos de novo na
      //--- primeira barra. Nao e motivo para falhar a inicializacao.
      if(!SelecionarOrdens(RelatorioInicial))
         Print("Selecao adiada para a primeira barra (historico ainda carregando)");
     }

   g_arima.Definir(g_p, g_d, g_q, IncluirConstante);
   g_garch.Definir(GARCH_p, GARCH_q);
   g_garch.DefinirOtimizador(Iteracoes_GARCH);

   PrintFormat("EA iniciado | %s | modelo: %s | ARIMA(%d,%d,%d)%s | janela=%d",
               _Symbol,
               UsarGARCH ? "ARIMA-GARCH" : "ARIMA puro",
               g_p, g_d, g_q,
               UsarGARCH ? StringFormat(" + GARCH(%d,%d)", GARCH_p, GARCH_q) : "",
               Janela_Estimacao);

   if(UsarGARCH)
      PrintFormat("Estrategia: %s | limiar: %s",
                  EnumToString(Estrategia),
                  (ModoLimiar == LIMIAR_ABSOLUTO)
                     ? StringFormat("absoluto %.6f", Limiar_Absoluto)
                     : StringFormat("percentil %.1f", Limiar_Percentil));

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| DESINICIALIZACAO                                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Print("---------------------------------------------------------");
   PrintFormat(" RESUMO | modelo: %s | ARIMA(%d,%d,%d)",
               UsarGARCH ? "ARIMA-GARCH" : "ARIMA puro", g_p, g_d, g_q);
   PrintFormat(" Barras processadas ....... %d", g_barras_processadas);
   PrintFormat(" Falhas de ajuste ......... %d", g_falhas_ajuste);
   PrintFormat(" Sinais gerados pelo ARIMA. %d", g_sinais_arima);
   PrintFormat(" Vetados pelo GARCH ....... %d", g_bloqueios_garch);
   PrintFormat(" Ordens enviadas .......... %d", g_ordens_enviadas);
   Print("---------------------------------------------------------");
  }

//+------------------------------------------------------------------+
//| A CADA TICK                                                      |
//+------------------------------------------------------------------+
void OnTick()
  {
   //--- Opera apenas na abertura de uma nova barra
   datetime barra = (datetime)SeriesInfoInteger(_Symbol, _Period, SERIES_LASTBAR_DATE);
   if(barra == g_ultima_barra)
      return;
   g_ultima_barra = barra;

   //--- Selecao de ordens pendente ou vencida
   if(ModoOrdens == ORDENS_AUTOMATICO)
     {
      bool precisa = (!g_ordens_definidas) ||
                     (Barras_Entre_Reselecao > 0 &&
                      g_barras_desde_selecao >= Barras_Entre_Reselecao);

      if(precisa)
        {
         if(SelecionarOrdens(!g_ordens_definidas && RelatorioInicial))
           {
            g_arima.Definir(g_p, g_d, g_q, IncluirConstante);
            PrintFormat("Ordens em uso: ARIMA(%d,%d,%d)", g_p, g_d, g_q);
           }
        }
      g_barras_desde_selecao++;
     }

   if(!g_ordens_definidas)
      return;

   g_barras_processadas++;

   //--- ── 1) Serie da janela movel ──
   double serie[];
   if(!CarregarSerie(Janela_Estimacao, serie))
      return;

   //--- ── 2) ARIMA: media condicional ──
   if(!g_arima.Ajustar(serie))
     {
      g_falhas_ajuste++;
      if(Diagnostico)
         Print("ARIMA nao ajustou: ", g_arima.UltimoErro());
      return;
     }

   //--- Previsao no espaco diferenciado.
   //--- Com log-preco e d=1, e o log-retorno esperado.
   double previsao = g_arima.PreverDiferenciado();

   if(!MathIsValidNumber(previsao))
     {
      g_falhas_ajuste++;
      return;
     }

   //--- ── 3) GARCH: variancia condicional dos residuos do ARIMA ──
   double vol_prevista = 0.0;
   double limiar = Limiar_Absoluto;
   bool   garch_ok = false;

   if(UsarGARCH)
     {
      double residuos[];

      if(!g_arima.ObterResiduos(residuos))
        {
         g_falhas_ajuste++;
         return;
        }

      if(g_garch.Ajustar(residuos))
        {
         vol_prevista = g_garch.VolatilidadeProximoPeriodo();
         garch_ok = true;

         //--- Limiar por percentil da propria volatilidade estimada
         if(ModoLimiar == LIMIAR_PERCENTIL)
           {
            double serie_vol[];
            if(g_garch.ObterSerieVolatilidade(serie_vol))
               limiar = Percentil(serie_vol, Limiar_Percentil);
            else
               limiar = Limiar_Absoluto;
           }
        }
      else
        {
         //--- GARCH nao convergiu. Por seguranca NAO operamos:
         //--- sem medida de risco, o modelo combinado perde seu
         //--- proposito. Operar seria virar ARIMA puro sem avisar.
         g_falhas_ajuste++;
         if(Diagnostico)
            Print("GARCH nao ajustou: ", g_garch.UltimoErro(), " - barra ignorada");
         return;
        }
     }

   //--- ── 4) Decisao ──
   DecisaoOperacao dec;
   DecidirOperacao(previsao, vol_prevista, UsarGARCH, Estrategia,
                   limiar, Vol_Alvo, K_Confianca,
                   Volume_Base, Frac_Volume_Min, Frac_Volume_Max,
                   Limiar_Sinal, dec);

   if(previsao > Limiar_Sinal || previsao < -Limiar_Sinal)
      g_sinais_arima++;

   if(dec.bloqueou_garch)
      g_bloqueios_garch++;

   //--- ── 5) Diagnostico ──
   if(Diagnostico)
     {
      Print("--------------------------------------------");
      PrintFormat("ARIMA(%d,%d,%d) previsao=%.8f  sigma2=%.10f  AIC=%.2f",
                  g_p, g_d, g_q, previsao, g_arima.Sigma2(), g_arima.AIC());

      if(UsarGARCH && garch_ok)
         PrintFormat("GARCH vol=%.8f (%.3f%%)  limiar=%.8f  persist=%.4f",
                     vol_prevista, vol_prevista * 100.0, limiar,
                     g_garch.Persistencia());

      PrintFormat("Decisao: sinal=%d volume=%.2f | %s",
                  dec.sinal, dec.volume, dec.motivo);
     }

   //--- ── 6) Execucao ──
   if(dec.sinal != 0)
      Executar(dec);
  }

//+------------------------------------------------------------------+
//| Executa a decisao                                                |
//+------------------------------------------------------------------+
void Executar(const DecisaoOperacao &dec)
  {
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick) || tick.ask <= 0.0 || tick.bid <= 0.0)
      return;

   ENUM_POSITION_TYPE posicao = PosicaoAtual();
   double volume = AjustarVolume(dec.volume);

   if(volume <= 0.0)
      return;

   //--- ── Compra ──
   if(dec.sinal > 0)
     {
      if(posicao == POSITION_TYPE_SELL)
        {
         if(!PermitirReversao)
            return;
         //--- Se o fechamento falhar, NAO abrimos a posicao oposta:
         //--- ficariamos travados (hedge) sem intencao.
         if(!FecharPosicao(POSITION_TYPE_SELL))
            return;
         posicao = PosicaoAtual();
        }

      if(posicao == POSITION_TYPE_BUY)
         return;

      double sl = (StopLoss_Points > 0)
                  ? NormalizeDouble(tick.ask - StopLoss_Points * g_ponto, g_digits) : 0.0;
      double tp = (TakeProfit_Points > 0)
                  ? NormalizeDouble(tick.ask + TakeProfit_Points * g_ponto, g_digits) : 0.0;

      if(g_trade.Buy(volume, _Symbol, tick.ask, sl, tp, "ARIMA-GARCH BUY"))
         g_ordens_enviadas++;
      else
         Print("Falha na compra: ", g_trade.ResultRetcodeDescription());

      return;
     }

   //--- ── Venda ──
   if(posicao == POSITION_TYPE_BUY)
     {
      if(!PermitirReversao)
         return;
      if(!FecharPosicao(POSITION_TYPE_BUY))
         return;
      posicao = PosicaoAtual();
     }

   if(posicao == POSITION_TYPE_SELL)
      return;

   double sl = (StopLoss_Points > 0)
               ? NormalizeDouble(tick.bid + StopLoss_Points * g_ponto, g_digits) : 0.0;
   double tp = (TakeProfit_Points > 0)
               ? NormalizeDouble(tick.bid - TakeProfit_Points * g_ponto, g_digits) : 0.0;

   if(g_trade.Sell(volume, _Symbol, tick.bid, sl, tp, "ARIMA-GARCH SELL"))
      g_ordens_enviadas++;
   else
      Print("Falha na venda: ", g_trade.ResultRetcodeDescription());
  }

//+------------------------------------------------------------------+
//| Posicao aberta deste EA neste simbolo                            |
//+------------------------------------------------------------------+
ENUM_POSITION_TYPE PosicaoAtual()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;

      if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
         (ulong)PositionGetInteger(POSITION_MAGIC) == MagicNumber)
         return((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE));
     }

   return((ENUM_POSITION_TYPE)-1);
  }

//+------------------------------------------------------------------+
//| Fecha a posicao do tipo indicado                                 |
//+------------------------------------------------------------------+
bool FecharPosicao(const ENUM_POSITION_TYPE tipo)
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;

      if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
         (ulong)PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
         PositionGetInteger(POSITION_TYPE) == tipo)
        {
         if(g_trade.PositionClose(ticket, Slippage))
            return(true);

         Print("Falha ao fechar posicao: ", g_trade.ResultRetcodeDescription());
         return(false);
        }
     }

   return(true);   // nao havia posicao a fechar
  }

//+------------------------------------------------------------------+
//| Ajusta o volume aos limites do simbolo                           |
//+------------------------------------------------------------------+
double AjustarVolume(double volume)
  {
   double v_min  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double v_max  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double v_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   if(v_step > 0.0)
      volume = MathRound(volume / v_step) * v_step;

   if(volume < v_min) volume = v_min;
   if(v_max > 0.0 && volume > v_max) volume = v_max;

   //--- Casas decimais coerentes com o passo de volume
   int casas = 0;
   if(v_step > 0.0 && v_step < 1.0)
      casas = (int)MathCeil(-MathLog10(v_step));

   return(NormalizeDouble(volume, casas));
  }
//+------------------------------------------------------------------+
