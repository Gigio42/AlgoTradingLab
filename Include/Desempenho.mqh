//+------------------------------------------------------------------+
//|                                                  Desempenho.mqh  |
//|                            Trabalho de Graduacao - FATEC Indaiatuba|
//+------------------------------------------------------------------+
//|                                                                  |
//|  AVALIACAO EM CAMADAS                                            |
//|                                                                  |
//|  O Strategy Tester mede so a variacao do patrimonio. Este modulo |
//|  monta, a partir de UM registro por barra, quatro curvas:        |
//|                                                                  |
//|    1) PURA           variacao do patrimonio no testador: so o    |
//|                      ganho/perda das posicoes. Caixa rende zero. |
//|    2) + CUSTOS       desconta 'custo' x valor de cada execucao   |
//|                      (emolumentos + liquidacao B3 ~ 0,03%/lado)  |
//|    3) + SELIC        a fracao do patrimonio fora da acao rende a |
//|                      Selic do dia (serie 11 do SGS/BCB)          |
//|    4) + PROVENTOS    quem estava comprado na data-ex recebe o    |
//|       (completa)     provento por acao; vendido paga             |
//|                                                                  |
//|  A camada 3 (sem proventos) usa so dados oficiais (B3 e BCB) e e |
//|  a base do criterio de otimizacao e das comparacoes. A camada 4  |
//|  e um ADENDO: a lista de proventos vem de fonte nao oficial (ver |
//|  dados/FONTES.md e INCERTEZAS.md).                               |
//|                                                                  |
//|  O modelo nunca ve custos, Selic ou proventos: eles so entram na |
//|  contabilidade. O preco que o modelo ve e o preco de tela.       |
//|                                                                  |
//|  REFERENCIAS no mesmo periodo: Selic acumulada; buy-and-hold so  |
//|  preco; buy-and-hold com proventos reinvestidos.                 |
//|                                                                  |
//|  METRICAS DE RISCO sobre o excesso diario sobre a Selic          |
//|  (e_t = r_t - s_t), calculadas nas camadas 3 e 4:                |
//|     Sharpe   = media(e) / desvio(e) x raiz(252). Selic = ativo   |
//|                livre de risco: Sharpe > 0 = rendeu mais que a    |
//|                Selic por unidade de risco. A Selic tem Sharpe 0. |
//|     t, p     = teste de Sharpe > 0 (erro-padrao de Lo, 2002)     |
//|     Sortino  = so penaliza os dias abaixo da Selic               |
//|     Calmar   = retorno anualizado / drawdown maximo              |
//|     alfa/beta= regressao e = alfa + beta x e_bh                  |
//|     z_SR     = Sharpe estrategia - Sharpe buy-and-hold           |
//|                (Jobson-Korkie com correcao de Memmel, 2003)      |
//|                                                                  |
//|  O registro e feito na abertura da barra ANTES de qualquer ordem:|
//|  a exposicao anotada em t e a posicao carregada entre t-1 e t.   |
//|                                                                  |
//+------------------------------------------------------------------+
#ifndef ALGOTRADINGLAB_DESEMPENHO_MQH
#define ALGOTRADINGLAB_DESEMPENHO_MQH

#include <Math\Stat\Normal.mqh>

//+------------------------------------------------------------------+
//| Metricas do periodo testado (retornos em fracao: 0.10 = 10%)     |
//+------------------------------------------------------------------+
struct ResultadoDesempenho
  {
   datetime inicio;
   datetime fim;
   int      dias;
   double   anos;
   //--- operacoes
   int      negocios;          // entradas executadas
   int      saidas;            // saidas com resultado
   double   taxa_acerto;       // saidas com lucro (apos custos) / saidas
   double   fator_lucro;       // lucro bruto / prejuizo bruto (apos custos)
   double   custo_total;       // custos B3 em fracao do capital inicial
   double   exposicao_media;   // fracao media do capital posicionada
   //--- retorno por camada
   double   ret_puro;          // 1) so as posicoes
   double   ret_custos;        // 2) + custos
   double   ret_selic;         // 3) + caixa na Selic (sem proventos)
   double   ret_completo;      // 4) + proventos
   double   selic;             // Selic acumulada
   double   bh_preco;          // buy-and-hold so preco
   double   bh_total;          // buy-and-hold com proventos
   double   cagr_puro, cagr_selic_camada, cagr_completo;
   double   cagr_selic, cagr_bh_preco, cagr_bh_total;
   double   excesso;           // ret_selic - selic (criterio da otimizacao)
   double   excesso_completo;  // ret_completo - selic
   //--- risco
   double   dd_puro, dd_selic, dd_completo, dd_bh_preco, dd_bh_total;
   double   vol_puro, vol_selic, vol_bh_preco;
   //--- risco x retorno, camada 3 (oficial) e comparacao com bh so preco
   double   sharpe, sharpe_t, sharpe_p, sharpe_bh;
   double   sortino, sortino_bh, calmar, calmar_bh;
   double   beta, alfa, alfa_t, z_sharpe_bh, p_sharpe_bh;
   //--- camada 4 (adendo) e bh com proventos
   double   sharpe_completo, sharpe_completo_p, sharpe_bh_total;
   bool     ruina;             // patrimonio chegou a zero ou ficou negativo
  };

