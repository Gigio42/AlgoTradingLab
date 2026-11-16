//+------------------------------------------------------------------+
//| ArimaVerossimilhanca.mqh                                         |
//| Opcao experimental (15/10/2026, fora do TG): refina os           |
//| coeficientes do Hannan-Rissanen por maxima verossimilhanca       |
//| condicional, minimizando a soma dos residuos ao quadrado.        |
//|                                                                  |
//| O otimizador trabalha com autocorrelacoes parciais r = tanh(u),  |
//| convertidas em coeficientes por Durbin-Levinson: assim o AR fica |
//| estacionario e o MA invertivel por construcao. Se o otimizador   |
//| falhar ou nao melhorar o ajuste, ficam os coeficientes do HR.    |
//+------------------------------------------------------------------+
#ifndef ALGOTRADINGLAB_ARIMAVEROSSIMILHANCA_MQH
#define ALGOTRADINGLAB_ARIMAVEROSSIMILHANCA_MQH

#include <Math\Alglib\alglib.mqh>
#include "Estatistica.mqh"

int g_tentativas_verossimilhanca = 0;   // refinamentos tentados
int g_mantidos_hannan_rissanen   = 0;   // refinamentos recusados (ficou o HR)

double TangenteHiperbolica(const double x)
  {
   if(x > 20.0)  return(1.0);
   if(x < -20.0) return(-1.0);
   double exponencial = MathExp(2.0 * x);
   return((exponencial - 1.0) / (exponencial + 1.0));
  }

double ArcoTangenteHiperbolica(const double r)
  {
   double limitado = MathMax(-0.999, MathMin(0.999, r));
   return(0.5 * MathLog((1.0 + limitado) / (1.0 - limitado)));
  }

//--- Durbin-Levinson: autocorrelacoes parciais (|r| < 1) -> coeficientes estacionarios
void ParciaisParaCoeficientes(const double &parciais[], const int ordem, double &coeficientes[])
  {
   ArrayResize(coeficientes, ordem);
   double anteriores[];
   ArrayResize(anteriores, ordem);
   for(int j = 0; j < ordem; j++)
     {
      coeficientes[j] = parciais[j];
      for(int i = 0; i < j; i++)
         coeficientes[i] = anteriores[i] - parciais[j] * anteriores[j - 1 - i];
      for(int i = 0; i <= j; i++)
         anteriores[i] = coeficientes[i];
     }
  }

//--- Inversa da anterior. Falha se os coeficientes nao forem estacionarios.
bool CoeficientesParaParciais(const double &coeficientes_entrada[], const int ordem, double &parciais[])
  {
   ArrayResize(parciais, ordem);
   double coeficientes[], anteriores[];
   ArrayResize(coeficientes, ordem);
   ArrayResize(anteriores, ordem);
   for(int i = 0; i < ordem; i++)
      coeficientes[i] = coeficientes_entrada[i];
   for(int j = ordem - 1; j >= 0; j--)
     {
      double parcial = coeficientes[j];
      if(!MathIsValidNumber(parcial) || MathAbs(parcial) >= 0.999)
         return(false);
      parciais[j] = parcial;
      double divisor = 1.0 - parcial * parcial;
      for(int i = 0; i < j; i++)
         anteriores[i] = (coeficientes[i] + parcial * coeficientes[j - 1 - i]) / divisor;
      for(int i = 0; i < j; i++)
         coeficientes[i] = anteriores[i];
     }
   return(true);
  }

class CDadosVerossimilhancaArima : public CObject
  {
public:
   double            serie[];               // serie diferenciada
   int               tamanho;
   int               p;
   int               q;
   bool              com_constante;
   int               inicio_recursao;
   int               inicio_soma;
   double            escala_constante;      // desvio-padrao da serie
   double            soma_referencia;       // soma do HR, normaliza a funcao objetivo

                     CDadosVerossimilhancaArima(void) : tamanho(0), p(0), q(0), com_constante(false),
                                                        inicio_recursao(0), inicio_soma(0),
                                                        escala_constante(1.0), soma_referencia(1.0) {}
                    ~CDadosVerossimilhancaArima(void) { ArrayFree(serie); }
  };

