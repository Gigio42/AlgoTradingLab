//+------------------------------------------------------------------+
//| SelecaoModelo.mqh                                                |
//| Ordens do ARIMA: d pelo teste ADF aplicado em sequencia; p e q   |
//| pela busca em grade de menor AIC.                                |
//+------------------------------------------------------------------+
#ifndef ALGOTRADINGLAB_SELECAOMODELO_MQH
#define ALGOTRADINGLAB_SELECAOMODELO_MQH

#include "Arima.mqh"
#include "Estatistica.mqh"

//@omitir-inicio
enum ENUM_CRITERIO_ORDENS
  {
   CRITERIO_AIC = 0,   // AIC (o do TG)
   CRITERIO_BIC = 1    // BIC (experimental)
  };

ENUM_CRITERIO_ORDENS g_criterio_ordens = CRITERIO_AIC;

void DefinirCriterioDeOrdens(const ENUM_CRITERIO_ORDENS criterio) { g_criterio_ordens = criterio; }
//@omitir-fim

struct ResultadoSelecao
  {
   bool     valido;
   int      p;
   int      d;
   int      q;
   double   aic;   //@omitir
   double   bic;   //@omitir
   int      modelos_testados;   //@omitir
   int      modelos_ajustados;   //@omitir
  };

//--- Diferencia ate o ADF rejeitar a raiz unitaria ou ate d_maximo. -1 se o ADF nao puder ser calculado.
int DeterminarOrdemD(const double &serie[], const int d_maximo,   //@omitir
//@apendice: int DeterminarOrdemD(const double &serie[], const int d_maximo)
                     const ENUM_ADF_DETERMINISTICO deterministico, string &relatorio)   //@omitir
  {
   relatorio = "";   //@omitir

   double atual[];
   ArrayResize(atual, ArraySize(serie));
   ArrayCopy(atual, serie);

   for(int d = 0; d <= d_maximo; d++)
     {
      ResultadoADF adf;
      if(!TesteADF(atual, deterministico, -1, adf))   //@omitir
      //@apendice: if(!TesteADF(atual, ADF_CONSTANTE, -1, adf))
        {
         relatorio += StringFormat("  d=%d: ADF nao pode ser calculado (dados insuficientes)\n", d);   //@omitir
         return(-1);
        }

      //@omitir-inicio
      relatorio += StringFormat("  d=%d: ADF=%8.4f  VC5%%=%8.4f  lags=%d  n=%d  -> %s\n",
                                d, adf.estatistica, adf.valor_critico_5, adf.defasagens, adf.observacoes,
                                adf.estacionaria ? "ESTACIONARIA" : "nao estacionaria");
                                //@omitir-fim

      if(adf.estacionaria)
         return(d);
      if(d == d_maximo)
         break;

      int tamanho = ArraySize(atual);
      if(tamanho < 3)
         break;
      for(int i = 0; i < tamanho - 1; i++)
         atual[i] = atual[i + 1] - atual[i];
      ArrayResize(atual, tamanho - 1);
     }

   relatorio += StringFormat("  Limite d_max=%d atingido sem estacionariedade; usando d=%d\n", d_maximo, d_maximo);   //@omitir
   return(d_maximo);
  }

