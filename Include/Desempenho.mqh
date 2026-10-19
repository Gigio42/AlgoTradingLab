//+------------------------------------------------------------------+
//| Desempenho.mqh                                                   |
//| Avaliacao no Strategy Tester, em camadas, a partir de um         |
//| registro por barra (feito antes de qualquer ordem):              |
//|   1) pura: variacao do patrimonio no testador                    |
//|   2) + custos B3 por execucao                                    |
//|   3) + caixa parado rendendo a Selic do dia                      |
//|   4) + proventos na data-ex (fonte nao oficial, so adendo)       |
//| O modelo nunca ve nada disso. Referencias: Selic e compra e      |
//| manutencao. Nao interfere na decisao de operar.                  |
//+------------------------------------------------------------------+
#ifndef ALGOTRADINGLAB_DESEMPENHO_MQH
#define ALGOTRADINGLAB_DESEMPENHO_MQH

#include <Math\Stat\Normal.mqh>

//--- Retornos em fracao (0,10 = 10%). Os nomes sao as colunas do CSV de metricas.
struct ResultadoDesempenho
  {
   datetime inicio;
   datetime fim;
   int      dias;
   double   anos;
   int      negocios;          // entradas
   int      saidas;            // saidas com resultado
   double   taxa_acerto;       // saidas com lucro depois dos custos / saidas
   double   fator_lucro;       // lucro bruto / prejuizo bruto, depois dos custos
   double   custo_total;       // custos em fracao do capital inicial
   double   exposicao_media;   // fracao media do capital posicionada
   double   ret_puro;          // camada 1
   double   ret_custos;        // camada 2
   double   ret_selic;         // camada 3
   double   ret_completo;      // camada 4
   double   selic;             // Selic acumulada
   double   bh_preco;          // compra e manutencao, so preco
   double   bh_total;          // compra e manutencao com proventos
   double   cagr_puro, cagr_selic_camada, cagr_completo;
   double   cagr_selic, cagr_bh_preco, cagr_bh_total;
   double   excesso;           // ret_selic - selic (criterio da otimizacao)
   double   excesso_completo;  // ret_completo - selic
   double   dd_puro, dd_selic, dd_completo, dd_bh_preco, dd_bh_total;
   double   vol_puro, vol_selic, vol_bh_preco;
   double   sharpe, sharpe_t, sharpe_p, sharpe_bh;
   double   sortino, sortino_bh, calmar, calmar_bh;
   double   beta, alfa, alfa_t, z_sharpe_bh, p_sharpe_bh;
   double   sharpe_completo, sharpe_completo_p, sharpe_bh_total;
   bool     ruina;             // patrimonio chegou a zero
  };

//--- Medidas sobre o excesso diario de uma estrategia e de uma referencia, ambos sobre a Selic
struct MedidasExcesso
  {
   double   sharpe, sharpe_t, sharpe_p, sharpe_referencia;
   double   sortino, sortino_referencia;
   double   beta, alfa, alfa_t;
   double   z_diferenca_sharpe, p_diferenca_sharpe;
   double   volatilidade, volatilidade_referencia;
  };

