//+------------------------------------------------------------------+
//| GarchAssimetrico.mqh                                             |
//| Variacoes assimetricas do GARCH(1,1), experimentais (18/11/2026, |
//| fora do TG). Nos dois, uma queda pesa mais na volatilidade do    |
//| dia seguinte que uma alta do mesmo tamanho (efeito alavanca).    |
//|                                                                  |
//| GJR-GARCH (Glosten, Jagannathan e Runkle, 1993), a variacao do   |
//| TGARCH sobre a variancia (Thomaz, 2019, secao 3.8.2):            |
//|   s2(t) = omega + (alfa + gama I[e(t-1) < 0]) e2(t-1)            |
//|           + beta s2(t-1)                                         |
//|   restricoes: omega > 0, alfa >= 0, beta >= 0, alfa + gama >= 0, |
//|   alfa + gama/2 + beta < 1 (gama > 0 = alavanca)                 |
//|                                                                  |
//| EGARCH (Nelson, 1991; Thomaz, 2019, secao 3.8.1):                |
//|   ln s2(t) = omega + beta ln s2(t-1)                             |
//|              + alfa (|z(t-1)| - E|z|) + gama z(t-1)              |
//|   z = e / s; sem restricao de sinal, so 0 <= beta < 1            |
//|   (gama < 0 = alavanca)                                          |
//|                                                                  |
//| Mesma maxima verossimilhanca do GARCH simetrico (MinBLEIC), com  |
//| a normal ou a t de Student. O otimizador ve omega numa escala    |
//| relativa: no GJR, omega / variancia amostral; no EGARCH, o       |
//| desvio do nivel medio de ln s2 em relacao a ln da variancia      |
//| amostral, de modo que omega = (1 - beta)(ln v + x0).             |
//+------------------------------------------------------------------+
#ifndef ALGOTRADINGLAB_GARCHASSIMETRICO_MQH
#define ALGOTRADINGLAB_GARCHASSIMETRICO_MQH

#include <Math\Alglib\alglib.mqh>
#include "GarchDistribuicao.mqh"

enum ENUM_MODELO_GARCH
  {
   GARCH_SIMETRICO = 0,   // GARCH(1,1), o do TG
   GARCH_GJR = 1,         // GJR-GARCH(1,1) (experimental)
   GARCH_EGARCH = 2       // EGARCH(1,1) (experimental)
  };

//--- E|z| de um erro com variancia 1: normal sqrt(2/pi); t padronizada com nu graus
double ValorAbsolutoEsperado(const ENUM_DISTRIBUICAO_GARCH distribuicao, const double graus_liberdade)
  {
   if(distribuicao != DISTRIBUICAO_STUDENT || graus_liberdade <= 2.0)
      return(MathSqrt(2.0 / M_PI));
   double nu = graus_liberdade;
   return(2.0 * MathSqrt(nu - 2.0) * MathExp(MathGammaLog(0.5 * (nu + 1.0)) - MathGammaLog(0.5 * nu))
          / (MathSqrt(M_PI) * (nu - 1.0)));
  }

//--- Variancia do periodo seguinte a partir do erro e da variancia do periodo atual
bool PassoVarianciaAssimetrica(const ENUM_MODELO_GARCH modelo, const double omega, const double alfa,
                               const double gama, const double beta, const double erro,
                               const double sigma2, const double valor_absoluto_esperado, double &saida)
  {
   if(sigma2 <= 0.0 || !MathIsValidNumber(sigma2))
      return(false);
   if(modelo == GARCH_GJR)
     {
      saida = omega + (alfa + (erro < 0.0 ? gama : 0.0)) * erro * erro + beta * sigma2;
     }
   else
     {
      double z = erro / MathSqrt(sigma2);
      double log_sigma2 = omega + beta * MathLog(sigma2) + alfa * (MathAbs(z) - valor_absoluto_esperado) + gama * z;
      if(log_sigma2 > 700.0 || log_sigma2 < -700.0)
         return(false);
      saida = MathExp(log_sigma2);
     }
   return(saida > 0.0 && MathIsValidNumber(saida));
  }

//--- Parametros no espaco do otimizador -> omega, alfa, gama, beta, nu
struct ParametrosGarchAssimetrico
  {
   double            omega;
   double            alfa;
   double            gama;
   double            beta;
   double            graus_liberdade;   // 0 com a normal
  };

