//+------------------------------------------------------------------+
//|                                                        GARCH.mq5 |
//|           Modelo GARCH(p,q) Isolado para Modelagem de Volatilidade |
//|                                                                  |
//|  Trabalho de Graduação - FATEC Indaiatuba (ADS)                |
//|  Tema: Previsão e Análise de Tendências no Mercado de Ativos   |
//+------------------------------------------------------------------+
#property copyright "TG - FATEC Indaiatuba"
#property link      "https://www.fatec.sp.gov.br"
#property version   "1.00"
#property description "Modelo GARCH(p,q) para modelagem de volatilidade condicional"
#property description ""
#property description "GARCH = Generalized Autoregressive Conditional Heteroskedasticity"
#property description "Modela a variância condicional (volatilidade) de séries temporais"

//+------------------------------------------------------------------+
//| EXPLICAÇÃO TEÓRICA DO MODELO GARCH                               |
//+------------------------------------------------------------------+
//
// ══════════════════════════════════════════════════════════════════
//  O QUE É GARCH?
// ══════════════════════════════════════════════════════════════════
//
//  GARCH(p, q) modela a VOLATILIDADE (variância condicional) de uma série.
//
//  Equação básica do SGARCH(1,1):
//
//    σ²(t) = ω + α·ε²(t-1) + β·σ²(t-1)
//
//  Onde:
//    σ²(t)   = Variância (volatilidade) no tempo t
//    ω       = Termo constante (omega) — volatilidade base
//    α       = Coeficiente ARCH — peso do choque passado (ε²(t-1))
//    β       = Coeficiente GARCH — peso da variância passada (σ²(t-1))
//    ε(t)    = Erro/resíduo no tempo t
//
//  Interpretação:
//    • α mede REATIVIDADE: quanto a volatilidade responde a choques
//    • β mede PERSISTÊNCIA: quanto da volatilidade passada persiste
//    • α + β < 1 → Volatilidade é mean-reverting (volta ao normal)
//    • α + β ≈ 1 → Volatilidade é persistente (shocks duram muito)
//
// ══════════════════════════════════════════════════════════════════
//  COMO ESTIMAR OS PARÂMETROS?
// ══════════════════════════════════════════════════════════════════
//
//  Usamos Maximum Likelihood Estimation (MLE) ou método simplificado:
//  - CSS (Conditional Sum of Squares)
//  - Aqui implementamos uma versão iterativa estável
//
// ══════════════════════════════════════════════════════════════════
//  FLUXO DO GARCH
// ══════════════════════════════════════════════════════════════════
//
//  1. Coleta de resíduos/erros da série (ex: do ARIMA)
//  2. Estimação dos parâmetros ω, α, β via otimização iterativa
//  3. Cálculo da série de variância condicional σ²(t)
//  4. Previsão da volatilidade futura
//  5. Uso na estratégia: volatilidade alta → menor confiança nos sinais
//
// ══════════════════════════════════════════════════════════════════


//+------------------------------------------------------------------+
//| CLASSE GARCH — Modelo de Volatilidade Condicional                |
//+------------------------------------------------------------------+

class GARCH
{
private:
   int      p;              // Ordem ARCH (default: 1)
   int      q;              // Ordem GARCH (default: 1)
   double   omega;          // Constante ω
   double   alpha[];        // Coeficientes α (ARCH)
   double   beta[];         // Coeficientes β (GARCH)
   double   variance[];     // Série de variância σ²(t)
   int      observations;   // Número de observações

public:
   //── Construtor ──
   GARCH(int p_order = 1, int q_order = 1)
   {
      p = p_order;
      q = q_order;
      omega = 0.0;

      ArrayResize(alpha, p);
      ArrayResize(beta, q);
      ArrayInitialize(alpha, 0.0);
      ArrayInitialize(beta, 0.0);

      observations = 0;

      Print("GARCH(", p, ",", q, ") inicializado");
   }

   //── Destrutor ──
   ~GARCH()
   {
      ArrayFree(alpha);
      ArrayFree(beta);
      ArrayFree(variance);
   }