//--- Sharpe anualizado (raiz de 252) com erro-padrao de Lo (2002); Sortino; alfa e beta
//--- contra a referencia; diferenca de Sharpe por Jobson-Korkie com a correcao de Memmel (2003).
void CalcularMedidasExcesso(const double &excesso[], const double &excesso_referencia[], MedidasExcesso &medidas)
  {
   ZeroMemory(medidas);
   int n = ArraySize(excesso);
   if(n < 3)
      return;

   double media = 0, media_ref = 0;
   for(int i = 0; i < n; i++) { media += excesso[i]; media_ref += excesso_referencia[i]; }
   media /= n;
   media_ref /= n;

   double variancia = 0, variancia_ref = 0, covariancia = 0, perdas = 0, perdas_ref = 0;
   for(int i = 0; i < n; i++)
     {
      variancia += (excesso[i] - media) * (excesso[i] - media);
      variancia_ref += (excesso_referencia[i] - media_ref) * (excesso_referencia[i] - media_ref);
      covariancia += (excesso[i] - media) * (excesso_referencia[i] - media_ref);
      if(excesso[i] < 0.0) perdas += excesso[i] * excesso[i];
      if(excesso_referencia[i] < 0.0) perdas_ref += excesso_referencia[i] * excesso_referencia[i];
     }
   variancia /= n - 1;
   variancia_ref /= n - 1;
   covariancia /= n - 1;

   double desvio = MathSqrt(variancia), desvio_ref = MathSqrt(variancia_ref), raiz252 = MathSqrt(252.0);
   int erro = 0;
   medidas.volatilidade = desvio * raiz252;
   medidas.volatilidade_referencia = desvio_ref * raiz252;

   double sharpe_diario = (desvio > 0) ? media / desvio : 0;
   double sharpe_diario_ref = (desvio_ref > 0) ? media_ref / desvio_ref : 0;
   medidas.sharpe = sharpe_diario * raiz252;
   medidas.sharpe_referencia = sharpe_diario_ref * raiz252;

   double erro_padrao_lo = MathSqrt((1.0 + 0.5 * sharpe_diario * sharpe_diario) / n);
   medidas.sharpe_t = (erro_padrao_lo > 0) ? sharpe_diario / erro_padrao_lo : 0;
   medidas.sharpe_p = 1.0 - MathCumulativeDistributionNormal(medidas.sharpe_t, 0.0, 1.0, erro);

   double desvio_perdas = MathSqrt(perdas / n), desvio_perdas_ref = MathSqrt(perdas_ref / n);
   medidas.sortino = (desvio_perdas > 0) ? media / desvio_perdas * raiz252 : 0;
   medidas.sortino_referencia = (desvio_perdas_ref > 0) ? media_ref / desvio_perdas_ref * raiz252 : 0;

   if(variancia_ref > 0)
     {
      medidas.beta = covariancia / variancia_ref;
      double alfa_diario = media - medidas.beta * media_ref, soma_residuos = 0;
      for(int i = 0; i < n; i++)
        {
         double residuo = excesso[i] - alfa_diario - medidas.beta * excesso_referencia[i];
         soma_residuos += residuo * residuo;
        }
      double erro_padrao_alfa = MathSqrt(soma_residuos / (n - 2.0) *
                                         (1.0 / n + media_ref * media_ref / ((n - 1.0) * variancia_ref)));
      medidas.alfa = alfa_diario * 252.0;
      medidas.alfa_t = (erro_padrao_alfa > 0) ? alfa_diario / erro_padrao_alfa : 0;
     }

   if(desvio > 0 && desvio_ref > 0)
     {
      double correlacao = covariancia / (desvio * desvio_ref);
      double theta = 2.0 - 2.0 * correlacao + 0.5 * (sharpe_diario * sharpe_diario + sharpe_diario_ref * sharpe_diario_ref
                     - 2.0 * sharpe_diario * sharpe_diario_ref * correlacao * correlacao);
      if(theta > 0)
        {
         medidas.z_diferenca_sharpe = (sharpe_diario - sharpe_diario_ref) / MathSqrt(theta / n);
         medidas.p_diferenca_sharpe = 2.0 * (1.0 - MathCumulativeDistributionNormal(MathAbs(medidas.z_diferenca_sharpe), 0.0, 1.0, erro));
        }
     }
  }

class CDesempenho
  {
private:
   datetime m_data[];
   double   m_patrimonio[];
   double   m_exposicao[];       // com sinal: + comprado, - vendido
   double   m_preco[];
   int      m_registros;

   datetime m_selic_data[];
   double   m_selic_taxa[];      // taxa do dia, em fracao
   int      m_selic_registros;

   datetime m_provento_data[];   // data-ex: primeiro pregao sem direito
   double   m_provento_valor[];  // R$ por acao
   int      m_provento_registros;

   double   m_custo_por_lado;
   ulong    m_magico;
   string   m_simbolo;

   //--- Curvas diarias (base 1), preenchidas por Calcular
   double   m_curva_pura[], m_curva_selic[], m_curva_completa[];
   double   m_curva_referencia_selic[], m_curva_bh_preco[], m_curva_bh_total[];

   double   SelicDoDia(const datetime data) const;
   double   ProventoNaData(const datetime data) const;
   double   Exposicao(const double preco) const;
   bool     LerSerie(const string arquivo, datetime &datas[], double &valores[], const double escala);

public:
                     CDesempenho(void) : m_registros(0), m_selic_registros(0), m_provento_registros(0),
                                         m_custo_por_lado(0.0003), m_magico(0) {}

   void     Definir(const string simbolo, const ulong magico, const double custo_por_lado)
     { m_simbolo = simbolo; m_magico = magico; m_custo_por_lado = MathMax(0.0, custo_por_lado); }

   //--- "AAAA.MM.DD,taxa", taxa diaria em percentual (SGS 11 do BCB)
   bool     CarregarSelic(const string arquivo)
     { m_selic_registros = LerSerie(arquivo, m_selic_data, m_selic_taxa, 0.01) ? ArraySize(m_selic_data) : 0; return(m_selic_registros > 0); }
   //--- "AAAA.MM.DD,valor": data-ex e provento em R$ por acao
   bool     CarregarProventos(const string arquivo)
     { m_provento_registros = LerSerie(arquivo, m_provento_data, m_provento_valor, 1.0) ? ArraySize(m_provento_data) : 0; return(m_provento_registros > 0); }

   void     RegistrarAgora(const datetime data);
   bool     Calcular(ResultadoDesempenho &resultado);
   void     Imprimir(const ResultadoDesempenho &resultado) const;
   static string Cabecalho(void);
   static string Linha(const ResultadoDesempenho &resultado);
   bool     GravarCurva(const string arquivo) const;
   //--- metricas_<rotulo>.csv e curva_<rotulo>.csv; na otimizacao, um arquivo de nome unico por passagem
   void     Gravar(const string rotulo, const string cabecalho_modelo,
                   const string valores_modelo, const ResultadoDesempenho &resultado) const;
  };

