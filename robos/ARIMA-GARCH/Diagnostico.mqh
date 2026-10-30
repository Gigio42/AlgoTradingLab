//+------------------------------------------------------------------+
//| Diagnostico.mqh                                                  |
//| Tudo o que o ARIMA_GARCH_EA so observa: mensagens no terminal,   |
//| contadores e o traco por barra (CSV com os parametros estimados  |
//| a cada dia). Nada aqui influencia a decisao de operar.           |
//| Le os inputs do EA, por isso e incluido depois deles.            |
//+------------------------------------------------------------------+
#ifndef ALGOTRADINGLAB_DIAGNOSTICO_MQH
#define ALGOTRADINGLAB_DIAGNOSTICO_MQH

class CDiagnostico
  {
private:
   CArima      *m_arima;
   CGarch      *m_garch;
   CNegociacao *m_negociacao;

   int      m_arquivo_traco;
   long     m_barras_processadas;
   long     m_falhas_ajuste;
   long     m_sinais_arima;
   long     m_vetos_garch;
   long     m_ordens_antes;
   double   m_soma_graus_liberdade;
   long     m_estimativas_graus_liberdade;

   void     AbrirTraco(void);

public:
                     CDiagnostico(void) : m_arima(NULL), m_garch(NULL), m_negociacao(NULL),
                                          m_arquivo_traco(INVALID_HANDLE), m_barras_processadas(0),
                                          m_falhas_ajuste(0), m_sinais_arima(0), m_vetos_garch(0),
                                          m_ordens_antes(0), m_soma_graus_liberdade(0.0),
                                          m_estimativas_graus_liberdade(0) {}

   void     Iniciar(CArima *arima, CGarch *garch, CNegociacao *negociacao, const int p, const int d, const int q);
   void     Encerrar(const int p, const int d, const int q);

   void     HistoricoInsuficiente(const int janela);
   void     Selecao(const string relatorio, const int janela, const bool ordens_ja_definidas);
   void     OrdensEmUso(const int p, const int d, const int q);

   void     BarraProcessada(void) { m_barras_processadas++; }
   void     FalhaDeAjuste(const string motivo);
   void     GrausLiberdadeEstimados(const double graus_liberdade);
   void     Decisao(const double previsao, const double volatilidade, const double limiar,
                    const bool garch_ajustado, const DecisaoOperacao &decisao);
   void     GravarTraco(const double previsao, const double volatilidade, const double limiar,
                        const bool garch_ajustado, const DecisaoOperacao &decisao);

   long     SinaisArima(void) const { return(m_sinais_arima); }
   long     VetosGarch(void)  const { return(m_vetos_garch); }
   double   GrausLiberdadeMedio(void) const
     { return((m_estimativas_graus_liberdade > 0) ? m_soma_graus_liberdade / (double)m_estimativas_graus_liberdade : 0.0); }
  };

void CDiagnostico::Iniciar(CArima *arima, CGarch *garch, CNegociacao *negociacao, const int p, const int d, const int q)
  {
   m_arima = arima;
   m_garch = garch;
   m_negociacao = negociacao;

   PrintFormat("EA iniciado | %s | modelo: %s | ARIMA(%d,%d,%d)%s | janela=%d",
               _Symbol, UsarGARCH ? "ARIMA-GARCH" : "ARIMA puro", p, d, q,
               UsarGARCH ? StringFormat(" + GARCH(%d,%d)", GARCH_p, GARCH_q) : "", Janela_Estimacao);
   if(UsarGARCH)
      PrintFormat("Estrategia: %s | limiar: %s", EnumToString(Estrategia),
                  (ModoLimiar == LIMIAR_ABSOLUTO) ? StringFormat("absoluto %.6f", Limiar_Absoluto)
                                                  : StringFormat("percentil %.1f", Limiar_Percentil));
   AbrirTraco();
  }