bool ConverterParametrosAssimetricos(const ENUM_MODELO_GARCH modelo, const bool student,
                                     const double variancia_amostral, const double &x[],
                                     ParametrosGarchAssimetrico &saida)
  {
   if(ArraySize(x) < (student ? 5 : 4))
      return(false);
   saida.alfa = x[1];
   saida.gama = x[2];
   saida.beta = x[3];
   saida.graus_liberdade = 0.0;
   if(modelo == GARCH_GJR)
     {
      saida.omega = x[0] * variancia_amostral;
      if(saida.omega <= 0.0 || saida.alfa < 0.0 || saida.beta < 0.0 || saida.alfa + saida.gama < 0.0
         || saida.alfa + 0.5 * saida.gama + saida.beta >= 1.0)
         return(false);
     }
   else
     {
      if(saida.beta < 0.0 || saida.beta >= 1.0)
         return(false);
      saida.omega = (1.0 - saida.beta) * (MathLog(variancia_amostral) + x[0]);
     }
   if(student)
     {
      double eta = x[4];
      if(eta < GARCH_ETA_MINIMO * 0.999 || eta > GARCH_ETA_MAXIMO * 1.001)
         return(false);
      saida.graus_liberdade = 1.0 / eta;
     }
   for(int i = 0; i < ArraySize(x); i++)
      if(!MathIsValidNumber(x[i]))
         return(false);
   return(true);
  }

class CDadosGarchAssimetrico : public CObject
  {
public:
   double            erros[];
   int               tamanho;
   int               inicio;
   double            variancia_amostral;
   ENUM_MODELO_GARCH modelo;
   ENUM_DISTRIBUICAO_GARCH distribuicao;

                     CDadosGarchAssimetrico(void) : tamanho(0), inicio(1), variancia_amostral(0.0),
                                                    modelo(GARCH_GJR), distribuicao(DISTRIBUICAO_NORMAL) {}
                    ~CDadosGarchAssimetrico(void) { ArrayFree(erros); }
  };

//--- Recursao da variancia condicional; devolve a log-verossimilhanca (ou false se invalida)
bool RecursaoGarchAssimetrico(const ENUM_MODELO_GARCH modelo, const ENUM_DISTRIBUICAO_GARCH distribuicao,
                              const ParametrosGarchAssimetrico &par, const double &erros[], const int n,
                              const int inicio, const double variancia_amostral,
                              double &sigma2[], double &log_verossimilhanca)
  {
   bool student = (distribuicao == DISTRIBUICAO_STUDENT && par.graus_liberdade > 2.0);
   double constante = student ? ConstanteStudent(par.graus_liberdade) : 0.0;
   double eabs = ValorAbsolutoEsperado(distribuicao, par.graus_liberdade);

   ArrayResize(sigma2, n);
   for(int t = 0; t < inicio && t < n; t++)
      sigma2[t] = variancia_amostral;

   log_verossimilhanca = 0.0;
   for(int t = inicio; t < n; t++)
     {
      double variancia;
      if(!PassoVarianciaAssimetrica(modelo, par.omega, par.alfa, par.gama, par.beta,
                                    erros[t - 1], sigma2[t - 1], eabs, variancia))
         return(false);
      sigma2[t] = variancia;
      double e2 = erros[t] * erros[t];
      log_verossimilhanca += student ? LogDensidadeStudent(e2, variancia, par.graus_liberdade, constante)
                                     : LogDensidadeNormal(e2, variancia);
     }
   return(MathIsValidNumber(log_verossimilhanca));
  }

double MenosLogVerossimilhancaAssimetrica(CDadosGarchAssimetrico &dados, const double &x[])
  {
   ParametrosGarchAssimetrico par;
   if(!ConverterParametrosAssimetricos(dados.modelo, dados.distribuicao == DISTRIBUICAO_STUDENT,
                                       dados.variancia_amostral, x, par))
      return(1.0e10);
   double sigma2[], log_verossimilhanca;
   if(!RecursaoGarchAssimetrico(dados.modelo, dados.distribuicao, par, dados.erros, dados.tamanho,
                                dados.inicio, dados.variancia_amostral, sigma2, log_verossimilhanca))
      return(1.0e10);
   return(-log_verossimilhanca);
  }

class CObjetivoGarchAssimetrico : public CNDimensional_Func
  {
public:
   virtual void      Func(CRowDouble &x, double &func, CObject &obj);
  };

void CObjetivoGarchAssimetrico::Func(CRowDouble &x, double &func, CObject &obj)
  {
   CDadosGarchAssimetrico *dados = dynamic_cast<CDadosGarchAssimetrico *>(GetPointer(obj));
   if(dados == NULL)
     {
      func = 1.0e10;
      return;
     }
   int k = x.Size();
   double parametros[];
   ArrayResize(parametros, k);
   for(int i = 0; i < k; i++)
      parametros[i] = x[i];
   func = MenosLogVerossimilhancaAssimetrica(dados, parametros);
  }