//--- Uma linha por registro; linhas que comecam com '#' sao comentario (procedencia)
bool CDesempenho::LerSerie(const string arquivo, datetime &datas[], double &valores[], const double escala)
  {
   ArrayResize(datas, 0, 8192);
   ArrayResize(valores, 0, 8192);
   int arquivo_aberto = FileOpen(arquivo, FILE_READ | FILE_TXT | FILE_ANSI);
   if(arquivo_aberto == INVALID_HANDLE)
      return(false);
   while(!FileIsEnding(arquivo_aberto))
     {
      string linha = FileReadString(arquivo_aberto);
      if(StringLen(linha) < 12 || StringGetCharacter(linha, 0) == '#')
         continue;
      string campos[];
      if(StringSplit(linha, ',', campos) < 2)
         continue;
      int k = ArraySize(datas);
      ArrayResize(datas, k + 1, 8192);
      ArrayResize(valores, k + 1, 8192);
      datas[k] = StringToTime(campos[0]);
      valores[k] = StringToDouble(campos[1]) * escala;
     }
   FileClose(arquivo_aberto);
   return(ArraySize(datas) > 0);
  }

//--- Taxa do ultimo dia publicado ate a data (busca binaria)
double CDesempenho::SelicDoDia(const datetime data) const
  {
   if(m_selic_registros == 0 || data < m_selic_data[0])
      return(0.0);
   int inicio = 0, fim = m_selic_registros - 1;
   while(inicio < fim)
     {
      int meio = (inicio + fim + 1) / 2;
      if(m_selic_data[meio] <= data) inicio = meio; else fim = meio - 1;
     }
   return(m_selic_taxa[inicio]);
  }

double CDesempenho::ProventoNaData(const datetime data) const
  {
   datetime dia = data - data % 86400;
   double soma = 0.0;
   for(int i = 0; i < m_provento_registros; i++)
      if(m_provento_data[i] - m_provento_data[i] % 86400 == dia)
         soma += m_provento_valor[i];
   return(soma);
  }

double CDesempenho::Exposicao(const double preco) const
  {
   double patrimonio = AccountInfoDouble(ACCOUNT_EQUITY);
   if(patrimonio <= 0.0)
      return(0.0);
   double contrato = SymbolInfoDouble(m_simbolo, SYMBOL_TRADE_CONTRACT_SIZE);
   double volume = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL) == m_simbolo &&
         (ulong)PositionGetInteger(POSITION_MAGIC) == m_magico)
        {
         double volume_posicao = PositionGetDouble(POSITION_VOLUME);
         volume += (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? volume_posicao : -volume_posicao;
        }
     }
   return(volume * preco * contrato / patrimonio);
  }

void CDesempenho::RegistrarAgora(const datetime data)
  {
   MqlTick tick;
   if(!SymbolInfoTick(m_simbolo, tick) || tick.bid <= 0.0)
      return;
   if(m_registros > 0 && data <= m_data[m_registros - 1])
      return;
   ArrayResize(m_data, m_registros + 1, 1024);
   ArrayResize(m_patrimonio, m_registros + 1, 1024);
   ArrayResize(m_exposicao, m_registros + 1, 1024);
   ArrayResize(m_preco, m_registros + 1, 1024);
   m_data[m_registros]       = data;
   m_patrimonio[m_registros] = AccountInfoDouble(ACCOUNT_EQUITY);
   m_exposicao[m_registros]  = Exposicao(tick.bid);
   m_preco[m_registros]      = tick.bid;
   m_registros++;
  }