//--- Ajusta ARIMA(p,d,q) para p em 0..p_maximo e q em 0..q_maximo e fica com o menor criterio
bool BuscarMelhorPQ(const double &serie[], const int d, const int p_maximo, const int q_maximo,
                    //@apendice: const bool com_constante, ResultadoSelecao &resultado)
                    const bool com_constante, ResultadoSelecao &resultado, string &tabela)   //@omitir
  {
   resultado.valido = false;
   resultado.p = 0;
   resultado.q = 0;
   resultado.d = d;
   resultado.aic = DBL_MAX;   //@omitir
   resultado.bic = DBL_MAX;   //@omitir
   resultado.modelos_testados = 0;   //@omitir
   resultado.modelos_ajustados = 0;   //@omitir

   //--- Todos os candidatos somam a verossimilhanca sobre as mesmas observacoes.
   //--- Sem isso o modelo menor soma mais parcelas e vence por construcao.
   int aquecimento_comum = MathMax(p_maximo, q_maximo);
   double melhor_criterio = DBL_MAX;

   //@omitir-inicio
   tabela = StringFormat("  (verossimilhanca avaliada sobre amostra comum: %d obs. descartadas no inicio)\n",
                         aquecimento_comum);
   tabela += "   p   q          AIC          BIC         logL     n\n";
   tabela += "  --- --- ------------ ------------ ------------ -----\n";
   //@omitir-fim

   for(int p = 0; p <= p_maximo; p++)
      for(int q = 0; q <= q_maximo; q++)
        {
         resultado.modelos_testados++;   //@omitir

         //--- ARIMA(0,d,0) sem constante nao tem o que estimar (com d = 0 a constante e obrigatoria)
         if(p == 0 && q == 0 && !com_constante && d != 0)
            continue;

         CArima candidato;
         candidato.Definir(p, d, q, com_constante);
         candidato.DefinirAquecimentoMinimo(aquecimento_comum);

         if(!candidato.Ajustar(serie))
           {
            tabela += StringFormat("  %3d %3d          ---          ---   %s\n", p, q, candidato.UltimoErro());   //@omitir
            continue;
           }

         double aic = candidato.AIC();
         double bic = candidato.BIC();   //@omitir
         if(!MathIsValidNumber(aic))
           {
            tabela += StringFormat("  %3d %3d          ---          ---   AIC invalido\n", p, q);   //@omitir
            continue;
           }

         resultado.modelos_ajustados++;   //@omitir
         double criterio = (g_criterio_ordens == CRITERIO_BIC) ? bic : aic;   //@omitir

         //@omitir-inicio
         tabela += StringFormat("  %3d %3d %12.3f %12.3f %12.3f %5d%s\n",
                                p, q, aic, bic, candidato.LogVerossimilhanca(),
                                candidato.ObservacoesEfetivas(), (criterio < melhor_criterio) ? "  <<<" : "");
                                //@omitir-fim

         //@apendice: if(aic < melhor_criterio)
         if(criterio < melhor_criterio)   //@omitir
           {
            //@apendice: melhor_criterio = aic;
            melhor_criterio = criterio;   //@omitir
            resultado.aic = aic;   //@omitir
            resultado.bic = bic;   //@omitir
            resultado.p = p;
            resultado.q = q;
            resultado.valido = true;
           }
        }

   return(resultado.valido);
  }

//--- d por ADF, depois (p,q) por AIC. 'relatorio' traz a sequencia do ADF e a grade inteira.
bool SelecionarModelo(const double &serie[], const int d_maximo, const int p_maximo, const int q_maximo,
                      const bool com_constante, const ENUM_ADF_DETERMINISTICO deterministico,   //@omitir
                      //@apendice: const bool com_constante, ResultadoSelecao &resultado)
                      ResultadoSelecao &resultado, string &relatorio)   //@omitir
  {
   string relatorio_adf = "";   //@omitir
   //@apendice: int d = DeterminarOrdemD(serie, d_maximo);
   int d = DeterminarOrdemD(serie, d_maximo, deterministico, relatorio_adf);   //@omitir

   relatorio = "[1] Ordem de integracao 'd' por ADF sequencial:\n" + relatorio_adf;   //@omitir
   if(d < 0)
     {
      relatorio += "    => d indeterminado; selecao adiada\n";   //@omitir
      resultado.valido = false;
      return(false);
     }
   relatorio += StringFormat("    => d = %d\n\n", d);   //@omitir

   string tabela = "";   //@omitir
   //@apendice: bool selecionou = BuscarMelhorPQ(serie, d, p_maximo, q_maximo, com_constante, resultado);
   bool selecionou = BuscarMelhorPQ(serie, d, p_maximo, q_maximo, com_constante, resultado, tabela);   //@omitir
   resultado.d = d;

   //@omitir-inicio
   relatorio += StringFormat("[2] Busca em grade (p,q) de 0..%d x 0..%d por AIC:\n", p_maximo, q_maximo);
   relatorio += tabela;
   if(selecionou)
      relatorio += StringFormat("\n    => SELECIONADO: ARIMA(%d,%d,%d)  AIC=%.3f  BIC=%.3f  (%d/%d modelos validos)\n",
                                resultado.p, resultado.d, resultado.q, resultado.aic, resultado.bic,
                                resultado.modelos_ajustados, resultado.modelos_testados);
   else
      relatorio += "\n    => NENHUM modelo pode ser ajustado.\n";
      //@omitir-fim

   return(selecionou);
  }

#endif