void CDiagnostico::Encerrar(const int p, const int d, const int q)
  {
   if(m_arquivo_traco != INVALID_HANDLE)
     {
      FileClose(m_arquivo_traco);
      m_arquivo_traco = INVALID_HANDLE;
     }

   Print("---------------------------------------------------------");
   PrintFormat(" RESUMO | modelo: %s | ARIMA(%d,%d,%d)", UsarGARCH ? "ARIMA-GARCH" : "ARIMA puro", p, d, q);
   PrintFormat(" Barras processadas ....... %d", m_barras_processadas);
   PrintFormat(" Falhas de ajuste ......... %d", m_falhas_ajuste);
   PrintFormat(" Sinais gerados pelo ARIMA. %d", m_sinais_arima);
   PrintFormat(" Vetados pelo GARCH ....... %d", m_vetos_garch);
   PrintFormat(" Ordens enviadas .......... %d", (m_negociacao != NULL) ? m_negociacao.OrdensEnviadas() : 0);
   Print("---------------------------------------------------------");
  }

void CDiagnostico::HistoricoInsuficiente(const int janela)
  {
   Print("Selecao de ordens: historico insuficiente (", janela, " barras)");
  }

//--- A sequencia do ADF e a grade de AIC saem uma vez, na primeira selecao
void CDiagnostico::Selecao(const string relatorio, const int janela, const bool ordens_ja_definidas)
  {
   if(!RelatorioInicial || ordens_ja_definidas)
      return;

   Print("=========================================================");
   Print(" SELECAO AUTOMATICA DE ORDENS - ", _Symbol, " ", EnumToString(_Period));
   Print(" Janela: ", janela, " barras | Transformacao: ",
         (Transformacao == TRANSF_LOG_PRECO) ? "log-preco" : "preco");
   Print("=========================================================");
   string linhas[];
   int quantidade = StringSplit(relatorio, '\n', linhas);
   for(int i = 0; i < quantidade; i++)
      if(StringLen(linhas[i]) > 0)
         Print(linhas[i]);
   Print("=========================================================");
  }

void CDiagnostico::OrdensEmUso(const int p, const int d, const int q)
  {
   PrintFormat("Ordens em uso: ARIMA(%d,%d,%d)", p, d, q);
  }

void CDiagnostico::FalhaDeAjuste(const string motivo)
  {
   m_falhas_ajuste++;
   if(Diagnostico && motivo != "")
      Print(motivo);
  }

void CDiagnostico::GrausLiberdadeEstimados(const double graus_liberdade)
  {
   if(graus_liberdade <= 0.0)
      return;
   m_soma_graus_liberdade += graus_liberdade;
   m_estimativas_graus_liberdade++;
  }

//--- Conta sinais e vetos, guarda o numero de ordens antes da execucao e, com o
//--- input Diagnostico, escreve a decisao da barra
void CDiagnostico::Decisao(const double previsao, const double volatilidade, const double limiar,
                           const bool garch_ajustado, const DecisaoOperacao &decisao)
  {
   if(previsao > Limiar_Sinal || previsao < -Limiar_Sinal)
      m_sinais_arima++;
   if(decisao.vetada_pelo_garch)
      m_vetos_garch++;
   m_ordens_antes = m_negociacao.OrdensEnviadas();

   if(!Diagnostico)
      return;
   Print("--------------------------------------------");
   PrintFormat("ARIMA(%d,%d,%d) previsao=%.8f  sigma2=%.10f  AIC=%.2f",
               m_arima.P(), m_arima.D(), m_arima.Q(), previsao, m_arima.Sigma2(), m_arima.AIC());
   if(UsarGARCH && garch_ajustado)
      PrintFormat("GARCH vol=%.8f (%.3f%%)  limiar=%.8f  persist=%.4f",
                  volatilidade, volatilidade * 100.0, limiar, m_garch.Persistencia());
   PrintFormat("Decisao: sinal=%d volume=%.2f | %s", decisao.sinal, decisao.volume, decisao.motivo);
  }

