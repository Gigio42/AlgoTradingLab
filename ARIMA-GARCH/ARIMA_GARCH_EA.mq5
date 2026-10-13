//+------------------------------------------------------------------+
//|                          ARIMA_GARCH_EA.mq5                      |
//|               Trabalho de Graduacao - FATEC Indaiatuba           |
//|              Previsao e Analise de Tendencias em Ativos          |
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
//@omitir-inicio  (metadados exibidos pelo MT5 na janela de propriedades)
#property copyright "TG - FATEC Indaiatuba (ADS)"
#property link      "https://www.fatec.sp.gov.br"
#property version   "2.00"
#property description "ARIMA(p,d,q) + GARCH(p,q) para negociacao automatizada"
#property description "ARIMA estimado por Hannan-Rissanen (MQO exato)"
#property description "GARCH estimado por maxima verossimilhanca com restricoes"
#property description "Ordens (p,d,q) selecionadas por ADF + AIC"
#property description "UsarGARCH=false roda o modelo ARIMA puro"
//@omitir-fim

//--- Marcadores //@omitir e //@apendice: (comentarios, nao mudam o programa)
//--- so definem o que a listagem do Apendice A do TG deixa de fora: log,
//--- diagnostico, traco e avaliacao no testador. Gerada por
//--- ferramentas/scripts/codigo_apendice.sh.
#include <Trade\Trade.mqh>
#include "..\Include\Arima.mqh"
#include "..\Include\Garch.mqh"
#include "..\Include\SelecaoModelo.mqh"
#include "..\Include\Estrategia.mqh"
#include "..\Include\Desempenho.mqh"   //@omitir

//@omitir-inicio
//--- Selic diaria (serie 11 do SGS/BCB) em MQL5\Files. O testador copia
//--- o arquivo para os agentes; so e usada no relatorio contra a Selic.
#property tester_file "selic_diaria.csv"
//--- Proventos por data-ex (adendo da avaliacao; ver dados/FONTES.md)
#property tester_file "proventos_PETR4.csv"
#property tester_file "proventos_VALE3.csv"
#property tester_file "proventos_USIM5.csv"
#property tester_file "proventos_POMO4.csv"
//@omitir-fim

//+------------------------------------------------------------------+
//| Transformacao aplicada ao preco antes de modelar                 |
//+------------------------------------------------------------------+
//|                                                                  |
//|  LOG-PRECO e o padrao, e a escolha importa:                      |
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