bool CDesempenho::Calcular(ResultadoDesempenho &resultado)
  {
   ZeroMemory(resultado);
   int n = m_registros;
   if(n < 3)
      return(false);

   resultado.inicio = m_data[0];
   resultado.fim    = m_data[n - 1];
   resultado.dias   = n - 1;
   resultado.anos   = resultado.dias / 252.0;

   //--- Negocios: custo de cada intervalo, acerto e fator de lucro
   double custo[];
   ArrayResize(custo, n);
   ArrayInitialize(custo, 0.0);
   double lucro_bruto = 0.0, prejuizo_bruto = 0.0;
   int acertos = 0;

   if(HistorySelect(0, TimeCurrent() + 1))
     {
      int total = HistoryDealsTotal();
      for(int i = 0; i < total; i++)
        {
         ulong ticket = HistoryDealGetTicket(i);
         if(ticket == 0) continue;
         if(HistoryDealGetString(ticket, DEAL_SYMBOL) != m_simbolo ||
            (ulong)HistoryDealGetInteger(ticket, DEAL_MAGIC) != m_magico)
            continue;
         double valor = HistoryDealGetDouble(ticket, DEAL_VOLUME) *
                        HistoryDealGetDouble(ticket, DEAL_PRICE) *
                        SymbolInfoDouble(m_simbolo, SYMBOL_TRADE_CONTRACT_SIZE);
         if(HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_IN)
            resultado.negocios++;
         else
           {
            double resultado_saida = HistoryDealGetDouble(ticket, DEAL_PROFIT) - 2.0 * valor * m_custo_por_lado;
            resultado.saidas++;
            if(resultado_saida > 0.0) { acertos++; lucro_bruto += resultado_saida; }
            else                      prejuizo_bruto -= resultado_saida;
           }
         datetime data_negocio = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
         int intervalo = 0;
         for(int j = n - 1; j >= 0; j--)
            if(m_data[j] <= data_negocio) { intervalo = j; break; }
         custo[intervalo] += valor * m_custo_por_lado;
        }
     }
   resultado.taxa_acerto = (resultado.saidas > 0) ? (double)acertos / resultado.saidas : 0.0;
   resultado.fator_lucro = (prejuizo_bruto > 0.0) ? lucro_bruto / prejuizo_bruto : 0.0;

   ArrayResize(m_curva_pura, n); ArrayResize(m_curva_selic, n); ArrayResize(m_curva_completa, n);
   ArrayResize(m_curva_referencia_selic, n); ArrayResize(m_curva_bh_preco, n); ArrayResize(m_curva_bh_total, n);
   m_curva_pura[0] = m_curva_selic[0] = m_curva_completa[0] = m_curva_referencia_selic[0] = m_curva_bh_preco[0] = m_curva_bh_total[0] = 1.0;

   double fator_custos = 1.0;
   double excesso_selic[], excesso_completo[], excesso_bh_preco[], excesso_bh_total[], retorno_puro[];
   ArrayResize(excesso_selic, n - 1); ArrayResize(excesso_completo, n - 1); ArrayResize(excesso_bh_preco, n - 1);
   ArrayResize(excesso_bh_total, n - 1); ArrayResize(retorno_puro, n - 1);
   double soma_exposicao = 0.0, soma_custo = 0.0;

   for(int i = 1; i < n; i++)
     {
      double patrimonio_anterior = m_patrimonio[i - 1], preco_anterior = m_preco[i - 1];
      if(preco_anterior <= 0.0)
         return(false);
      //--- Conta zerada: a curva fica parada em zero ate o fim do periodo
      if(patrimonio_anterior <= 0.0 || resultado.ruina)
        {
         resultado.ruina = true;
         retorno_puro[i - 1] = 0.0;
         double selic_ruina = SelicDoDia(m_data[i - 1]);
         excesso_selic[i - 1] = -selic_ruina; excesso_completo[i - 1] = -selic_ruina;
         double retorno_acao = m_preco[i] / preco_anterior - 1.0;
         excesso_bh_preco[i - 1] = retorno_acao - selic_ruina; excesso_bh_total[i - 1] = retorno_acao - selic_ruina;
         m_curva_pura[i] = m_curva_selic[i] = m_curva_completa[i] = 0.0;
         m_curva_referencia_selic[i] = m_curva_referencia_selic[i - 1] * (1.0 + selic_ruina);
         m_curva_bh_preco[i] = m_curva_bh_preco[i - 1] * (1.0 + retorno_acao);
         m_curva_bh_total[i] = m_curva_bh_total[i - 1] * (1.0 + retorno_acao);
         continue;
        }
      double selic    = SelicDoDia(m_data[i - 1]);
      double provento = ProventoNaData(m_data[i]);
      double exposicao = m_exposicao[i];
      double parado   = 1.0 - MathMin(1.0, MathAbs(exposicao));

      double retorno_camada1 = m_patrimonio[i] / patrimonio_anterior - 1.0;
      double retorno_camada2 = retorno_camada1 - custo[i - 1] / patrimonio_anterior;
      double retorno_camada3 = retorno_camada2 + parado * selic;
      double retorno_camada4 = retorno_camada3 + exposicao * provento / preco_anterior;
      double retorno_bh_preco = m_preco[i] / preco_anterior - 1.0;
      double retorno_bh_total = (m_preco[i] + provento) / preco_anterior - 1.0;

      fator_custos *= 1.0 + retorno_camada2;
      m_curva_pura[i]              = m_curva_pura[i - 1] * (1.0 + retorno_camada1);
      m_curva_selic[i]             = m_curva_selic[i - 1] * (1.0 + retorno_camada3);
      m_curva_completa[i]          = m_curva_completa[i - 1] * (1.0 + retorno_camada4);
      m_curva_referencia_selic[i]  = m_curva_referencia_selic[i - 1] * (1.0 + selic);
      m_curva_bh_preco[i]          = m_curva_bh_preco[i - 1] * (1.0 + retorno_bh_preco);
      m_curva_bh_total[i]          = m_curva_bh_total[i - 1] * (1.0 + retorno_bh_total);

      retorno_puro[i - 1] = retorno_camada1;
      excesso_selic[i - 1] = retorno_camada3 - selic; excesso_completo[i - 1] = retorno_camada4 - selic;
      excesso_bh_preco[i - 1] = retorno_bh_preco - selic; excesso_bh_total[i - 1] = retorno_bh_total - selic;
      soma_exposicao += MathMin(1.0, MathAbs(exposicao));
      soma_custo += custo[i - 1] / m_patrimonio[0];
     }

   int ultimo = n - 1;
   resultado.ret_puro     = m_curva_pura[ultimo] - 1.0;
   resultado.ret_custos   = fator_custos - 1.0;
   resultado.ret_selic    = m_curva_selic[ultimo] - 1.0;
   resultado.ret_completo = m_curva_completa[ultimo] - 1.0;
   resultado.selic        = m_curva_referencia_selic[ultimo] - 1.0;
   resultado.bh_preco     = m_curva_bh_preco[ultimo] - 1.0;
   resultado.bh_total     = m_curva_bh_total[ultimo] - 1.0;
   resultado.excesso          = resultado.ret_selic - resultado.selic;
   resultado.excesso_completo = resultado.ret_completo - resultado.selic;
   resultado.custo_total      = soma_custo;
   resultado.exposicao_media  = soma_exposicao / resultado.dias;

   //--- Perda acima de 100% (vendido) nao tem retorno anualizado
   double expoente = 1.0 / resultado.anos;
   if(resultado.ret_puro <= -1.0 || resultado.ret_selic <= -1.0) resultado.ruina = true;
   resultado.cagr_puro         = (resultado.ret_puro > -1.0) ? MathPow(1.0 + resultado.ret_puro, expoente) - 1.0 : -1.0;
   resultado.cagr_selic_camada = (resultado.ret_selic > -1.0) ? MathPow(1.0 + resultado.ret_selic, expoente) - 1.0 : -1.0;
   resultado.cagr_completo     = (resultado.ret_completo > -1.0) ? MathPow(1.0 + resultado.ret_completo, expoente) - 1.0 : -1.0;
   resultado.cagr_selic        = (resultado.selic > -1.0) ? MathPow(1.0 + resultado.selic, expoente) - 1.0 : -1.0;
   resultado.cagr_bh_preco     = (resultado.bh_preco > -1.0) ? MathPow(1.0 + resultado.bh_preco, expoente) - 1.0 : -1.0;
   resultado.cagr_bh_total     = (resultado.bh_total > -1.0) ? MathPow(1.0 + resultado.bh_total, expoente) - 1.0 : -1.0;

   //--- Queda maxima de cada curva
   double pico[5] = {1, 1, 1, 1, 1};
   for(int i = 1; i < n; i++)
     {
      pico[0] = MathMax(pico[0], m_curva_pura[i]);     resultado.dd_puro     = MathMax(resultado.dd_puro, 1 - m_curva_pura[i] / pico[0]);
      pico[1] = MathMax(pico[1], m_curva_selic[i]);    resultado.dd_selic    = MathMax(resultado.dd_selic, 1 - m_curva_selic[i] / pico[1]);
      pico[2] = MathMax(pico[2], m_curva_completa[i]); resultado.dd_completo = MathMax(resultado.dd_completo, 1 - m_curva_completa[i] / pico[2]);
      pico[3] = MathMax(pico[3], m_curva_bh_preco[i]); resultado.dd_bh_preco = MathMax(resultado.dd_bh_preco, 1 - m_curva_bh_preco[i] / pico[3]);
      pico[4] = MathMax(pico[4], m_curva_bh_total[i]); resultado.dd_bh_total = MathMax(resultado.dd_bh_total, 1 - m_curva_bh_total[i] / pico[4]);
     }

   //--- Volatilidade anualizada da camada pura
   double media = 0, variancia = 0;
   for(int i = 0; i < ultimo; i++) media += retorno_puro[i];
   media /= ultimo;
   for(int i = 0; i < ultimo; i++) variancia += (retorno_puro[i] - media) * (retorno_puro[i] - media);
   resultado.vol_puro = MathSqrt(variancia / (ultimo - 1) * 252.0);

   MedidasExcesso camada3;
   CalcularMedidasExcesso(excesso_selic, excesso_bh_preco, camada3);
   resultado.sharpe = camada3.sharpe; resultado.sharpe_t = camada3.sharpe_t;
   resultado.sharpe_p = camada3.sharpe_p; resultado.sharpe_bh = camada3.sharpe_referencia;
   resultado.sortino = camada3.sortino; resultado.sortino_bh = camada3.sortino_referencia;
   resultado.beta = camada3.beta; resultado.alfa = camada3.alfa; resultado.alfa_t = camada3.alfa_t;
   resultado.z_sharpe_bh = camada3.z_diferenca_sharpe; resultado.p_sharpe_bh = camada3.p_diferenca_sharpe;
   resultado.vol_selic = camada3.volatilidade; resultado.vol_bh_preco = camada3.volatilidade_referencia;
   resultado.calmar    = (resultado.dd_selic > 0) ? resultado.cagr_selic_camada / resultado.dd_selic : 0;
   resultado.calmar_bh = (resultado.dd_bh_preco > 0) ? resultado.cagr_bh_preco / resultado.dd_bh_preco : 0;

   MedidasExcesso camada4;
   CalcularMedidasExcesso(excesso_completo, excesso_bh_total, camada4);
   resultado.sharpe_completo = camada4.sharpe;
   resultado.sharpe_completo_p = camada4.sharpe_p;
   resultado.sharpe_bh_total = camada4.sharpe_referencia;
   return(true);
  }

