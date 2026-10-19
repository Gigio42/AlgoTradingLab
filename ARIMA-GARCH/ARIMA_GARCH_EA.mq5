#property copyright "TG - FATEC Indaiatuba (ADS)"
#property version   "3.00"
#property tester_file "selic_diaria.csv"
#property tester_file "proventos_PETR4.csv"
#property tester_file "proventos_VALE3.csv"
#property tester_file "proventos_USIM5.csv"
#property tester_file "proventos_POMO4.csv"

#include "..\Include\Arima.mqh"
#include "..\Include\Garch.mqh"
#include "..\Include\SelecaoModelo.mqh"
#include "..\Include\Estrategia.mqh"
#include "..\Include\Negociacao.mqh"

enum ENUM_TRANSFORMACAO
  {
   TRANSF_LOG_PRECO = 0,   // Log-preco: com d = 1 modela o log-retorno e a volatilidade sai em %
   TRANSF_PRECO = 1        // Preco bruto: limiares na moeda do ativo
  };

enum ENUM_MODO_VOLUME
  {
   VOLUME_FIXO = 0,        // Volume_Base acoes
   VOLUME_CAPITAL = 1      // Fracao_Capital do patrimonio
  };

enum ENUM_MODO_ORDENS
  {
   ORDENS_AUTOMATICO = 0,  // d por ADF, (p,q) por AIC
   ORDENS_MANUAL = 1       // ARIMA_p, ARIMA_d, ARIMA_q
  };

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
input int                Janela_Selecao       = 240;               // Barras usadas para selecionar as ordens
input int                Barras_Entre_Reselecao = 21;              // Reavaliar ordens a cada N barras (0 = so no inicio)
input bool               IncluirConstante     = false;             // Incluir constante (drift) no ARIMA

input group "=== Estimacao a cada barra ==="
input int                Janela_Estimacao     = 120;               // Barras da janela movel de estimacao
input int                GARCH_p              = 1;                 // Ordem ARCH
input int                GARCH_q              = 1;                 // Ordem GARCH
input int                Iteracoes_GARCH      = 300;               // Iteracoes maximas do otimizador

input group "=== Estrategia de uso do GARCH ==="
input ENUM_ESTRATEGIA_GARCH Estrategia        = FILTRO_VOLATILIDADE; // Como o GARCH entra na decisao
input ENUM_MODO_LIMIAR   ModoLimiar           = LIMIAR_PERCENTIL;  // Como definir o limiar de volatilidade
input double             Limiar_Absoluto      = 0.020;             // Limiar absoluto (0.02 = 2%/dia)
input double             Limiar_Percentil     = 50.0;              // Percentil da volatilidade estimada (0-100)
input double             Vol_Alvo             = 0.015;             // Volatilidade alvo do targeting
input double             K_Confianca          = 0.50;              // Desvios-padrao exigidos (intervalo de confianca)
input double             Limiar_Sinal         = 0.0;               // Previsao minima para operar (0.0005 = 0,05%)

input group "=== Negociacao ==="
input ENUM_MODO_VOLUME   ModoVolume           = VOLUME_CAPITAL;    // Como dimensionar a posicao
input double             Fracao_Capital       = 0.95;              // Fracao do patrimonio (modo CAPITAL)
input double             Volume_Base          = 100;               // Volume base (acoes, modo FIXO)
input double             Frac_Volume_Min      = 0.25;              // Volume minimo do targeting (fracao do base)
input double             Frac_Volume_Max      = 2.00;              // Volume maximo do targeting (fracao do base)
input int                StopLoss_Points      = 0;                 // Stop Loss em pontos (0 = sem)
input int                TakeProfit_Points    = 0;                 // Take Profit em pontos (0 = sem)
input bool               PermitirReversao     = true;              // Fechar a posicao oposta ao inverter o sinal
input bool               SomenteCompra        = true;              // Sinal de venda so zera a compra
input bool               ZerarNoVeto          = false;             // Fechar a posicao quando o GARCH vetar

input group "=== Sistema ==="
input ulong              MagicNumber          = 20260803;          // Numero magico
input int                Slippage             = 10;                // Desvio maximo em pontos