//+------------------------------------------------------------------+
//| Dimensionamento da posicao                                       |
//+------------------------------------------------------------------+
//|                                                                  |
//|  FIXO    — sempre Volume_Base acoes. Com 100 acoes de PETR4      |
//|            (~R$ 3.000) numa conta de R$ 50.000, 94% do capital   |
//|            fica parado e o resultado e dominado pelo caixa.      |
//|  CAPITAL — Fracao_Capital do patrimonio, arredondado para baixo  |
//|            ao lote. E o que torna o retorno comparavel com a     |
//|            Selic, que remunera o capital inteiro.                |
//|                                                                  |
//|  Em ambos, o volume_base e multiplicado pelo fator do targeting  |
//|  quando essa estrategia esta ativa.                              |
//|                                                                  |
//+------------------------------------------------------------------+
enum ENUM_MODO_VOLUME
  {
   VOLUME_FIXO = 0,        // Fixo: Volume_Base acoes
   VOLUME_CAPITAL = 1      // Fracao do patrimonio
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
input int                Janela_Selecao       = 240;               // Barras usadas para selecionar as ordens
input int                Barras_Entre_Reselecao = 21;              // Reavaliar ordens a cada N barras (0 = so no inicio)
input bool               IncluirConstante     = false;             // Incluir constante (drift) no ARIMA

input group "=== Estimacao a cada barra ==="
input int                Janela_Estimacao     = 120;               // Barras da janela movel de estimacao
input int                GARCH_p              = 1;                 // Ordem ARCH
input int                GARCH_q              = 1;                 // Ordem GARCH
input int                Iteracoes_GARCH      = 300;               // Iteracoes maximas do otimizador
input ENUM_DIST_GARCH    DistribuicaoGARCH    = DIST_NORMAL;       // Distribuicao dos erros do GARCH (13/10/2026)   //@omitir

input group "=== Estrategia de uso do GARCH ==="
input ENUM_ESTRATEGIA_GARCH Estrategia        = EST_FILTRO_VOLATILIDADE; // Como o GARCH entra na decisao
input ENUM_MODO_LIMIAR   ModoLimiar           = LIMIAR_PERCENTIL;  // Como definir o limiar de volatilidade
input double             Limiar_Absoluto      = 0.020;             // Limiar absoluto (log-retorno: 0.02 = 2%/dia)
input double             Limiar_Percentil     = 50.0;              // Percentil da vol historica (0-100)
input double             Vol_Alvo             = 0.015;             // Volatilidade alvo do targeting
input double             K_Confianca          = 0.50;              // Desvios-padrao exigidos (intervalo de confianca)
input double             Limiar_Sinal         = 0.0;               // Previsao minima para operar (0.0005 = 0,05%)

input group "=== Negociacao ==="
input ENUM_MODO_VOLUME   ModoVolume           = VOLUME_CAPITAL;    // Como dimensionar a posicao
input double             Fracao_Capital       = 0.95;              // Fracao do patrimonio (modo CAPITAL)
input double             Volume_Base          = 100;               // Volume base (acoes/lotes, modo FIXO)
input double             Frac_Volume_Min      = 0.25;              // Volume minimo (fracao do base)
input double             Frac_Volume_Max      = 2.00;              // Volume maximo (fracao do base)
input int                StopLoss_Points      = 0;                 // Stop Loss em pontos (0 = sem SL)
input int                TakeProfit_Points    = 0;                 // Take Profit em pontos (0 = sem TP)
input bool               PermitirReversao     = true;              // Fechar posicao oposta ao inverter o sinal
input bool               SomenteCompra        = true;              // So compra: sinal de venda apenas zera (sem venda a descoberto)
input bool               ZerarNoVeto          = false;             // Fechar a posicao aberta quando o GARCH vetar

//@omitir-inicio
input group "=== Avaliacao (Strategy Tester) ==="
input double             Custo_Por_Lado       = 0.0003;            // Custo B3 por execucao (fracao do valor negociado)
input string             Arquivo_Proventos    = "proventos_PETR4.csv"; // Proventos por data-ex (so avaliacao)
input string             Rotulo               = "";                // Nome da curva diaria exportada (vazio = nao exporta)

//@omitir-fim
input group "=== Sistema ==="
input ulong              MagicNumber          = 20260803;          // Numero magico
input int                Slippage             = 10;                // Desvio maximo em pontos
//@omitir-inicio
input bool               Diagnostico          = false;             // Log detalhado a cada barra
input bool               RelatorioInicial     = true;              // Imprimir ADF + grade AIC no inicio
input string             Arquivo_Traco        = "";                // Traco por barra (CSV em Common/Files/AlgoLab); vazio = desligado
//@omitir-fim

//+------------------------------------------------------------------+
//| ESTADO GLOBAL                                                    |
//+------------------------------------------------------------------+

CTrade   g_trade;
CArima   g_arima;
CGarch   g_garch;
CDesempenho g_desempenho;         //@omitir
bool     g_no_testador = false;   //@omitir

int      g_p = 1, g_d = 1, g_q = 1;   // ordens em uso
int      g_digits;
double   g_ponto;
datetime g_ultima_barra = 0;
int      g_barras_desde_selecao = 0;
bool     g_ordens_definidas = false;

//@omitir-inicio
//--- Contadores para o resumo final
long     g_barras_processadas = 0;
long     g_sinais_arima = 0;
long     g_bloqueios_garch = 0;
long     g_ordens_enviadas = 0;
long     g_falhas_ajuste = 0;
double   g_soma_nu = 0.0;        // graus de liberdade estimados (t de Student)
long     g_n_nu = 0;

//--- Traco por barra (diagnostico; nao interfere em nenhuma decisao)
int      g_fh_traco = INVALID_HANDLE;

//+------------------------------------------------------------------+
//| TRACO POR BARRA                                                  |
//+------------------------------------------------------------------+
//|  Grava, a cada barra, TODOS os parametros que o modelo estimou.  |
//|  E so diagnostico: nada aqui influencia a decisao de operar.     |
//|  Ligado pelo input Arquivo_Traco; vazio deixa tudo desligado.    |
//+------------------------------------------------------------------+
void AbrirTraco(void)
  {
   if(Arquivo_Traco == "")
      return;

   string nome = "AlgoLab\\traco_" + Arquivo_Traco + ".csv";
   g_fh_traco = FileOpen(nome, FILE_WRITE | FILE_TXT | FILE_ANSI | FILE_COMMON);

   if(g_fh_traco == INVALID_HANDLE)
     {
      PrintFormat("Traco: nao consegui abrir %s (erro %d)", nome, GetLastError());
      return;
     }

   FileWriteString(g_fh_traco,
      "data;preco;usa_garch;"
      "p;d;q;constante;phi1;phi2;phi3;phi4;theta1;theta2;theta3;theta4;"
      "arima_sigma2;arima_logL;arima_aic;arima_bic;arima_nef;arima_estavel;"
      "prev_dif;prev_nivel;"
      "garch_omega;garch_alpha1;garch_beta1;garch_persist;garch_var_lp;"
      "garch_logL;garch_aic;vol_prevista;vol_atual;limiar;"
      "sinal;volume;vetou;ordem_enviada;posicao;motivo\r\n");
   PrintFormat("Traco por barra ligado: Common\\Files\\%s", nome);
  }

void GravarTraco(const double preco, const double prev_dif, const bool garch_ok,
                 const double vol_prevista, const double limiar,
                 const DecisaoOperacao &dec, const bool ordem_enviada)
  {
   if(g_fh_traco == INVALID_HANDLE)
      return;

   ENUM_POSITION_TYPE pos = PosicaoAtual();
   int pos_cod = (pos == POSITION_TYPE_BUY) ? 1 : (pos == POSITION_TYPE_SELL) ? -1 : 0;

   FileWriteString(g_fh_traco, StringFormat(
      "%s;%.5f;%d;"
      "%d;%d;%d;%.10g;%.10g;%.10g;%.10g;%.10g;%.10g;%.10g;%.10g;%.10g;"
      "%.10g;%.6f;%.6f;%.6f;%d;%d;"
      "%.10g;%.6f;"
      "%.10g;%.10g;%.10g;%.6f;%.10g;"
      "%.6f;%.6f;%.10g;%.10g;%.10g;"
      "%d;%.2f;%d;%d;%d;%s\r\n",
      TimeToString(iTime(_Symbol, _Period, 0), TIME_DATE), preco, UsarGARCH ? 1 : 0,
      g_arima.P(), g_arima.D(), g_arima.Q(), g_arima.Constante(),
      g_arima.Phi(0), g_arima.Phi(1), g_arima.Phi(2), g_arima.Phi(3),
      g_arima.Theta(0), g_arima.Theta(1), g_arima.Theta(2), g_arima.Theta(3),
      g_arima.Sigma2(), g_arima.LogVerossimilhanca(), g_arima.AIC(), g_arima.BIC(),
      g_arima.NEfetivo(), g_arima.EstavelConservador() ? 1 : 0,
      prev_dif, g_arima.PreverNivel(),
      garch_ok ? g_garch.Omega() : 0.0, garch_ok ? g_garch.Alpha(0) : 0.0,
      garch_ok ? g_garch.Beta(0) : 0.0, garch_ok ? g_garch.Persistencia() : 0.0,
      garch_ok ? g_garch.VarianciaLongoPrazo() : 0.0,
      garch_ok ? g_garch.LogVerossimilhanca() : 0.0, garch_ok ? g_garch.AIC() : 0.0,
      vol_prevista, garch_ok ? g_garch.VolatilidadeAtual() : 0.0, limiar,
      dec.sinal, dec.volume, dec.bloqueou_garch ? 1 : 0, ordem_enviada ? 1 : 0,
      pos_cod, dec.motivo));
  }

//@omitir-fim

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
//@apendice: bool SelecionarOrdens()
//@omitir-inicio
bool SelecionarOrdens(const bool imprimir)
//@omitir-fim
  {
   double serie[];
   int janela = MathMax(Janela_Selecao, Janela_Estimacao);

   if(!CarregarSerie(janela, serie))
     {
      Print("Selecao de ordens: historico insuficiente (", janela, " barras)");   //@omitir
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

   //@omitir-inicio
   if(imprimir)
     {
      Print("=========================================================");
      Print(" SELECAO AUTOMATICA DE ORDENS - ", _Symbol, " ", EnumToString(_Period));
      Print(" Janela: ", janela, " barras | Transformacao: ",
            (Transformacao == TRANSF_LOG_PRECO) ? "log-preco" : "preco");
      Print("=========================================================");
      string linhas[];
      int n = StringSplit(relatorio, '\n', linhas);
      for(int i = 0; i < n; i++)
         if(StringLen(linhas[i]) > 0)
            Print(linhas[i]);
      Print("=========================================================");
     }
   //@omitir-fim

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
      Print("ERRO: Janela_Estimacao muito pequena (minimo 80 barras)");   //@omitir
      return(INIT_PARAMETERS_INCORRECT);
     }

   if(Frac_Volume_Min <= 0.0 || Frac_Volume_Max < Frac_Volume_Min)
     {
      Print("ERRO: Fracoes de volume inconsistentes");   //@omitir
      return(INIT_PARAMETERS_INCORRECT);
     }

   if(ModoVolume == VOLUME_CAPITAL && (Fracao_Capital <= 0.0 || Fracao_Capital > 1.0))
     {
      Print("ERRO: Fracao_Capital deve estar em (0, 1]");   //@omitir
      return(INIT_PARAMETERS_INCORRECT);
     }

   //@omitir-inicio
   //--- Registro por barra para a avaliacao contra a Selic
   g_no_testador = (bool)MQLInfoInteger(MQL_TESTER);
   if(g_no_testador)
     {
      g_desempenho.Definir(_Symbol, MagicNumber, Custo_Por_Lado);
      if(!g_desempenho.CarregarSelic("selic_diaria.csv"))
         Print("AVISO: selic_diaria.csv nao encontrado - caixa parado rendera 0");
      if(!g_desempenho.CarregarProventos(Arquivo_Proventos))
         Print("AVISO: ", Arquivo_Proventos, " nao encontrado - camada de proventos = 0");
     }

   //@omitir-fim
   if(ModoLimiar == LIMIAR_PERCENTIL &&
      (Limiar_Percentil <= 0.0 || Limiar_Percentil >= 100.0))
     {
      Print("ERRO: Limiar_Percentil deve estar entre 0 e 100");   //@omitir
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
      //@apendice: SelecionarOrdens();
      //@omitir-inicio
      if(!SelecionarOrdens(RelatorioInicial))
         Print("Selecao adiada para a primeira barra (historico ainda carregando)");
      //@omitir-fim
     }

   g_arima.Definir(g_p, g_d, g_q, IncluirConstante);
   g_garch.Definir(GARCH_p, GARCH_q);
   g_garch.DefinirOtimizador(Iteracoes_GARCH);
   g_garch.DefinirDistribuicao(DistribuicaoGARCH);   //@omitir

   //@omitir-inicio
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

   AbrirTraco();
   //@omitir-fim

   return(INIT_SUCCEEDED);
  }

//@omitir-inicio
//+------------------------------------------------------------------+
//| DESINICIALIZACAO                                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(g_fh_traco != INVALID_HANDLE)
     {
      FileClose(g_fh_traco);
      g_fh_traco = INVALID_HANDLE;
     }

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

//@omitir-fim

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

   //@omitir-inicio
   //--- Registro ANTES de qualquer ordem: a exposicao anotada e a
   //--- posicao carregada desde a barra anterior
   if(g_no_testador)
      g_desempenho.RegistrarAgora(barra);

   //@omitir-fim
   //--- Selecao de ordens pendente ou vencida
   if(ModoOrdens == ORDENS_AUTOMATICO)
     {
      bool precisa = (!g_ordens_definidas) ||
                     (Barras_Entre_Reselecao > 0 &&
                      g_barras_desde_selecao >= Barras_Entre_Reselecao);

      if(precisa)
        {
         //@apendice: if(SelecionarOrdens())
         //@omitir-inicio
         if(SelecionarOrdens(!g_ordens_definidas && RelatorioInicial))
         //@omitir-fim
           {
            g_arima.Definir(g_p, g_d, g_q, IncluirConstante);
            PrintFormat("Ordens em uso: ARIMA(%d,%d,%d)", g_p, g_d, g_q);   //@omitir
           }
        }
      g_barras_desde_selecao++;
     }

   if(!g_ordens_definidas)
      return;

   g_barras_processadas++;   //@omitir

   //--- ── 1) Serie da janela movel ──
   double serie[];
   if(!CarregarSerie(Janela_Estimacao, serie))
      return;

   //--- ── 2) ARIMA: media condicional ──
   if(!g_arima.Ajustar(serie))
     {
      //@omitir-inicio
      g_falhas_ajuste++;
      if(Diagnostico)
         Print("ARIMA nao ajustou: ", g_arima.UltimoErro());
      //@omitir-fim
      return;
     }

   //--- Previsao do RETORNO do dia, que da a direcao da operacao.
   //--- Com log-preco e d=1, e a propria previsao no espaco diferenciado
   //--- (o log-retorno esperado). Com d=0 o ARIMA modela o NIVEL do
   //--- log-preco, e a previsao diferenciada e o proprio nivel (~3,2):
   //--- sempre positiva, ela fazia o EA "prever alta" todo dia. A direcao
   //--- passa a ser nivel previsto menos nivel atual. (Corrigido em
   //--- 05/10/2026; ver notas/INCERTEZAS.md. Para d=1 nada muda.)
   double previsao = (g_arima.D() == 1)
                     ? g_arima.PreverDiferenciado()
                     : g_arima.PreverNivel() - serie[ArraySize(serie) - 1];

   if(!MathIsValidNumber(previsao))
     {
      g_falhas_ajuste++;   //@omitir
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
         g_falhas_ajuste++;   //@omitir
         return;
        }

      if(g_garch.Ajustar(residuos))
        {
         vol_prevista = g_garch.VolatilidadeProximoPeriodo();
         garch_ok = true;
         if(g_garch.Nu() > 0.0) { g_soma_nu += g_garch.Nu(); g_n_nu++; }   //@omitir

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
         //@omitir-inicio
         g_falhas_ajuste++;
         if(Diagnostico)
            Print("GARCH nao ajustou: ", g_garch.UltimoErro(), " - barra ignorada");
         //@omitir-fim
         return;
        }
     }

   //--- ── 4) Decisao ──
   DecisaoOperacao dec;
   DecidirOperacao(previsao, vol_prevista, UsarGARCH, Estrategia,
                   limiar, Vol_Alvo, K_Confianca,
                   Volume_Base, Frac_Volume_Min, Frac_Volume_Max,
                   Limiar_Sinal, dec);

   //@omitir-inicio
   if(previsao > Limiar_Sinal || previsao < -Limiar_Sinal)
      g_sinais_arima++;

   if(dec.bloqueou_garch)
      g_bloqueios_garch++;

   //@omitir-fim
   //@omitir-inicio
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
   long ordens_antes = g_ordens_enviadas;

   //@omitir-fim
   if(dec.sinal != 0)
      Executar(dec);
   else if(dec.bloqueou_garch && ZerarNoVeto)
     {
      //--- Veto com posicao aberta: sem zerar, o veto impediria apenas
      //--- a ENTRADA e a posicao antiga atravessaria o periodo agitado
      //--- que o filtro existe para evitar.
      ENUM_POSITION_TYPE posicao = PosicaoAtual();
      if(posicao == POSITION_TYPE_BUY || posicao == POSITION_TYPE_SELL)
         FecharPosicao(posicao);
     }

   //@omitir-inicio
   //--- ── 7) Traco (diagnostico; depois da execucao, para saber se a
   //---        ordem foi de fato enviada) ──
   GravarTraco(iClose(_Symbol, _Period, 1), previsao, garch_ok,
               vol_prevista, limiar, dec, g_ordens_enviadas > ordens_antes);
   //@omitir-fim
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

   //--- ── So compra: sinal de venda apenas encerra a compra ──
   if(dec.sinal < 0 && SomenteCompra)
     {
      if(posicao == POSITION_TYPE_BUY)
         FecharPosicao(POSITION_TYPE_BUY);
      return;
     }

   double volume = AjustarVolume(VolumeDesejado(dec.volume,
                                 (dec.sinal > 0) ? tick.ask : tick.bid));

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

      //@apendice: g_trade.Buy(volume, _Symbol, tick.ask, sl, tp, "ARIMA-GARCH BUY");
      //@omitir-inicio
      if(g_trade.Buy(volume, _Symbol, tick.ask, sl, tp, "ARIMA-GARCH BUY"))
         g_ordens_enviadas++;
      else
         Print("Falha na compra: ", g_trade.ResultRetcodeDescription());
      //@omitir-fim

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

   //@apendice: g_trade.Sell(volume, _Symbol, tick.bid, sl, tp, "ARIMA-GARCH SELL");
   //@omitir-inicio
   if(g_trade.Sell(volume, _Symbol, tick.bid, sl, tp, "ARIMA-GARCH SELL"))
      g_ordens_enviadas++;
   else
      Print("Falha na venda: ", g_trade.ResultRetcodeDescription());
   //@omitir-fim
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

         Print("Falha ao fechar posicao: ", g_trade.ResultRetcodeDescription());   //@omitir
         return(false);
        }
     }

   return(true);   // nao havia posicao a fechar
  }