   //+------------------------------------------------------------------+
   //| Fit — Estima os parâmetros do GARCH                              |
   //+------------------------------------------------------------------+
   // Recebe resíduos (erros) e estima ω, α, β usando otimização
   // iterativa com gradient descent
   //
   void Fit(const double &residuals[], int max_iterations = 200, double learning_rate = 0.001)
   {
      int n = ArraySize(residuals);
      observations = n;

      // Validação
      if(n < p + q + 10)
      {
         Print("ERRO: Série de resíduos muito curta para GARCH(", p, ",", q, ")");
         return;
      }

      // ── Inicialização ──
      omega = 0.1;
      ArrayInitialize(alpha, 0.05);
      ArrayInitialize(beta, 0.8);

      // Array para armazenar variâncias calculadas
      ArrayResize(variance, n);
      ArrayInitialize(variance, 0.0);

      // Variância incondicional inicial
      double unconditional_var = 0.0;
      for(int i = 0; i < n; i++)
         unconditional_var += residuals[i] * residuals[i];
      unconditional_var /= n;

      // ── Loop de otimização (Gradient Descent) ──
      for(int iter = 0; iter < max_iterations; iter++)
      {
         // Taxa de aprendizado adaptativa
         double lr = learning_rate / (1.0 + 0.01 * iter);

         // ── Forward pass: calcular variâncias com parâmetros atuais ──
         for(int t = MathMax(p, q); t < n; t++)
         {
            double var_t = omega;

            // Componente ARCH: α·ε²(t-i)
            for(int i = 0; i < p && (t - 1 - i) >= 0; i++)
               var_t += alpha[i] * residuals[t - 1 - i] * residuals[t - 1 - i];

            // Componente GARCH: β·σ²(t-j)
            for(int j = 0; j < q && (t - 1 - j) >= 0; j++)
               var_t += beta[j] * variance[t - 1 - j];

            // Evitar variância negativa ou muito pequena
            variance[t] = MathMax(1e-8, var_t);
         }

         // ── Backward pass: calcular gradientes ──
         // Usamos log-likelihood Gaussiana: -0.5 * (ln(σ²) + ε²/σ²)
         double grad_omega = 0.0;
         double grad_alpha[];
         double grad_beta[];
         ArrayResize(grad_alpha, p);
         ArrayResize(grad_beta, q);
         ArrayInitialize(grad_alpha, 0.0);
         ArrayInitialize(grad_beta, 0.0);

         int count = 0;
         for(int t = MathMax(p, q); t < n; t++)
         {
            if(variance[t] < 1e-8) continue;

            double e_sq = residuals[t] * residuals[t];
            double var_inv = 1.0 / variance[t];

            // Derivada do log-likelihood em relação ao parâmetro
            double factor = -0.5 * (var_inv - e_sq * var_inv * var_inv);

            grad_omega += factor;

            // Gradientes ARCH
            for(int i = 0; i < p && (t - 1 - i) >= 0; i++)
            {
               double eps_sq = residuals[t - 1 - i] * residuals[t - 1 - i];
               grad_alpha[i] += factor * eps_sq;
            }

            // Gradientes GARCH
            for(int j = 0; j < q && (t - 1 - j) >= 0; j++)
               grad_beta[j] += factor * variance[t - 1 - j];

            count++;
         }

         // Normalizar gradientes
         if(count > 0)
         {
            double inv_count = 1.0 / count;
            grad_omega *= inv_count;
            for(int i = 0; i < p; i++) grad_alpha[i] *= inv_count;
            for(int j = 0; j < q; j++) grad_beta[j] *= inv_count;
         }

         // ── Atualizar parâmetros ──
         omega -= lr * grad_omega;
         for(int i = 0; i < p; i++) alpha[i] -= lr * grad_alpha[i];
         for(int j = 0; j < q; j++) beta[j] -= lr * grad_beta[j];

         // ── Constraints: garantir estabilidade ──
         omega = MathMax(1e-6, MathMin(10.0, omega));

         for(int i = 0; i < p; i++)
            alpha[i] = MathMax(0.0, MathMin(0.5, alpha[i]));

         for(int j = 0; j < q; j++)
            beta[j] = MathMax(0.0, MathMin(0.99, beta[j]));

         // Verificar convergência (α + β < 1)
         double sum_coefs = 0.0;
         for(int i = 0; i < p; i++) sum_coefs += alpha[i];
         for(int j = 0; j < q; j++) sum_coefs += beta[j];

         if(sum_coefs >= 0.99)
         {
            // Reduzir β para garantir estabilidade
            double reduction = (sum_coefs - 0.95) / q;
            for(int j = 0; j < q; j++)
               beta[j] -= reduction;
         }
      }

      Print("✓ GARCH(", p, ",", q, ") ajustado | ω=", DoubleToString(omega, 6),
            " α+β=", DoubleToString(GetSumCoefficients(), 6));
   }

   //+------------------------------------------------------------------+
   //| GetVarianceSeries — Retorna a série de variância                  |
   //+------------------------------------------------------------------+
   bool GetVarianceSeries(double &out_variance[])
   {
      if(ArraySize(variance) == 0)
      {
         Print("ERRO: Modelo não foi ajustado. Chame Fit() antes.");
         return false;
      }

      ArrayCopy(out_variance, variance);
      return true;
   }