//+------------------------------------------------------------------+
//| Momentos de duas series de excesso: Sharpe, Lo, Memmel, regressao|
//+------------------------------------------------------------------+
struct EstatExcesso
  {
   double sr, t, p, srb, sortino, sortino_b, beta, alfa, alfa_t, z, pz, vol, volb;
  };

void CalcularEstatExcesso(const double &e[], const double &eb[], EstatExcesso &o)
  {
   ZeroMemory(o);
   int n = ArraySize(e);
   if(n < 3) return;
   double me = 0, mb = 0;
   for(int i = 0; i < n; i++) { me += e[i]; mb += eb[i]; }
   me /= n; mb /= n;
   double ve = 0, vb = 0, cov = 0, neg = 0, negb = 0;
   for(int i = 0; i < n; i++)
     {
      ve += (e[i] - me) * (e[i] - me); vb += (eb[i] - mb) * (eb[i] - mb);
      cov += (e[i] - me) * (eb[i] - mb);
      if(e[i] < 0.0) neg += e[i] * e[i];
      if(eb[i] < 0.0) negb += eb[i] * eb[i];
     }
   ve /= n - 1; vb /= n - 1; cov /= n - 1;
   double de = MathSqrt(ve), db = MathSqrt(vb), r252 = MathSqrt(252.0);
   int erro = 0;
   o.vol = de * r252; o.volb = db * r252;
   double sr = (de > 0) ? me / de : 0, srb = (db > 0) ? mb / db : 0;
   o.sr = sr * r252; o.srb = srb * r252;
   double ep = MathSqrt((1.0 + 0.5 * sr * sr) / n);
   o.t = (ep > 0) ? sr / ep : 0;
   o.p = 1.0 - MathCumulativeDistributionNormal(o.t, 0.0, 1.0, erro);
   double dn = MathSqrt(neg / n), dnb = MathSqrt(negb / n);
   o.sortino = (dn > 0) ? me / dn * r252 : 0;
   o.sortino_b = (dnb > 0) ? mb / dnb * r252 : 0;
   if(vb > 0)
     {
      o.beta = cov / vb;
      double a = me - o.beta * mb, sres = 0;
      for(int i = 0; i < n; i++)
        { double u = e[i] - a - o.beta * eb[i]; sres += u * u; }
      double ep_a = MathSqrt(sres / (n - 2.0) * (1.0 / n + mb * mb / ((n - 1.0) * vb)));
      o.alfa = a * 252.0;
      o.alfa_t = (ep_a > 0) ? a / ep_a : 0;
     }
   if(de > 0 && db > 0)
     {
      double rho = cov / (de * db);
      double th = 2.0 - 2.0 * rho + 0.5 * (sr * sr + srb * srb - 2.0 * sr * srb * rho * rho);
      if(th > 0)
        {
         o.z = (sr - srb) / MathSqrt(th / n);
         o.pz = 2.0 * (1.0 - MathCumulativeDistributionNormal(MathAbs(o.z), 0.0, 1.0, erro));
        }
     }
  }

