//+------------------------------------------------------------------+
//|                                                SelecaoModelo.mqh |
//|                            Trabalho de Graduacao - FATEC Indaiatuba|
//+------------------------------------------------------------------+
//|                                                                  |
//|  SELECAO AUTOMATICA DE ORDENS (p, d, q)                          |
//|                                                                  |
//|  Implementa o procedimento descrito na metodologia do TG:        |
//|                                                                  |
//|    1. 'd' vem da aplicacao SEQUENCIAL do teste ADF: diferencia   |
//|       enquanto a serie nao for estacionaria.                     |
//|                                                                  |
//|    2. 'p' e 'q' vem de uma busca em grade de 0 a 4, escolhendo   |
//|       a combinacao de MENOR AIC.                                 |
//|                                                                  |
//|  O AIC equilibra ajuste e parcimonia: adicionar parametros       |
//|  sempre melhora o ajuste aos dados historicos, mas o AIC cobra   |
//|  um pedagio de 2 por parametro. Assim ele penaliza o             |
//|  sobreajuste, que produziria um modelo excelente no passado e    |
//|  inutil no futuro.                                               |
//|                                                                  |
//+------------------------------------------------------------------+
#ifndef ALGOTRADINGLAB_SELECAOMODELO_MQH
#define ALGOTRADINGLAB_SELECAOMODELO_MQH

#include "Arima.mqh"
#include "Estatistica.mqh"

//+------------------------------------------------------------------+
//| Resultado da selecao de ordens                                   |
//+------------------------------------------------------------------+
struct ResultadoSelecao
  {
   bool     valido;
   int      p;
   int      d;
   int      q;
   double   aic;
   double   bic;
   double   logL;
   int      modelos_testados;
   int      modelos_ok;
   //--- Diagnostico do ADF que definiu 'd'
   double   adf_stat_final;
   double   adf_vc5_final;
  };

//+------------------------------------------------------------------+
//| DETERMINAR 'd' — aplicacao sequencial do teste ADF               |
//+------------------------------------------------------------------+
//|                                                                  |
//|  Testa a serie. Se nao for estacionaria, diferencia e testa de   |
//|  novo. Repete ate estacionaria ou ate atingir d_max.             |
//|                                                                  |
//|  Observacao sobre os termos deterministicos: para o NIVEL da     |
//|  serie usamos constante (a serie tem media diferente de zero);   |
//|  para as diferencas, tambem mantemos a constante, pois um ativo  |
//|  pode ter drift. Manter a constante e a escolha conservadora.    |
//|                                                                  |
//+------------------------------------------------------------------+
int DeterminarOrdemD(const double &serie[], const int d_max,
                     const ENUM_ADF_DETERMINISTICO det,
                     string &relatorio,
                     double &stat_final, double &vc5_final)
  {
   relatorio = "";
   stat_final = 0.0;
   vc5_final = 0.0;

   double atual[];
   int n = ArraySize(serie);
   ArrayResize(atual, n);
   ArrayCopy(atual, serie);

   for(int d = 0; d <= d_max; d++)
     {
      ResultadoADF r;

      if(!TesteADF(atual, det, -1, r))
        {
         relatorio += StringFormat("  d=%d: ADF nao pode ser calculado (dados insuficientes)\n", d);
         return(d);
        }

      relatorio += StringFormat("  d=%d: ADF=%8.4f  VC5%%=%8.4f  lags=%d  n=%d  -> %s\n",
                                d, r.estatistica, r.vc_5pct, r.lags, r.n_obs,
                                r.estacionaria_5pct ? "ESTACIONARIA" : "nao estacionaria");

      stat_final = r.estatistica;
      vc5_final  = r.vc_5pct;

      if(r.estacionaria_5pct)
         return(d);

      if(d == d_max)
         break;

      //--- Diferencia mais uma vez
      int m = ArraySize(atual);
      if(m < 3)
         break;

      for(int i = 0; i < m - 1; i++)
         atual[i] = atual[i + 1] - atual[i];
      ArrayResize(atual, m - 1);
     }

   relatorio += StringFormat("  Limite d_max=%d atingido sem estacionariedade; usando d=%d\n",
                             d_max, d_max);
   return(d_max);
  }