//@omitir-inicio
input group "=== Avaliacao e diagnostico ==="
input double             Custo_Por_Lado       = 0.0003;            // Custo B3 por execucao (fracao do valor)
input string             Arquivo_Proventos    = "proventos_PETR4.csv"; // Proventos por data-ex
input string             Rotulo               = "";                // Nome das metricas e da curva (vazio = nao grava)
input bool               Diagnostico          = false;             // Log de cada barra
input bool               RelatorioInicial     = true;              // ADF e grade de AIC no log da primeira selecao
input string             Arquivo_Traco        = "";                // Traco por barra (vazio = desligado)

input group "=== Opcoes experimentais (fora do TG) ==="
input ENUM_ESTIMACAO_ARIMA    MetodoARIMA       = ESTIMACAO_HANNAN_RISSANEN; // Estimacao do ARIMA
input bool                    SelecaoPorBIC     = false;           // Escolher (p,q) pelo BIC
input ENUM_DISTRIBUICAO_GARCH DistribuicaoGARCH = DISTRIBUICAO_NORMAL; // Distribuicao dos erros do GARCH
//@omitir-fim

CArima      g_arima;
CGarch      g_garch;
CNegociacao g_negociacao;

int      g_ordem_p = 1, g_ordem_d = 1, g_ordem_q = 1;
bool     g_ordens_definidas = false;
int      g_barras_desde_selecao = 0;
datetime g_ultima_barra = 0;

#include "Diagnostico.mqh"   //@omitir
#include "Avaliacao.mqh"     //@omitir
CDiagnostico g_diagnostico;  //@omitir

int OnInit()
  {
   if(Janela_Estimacao < 80 || Frac_Volume_Min <= 0.0 || Frac_Volume_Max < Frac_Volume_Min ||
      (ModoVolume == VOLUME_CAPITAL && (Fracao_Capital <= 0.0 || Fracao_Capital > 1.0)) ||
      (ModoLimiar == LIMIAR_PERCENTIL && (Limiar_Percentil <= 0.0 || Limiar_Percentil >= 100.0)))
     {
      Print("Parametros inconsistentes: Janela_Estimacao >= 80, fracoes de volume e percentil entre 0 e 100");
      return(INIT_PARAMETERS_INCORRECT);
     }

   g_negociacao.Configurar(_Symbol, MagicNumber, Slippage);
   CArima::DefinirEstimacaoPadrao(MetodoARIMA);                            //@omitir
   g_arima.DefinirEstimacao(MetodoARIMA);                                   //@omitir
   DefinirCriterioDeOrdens(SelecaoPorBIC ? CRITERIO_BIC : CRITERIO_AIC);    //@omitir
   IniciarAvaliacao();                                                      //@omitir

   if(ModoOrdens == ORDENS_MANUAL)
     {
      g_ordem_p = MathMax(0, ARIMA_p);
      g_ordem_d = MathMax(0, MathMin(2, ARIMA_d));
      g_ordem_q = MathMax(0, ARIMA_q);
      g_ordens_definidas = true;
     }
   else
      SelecionarOrdens();

   g_arima.Definir(g_ordem_p, g_ordem_d, g_ordem_q, IncluirConstante);
   g_garch.Definir(GARCH_p, GARCH_q);
   g_garch.DefinirOtimizador(Iteracoes_GARCH);
   g_garch.DefinirDistribuicao(DistribuicaoGARCH);   //@omitir

   g_diagnostico.Iniciar(GetPointer(g_arima), GetPointer(g_garch), GetPointer(g_negociacao), g_ordem_p, g_ordem_d, g_ordem_q);   //@omitir
   return(INIT_SUCCEEDED);
  }

//@omitir-inicio
void OnDeinit(const int reason)
  {
   g_diagnostico.Encerrar(g_ordem_p, g_ordem_d, g_ordem_q);
  }

double OnTester()
  {
   return(AvaliarTeste(g_ordem_p, g_ordem_d, g_ordem_q, g_diagnostico));
  }
//@omitir-fim