//--- Vetor do otimizador -> (constante, phi, theta)
void ParametrosDoOtimizador(const CDadosVerossimilhancaArima &dados, const double &parametros[],
                            double &constante, double &phi[], double &theta[])
  {
   int k = 0;
   constante = dados.com_constante ? parametros[k++] * dados.escala_constante : 0.0;
   double parciais[];
   if(dados.p > 0)
     {
      ArrayResize(parciais, dados.p);
      for(int i = 0; i < dados.p; i++)
         parciais[i] = TangenteHiperbolica(parametros[k++]);
      ParciaisParaCoeficientes(parciais, dados.p, phi);
     }
   else
      ArrayResize(phi, 0);
   if(dados.q > 0)
     {
      ArrayResize(parciais, dados.q);
      for(int j = 0; j < dados.q; j++)
         parciais[j] = TangenteHiperbolica(parametros[k++]);
      //--- 1 + soma theta_j B^j e invertivel quando -theta e estacionario
      ParciaisParaCoeficientes(parciais, dados.q, theta);
      for(int j = 0; j < dados.q; j++)
         theta[j] = -theta[j];
     }
   else
      ArrayResize(theta, 0);
  }

//--- Mesma recursao de CArima::CalcularResiduos
double SomaQuadradosResiduosArima(const CDadosVerossimilhancaArima &dados, const double &constante,
                                  const double &phi[], const double &theta[])
  {
   double residuos[];
   ArrayResize(residuos, dados.tamanho);
   ArrayInitialize(residuos, 0.0);
   double soma = 0.0;
   for(int t = dados.inicio_recursao; t < dados.tamanho; t++)
     {
      double ajuste = constante;
      for(int i = 0; i < dados.p; i++)
         ajuste += phi[i] * dados.serie[t - 1 - i];
      for(int j = 0; j < dados.q; j++)
         ajuste += theta[j] * residuos[t - 1 - j];
      residuos[t] = dados.serie[t] - ajuste;
      if(t >= dados.inicio_soma)
         soma += residuos[t] * residuos[t];
     }
   return(soma);
  }

class CObjetivoVerossimilhancaArima : public CNDimensional_Func
  {
public:
   virtual void      Func(CRowDouble &x, double &func, CObject &obj);
  };

void CObjetivoVerossimilhancaArima::Func(CRowDouble &x, double &func, CObject &obj)
  {
   CDadosVerossimilhancaArima *dados = dynamic_cast<CDadosVerossimilhancaArima *>(GetPointer(obj));
   if(dados == NULL)
     {
      func = 1.0e10;
      return;
     }
   int k = x.Size();
   double parametros[], constante, phi[], theta[];
   ArrayResize(parametros, k);
   for(int i = 0; i < k; i++)
      parametros[i] = x[i];
   ParametrosDoOtimizador(dados, parametros, constante, phi, theta);
   double soma = SomaQuadradosResiduosArima(dados, constante, phi, theta);
   func = (MathIsValidNumber(soma) && dados.soma_referencia > 0.0) ? soma / dados.soma_referencia : 1.0e10;
  }

//--- Encolhe os coeficientes ate entrarem na regiao estacionaria e devolve u = atanh(r)
void PontoDePartida(const double &coeficientes[], const int ordem, const double sinal,
                    double &x[], int &posicao)
  {
   double encolhidos[], parciais[];
   ArrayResize(encolhidos, ordem);
   double fator = 1.0;
   bool dentro = false;
   for(int tentativa = 0; tentativa < 30 && !dentro; tentativa++, fator *= 0.9)
     {
      for(int i = 0; i < ordem; i++)
         encolhidos[i] = sinal * coeficientes[i] * fator;
      dentro = CoeficientesParaParciais(encolhidos, ordem, parciais);
     }
   for(int i = 0; i < ordem; i++)
      x[posicao++] = dentro ? ArcoTangenteHiperbolica(parciais[i]) : 0.0;
  }