//--- Ligado pelo input Arquivo_Traco: Common/Files/AlgoLab/traco_<nome>.csv
void CDiagnostico::AbrirTraco(void)
  {
   if(Arquivo_Traco == "")
      return;

   string nome = "AlgoLab\\traco_" + Arquivo_Traco + ".csv";
   m_arquivo_traco = FileOpen(nome, FILE_WRITE | FILE_TXT | FILE_ANSI | FILE_COMMON);
   if(m_arquivo_traco == INVALID_HANDLE)
     {
      PrintFormat("Traco: nao consegui abrir %s (erro %d)", nome, GetLastError());
      return;
     }

   FileWriteString(m_arquivo_traco,
      "data;preco;usa_garch;"
      "p;d;q;constante;phi1;phi2;phi3;phi4;theta1;theta2;theta3;theta4;"
      "arima_sigma2;arima_logL;arima_aic;arima_bic;arima_nef;arima_estavel;"
      "prev_dif;prev_nivel;"
      "garch_omega;garch_alpha1;garch_beta1;garch_persist;garch_var_lp;"
      "garch_logL;garch_aic;vol_prevista;vol_atual;limiar;"
      "sinal;volume;vetou;ordem_enviada;posicao;motivo\r\n");
   PrintFormat("Traco por barra ligado: Common\\Files\\%s", nome);
  }

//--- Chamado depois da execucao: ordem_enviada diz se o EA de fato mandou ordem na barra
void CDiagnostico::GravarTraco(const double previsao, const double volatilidade, const double limiar,
                               const bool garch_ajustado, const DecisaoOperacao &decisao)
  {
   if(m_arquivo_traco == INVALID_HANDLE)
      return;

   ENUM_POSITION_TYPE posicao = m_negociacao.PosicaoAtual();
   int codigo_posicao = (posicao == POSITION_TYPE_BUY) ? 1 : (posicao == POSITION_TYPE_SELL) ? -1 : 0;
   bool ordem_enviada = (m_negociacao.OrdensEnviadas() > m_ordens_antes);

   FileWriteString(m_arquivo_traco, StringFormat(
      "%s;%.5f;%d;"
      "%d;%d;%d;%.10g;%.10g;%.10g;%.10g;%.10g;%.10g;%.10g;%.10g;%.10g;"
      "%.10g;%.6f;%.6f;%.6f;%d;%d;"
      "%.10g;%.6f;"
      "%.10g;%.10g;%.10g;%.6f;%.10g;"
      "%.6f;%.6f;%.10g;%.10g;%.10g;"
      "%d;%.2f;%d;%d;%d;%s\r\n",
      TimeToString(iTime(_Symbol, _Period, 0), TIME_DATE), iClose(_Symbol, _Period, 1), UsarGARCH ? 1 : 0,
      m_arima.P(), m_arima.D(), m_arima.Q(), m_arima.Constante(),
      m_arima.Phi(0), m_arima.Phi(1), m_arima.Phi(2), m_arima.Phi(3),
      m_arima.Theta(0), m_arima.Theta(1), m_arima.Theta(2), m_arima.Theta(3),
      m_arima.Sigma2(), m_arima.LogVerossimilhanca(), m_arima.AIC(), m_arima.BIC(),
      m_arima.ObservacoesEfetivas(), m_arima.EstacionariedadeGarantida() ? 1 : 0,
      previsao, m_arima.PreverNivel(),
      garch_ajustado ? m_garch.Omega() : 0.0, garch_ajustado ? m_garch.Alfa(0) : 0.0,
      garch_ajustado ? m_garch.Beta(0) : 0.0, garch_ajustado ? m_garch.Persistencia() : 0.0,
      garch_ajustado ? m_garch.VarianciaLongoPrazo() : 0.0,
      garch_ajustado ? m_garch.LogVerossimilhanca() : 0.0, garch_ajustado ? m_garch.AIC() : 0.0,
      volatilidade, garch_ajustado ? m_garch.VolatilidadeAtual() : 0.0, limiar,
      decisao.sinal, decisao.volume, decisao.vetada_pelo_garch ? 1 : 0, ordem_enviada ? 1 : 0,
      codigo_posicao, decisao.motivo));
  }

#endif