//+------------------------------------------------------------------+
//| Registro por barra e calculo das metricas                        |
//+------------------------------------------------------------------+
class CDesempenho
  {
private:
   datetime m_t[];
   double   m_patrimonio[];
   double   m_exposicao[];     // COM SINAL: + comprado, - vendido
   double   m_preco[];
   int      m_n;

   datetime m_selic_t[];
   double   m_selic_dia[];
   int      m_ns;

   datetime m_prov_t[];        // data-ex (primeiro pregao sem direito)
   double   m_prov_v[];        // R$ por acao
   int      m_np;

   double   m_custo;
   ulong    m_magic;
   string   m_simbolo;

   //--- curvas diarias (base 1), preenchidas por Calcular()
   double   m_c_puro[], m_c_selic[], m_c_completo[], m_c_ref[], m_c_bh_preco[], m_c_bh_total[];

   double   SelicDoDia(const datetime t) const;
   double   ProventoNaData(const datetime t) const;
   double   Exposicao(const double preco) const;
   bool     LerSerie(const string arquivo, datetime &t[], double &v[], const double escala);

public:
                     CDesempenho(void) : m_n(0), m_ns(0), m_np(0), m_custo(0.0003), m_magic(0) {}

   void     Definir(const string simbolo, const ulong magic, const double custo)
     { m_simbolo = simbolo; m_magic = magic; m_custo = MathMax(0.0, custo); }

   //--- "AAAA.MM.DD,taxa" com a taxa diaria em PERCENTUAL (SGS 11/BCB)
   bool     CarregarSelic(const string arquivo)
     { m_ns = LerSerie(arquivo, m_selic_t, m_selic_dia, 0.01) ? ArraySize(m_selic_t) : 0; return(m_ns > 0); }
   //--- "AAAA.MM.DD,valor" com a data-ex e o provento em R$ por acao
   bool     CarregarProventos(const string arquivo)
     { m_np = LerSerie(arquivo, m_prov_t, m_prov_v, 1.0) ? ArraySize(m_prov_t) : 0; return(m_np > 0); }

   void     RegistrarAgora(const datetime t);
   bool     Calcular(ResultadoDesempenho &r);
   void     Imprimir(const ResultadoDesempenho &r) const;
   static string Cabecalho(void);
   static string Linha(const ResultadoDesempenho &r);
   bool     GravarCurva(const string arquivo) const;
   void     Gravar(const string rotulo, const string cab_modelo,
                   const string val_modelo, const ResultadoDesempenho &r) const;
  };

//+------------------------------------------------------------------+
bool CDesempenho::LerSerie(const string arquivo, datetime &t[], double &v[], const double escala)
  {
   //--- Linha a linha ("data,valor"); linhas iniciadas por '#' sao
   //--- comentario (procedencia do arquivo)
   ArrayResize(t, 0, 8192);
   ArrayResize(v, 0, 8192);
   int fh = FileOpen(arquivo, FILE_READ | FILE_TXT | FILE_ANSI);
   if(fh == INVALID_HANDLE)
      return(false);
   while(!FileIsEnding(fh))
     {
      string linha = FileReadString(fh);
      if(StringLen(linha) < 12 || StringGetCharacter(linha, 0) == '#')
         continue;
      string campos[];
      if(StringSplit(linha, ',', campos) < 2)
         continue;
      int k = ArraySize(t);
      ArrayResize(t, k + 1, 8192);
      ArrayResize(v, k + 1, 8192);
      t[k] = StringToTime(campos[0]);
      v[k] = StringToDouble(campos[1]) * escala;
     }
   FileClose(fh);
   return(ArraySize(t) > 0);
  }

//+------------------------------------------------------------------+
double CDesempenho::SelicDoDia(const datetime t) const
  {
   if(m_ns == 0 || t < m_selic_t[0])
      return(0.0);
   int lo = 0, hi = m_ns - 1;
   while(lo < hi)
     {
      int mid = (lo + hi + 1) / 2;
      if(m_selic_t[mid] <= t) lo = mid; else hi = mid - 1;
     }
   return(m_selic_dia[lo]);
  }

//+------------------------------------------------------------------+
//| Soma dos proventos com data-ex no MESMO dia de t                 |
//+------------------------------------------------------------------+
double CDesempenho::ProventoNaData(const datetime t) const
  {
   datetime dia = t - t % 86400;
   double s = 0.0;
   for(int i = 0; i < m_np; i++)
      if(m_prov_t[i] - m_prov_t[i] % 86400 == dia)
         s += m_prov_v[i];
   return(s);
  }