//+------------------------------------------------------------------+
//| BUSCA EM GRADE (p,q) POR AIC                                     |
//+------------------------------------------------------------------+
//|                                                                  |
//|  Ajusta ARIMA(p,d,q) para todo p em [0,p_max] e q em [0,q_max]   |
//|  e devolve a combinacao de menor AIC.                            |
//|                                                                  |
//|  CUSTO: (p_max+1)*(q_max+1) ajustes. Com o padrao 0..4 sao 25    |
//|  modelos. Cada ajuste e MQO exato, entao e rapido — mas NAO e    |
//|  para rodar a cada barra. Veja a politica de reavaliacao no EA.  |
//|                                                                  |
//|  'tabela' recebe a grade completa, pronta para virar tabela do   |
//|  TG.                                                             |
//|                                                                  |
//+------------------------------------------------------------------+
bool BuscarMelhorPQ(const double &serie[], const int d,
                    const int p_max, const int q_max,
                    const bool com_constante,
                    ResultadoSelecao &res,
                    string &tabela)
  {
   res.valido = false;
   res.p = 0;
   res.q = 0;
   res.d = d;
   res.aic = DBL_MAX;
   res.bic = DBL_MAX;
   res.logL = 0.0;
   res.modelos_testados = 0;
   res.modelos_ok = 0;

   //--- AMOSTRA COMUM: todos os candidatos avaliam a verossimilhanca
   //--- sobre exatamente as mesmas observacoes. Sem isto o ARIMA(0,d,0)
   //--- somaria mais parcelas que o ARIMA(4,d,4) e venceria por
   //--- construcao, nao por merito.
   int aquecimento_comum = MathMax(p_max, q_max);

   tabela = StringFormat("  (verossimilhanca avaliada sobre amostra comum: %d obs. descartadas no inicio)\n",
                         aquecimento_comum);
   tabela += "   p   q          AIC          BIC         logL     n\n";
   tabela += "  --- --- ------------ ------------ ------------ -----\n";

   for(int p = 0; p <= p_max; p++)
     {
      for(int q = 0; q <= q_max; q++)
        {
         res.modelos_testados++;

         //--- ARIMA(0,d,0) sem constante nao tem nada a estimar
         if(p == 0 && q == 0 && !com_constante)
            continue;

         CArima m;
         m.Definir(p, d, q, com_constante);
         m.DefinirAquecimentoMinimo(aquecimento_comum);

         if(!m.Ajustar(serie))
           {
            tabela += StringFormat("  %3d %3d          ---          ---   %s\n",
                                   p, q, m.UltimoErro());
            continue;
           }

         double aic = m.AIC();
         double bic = m.BIC();

         if(!MathIsValidNumber(aic))
           {
            tabela += StringFormat("  %3d %3d          ---          ---   AIC invalido\n", p, q);
            continue;
           }

         res.modelos_ok++;

         tabela += StringFormat("  %3d %3d %12.3f %12.3f %12.3f %5d%s\n",
                                p, q, aic, bic, m.LogVerossimilhanca(),
                                m.NEfetivo(), (aic < res.aic) ? "  <<<" : "");

         if(aic < res.aic)
           {
            res.aic  = aic;
            res.bic  = bic;
            res.logL = m.LogVerossimilhanca();
            res.p    = p;
            res.q    = q;
            res.valido = true;
           }
        }
     }

   return(res.valido);
  }

//+------------------------------------------------------------------+
//| SELECAO COMPLETA: d por ADF, depois (p,q) por AIC                |
//+------------------------------------------------------------------+
bool SelecionarModelo(const double &serie[],
                      const int d_max, const int p_max, const int q_max,
                      const bool com_constante,
                      const ENUM_ADF_DETERMINISTICO det,
                      ResultadoSelecao &res,
                      string &relatorio)
  {
   relatorio = "";

   //--- ── Etapa 1: ordem de integracao ──
   string rel_adf = "";
   double stat = 0.0, vc5 = 0.0;

   int d = DeterminarOrdemD(serie, d_max, det, rel_adf, stat, vc5);

   relatorio += "[1] Ordem de integracao 'd' por ADF sequencial:\n";
   relatorio += rel_adf;
   relatorio += StringFormat("    => d = %d\n\n", d);

   //--- ── Etapa 2: ordens p e q ──
   string tabela = "";
   bool ok = BuscarMelhorPQ(serie, d, p_max, q_max, com_constante, res, tabela);

   res.adf_stat_final = stat;
   res.adf_vc5_final  = vc5;
   res.d = d;

   relatorio += StringFormat("[2] Busca em grade (p,q) de 0..%d x 0..%d por AIC:\n", p_max, q_max);
   relatorio += tabela;

   if(ok)
      relatorio += StringFormat("\n    => SELECIONADO: ARIMA(%d,%d,%d)  AIC=%.3f  BIC=%.3f  (%d/%d modelos validos)\n",
                                res.p, res.d, res.q, res.aic, res.bic,
                                res.modelos_ok, res.modelos_testados);
   else
      relatorio += "\n    => NENHUM modelo pode ser ajustado.\n";

   return(ok);
  }

#endif // ALGOTRADINGLAB_SELECAOMODELO_MQH
//+------------------------------------------------------------------+