void CDesempenho::Imprimir(const ResultadoDesempenho &r) const
  {
   PrintFormat("DESEMPENHO %s a %s (%.2f anos) | negocios=%d acerto=%.1f%% FL=%.2f exposicao=%.1f%%",
               TimeToString(r.inicio, TIME_DATE), TimeToString(r.fim, TIME_DATE), r.anos,
               r.negocios, r.taxa_acerto * 100, r.fator_lucro, r.exposicao_media * 100);
   PrintFormat("  camadas: 1) puro %+.2f%% | 2) +custos %+.2f%% | 3) +Selic %+.2f%% | 4) +proventos %+.2f%%",
               r.ret_puro * 100, r.ret_custos * 100, r.ret_selic * 100, r.ret_completo * 100);
   PrintFormat("  referencias: Selic %+.2f%% | B&H so preco %+.2f%% | B&H c/ proventos %+.2f%%",
               r.selic * 100, r.bh_preco * 100, r.bh_total * 100);
   PrintFormat("  camada 3: Sharpe %.3f (t=%.2f p=%.3f) | B&H %.3f | Sortino %.2f | Calmar %.2f | DD %.1f%% (puro %.1f%%, B&H %.1f%%)",
               r.sharpe, r.sharpe_t, r.sharpe_p, r.sharpe_bh, r.sortino, r.calmar,
               r.dd_selic * 100, r.dd_puro * 100, r.dd_bh_preco * 100);
   PrintFormat("  camada 4: Sharpe %.3f (p=%.3f) | B&H c/ proventos %.3f",
               r.sharpe_completo, r.sharpe_completo_p, r.sharpe_bh_total);
  }