//+------------------------------------------------------------------+
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
         (ulong)PositionGetInteger(POSITION_MAGIC) == m_magic)
        {
         double v = PositionGetDouble(POSITION_VOLUME);
         volume += (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? v : -v;
        }
     }
   return(volume * preco * contrato / patrimonio);
  }

//+------------------------------------------------------------------+
void CDesempenho::RegistrarAgora(const datetime t)
  {
   MqlTick tick;
   if(!SymbolInfoTick(m_simbolo, tick) || tick.bid <= 0.0)
      return;
   if(m_n > 0 && t <= m_t[m_n - 1])
      return;
   ArrayResize(m_t, m_n + 1, 1024);
   ArrayResize(m_patrimonio, m_n + 1, 1024);
   ArrayResize(m_exposicao, m_n + 1, 1024);
   ArrayResize(m_preco, m_n + 1, 1024);
   m_t[m_n]          = t;
   m_patrimonio[m_n] = AccountInfoDouble(ACCOUNT_EQUITY);
   m_exposicao[m_n]  = Exposicao(tick.bid);
   m_preco[m_n]      = tick.bid;
   m_n++;
  }

//+------------------------------------------------------------------+
bool CDesempenho::Calcular(ResultadoDesempenho &r)
  {
   ZeroMemory(r);
   if(m_n < 3)
      return(false);

   r.inicio = m_t[0];
   r.fim    = m_t[m_n - 1];
   r.dias   = m_n - 1;
   r.anos   = r.dias / 252.0;

   //--- ── Negocios: custo por intervalo, acerto, fator de lucro ──
   double custo[];
   ArrayResize(custo, m_n);
   ArrayInitialize(custo, 0.0);
   double ganho = 0.0, perda = 0.0;
   int acertos = 0;

   if(HistorySelect(0, TimeCurrent() + 1))
     {
      int total = HistoryDealsTotal();
      for(int i = 0; i < total; i++)
        {
         ulong tk = HistoryDealGetTicket(i);
         if(tk == 0) continue;
         if(HistoryDealGetString(tk, DEAL_SYMBOL) != m_simbolo ||
            (ulong)HistoryDealGetInteger(tk, DEAL_MAGIC) != m_magic)
            continue;
         double valor = HistoryDealGetDouble(tk, DEAL_VOLUME) *
                        HistoryDealGetDouble(tk, DEAL_PRICE) *
                        SymbolInfoDouble(m_simbolo, SYMBOL_TRADE_CONTRACT_SIZE);
         if(HistoryDealGetInteger(tk, DEAL_ENTRY) == DEAL_ENTRY_IN)
            r.negocios++;
         else
           {
            double res = HistoryDealGetDouble(tk, DEAL_PROFIT) - 2.0 * valor * m_custo;
            r.saidas++;
            if(res > 0.0) { acertos++; ganho += res; }
            else          perda -= res;
           }
         datetime td = (datetime)HistoryDealGetInteger(tk, DEAL_TIME);
         int k = 0;
         for(int j = m_n - 1; j >= 0; j--)
            if(m_t[j] <= td) { k = j; break; }
         custo[k] += valor * m_custo;
        }
     }
   r.taxa_acerto = (r.saidas > 0) ? (double)acertos / r.saidas : 0.0;
   r.fator_lucro = (perda > 0.0) ? ganho / perda : 0.0;

   //--- ── Curvas por camada ──
   ArrayResize(m_c_puro, m_n); ArrayResize(m_c_selic, m_n); ArrayResize(m_c_completo, m_n);
   ArrayResize(m_c_ref, m_n); ArrayResize(m_c_bh_preco, m_n); ArrayResize(m_c_bh_total, m_n);
   m_c_puro[0] = m_c_selic[0] = m_c_completo[0] = m_c_ref[0] = m_c_bh_preco[0] = m_c_bh_total[0] = 1.0;

   double f_custos = 1.0;
   double e3[], e4[], eb[], ebt[], rp[];
   ArrayResize(e3, m_n - 1); ArrayResize(e4, m_n - 1); ArrayResize(eb, m_n - 1);
   ArrayResize(ebt, m_n - 1); ArrayResize(rp, m_n - 1);
   double soma_expo = 0.0, soma_custo = 0.0;

   for(int i = 1; i < m_n; i++)
     {
      double e0 = m_patrimonio[i - 1], p0 = m_preco[i - 1];
      if(p0 <= 0.0)
         return(false);
      //--- Conta zerada (chamada de margem): marca ruina e segue com a
      //--- curva parada em zero, para os vetores continuarem do mesmo
      //--- tamanho e as metricas cobrirem o periodo inteiro.
      if(e0 <= 0.0 || r.ruina)
        {
         r.ruina = true;
         rp[i - 1] = 0.0;
         double s0 = SelicDoDia(m_t[i - 1]);
         e3[i - 1] = -s0; e4[i - 1] = -s0;
         double rb0 = m_preco[i] / p0 - 1.0;
         eb[i - 1] = rb0 - s0; ebt[i - 1] = rb0 - s0;
         m_c_puro[i] = m_c_selic[i] = m_c_completo[i] = 0.0;
         m_c_ref[i] = m_c_ref[i - 1] * (1.0 + s0);
         m_c_bh_preco[i] = m_c_bh_preco[i - 1] * (1.0 + rb0);
         m_c_bh_total[i] = m_c_bh_total[i - 1] * (1.0 + rb0);
         continue;
        }
      double s     = SelicDoDia(m_t[i - 1]);
      double prov  = ProventoNaData(m_t[i]);
      double expo  = m_exposicao[i];
      double parado = 1.0 - MathMin(1.0, MathAbs(expo));

      double r1 = m_patrimonio[i] / e0 - 1.0;          // puro
      double r2 = r1 - custo[i - 1] / e0;               // + custos
      double r3 = r2 + parado * s;                      // + Selic
      double r4 = r3 + expo * prov / p0;                // + proventos
      double rb = m_preco[i] / p0 - 1.0;
      double rbt = (m_preco[i] + prov) / p0 - 1.0;

      f_custos *= 1.0 + r2;
      m_c_puro[i]     = m_c_puro[i - 1] * (1.0 + r1);
      m_c_selic[i]    = m_c_selic[i - 1] * (1.0 + r3);
      m_c_completo[i] = m_c_completo[i - 1] * (1.0 + r4);
      m_c_ref[i]      = m_c_ref[i - 1] * (1.0 + s);
      m_c_bh_preco[i] = m_c_bh_preco[i - 1] * (1.0 + rb);
      m_c_bh_total[i] = m_c_bh_total[i - 1] * (1.0 + rbt);

      rp[i - 1] = r1;
      e3[i - 1] = r3 - s; e4[i - 1] = r4 - s;
      eb[i - 1] = rb - s; ebt[i - 1] = rbt - s;
      soma_expo += MathMin(1.0, MathAbs(expo));
      soma_custo += custo[i - 1] / m_patrimonio[0];
     }

   int u = m_n - 1;
   r.ret_puro     = m_c_puro[u] - 1.0;
   r.ret_custos   = f_custos - 1.0;
   r.ret_selic    = m_c_selic[u] - 1.0;
   r.ret_completo = m_c_completo[u] - 1.0;
   r.selic        = m_c_ref[u] - 1.0;
   r.bh_preco     = m_c_bh_preco[u] - 1.0;
   r.bh_total     = m_c_bh_total[u] - 1.0;
   r.excesso          = r.ret_selic - r.selic;
   r.excesso_completo = r.ret_completo - r.selic;
   r.custo_total      = soma_custo;
   r.exposicao_media  = soma_expo / r.dias;

   //--- MathPow com base negativa devolve NaN: com perda de mais de 100%
   //--- (posicao vendida) o retorno anualizado nao e definido.
   double k = 1.0 / r.anos;
   if(r.ret_puro <= -1.0 || r.ret_selic <= -1.0) r.ruina = true;
   r.cagr_puro = (r.ret_puro > -1.0) ? MathPow(1.0 + r.ret_puro, k) - 1.0 : -1.0;
   r.cagr_selic_camada = (r.ret_selic > -1.0) ? MathPow(1.0 + r.ret_selic, k) - 1.0 : -1.0;
   r.cagr_completo = (r.ret_completo > -1.0) ? MathPow(1.0 + r.ret_completo, k) - 1.0 : -1.0;
   r.cagr_selic = (r.selic > -1.0) ? MathPow(1.0 + r.selic, k) - 1.0 : -1.0;
   r.cagr_bh_preco = (r.bh_preco > -1.0) ? MathPow(1.0 + r.bh_preco, k) - 1.0 : -1.0;
   r.cagr_bh_total = (r.bh_total > -1.0) ? MathPow(1.0 + r.bh_total, k) - 1.0 : -1.0;

   //--- drawdowns
   double pk[5] = {1, 1, 1, 1, 1};
   for(int i = 1; i < m_n; i++)
     {
      pk[0] = MathMax(pk[0], m_c_puro[i]);     r.dd_puro     = MathMax(r.dd_puro, 1 - m_c_puro[i] / pk[0]);
      pk[1] = MathMax(pk[1], m_c_selic[i]);    r.dd_selic    = MathMax(r.dd_selic, 1 - m_c_selic[i] / pk[1]);
      pk[2] = MathMax(pk[2], m_c_completo[i]); r.dd_completo = MathMax(r.dd_completo, 1 - m_c_completo[i] / pk[2]);
      pk[3] = MathMax(pk[3], m_c_bh_preco[i]); r.dd_bh_preco = MathMax(r.dd_bh_preco, 1 - m_c_bh_preco[i] / pk[3]);
      pk[4] = MathMax(pk[4], m_c_bh_total[i]); r.dd_bh_total = MathMax(r.dd_bh_total, 1 - m_c_bh_total[i] / pk[4]);
     }

   //--- volatilidade da camada pura
   double m = 0, v = 0;
   for(int i = 0; i < u; i++) m += rp[i];
   m /= u;
   for(int i = 0; i < u; i++) v += (rp[i] - m) * (rp[i] - m);
   r.vol_puro = MathSqrt(v / (u - 1) * 252.0);

   //--- camada 3 (oficial) contra bh so preco
   EstatExcesso o;
   CalcularEstatExcesso(e3, eb, o);
   r.sharpe = o.sr; r.sharpe_t = o.t; r.sharpe_p = o.p; r.sharpe_bh = o.srb;
   r.sortino = o.sortino; r.sortino_bh = o.sortino_b;
   r.beta = o.beta; r.alfa = o.alfa; r.alfa_t = o.alfa_t;
   r.z_sharpe_bh = o.z; r.p_sharpe_bh = o.pz;
   r.vol_selic = o.vol; r.vol_bh_preco = o.volb;
   r.calmar    = (r.dd_selic > 0) ? r.cagr_selic_camada / r.dd_selic : 0;
   r.calmar_bh = (r.dd_bh_preco > 0) ? r.cagr_bh_preco / r.dd_bh_preco : 0;

   //--- camada 4 (adendo) contra bh com proventos
   EstatExcesso o4;
   CalcularEstatExcesso(e4, ebt, o4);
   r.sharpe_completo = o4.sr; r.sharpe_completo_p = o4.p; r.sharpe_bh_total = o4.srb;
   return(true);
  }