void OnTick()
  {
   datetime barra = (datetime)SeriesInfoInteger(_Symbol, _Period, SERIES_LASTBAR_DATE);
   if(barra == g_ultima_barra)
      return;
   g_ultima_barra = barra;
   RegistrarBarraNaAvaliacao(barra);   //@omitir

   if(ModoOrdens == ORDENS_AUTOMATICO)
      ReselecionarOrdensSeVencidas();
   if(!g_ordens_definidas)
      return;
   g_diagnostico.BarraProcessada();   //@omitir

   double serie[];
   if(!CarregarSerie(Janela_Estimacao, serie))
      return;

   if(!g_arima.Ajustar(serie))
     {
      g_diagnostico.FalhaDeAjuste("ARIMA nao ajustou: " + g_arima.UltimoErro());   //@omitir
      return;
     }

   double previsao = PrevisaoDoRetorno(serie);
   if(!MathIsValidNumber(previsao))
     {
      g_diagnostico.FalhaDeAjuste("");   //@omitir
      return;
     }

   double volatilidade = 0.0;
   double limiar = Limiar_Absoluto;
   if(UsarGARCH && !EstimarVolatilidade(volatilidade, limiar))
      return;   // sem medida de risco o modelo combinado nao opera

   DecisaoOperacao decisao;
   DecidirOperacao(previsao, volatilidade, UsarGARCH, Estrategia, limiar, Vol_Alvo, K_Confianca,
                   Volume_Base, Frac_Volume_Min, Frac_Volume_Max, Limiar_Sinal, decisao);
   g_diagnostico.Decisao(previsao, volatilidade, limiar, UsarGARCH, decisao);   //@omitir

   if(decisao.sinal != 0)
      Executar(decisao);
   else if(decisao.vetada_pelo_garch && ZerarNoVeto)
      FecharPosicaoAberta();

   g_diagnostico.GravarTraco(previsao, volatilidade, limiar, UsarGARCH, decisao);   //@omitir
  }

//--- Fechamentos a partir da barra 1: a barra 0 ainda esta se formando
bool CarregarSerie(const int quantidade, double &serie[])
  {
   double fechamento[];
   int copiados = CopyClose(_Symbol, _Period, 1, quantidade, fechamento);
   if(copiados < quantidade)
      return(false);

   ArrayResize(serie, copiados);
   for(int i = 0; i < copiados; i++)
     {
      if(Transformacao == TRANSF_PRECO)
         serie[i] = fechamento[i];
      else if(fechamento[i] > 0.0)
         serie[i] = MathLog(fechamento[i]);
      else
         return(false);
     }
   return(true);
  }

bool SelecionarOrdens()
  {
   double serie[];
   int janela = MathMax(Janela_Selecao, Janela_Estimacao);
   if(!CarregarSerie(janela, serie))
     {
      g_diagnostico.HistoricoInsuficiente(janela);   //@omitir
      return(false);
     }

   ResultadoSelecao selecao;
   string relatorio = "";
   bool selecionou = SelecionarModelo(serie, Max_d, Max_p, Max_q, IncluirConstante, ADF_CONSTANTE, selecao, relatorio);
   g_diagnostico.Selecao(relatorio, janela, g_ordens_definidas);   //@omitir
   if(!selecionou)
      return(false);

   g_ordem_p = selecao.p;
   g_ordem_d = selecao.d;
   g_ordem_q = selecao.q;
   g_ordens_definidas = true;
   g_barras_desde_selecao = 0;
   return(true);
  }

void ReselecionarOrdensSeVencidas()
  {
   bool vencidas = !g_ordens_definidas ||
                   (Barras_Entre_Reselecao > 0 && g_barras_desde_selecao >= Barras_Entre_Reselecao);
   if(vencidas && SelecionarOrdens())
     {
      g_arima.Definir(g_ordem_p, g_ordem_d, g_ordem_q, IncluirConstante);
      g_diagnostico.OrdensEmUso(g_ordem_p, g_ordem_d, g_ordem_q);   //@omitir
     }
   g_barras_desde_selecao++;
  }

//--- Retorno previsto para o dia, que da a direcao. Com d = 0 o ARIMA modela o
//--- nivel do log-preco, e a direcao e o nivel previsto menos o atual.
double PrevisaoDoRetorno(const double &serie[])
  {
   if(g_arima.D() == 1)
      return(g_arima.PreverDiferenciado());
   return(g_arima.PreverNivel() - serie[ArraySize(serie) - 1]);
  }

