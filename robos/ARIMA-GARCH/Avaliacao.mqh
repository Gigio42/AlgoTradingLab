//+------------------------------------------------------------------+
//| Avaliacao.mqh                                                    |
//| Avaliacao do ARIMA_GARCH_EA no Strategy Tester: registro por     |
//| barra e, no fim do teste, a linha de metricas com a configuracao |
//| usada. So roda no testador. Le os inputs do EA.                  |
//+------------------------------------------------------------------+
#ifndef ALGOTRADINGLAB_AVALIACAO_MQH
#define ALGOTRADINGLAB_AVALIACAO_MQH

#include "..\Include\Desempenho.mqh"

CDesempenho g_desempenho;
bool        g_no_testador = false;

void IniciarAvaliacao(void)
  {
   g_no_testador = (bool)MQLInfoInteger(MQL_TESTER);
   if(!g_no_testador)
      return;

   g_desempenho.Definir(_Symbol, MagicNumber, Custo_Por_Lado);
   if(!g_desempenho.CarregarSelic("selic_diaria.csv"))
      Print("AVISO: selic_diaria.csv nao encontrado - caixa parado rendera 0");
   if(!g_desempenho.CarregarProventos(Arquivo_Proventos))
      Print("AVISO: ", Arquivo_Proventos, " nao encontrado - camada de proventos = 0");
  }

//--- Na abertura da barra, antes de qualquer ordem: a exposicao anotada e a carregada desde a anterior
void RegistrarBarraNaAvaliacao(const datetime barra)
  {
   if(g_no_testador)
      g_desempenho.RegistrarAgora(barra);
  }

//--- Grava metricas_<Rotulo>.csv e curva_<Rotulo>.csv. Devolve o excesso sobre a Selic em
//--- pontos percentuais, criterio personalizado da otimizacao.
double AvaliarTeste(const int p, const int d, const int q, const CDiagnostico &diagnostico)
  {
   g_desempenho.RegistrarAgora(TimeCurrent());

   ResultadoDesempenho resultado;
   if(!g_desempenho.Calcular(resultado))
      return(0.0);

   g_desempenho.Imprimir(resultado);
   PrintFormat("  GARCH: %d vetos em %d sinais do ARIMA", diagnostico.VetosGarch(), diagnostico.SinaisArima());

   string cabecalho = "modelo;UsarGARCH;Estrategia;ModoLimiar;Limiar_Percentil;"
                      "Limiar_Absoluto;Vol_Alvo;Limiar_Sinal;Janela_Estimacao;"
                      "SomenteCompra;ZerarNoVeto;ModoVolume;Fracao_Capital;Volume_Base;ModoOrdens;"
                      "IncluirConstante;Barras_Entre_Reselecao;p;d;q;vetos;sinais;DistribuicaoGARCH;nu_medio;"
                      "MetodoARIMA;mv_tentativas;mv_fallback;fator_recuperacao_mt5;lucro_mt5;dd_capital_mt5;SelecaoPorBIC";

   string valores = StringFormat("%s;%d;%d;%d;%.1f;%.4f;%.4f;%.5f;%d;%d;%d;%d;%.2f;%.0f;%d;%d;%d;%d;%d;%d;%d;%d;%d;%.3f",
                                 UsarGARCH ? "ARIMA-GARCH" : "ARIMA",
                                 UsarGARCH, Estrategia, ModoLimiar, Limiar_Percentil,
                                 Limiar_Absoluto, Vol_Alvo, Limiar_Sinal,
                                 Janela_Estimacao, SomenteCompra, ZerarNoVeto, ModoVolume,
                                 Fracao_Capital, Volume_Base, ModoOrdens, IncluirConstante,
                                 Barras_Entre_Reselecao, p, d, q,
                                 diagnostico.VetosGarch(), diagnostico.SinaisArima(), DistribuicaoGARCH,
                                 diagnostico.GrausLiberdadeMedio());
   //--- Medidas do proprio relatorio do testador (camada pura, sem custo nem Selic)
   valores += StringFormat(";%d;%d;%d;%.6f;%.2f;%.6f", MetodoARIMA,
                           g_tentativas_verossimilhanca, g_mantidos_hannan_rissanen,
                           TesterStatistics(STAT_RECOVERY_FACTOR),
                           TesterStatistics(STAT_PROFIT),
                           TesterStatistics(STAT_EQUITY_DDREL_PERCENT));
   valores += StringFormat(";%d", SelecaoPorBIC);

   g_desempenho.Gravar(Rotulo, cabecalho, valores, resultado);
   return(resultado.excesso * 100.0);
  }

#endif