//+------------------------------------------------------------------+
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
               r.sharpe_completo, r.sharpe_completo_p, r.sharpe_bh_total, (int)r.ruina);
  }

//+------------------------------------------------------------------+
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

//+------------------------------------------------------------------+
string CDesempenho::Linha(const ResultadoDesempenho &r)
  {
   string s = StringFormat("%s;%s;%.3f;%d;%d;%.4f;%.4f;%.6f;%.4f;",
                           TimeToString(r.inicio, TIME_DATE), TimeToString(r.fim, TIME_DATE), r.anos,
                           r.negocios, r.saidas, r.taxa_acerto, r.fator_lucro, r.custo_total,
                           r.exposicao_media);
   s += StringFormat("%.6f;%.6f;%.6f;%.6f;%.6f;%.6f;%.6f;",
                     r.ret_puro, r.ret_custos, r.ret_selic, r.ret_completo, r.selic, r.bh_preco, r.bh_total);
   s += StringFormat("%.6f;%.6f;%.6f;%.6f;%.6f;%.6f;",
                     r.cagr_puro, r.cagr_selic_camada, r.cagr_completo, r.cagr_selic,
                     r.cagr_bh_preco, r.cagr_bh_total);
   s += StringFormat("%.6f;%.6f;%.6f;%.6f;%.6f;%.6f;%.6f;",
                     r.excesso, r.excesso_completo, r.dd_puro, r.dd_selic, r.dd_completo,
                     r.dd_bh_preco, r.dd_bh_total);
   s += StringFormat("%.6f;%.6f;%.6f;%.4f;%.4f;%.4f;%.4f;%.4f;%.4f;",
                     r.vol_puro, r.vol_selic, r.vol_bh_preco, r.sharpe, r.sharpe_t, r.sharpe_p,
                     r.sharpe_bh, r.sortino, r.sortino_bh);
   s += StringFormat("%.4f;%.4f;%.4f;%.6f;%.4f;%.4f;%.4f;%.4f;%.4f;%.4f;%d",
                     r.calmar, r.calmar_bh, r.beta, r.alfa, r.alfa_t, r.z_sharpe_bh, r.p_sharpe_bh,
                     r.sharpe_completo, r.sharpe_completo_p, r.sharpe_bh_total, (int)r.ruina);
   return(s);
  }

