//+------------------------------------------------------------------+
//| GarchDistribuicao.mqh                                            |
//| Distribuicao suposta para os erros do GARCH. A normal e a do TG. |
//| A t de Student padronizada (variancia 1) e experimental          |
//| (13/10/2026): caudas mais grossas, com nu graus de liberdade     |
//| estimados junto com os outros parametros. A equacao da variancia |
//| e a previsao sao as mesmas nas duas.                             |
//+------------------------------------------------------------------+
#ifndef ALGOTRADINGLAB_GARCHDISTRIBUICAO_MQH
#define ALGOTRADINGLAB_GARCHDISTRIBUICAO_MQH

#include <Math\Stat\Math.mqh>

enum ENUM_DISTRIBUICAO_GARCH
  {
   DISTRIBUICAO_NORMAL = 0,    // Normal
   DISTRIBUICAO_STUDENT = 1    // t de Student padronizada (experimental)
  };

//--- O otimizador ve eta = 1/nu, da mesma ordem de alfa e beta: nu entre 2,22 e 200
#define GARCH_ETA_MINIMO 0.005
#define GARCH_ETA_MAXIMO 0.45

//--- Log-densidade de um erro com variancia condicional sigma2
double LogDensidadeNormal(const double erro_quadrado, const double sigma2)
  {
   return(-0.5 * (MathLog(2.0 * M_PI) + MathLog(sigma2) + erro_quadrado / sigma2));
  }

//--- Parte da log-densidade da t que so depende de nu
double ConstanteStudent(const double graus_liberdade)
  {
   return(MathGammaLog(0.5 * (graus_liberdade + 1.0)) - MathGammaLog(0.5 * graus_liberdade)
          - 0.5 * MathLog(M_PI * (graus_liberdade - 2.0)));
  }

double LogDensidadeStudent(const double erro_quadrado, const double sigma2,
                           const double graus_liberdade, const double constante)
  {
   return(constante - 0.5 * MathLog(sigma2)
          - 0.5 * (graus_liberdade + 1.0) * MathLog(1.0 + erro_quadrado / ((graus_liberdade - 2.0) * sigma2)));
  }

#endif