//--- Maxima verossimilhanca. Partida tipica de serie diaria; com a t, nu ~ 6,7.
bool AjustarGarchAssimetrico(const ENUM_MODELO_GARCH modelo, const ENUM_DISTRIBUICAO_GARCH distribuicao,
                             const double &erros[], const double variancia_amostral,
                             const int iteracoes_maximas, const double passo_diferencas,
                             ParametrosGarchAssimetrico &saida, string &erro)
  {
   int n = ArraySize(erros);
   bool student = (distribuicao == DISTRIBUICAO_STUDENT);
   int k = student ? 5 : 4;

   CDadosGarchAssimetrico dados;
   ArrayResize(dados.erros, n);
   ArrayCopy(dados.erros, erros);
   dados.tamanho = n;
   dados.inicio = 1;
   dados.variancia_amostral = variancia_amostral;
   dados.modelo = modelo;
   dados.distribuicao = distribuicao;

   double x[], inferior[], superior[];
   ArrayResize(x, k);
   ArrayResize(inferior, k);
   ArrayResize(superior, k);
   if(modelo == GARCH_GJR)
     {
      x[0] = 0.05;   inferior[0] = 1.0e-8; superior[0] = 10.0;
      x[1] = 0.03;   inferior[1] = 0.0;    superior[1] = 1.0;
      x[2] = 0.10;   inferior[2] = -1.0;   superior[2] = 1.0;
      x[3] = 0.85;   inferior[3] = 0.0;    superior[3] = 1.0;
     }
   else
     {
      x[0] = 0.0;    inferior[0] = -5.0;   superior[0] = 5.0;
      x[1] = 0.15;   inferior[1] = -1.0;   superior[1] = 2.0;
      x[2] = -0.05;  inferior[2] = -1.0;   superior[2] = 1.0;
      x[3] = 0.95;   inferior[3] = 0.0;    superior[3] = 0.9999;
     }
   if(student)
     {
      x[4] = 0.15; inferior[4] = GARCH_ETA_MINIMO; superior[4] = GARCH_ETA_MAXIMO;
     }

   CMinBLEICStateShell estado;
   CMinBLEICReportShell relatorio;
   CObjetivoGarchAssimetrico objetivo;
   CNDimensional_Rep repositor;

   CAlglib::MinBLEICCreateF(k, x, passo_diferencas, estado);
   CAlglib::MinBLEICSetBC(estado, inferior, superior);
   if(modelo == GARCH_GJR)
     {
      //--- alfa + gama/2 + beta <= 0,9999 (estacionariedade) e alfa + gama >= 0 (queda nao reduz s2)
      CMatrixDouble restricao(2, k + 1);
      for(int r = 0; r < 2; r++)
         for(int i = 0; i <= k; i++)
            restricao.Set(r, i, 0.0);
      restricao.Set(0, 1, 1.0); restricao.Set(0, 2, 0.5); restricao.Set(0, 3, 1.0); restricao.Set(0, k, 0.9999);
      restricao.Set(1, 1, 1.0); restricao.Set(1, 2, 1.0); restricao.Set(1, k, 0.0);
      int tipo[];
      ArrayResize(tipo, 2);
      tipo[0] = -1;   // menor ou igual
      tipo[1] = 1;    // maior ou igual
      CAlglib::MinBLEICSetLC(estado, restricao, tipo, 2);
     }
   CAlglib::MinBLEICSetInnerCond(estado, 0.0, 0.0, 1.0e-8);
   CAlglib::MinBLEICSetOuterCond(estado, 1.0e-8, 1.0e-8);
   CAlglib::MinBLEICSetMaxIts(estado, iteracoes_maximas);
   CAlglib::MinBLEICOptimize(estado, objetivo, repositor, false, dados);

   double x_final[];
   CAlglib::MinBLEICResults(estado, x_final, relatorio);
   int codigo = relatorio.GetTerminationType();
   if(codigo <= 0 || ArraySize(x_final) < k)
     {
      erro = StringFormat("Otimizador falhou (codigo %d)", codigo);
      return(false);
     }
   //--- O otimizador pode parar um pouco fora da restricao linear: puxa de volta
   if(modelo == GARCH_GJR)
     {
      if(x_final[1] + x_final[2] < 0.0)
         x_final[2] = -x_final[1];
      double persistencia = x_final[1] + 0.5 * x_final[2] + x_final[3];
      if(persistencia >= 0.99995)
         x_final[3] -= persistencia - 0.9999;
     }
   if(!ConverterParametrosAssimetricos(modelo, student, variancia_amostral, x_final, saida))
     {
      erro = "Parametros estimados invalidos";
      return(false);
     }
   return(true);
  }

#endif