//--- Parte das estimativas do HR. Troca os coeficientes so se o otimizador terminar
//--- normalmente e a soma dos residuos ao quadrado nao piorar.
bool RefinarPorVerossimilhanca(const double &serie[], const int p, const int q, const bool com_constante,
                               const int inicio_recursao, const int inicio_soma,
                               double &constante, double &phi[], double &theta[])
  {
   int k = (com_constante ? 1 : 0) + p + q;
   if(k == 0)
      return(true);
   g_tentativas_verossimilhanca++;

   CDadosVerossimilhancaArima dados;
   dados.tamanho = ArraySize(serie);
   ArrayResize(dados.serie, dados.tamanho);
   for(int t = 0; t < dados.tamanho; t++)
      dados.serie[t] = serie[t];
   dados.p = p;
   dados.q = q;
   dados.com_constante = com_constante;
   dados.inicio_recursao = inicio_recursao;
   dados.inicio_soma = inicio_soma;
   double desvio = MathSqrt(Variancia(serie));
   dados.escala_constante = (desvio > 0.0 && MathIsValidNumber(desvio)) ? desvio : 1.0;

   double soma_hannan_rissanen = SomaQuadradosResiduosArima(dados, constante, phi, theta);
   if(!MathIsValidNumber(soma_hannan_rissanen) || soma_hannan_rissanen <= 0.0)
     {
      g_mantidos_hannan_rissanen++;
      return(false);
     }
   dados.soma_referencia = soma_hannan_rissanen;

   double x[];
   ArrayResize(x, k);
   int posicao = 0;
   if(com_constante)
      x[posicao++] = constante / dados.escala_constante;
   if(p > 0)
      PontoDePartida(phi, p, 1.0, x, posicao);
   if(q > 0)
      PontoDePartida(theta, q, -1.0, x, posicao);

   double limite_inferior[], limite_superior[];
   ArrayResize(limite_inferior, k);
   ArrayResize(limite_superior, k);
   for(int i = 0; i < k; i++)
     {
      limite_inferior[i] = -3.8;   // tanh(3,8) = 0,999
      limite_superior[i] = 3.8;
     }
   if(com_constante)
     {
      limite_inferior[0] = -50.0;
      limite_superior[0] = 50.0;
     }
   for(int i = 0; i < k; i++)
      x[i] = MathMax(limite_inferior[i], MathMin(limite_superior[i], x[i]));

   CMinBLEICStateShell estado;
   CMinBLEICReportShell relatorio;
   CObjetivoVerossimilhancaArima objetivo;
   CNDimensional_Rep repositor;

   CAlglib::MinBLEICCreateF(k, x, 1.0e-6, estado);
   CAlglib::MinBLEICSetBC(estado, limite_inferior, limite_superior);
   CAlglib::MinBLEICSetInnerCond(estado, 0.0, 0.0, 1.0e-8);
   CAlglib::MinBLEICSetOuterCond(estado, 1.0e-8, 1.0e-8);
   CAlglib::MinBLEICSetMaxIts(estado, 200);
   CAlglib::MinBLEICOptimize(estado, objetivo, repositor, false, dados);

   double x_final[];
   CAlglib::MinBLEICResults(estado, x_final, relatorio);
   if(relatorio.GetTerminationType() <= 0 || ArraySize(x_final) < k)
     {
      g_mantidos_hannan_rissanen++;
      return(false);
     }

   double nova_constante, novo_phi[], novo_theta[];
   ParametrosDoOtimizador(dados, x_final, nova_constante, novo_phi, novo_theta);
   double soma_verossimilhanca = SomaQuadradosResiduosArima(dados, nova_constante, novo_phi, novo_theta);
   if(!MathIsValidNumber(soma_verossimilhanca) || soma_verossimilhanca > soma_hannan_rissanen)
     {
      g_mantidos_hannan_rissanen++;
      return(false);
     }

   constante = nova_constante;
   for(int i = 0; i < p; i++)
      phi[i] = novo_phi[i];
   for(int i = 0; i < q; i++)
      theta[i] = novo_theta[i];
   return(true);
  }

#endif