string CDesempenho::Cabecalho(void)
  {
   return("inicio;fim;anos;negocios;saidas;taxa_acerto;fator_lucro;custo_total;exposicao;"
          "ret_puro;ret_custos;ret_selic;ret_completo;selic;bh_preco;bh_total;"
          "cagr_puro;cagr_selic_camada;cagr_completo;cagr_selic;cagr_bh_preco;cagr_bh_total;"
          "excesso;excesso_completo;dd_puro;dd_selic;dd_completo;dd_bh_preco;dd_bh_total;"
          "vol_puro;vol_selic;vol_bh_preco;sharpe;sharpe_t;sharpe_p;sharpe_bh;sortino;sortino_bh;"
          "calmar;calmar_bh;beta;alfa;alfa_t;z_sharpe_bh;p_sharpe_bh;"
          "sharpe_completo;sharpe_completo_p;sharpe_bh_total;ruina");
  }

string CDesempenho::Linha(const ResultadoDesempenho &r)
  {
   string linha = StringFormat("%s;%s;%.3f;%d;%d;%.4f;%.4f;%.6f;%.4f;",
                               TimeToString(r.inicio, TIME_DATE), TimeToString(r.fim, TIME_DATE), r.anos,
                               r.negocios, r.saidas, r.taxa_acerto, r.fator_lucro, r.custo_total,
                               r.exposicao_media);
   linha += StringFormat("%.6f;%.6f;%.6f;%.6f;%.6f;%.6f;%.6f;",
                         r.ret_puro, r.ret_custos, r.ret_selic, r.ret_completo, r.selic, r.bh_preco, r.bh_total);
   linha += StringFormat("%.6f;%.6f;%.6f;%.6f;%.6f;%.6f;",
                         r.cagr_puro, r.cagr_selic_camada, r.cagr_completo, r.cagr_selic,
                         r.cagr_bh_preco, r.cagr_bh_total);
   linha += StringFormat("%.6f;%.6f;%.6f;%.6f;%.6f;%.6f;%.6f;",
                         r.excesso, r.excesso_completo, r.dd_puro, r.dd_selic, r.dd_completo,
                         r.dd_bh_preco, r.dd_bh_total);
   linha += StringFormat("%.6f;%.6f;%.6f;%.4f;%.4f;%.4f;%.4f;%.4f;%.4f;",
                         r.vol_puro, r.vol_selic, r.vol_bh_preco, r.sharpe, r.sharpe_t, r.sharpe_p,
                         r.sharpe_bh, r.sortino, r.sortino_bh);
   linha += StringFormat("%.4f;%.4f;%.4f;%.6f;%.4f;%.4f;%.4f;%.4f;%.4f;%.4f;%d",
                         r.calmar, r.calmar_bh, r.beta, r.alfa, r.alfa_t, r.z_sharpe_bh, r.p_sharpe_bh,
                         r.sharpe_completo, r.sharpe_completo_p, r.sharpe_bh_total, (int)r.ruina);
   return(linha);
  }