   //+------------------------------------------------------------------+
   //| GetVolatilitySeries — Retorna a série de volatilidade (√σ²)      |
   //+------------------------------------------------------------------+
   bool GetVolatilitySeries(double &out_volatility[])
   {
      if(ArraySize(variance) == 0)
      {
         Print("ERRO: Modelo não foi ajustado. Chame Fit() antes.");
         return false;
      }

      int n = ArraySize(variance);
      ArrayResize(out_volatility, n);

      for(int i = 0; i < n; i++)
         out_volatility[i] = MathSqrt(variance[i]);

      return true;
   }

   //+------------------------------------------------------------------+
   //| ForecastVariance — Prevê a variância para h períodos à frente     |
   //+------------------------------------------------------------------+
   bool ForecastVariance(int steps, double &forecast[])
   {
      if(ArraySize(variance) == 0)
      {
         Print("ERRO: Modelo não foi ajustado. Chame Fit() antes.");
         return false;
      }

      int n = ArraySize(variance);
      ArrayResize(forecast, steps);

      // Cópia das últimas variâncias para usar na previsão
      double last_variances[];
      ArrayResize(last_variances, MathMax(p, q));

      int start_idx = n - MathMax(p, q);
      for(int i = 0; i < MathMax(p, q) && (start_idx + i) < n; i++)
         last_variances[i] = variance[start_idx + i];

      // Previsão iterativa
      for(int h = 0; h < steps; h++)
      {
         double var_h = omega;

         // ARCH: α·ε²(t-i)
         // Para previsão, usamos 0 pois ε futuro é desconhecido
         // Alternativa: usar a variância condicional esperada

         // GARCH: β·σ²(t-j)
         for(int j = 0; j < q; j++)
         {
            int idx = h - 1 - j;
            if(idx >= 0)
               var_h += beta[j] * forecast[idx];
            else if((n - MathMax(p, q) + idx) >= 0)
               var_h += beta[j] * variance[n - MathMax(p, q) + idx];
         }

         forecast[h] = MathMax(1e-8, var_h);
      }

      return true;
   }

   //+------------------------------------------------------------------+
   //| ForecastVolatility — Prevê a volatilidade (desvio padrão)         |
   //+------------------------------------------------------------------+
   bool ForecastVolatility(int steps, double &forecast[])
   {
      double var_forecast[];
      if(!ForecastVariance(steps, var_forecast))
         return false;

      int n = ArraySize(var_forecast);
      ArrayResize(forecast, n);

      for(int i = 0; i < n; i++)
         forecast[i] = MathSqrt(var_forecast[i]);

      return true;
   }

   //+------------------------------------------------------------------+
   //| GetCurrentVolatility — Retorna a volatilidade atual                |
   //+------------------------------------------------------------------+
   double GetCurrentVolatility()
   {
      if(ArraySize(variance) == 0)
         return 0.0;

      int n = ArraySize(variance);
      return MathSqrt(variance[n - 1]);
   }

   //+------------------------------------------------------------------+
   //| GetParameters — Retorna os parâmetros estimados                    |
   //+------------------------------------------------------------------+
   void GetParameters(double &out_omega, double &out_alpha[], double &out_beta[])
   {
      out_omega = omega;
      ArrayCopy(out_alpha, alpha);
      ArrayCopy(out_beta, beta);
   }

   //+------------------------------------------------------------------+
   //| GetSumCoefficients — Retorna α + β (medida de persistência)        |
   //+------------------------------------------------------------------+
   double GetSumCoefficients()
   {
      double sum = 0.0;
      for(int i = 0; i < p; i++) sum += alpha[i];
      for(int j = 0; j < q; j++) sum += beta[j];
      return sum;
   }

   //+------------------------------------------------------------------+
   //| Diagnostics — Retorna informações de diagnóstico                  |
   //+------------------------------------------------------------------+
   void Diagnostics()
   {
      Print("──────────────────────────────────");
      Print("GARCH(", p, ",", q, ") Diagnósticos");
      Print("──────────────────────────────────");

      Print("ω (constante): ", DoubleToString(omega, 8));

      string alpha_str = "α = [";
      for(int i = 0; i < p; i++)
         alpha_str += StringFormat("%.6f%s", alpha[i], (i < p - 1) ? ", " : "");
      alpha_str += "]";
      Print(alpha_str);

      string beta_str = "β = [";
      for(int j = 0; j < q; j++)
         beta_str += StringFormat("%.6f%s", beta[j], (j < q - 1) ? ", " : "");
      beta_str += "]";
      Print(beta_str);

      double sum = GetSumCoefficients();
      Print("Persistência (α+β): ", DoubleToString(sum, 6));

      if(sum < 1.0)
         Print("✓ Modelo é mean-reverting");
      else if(sum >= 1.0)
         Print("⚠ Volatilidade é altamente persistente");

      if(ArraySize(variance) > 0)
      {
         double vol_current = GetCurrentVolatility();
         Print("Volatilidade atual: ", DoubleToString(vol_current, 6));
      }

      Print("──────────────────────────────────");
   }
};

//+------------------------------------------------------------------+