//+------------------------------------------------------------------+
//| Curva diaria (base 1). As colunas 1 e 2 (estrategia, selic) sao  |
//| as usadas por CompararCurvas: estrategia = camada 3 (oficial).   |
//+------------------------------------------------------------------+
bool CDesempenho::GravarCurva(const string arquivo) const
  {
   if(ArraySize(m_c_selic) != m_n)
      return(false);
   int fh = FileOpen(arquivo, FILE_WRITE | FILE_TXT | FILE_ANSI | FILE_COMMON);
   if(fh == INVALID_HANDLE)
      return(false);
   FileWriteString(fh, "data,estrategia,selic,puro,completo,buyhold,buyhold_total,exposicao,dd,dd_puro,dd_bh\n");
   double pk = 1, pkp = 1, pkb = 1;
   for(int i = 0; i < m_n; i++)
     {
      string data = TimeToString(m_t[i], TIME_DATE);
      StringReplace(data, ".", "-");          // formato de data do pgfplots
      pk = MathMax(pk, m_c_selic[i]); pkp = MathMax(pkp, m_c_puro[i]); pkb = MathMax(pkb, m_c_bh_preco[i]);
      FileWriteString(fh, StringFormat("%s,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.4f,%.6f,%.6f,%.6f\n",
                      data, m_c_selic[i], m_c_ref[i], m_c_puro[i], m_c_completo[i],
                      m_c_bh_preco[i], m_c_bh_total[i], m_exposicao[i],
                      1 - m_c_selic[i] / pk, 1 - m_c_puro[i] / pkp, 1 - m_c_bh_preco[i] / pkb));
     }
   FileClose(fh);
   return(true);
  }