//--- Curva diaria (base 1). As colunas estrategia (camada 3) e selic sao as que CompararCurvas le.
bool CDesempenho::GravarCurva(const string arquivo) const
  {
   if(ArraySize(m_curva_selic) != m_registros)
      return(false);
   int arquivo_aberto = FileOpen(arquivo, FILE_WRITE | FILE_TXT | FILE_ANSI | FILE_COMMON);
   if(arquivo_aberto == INVALID_HANDLE)
      return(false);
   FileWriteString(arquivo_aberto, "data,estrategia,selic,puro,completo,buyhold,buyhold_total,exposicao,dd,dd_puro,dd_bh\n");
   double pico_selic = 1, pico_puro = 1, pico_bh = 1;
   for(int i = 0; i < m_registros; i++)
     {
      string data = TimeToString(m_data[i], TIME_DATE);
      StringReplace(data, ".", "-");   // formato de data do pgfplots
      pico_selic = MathMax(pico_selic, m_curva_selic[i]);
      pico_puro = MathMax(pico_puro, m_curva_pura[i]);
      pico_bh = MathMax(pico_bh, m_curva_bh_preco[i]);
      FileWriteString(arquivo_aberto, StringFormat("%s,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.4f,%.6f,%.6f,%.6f\n",
                      data, m_curva_selic[i], m_curva_referencia_selic[i], m_curva_pura[i], m_curva_completa[i],
                      m_curva_bh_preco[i], m_curva_bh_total[i], m_exposicao[i],
                      1 - m_curva_selic[i] / pico_selic, 1 - m_curva_pura[i] / pico_puro, 1 - m_curva_bh_preco[i] / pico_bh));
     }
   FileClose(arquivo_aberto);
   return(true);
  }

void CDesempenho::Gravar(const string rotulo, const string cabecalho_modelo,
                         const string valores_modelo, const ResultadoDesempenho &resultado) const
  {
   string cabecalho = cabecalho_modelo + ";" + Cabecalho();
   string linha = valores_modelo + ";" + Linha(resultado);
   string nome;

   bool otimizando = (bool)MQLInfoInteger(MQL_OPTIMIZATION);
   if(!otimizando && StringLen(rotulo) > 0)
     {
      nome = "AlgoLab\\metricas_" + rotulo + ".csv";
      GravarCurva("AlgoLab\\curva_" + rotulo + ".csv");
     }
   else
     {
      //--- Agentes em paralelo: nome derivado do conteudo e do relogio (hash djb2)
      string identidade = StringFormat("%s|%s|%I64u|%u", TerminalInfoString(TERMINAL_DATA_PATH),
                                       linha, GetMicrosecondCount(), GetTickCount());
      uint hash = 5381;
      for(int i = 0; i < StringLen(identidade); i++)
         hash = hash * 33 + (uint)StringGetCharacter(identidade, i);
      nome = StringFormat("AlgoLab\\res_%08x_%I64u.csv", hash, GetMicrosecondCount());
     }

   int arquivo_aberto = FileOpen(nome, FILE_WRITE | FILE_TXT | FILE_ANSI | FILE_COMMON);
   if(arquivo_aberto != INVALID_HANDLE)
     {
      FileWriteString(arquivo_aberto, cabecalho + "\n" + linha + "\n");
      FileClose(arquivo_aberto);
     }
  }

//--- Dois modelos no mesmo periodo, a partir das curvas gravadas (mesmos dias):
//--- diferenca de Sharpe (Memmel), diferenca media diaria (t pareado) e volatilidade
//--- (Pitman-Morgan: correlacao entre a soma e a diferenca dos retornos; r < 0, A oscilou menos).
struct ComparacaoModelos
  {
   int      n;
   double   sharpe_a, sharpe_b;
   double   rho;                  // correlacao dos excessos diarios
   double   z_sharpe, p_sharpe;   // p bilateral
   double   dif_anual;            // media(r_a - r_b) x 252
   double   t_dif, p_dif;
   double   vol_a, vol_b;
   double   r_pm, t_pm, p_pm;
  };

bool LerCurva(const string arquivo, string &datas[], double &retorno[], double &selic[])
  {
   int arquivo_aberto = FileOpen(arquivo, FILE_READ | FILE_TXT | FILE_ANSI | FILE_COMMON);
   if(arquivo_aberto == INVALID_HANDLE)
      return(false);

   FileReadString(arquivo_aberto);   // cabecalho
   double anterior = 0.0, anterior_selic = 0.0;
   int linhas = 0;
   while(!FileIsEnding(arquivo_aberto))
     {
      string campos[];
      if(StringSplit(FileReadString(arquivo_aberto), ',', campos) < 3)
         continue;
      double valor = StringToDouble(campos[1]), valor_selic = StringToDouble(campos[2]);
      if(linhas > 0)
        {
         int m = ArraySize(retorno);
         ArrayResize(retorno, m + 1, 2048); ArrayResize(selic, m + 1, 2048); ArrayResize(datas, m + 1, 2048);
         retorno[m] = valor / anterior - 1.0;
         selic[m] = valor_selic / anterior_selic - 1.0;
         datas[m] = campos[0];
        }
      anterior = valor; anterior_selic = valor_selic; linhas++;
     }
   FileClose(arquivo_aberto);
   return(ArraySize(retorno) > 2);
  }