//--- Volatilidade prevista pelo GARCH sobre os residuos do ARIMA e o limiar do dia
bool EstimarVolatilidade(double &volatilidade, double &limiar)
  {
   double residuos[];
   if(!g_arima.ObterResiduos(residuos))
     {
      g_diagnostico.FalhaDeAjuste("");   //@omitir
      return(false);
     }
   if(!g_garch.Ajustar(residuos))
     {
      g_diagnostico.FalhaDeAjuste("GARCH nao ajustou: " + g_garch.UltimoErro() + " - barra ignorada");   //@omitir
      return(false);
     }

   volatilidade = g_garch.VolatilidadeProximoPeriodo();
   g_diagnostico.GrausLiberdadeEstimados(g_garch.GrausLiberdade());   //@omitir

   if(ModoLimiar == LIMIAR_PERCENTIL)
     {
      double historico[];
      limiar = g_garch.ObterSerieVolatilidade(historico) ? Percentil(historico, Limiar_Percentil) : Limiar_Absoluto;
     }
   return(true);
  }

void Executar(const DecisaoOperacao &decisao)
  {
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick) || tick.ask <= 0.0 || tick.bid <= 0.0)
      return;

   ENUM_POSITION_TYPE posicao = g_negociacao.PosicaoAtual();
   if(decisao.sinal < 0 && SomenteCompra)
     {
      if(posicao == POSITION_TYPE_BUY)
         g_negociacao.Fechar(POSITION_TYPE_BUY);
      return;
     }

   bool compra = (decisao.sinal > 0);
   double preco = compra ? tick.ask : tick.bid;
   double volume = g_negociacao.AjustarVolume(VolumeDesejado(decisao.volume, preco));
   if(volume <= 0.0)
      return;

   ENUM_POSITION_TYPE mesma   = compra ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
   ENUM_POSITION_TYPE oposta  = compra ? POSITION_TYPE_SELL : POSITION_TYPE_BUY;
   if(posicao == oposta)
     {
      //--- Se o fechamento falhar, nao abre a oposta: ficaria com as duas
      if(!PermitirReversao || !g_negociacao.Fechar(oposta))
         return;
      posicao = g_negociacao.PosicaoAtual();
     }
   if(posicao == mesma)
      return;

   double ponto = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   int casas = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   double stop_loss = 0.0, take_profit = 0.0;
   if(compra)
     {
      if(StopLoss_Points > 0)   stop_loss   = NormalizeDouble(preco - StopLoss_Points * ponto, casas);
      if(TakeProfit_Points > 0) take_profit = NormalizeDouble(preco + TakeProfit_Points * ponto, casas);
      g_negociacao.Comprar(volume, preco, stop_loss, take_profit, "ARIMA-GARCH BUY");
     }
   else
     {
      if(StopLoss_Points > 0)   stop_loss   = NormalizeDouble(preco + StopLoss_Points * ponto, casas);
      if(TakeProfit_Points > 0) take_profit = NormalizeDouble(preco - TakeProfit_Points * ponto, casas);
      g_negociacao.Vender(volume, preco, stop_loss, take_profit, "ARIMA-GARCH SELL");
     }
  }

//--- Sem zerar, o veto so impede a entrada e a posicao atravessa o periodo agitado
void FecharPosicaoAberta()
  {
   ENUM_POSITION_TYPE posicao = g_negociacao.PosicaoAtual();
   if(posicao == POSITION_TYPE_BUY || posicao == POSITION_TYPE_SELL)
      g_negociacao.Fechar(posicao);
  }

//--- O volume da decisao ja traz o fator do targeting sobre Volume_Base; no modo
//--- CAPITAL o mesmo fator e aplicado sobre a fracao do patrimonio.
double VolumeDesejado(const double volume_decisao, const double preco)
  {
   if(ModoVolume == VOLUME_FIXO || preco <= 0.0)
      return(volume_decisao);

   double fator = (Volume_Base > 0.0) ? volume_decisao / Volume_Base : 1.0;
   return(VolumePorCapital(_Symbol, Fracao_Capital * fator, preco));
  }