//+------------------------------------------------------------------+
void CDesempenho::Gravar(const string rotulo, const string cab_modelo,
                         const string val_modelo, const ResultadoDesempenho &r) const
  {
   string cab = cab_modelo + ";" + Cabecalho();
   string lin = val_modelo + ";" + Linha(r);
   string nome;

   bool otimizando = (bool)MQLInfoInteger(MQL_OPTIMIZATION);
   if(!otimizando && StringLen(rotulo) > 0)
     {
      nome = "AlgoLab\\metricas_" + rotulo + ".csv";
      GravarCurva("AlgoLab\\curva_" + rotulo + ".csv");
     }
   else
     {
      string id = StringFormat("%s|%s|%I64u|%u", TerminalInfoString(TERMINAL_DATA_PATH),
                               lin, GetMicrosecondCount(), GetTickCount());
      uint h = 5381;
      for(int i = 0; i < StringLen(id); i++)
         h = h * 33 + (uint)StringGetCharacter(id, i);
      nome = StringFormat("AlgoLab\\res_%08x_%I64u.csv", h, GetMicrosecondCount());
     }

   int fh = FileOpen(nome, FILE_WRITE | FILE_TXT | FILE_ANSI | FILE_COMMON);
   if(fh != INVALID_HANDLE)
     {
      FileWriteString(fh, cab + "\n" + lin + "\n");
      FileClose(fh);
     }
  }