//+------------------------------------------------------------------+
//| Volume em acoes a partir do volume da decisao                    |
//+------------------------------------------------------------------+
//|  volume_decisao ja traz o fator do targeting aplicado sobre      |
//|  Volume_Base; no modo CAPITAL o mesmo fator e aplicado sobre a   |
//|  fracao do patrimonio (VolumePorCapital, em Estrategia.mqh).     |
//+------------------------------------------------------------------+
double VolumeDesejado(const double volume_decisao, const double preco)
  {
   if(ModoVolume == VOLUME_FIXO || preco <= 0.0)
      return(volume_decisao);

   double fator = (Volume_Base > 0.0) ? volume_decisao / Volume_Base : 1.0;
   return(VolumePorCapital(_Symbol, Fracao_Capital * fator, preco));
  }

//@omitir-inicio
//+------------------------------------------------------------------+
//| Fim do teste: metricas contra a Selic e o buy-and-hold           |
//+------------------------------------------------------------------+
//|  O valor devolvido - retorno acima da Selic, em pontos           |
//|  percentuais - e o criterio personalizado da otimizacao.         |
//+------------------------------------------------------------------+
double OnTester()
  {
   g_desempenho.RegistrarAgora(TimeCurrent());

   ResultadoDesempenho r;
   if(!g_desempenho.Calcular(r))
      return(0.0);

   g_desempenho.Imprimir(r);
   PrintFormat("  GARCH: %d vetos em %d sinais do ARIMA", g_bloqueios_garch, g_sinais_arima);

   string cab = "modelo;UsarGARCH;Estrategia;ModoLimiar;Limiar_Percentil;"
                "Limiar_Absoluto;K_Confianca;Vol_Alvo;Limiar_Sinal;Janela_Estimacao;"
                "SomenteCompra;ZerarNoVeto;ModoVolume;Fracao_Capital;Volume_Base;ModoOrdens;"
                "IncluirConstante;Barras_Entre_Reselecao;p;d;q;vetos;sinais;DistribuicaoGARCH;nu_medio";

   string val = StringFormat("%s;%d;%d;%d;%.1f;%.4f;%.3f;%.4f;%.5f;%d;%d;%d;%d;%.2f;%.0f;%d;%d;%d;%d;%d;%d;%d;%d;%d;%.3f",
                             UsarGARCH ? "ARIMA-GARCH" : "ARIMA",
                             UsarGARCH, Estrategia, ModoLimiar, Limiar_Percentil,
                             Limiar_Absoluto, K_Confianca, Vol_Alvo, Limiar_Sinal,
                             Janela_Estimacao, SomenteCompra, ZerarNoVeto, ModoVolume,
                             Fracao_Capital, Volume_Base, ModoOrdens, IncluirConstante,
                             Barras_Entre_Reselecao, g_p, g_d, g_q,
                             g_bloqueios_garch, g_sinais_arima, DistribuicaoGARCH,
                             (g_n_nu > 0) ? g_soma_nu / (double)g_n_nu : 0.0);

   g_desempenho.Gravar(Rotulo, cab, val, r);
   return(r.excesso * 100.0);
  }

//@omitir-fim

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