bool CompararCurvas(const string arquivo_a, const string arquivo_b, ComparacaoModelos &c)
  {
   ZeroMemory(c);
   string datas_a[], datas_b[];
   double retorno_a[], selic_a[], retorno_b[], selic_b[];
   if(!LerCurva(arquivo_a, datas_a, retorno_a, selic_a) || !LerCurva(arquivo_b, datas_b, retorno_b, selic_b))
      return(false);
   if(ArraySize(retorno_a) != ArraySize(retorno_b) || datas_a[0] != datas_b[0])
      return(false);   // periodos diferentes

   int n = ArraySize(retorno_a);
   double media_a = 0, media_b = 0, media_dif = 0;
   for(int i = 0; i < n; i++)
     {
      media_a += retorno_a[i] - selic_a[i]; media_b += retorno_b[i] - selic_a[i]; media_dif += retorno_a[i] - retorno_b[i];
     }
   media_a /= n; media_b /= n; media_dif /= n;

   double variancia_a = 0, variancia_b = 0, covariancia = 0, variancia_dif = 0;
   for(int i = 0; i < n; i++)
     {
      double desvio_a = retorno_a[i] - selic_a[i] - media_a, desvio_b = retorno_b[i] - selic_a[i] - media_b;
      double desvio_dif = retorno_a[i] - retorno_b[i] - media_dif;
      variancia_a += desvio_a * desvio_a; variancia_b += desvio_b * desvio_b;
      covariancia += desvio_a * desvio_b; variancia_dif += desvio_dif * desvio_dif;
     }
   variancia_a /= n - 1; variancia_b /= n - 1; covariancia /= n - 1; variancia_dif /= n - 1;
   if(variancia_a <= 0.0 || variancia_b <= 0.0)
      return(false);

   double sharpe_diario_a = media_a / MathSqrt(variancia_a), sharpe_diario_b = media_b / MathSqrt(variancia_b);
   c.n = n;
   c.sharpe_a = sharpe_diario_a * MathSqrt(252.0);
   c.sharpe_b = sharpe_diario_b * MathSqrt(252.0);
   c.rho = covariancia / MathSqrt(variancia_a * variancia_b);

   int erro = 0;
   double theta = 2.0 - 2.0 * c.rho + 0.5 * (sharpe_diario_a * sharpe_diario_a + sharpe_diario_b * sharpe_diario_b
                  - 2.0 * sharpe_diario_a * sharpe_diario_b * c.rho * c.rho);
   if(theta > 0.0)
     {
      c.z_sharpe = (sharpe_diario_a - sharpe_diario_b) / MathSqrt(theta / n);
      c.p_sharpe = 2.0 * (1.0 - MathCumulativeDistributionNormal(MathAbs(c.z_sharpe), 0.0, 1.0, erro));
     }

   c.dif_anual = media_dif * 252.0;
   if(variancia_dif > 0.0)
     {
      c.t_dif = media_dif / MathSqrt(variancia_dif / n);
      c.p_dif = 2.0 * (1.0 - MathCumulativeDistributionNormal(MathAbs(c.t_dif), 0.0, 1.0, erro));
     }

   //--- Volatilidade e Pitman-Morgan sobre os retornos diarios brutos
   double media_bruta_a = 0, media_bruta_b = 0;
   for(int i = 0; i < n; i++) { media_bruta_a += retorno_a[i]; media_bruta_b += retorno_b[i]; }
   media_bruta_a /= n; media_bruta_b /= n;
   double soma_a2 = 0, soma_b2 = 0, soma_uu = 0, soma_vv = 0, soma_uv = 0;
   for(int i = 0; i < n; i++)
     {
      double xa = retorno_a[i] - media_bruta_a, xb = retorno_b[i] - media_bruta_b;
      double soma_ab = xa + xb, diferenca_ab = xa - xb;
      soma_a2 += xa * xa; soma_b2 += xb * xb;
      soma_uu += soma_ab * soma_ab; soma_vv += diferenca_ab * diferenca_ab; soma_uv += soma_ab * diferenca_ab;
     }
   c.vol_a = MathSqrt(soma_a2 / (n - 1)) * MathSqrt(252.0);
   c.vol_b = MathSqrt(soma_b2 / (n - 1)) * MathSqrt(252.0);
   if(soma_uu > 0.0 && soma_vv > 0.0)
     {
      c.r_pm = soma_uv / MathSqrt(soma_uu * soma_vv);
      if(MathAbs(c.r_pm) < 1.0)
        {
         c.t_pm = c.r_pm * MathSqrt(n - 2.0) / MathSqrt(1.0 - c.r_pm * c.r_pm);
         c.p_pm = 2.0 * (1.0 - MathCumulativeDistributionNormal(MathAbs(c.t_pm), 0.0, 1.0, erro));
        }
     }
   return(true);
  }

#endif