//+------------------------------------------------------------------+
//| COMPARACAO ENTRE DOIS MODELOS NO MESMO PERIODO                   |
//+------------------------------------------------------------------+
//|  Le duas curvas diarias gravadas por GravarCurva() (mesmas       |
//|  datas) e testa se o modelo A foi melhor que o B:                |
//|                                                                  |
//|   - Sharpe de cada um sobre a Selic e o teste da diferenca       |
//|     (Jobson-Korkie com correcao de Memmel, 2003)                 |
//|   - diferenca media de retorno diario (A - B), anualizada, com   |
//|     teste t pareado: "A rendeu mais que B, dia a dia?"           |
//|                                                                  |
//|  O pareamento e o que torna o teste justo: os dois modelos       |
//|  enfrentaram exatamente os mesmos dias de mercado.               |
//+------------------------------------------------------------------+
struct ComparacaoModelos
  {
   int      n;
   double   sharpe_a, sharpe_b;
   double   rho;               // correlacao dos excessos diarios
   double   z_sharpe, p_sharpe;// Memmel, p bilateral
   double   dif_anual;         // media(r_a - r_b) x 252
   double   t_dif, p_dif;      // t pareado, p bilateral
  };

bool LerCurva(const string arquivo, string &datas[], double &r[], double &s[])
  {
   int fh = FileOpen(arquivo, FILE_READ | FILE_TXT | FILE_ANSI | FILE_COMMON);
   if(fh == INVALID_HANDLE)
      return(false);

   FileReadString(fh);   // cabecalho
   double ant = 0.0, ant_s = 0.0;
   int k = 0;
   while(!FileIsEnding(fh))
     {
      string campos[];
      if(StringSplit(FileReadString(fh), ',', campos) < 3)
         continue;
      double v = StringToDouble(campos[1]), vs = StringToDouble(campos[2]);
      if(k > 0)
        {
         int m = ArraySize(r);
         ArrayResize(r, m + 1, 2048); ArrayResize(s, m + 1, 2048); ArrayResize(datas, m + 1, 2048);
         r[m] = v / ant - 1.0;
         s[m] = vs / ant_s - 1.0;
         datas[m] = campos[0];
        }
      ant = v; ant_s = vs; k++;
     }
   FileClose(fh);
   return(ArraySize(r) > 2);
  }

bool CompararCurvas(const string arq_a, const string arq_b, ComparacaoModelos &c)
  {
   ZeroMemory(c);
   string da[], db[];
   double ra[], sa[], rb[], sb[];
   if(!LerCurva(arq_a, da, ra, sa) || !LerCurva(arq_b, db, rb, sb))
      return(false);
   if(ArraySize(ra) != ArraySize(rb) || da[0] != db[0])
      return(false);   // curvas de periodos diferentes

   int n = ArraySize(ra);
   double ma = 0, mb = 0, md = 0;
   for(int i = 0; i < n; i++)
     {
      ma += ra[i] - sa[i]; mb += rb[i] - sa[i]; md += ra[i] - rb[i];
     }
   ma /= n; mb /= n; md /= n;

   double va = 0, vb = 0, cab = 0, vd = 0;
   for(int i = 0; i < n; i++)
     {
      double ea = ra[i] - sa[i] - ma, eb = rb[i] - sa[i] - mb, d = ra[i] - rb[i] - md;
      va += ea * ea; vb += eb * eb; cab += ea * eb; vd += d * d;
     }
   va /= n - 1; vb /= n - 1; cab /= n - 1; vd /= n - 1;
   if(va <= 0.0 || vb <= 0.0)
      return(false);

   double sra = ma / MathSqrt(va), srb = mb / MathSqrt(vb);
   c.n = n;
   c.sharpe_a = sra * MathSqrt(252.0);
   c.sharpe_b = srb * MathSqrt(252.0);
   c.rho = cab / MathSqrt(va * vb);

   int erro = 0;
   double theta = 2.0 - 2.0 * c.rho + 0.5 * (sra * sra + srb * srb - 2.0 * sra * srb * c.rho * c.rho);
   if(theta > 0.0)
     {
      c.z_sharpe = (sra - srb) / MathSqrt(theta / n);
      c.p_sharpe = 2.0 * (1.0 - MathCumulativeDistributionNormal(MathAbs(c.z_sharpe), 0.0, 1.0, erro));
     }

   c.dif_anual = md * 252.0;
   if(vd > 0.0)
     {
      c.t_dif = md / MathSqrt(vd / n);
      c.p_dif = 2.0 * (1.0 - MathCumulativeDistributionNormal(MathAbs(c.t_dif), 0.0, 1.0, erro));
     }
   return(true);
  }

#endif // ALGOTRADINGLAB_DESEMPENHO_MQH
//+------------------------------------------------------------------+
