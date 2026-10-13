   //+------------------------------------------------------------------+
   //|                                                     ARIMA_EA.mq5 |
   //|                          Copyright 2026, MQL5 Algo Forge/gsloose |
   //|                                             https://www.mql5.com |
   //+------------------------------------------------------------------+
   #property copyright "MQL5 Algo Forge / gsloose"
   #property link      "https://www.mql5.com"
   #property version   "1.00"
   #property description "Expert Advisor baseado em modelo ARIMA(p,d,q)"
   #property description "Implementação pura em MQL5 — sem dependências externas"
   #property description ""
   #property description "ARIMA = AutoRegressive Integrated Moving Average"
   #property description "  AR(p): Regressão sobre os 'p' valores passados diferenciados"
   #property description "  I(d) : Diferenciação de ordem 'd' para tornar a série estacionária"
   #property description "  MA(q): Regressão sobre os 'q' erros de previsão passados"

   //+------------------------------------------------------------------+
   //| EXPLICAÇÃO GERAL DO MODELO ARIMA                                 |
   //+------------------------------------------------------------------+
   //
   // ══════════════════════════════════════════════════════════════════
   //  O QUE É ARIMA?
   // ══════════════════════════════════════════════════════════════════
   //
   //  ARIMA(p, d, q) combina três ideias:
   //
   //  1. AR (AutoRegressivo) — ordem p
   //     O valor atual depende de 'p' valores passados.
   //     Equação: y(t) = φ₁·y(t-1) + φ₂·y(t-2) + ... + φₚ·y(t-p) + ε(t)
   //     Analogia: "O preço de amanhã é uma média ponderada dos últimos p preços"
   //
   //  2. I (Integrado) — ordem d
   //     Diferenciamos a série 'd' vezes para remover tendência.
   //     d=1: z(t) = y(t) - y(t-1)       (variação entre barras)
   //     d=2: z(t) = Δy(t) - Δy(t-1)     (variação da variação)
   //     Analogia: "Ao invés de prever o preço, prevemos a MUDANÇA do preço"
   //
   //  3. MA (Média Móvel dos Erros) — ordem q
   //     Corrigimos a previsão usando os erros passados.
   //     Equação: y(t) = ε(t) + θ₁·ε(t-1) + θ₂·ε(t-2) + ... + θq·ε(t-q)
   //     Analogia: "Se errei muito ontem, ajusto minha previsão de hoje"
   //
   //  Equação completa ARIMA (após diferenciação):
   //     z(t) = c + φ₁·z(t-1) + ... + φₚ·z(t-p)
   //              + ε(t) + θ₁·ε(t-1) + ... + θq·ε(t-q)
   //
   //  Onde:
   //     z(t) = série diferenciada d vezes
   //     φ    = coeficientes AR (autorregressivos)
   //     θ    = coeficientes MA (média móvel dos erros)
   //     c    = constante (intercepto)
   //     ε(t) = erro/resíduo no tempo t
   //
   // ══════════════════════════════════════════════════════════════════
   //  COMO ESTIMAMOS OS PARÂMETROS?
   // ══════════════════════════════════════════════════════════════════
   //
   //  Usamos o método CSS (Conditional Sum of Squares):
   //  - Minimizamos a soma dos quadrados dos resíduos ε(t)²
   //  - Otimização via Gradiente Descendente iterativo
   //  - É o método mais prático para implementação em MQL5
   //    (métodos como MLE exigem inversão de matrizes grandes)
   //
   // ══════════════════════════════════════════════════════════════════
   //  FLUXO DO EA
   // ══════════════════════════════════════════════════════════════════
   //
   //  1. A cada nova barra, coletamos N preços de fechamento
   //  2. Aplicamos diferenciação de ordem d
   //  3. Estimamos coeficientes φ e θ via CSS
   //  4. Fazemos previsão do próximo valor diferenciado
   //  5. Revertemos a diferenciação para obter preço previsto
   //  6. Se preço previsto > preço atual → COMPRA
   //     Se preço previsto < preço atual → VENDA
   //
   // ══════════════════════════════════════════════════════════════════

   #include <Trade\Trade.mqh>

   //+------------------------------------------------------------------+
   //| PARÂMETROS DE ENTRADA DO USUÁRIO                                 |
   //+------------------------------------------------------------------+
   // Estes são os valores que você configura ao colocar o EA no gráfico.

   input group "═══ Parâmetros do Modelo ARIMA(p,d,q) ═══"
   input int    ARIMA_p             = 3;      // p (AR): Quantos preços passados usar na regressão
   input int    ARIMA_d             = 1;      // d (I) : Ordem de diferenciação (1 = prever mudanças)
   input int    ARIMA_q             = 2;      // q (MA): Quantos erros passados usar na correção
   input int    Janela_Dados        = 200;    // Quantidade de barras para treinar o modelo
   input int    Iteracoes_Treino    = 300;    // Iterações do gradiente descendente
   input double Taxa_Aprendizado    = 0.001;  // Taxa de aprendizado (learning rate)

   input group "═══ Parâmetros de Negociação ═══"
   input double Volume_Fixo         = 1.0;    // Volume da operação (lotes)
   input int    StopLoss_Points     = 100;    // Stop Loss em pontos
   input int    TakeProfit_Points   = 200;    // Take Profit em pontos
   input ulong  MagicNumber         = 20260306; // Número mágico (identifica este EA)
   input int    Slippage_Points     = 10;     // Slippage máximo em pontos
   input double Limiar_Sinal        = 0.0;    // Limiar mínimo de previsão para abrir ordem (0 = qualquer)
   input bool   TradeOnNewBarOnly   = true;   // Operar apenas na abertura de nova barra

   input group "═══ Diagnóstico ═══"
   input bool   Mostrar_Diagnostico = true;   // Imprimir diagnósticos no log (aba Experts)

   //+------------------------------------------------------------------+
   //| VARIÁVEIS GLOBAIS DO EA                                          |
   //+------------------------------------------------------------------+

   CTrade Trade;                     // Objeto da biblioteca padrão para executar ordens

   // Coeficientes do modelo ARIMA — estimados a cada barra
   double gl_phi[];                  // φ₁..φₚ — coeficientes AR
   double gl_theta[];                // θ₁..θq — coeficientes MA
   double gl_constante;              // c — intercepto

   // Controle
   int    gl_DigitsPrice;            // Casas decimais do símbolo
   double gl_VolumeOperacional;      // Volume ajustado aos limites do símbolo

   //+------------------------------------------------------------------+
   //| INICIALIZAÇÃO — executada uma vez ao carregar o EA               |
   //+------------------------------------------------------------------+
   int OnInit()
   {
      // ── Validação dos parâmetros ARIMA ──
      // p e q devem ser >= 0, d entre 0 e 2, janela grande o suficiente
      if(ARIMA_p < 0 || ARIMA_q < 0 || ARIMA_d < 0 || ARIMA_d > 2)
      {
         Print("ERRO: Parâmetros ARIMA inválidos. p>=0, q>=0, 0<=d<=2");
         return(INIT_FAILED);
      }
      
      int minimo_necessario = ARIMA_p + ARIMA_d + ARIMA_q + 20; // margem de segurança
      if(Janela_Dados < minimo_necessario)
      {
         PrintFormat("ERRO: Janela_Dados(%d) muito pequena. Mínimo necessário: %d", 
                     Janela_Dados, minimo_necessario);
         return(INIT_FAILED);
      }

      // ── Aloca arrays dos coeficientes ──
      ArrayResize(gl_phi, ARIMA_p);
      ArrayResize(gl_theta, ARIMA_q);
      ArrayInitialize(gl_phi, 0.0);
      ArrayInitialize(gl_theta, 0.0);
      gl_constante = 0.0;

      // ── Configura objeto de negociação ──
      Trade.SetExpertMagicNumber(MagicNumber);
      Trade.SetDeviationInPoints(Slippage_Points);
      Trade.SetTypeFillingBySymbol(_Symbol);

      gl_DigitsPrice = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

      // ── Ajusta volume aos limites do símbolo ──
      gl_VolumeOperacional = AjustarVolume(Volume_Fixo);

      PrintFormat("ARIMA(%d,%d,%d) inicializado | Janela=%d | Volume=%.2f | Símbolo=%s",
                  ARIMA_p, ARIMA_d, ARIMA_q, Janela_Dados, gl_VolumeOperacional, _Symbol);

      return(INIT_SUCCEEDED);
   }

   //+------------------------------------------------------------------+
   //| DESINICIALIZAÇÃO — limpeza ao remover o EA                       |
   //+------------------------------------------------------------------+
   void OnDeinit(const int reason)
   {
      Print("ARIMA EA removido. Razão: ", reason);
   }

   //+------------------------------------------------------------------+
   //| A CADA TICK — lógica principal do EA                             |
   //+------------------------------------------------------------------+
   void OnTick()
   {
      // ══════════════════════════════════════════════════════════════
      // PASSO 0: Verificar se é nova barra (se configurado)
      // ══════════════════════════════════════════════════════════════
      // Operar apenas na abertura de nova barra evita ruído intra-bar
      // e reduz custo computacional (ARIMA recalcula a cada chamada)
      
      if(TradeOnNewBarOnly)
      {
         static datetime ultimaBarra = 0;
         datetime barraAtual = (datetime)SeriesInfoInteger(_Symbol, _Period, SERIES_LASTBAR_DATE);
         if(barraAtual == ultimaBarra) return;
         ultimaBarra = barraAtual;
      }

      // ══════════════════════════════════════════════════════════════
      // PASSO 1: Coletar dados de preço (fechamento das últimas barras)
      // ══════════════════════════════════════════════════════════════
      // Copiamos Janela_Dados+1 preços para ter margem na diferenciação
      
      double precos[];
      int copiados = CopyClose(_Symbol, _Period, 0, Janela_Dados + 1, precos);
      if(copiados < Janela_Dados + 1)
      {
         Print("Dados insuficientes: copiados=", copiados, " necessários=", Janela_Dados + 1);
         return;
      }

      // ══════════════════════════════════════════════════════════════
      // PASSO 2: Diferenciação — transformar série para estacionária
      // ══════════════════════════════════════════════════════════════
      // A diferenciação remove tendência. Após d=1:
      //   z(t) = preço(t) - preço(t-1)
      // Isso nos dá os "retornos" ou "variações" entre barras.
      // Se d=2, diferenciamos novamente a série já diferenciada.
      
      double serie_diff[];
      Diferenciar(precos, serie_diff, ARIMA_d);
      
      int tamanho_serie = ArraySize(serie_diff);
      if(tamanho_serie < ARIMA_p + ARIMA_q + 20)
      {
         Print("Série diferenciada muito curta: ", tamanho_serie);
         return;
      }

      // ══════════════════════════════════════════════════════════════
      // PASSO 3: Estimar coeficientes φ, θ, c via CSS
      // ══════════════════════════════════════════════════════════════
      // CSS = Conditional Sum of Squares
      // Inicializamos φ, θ em 0 e iterativamente ajustamos usando
      // gradiente descendente para minimizar Σ ε(t)²
      //
      // A cada iteração:
      //   1. Calculamos todos os resíduos ε(t) com coeficientes atuais
      //   2. Calculamos o gradiente (derivada parcial) de cada coeficiente
      //   3. Atualizamos: coeficiente -= taxa_aprendizado × gradiente
      
      EstimarCoeficientesCSS(serie_diff);

      // ══════════════════════════════════════════════════════════════
      // PASSO 4: Fazer previsão do próximo valor diferenciado
      // ══════════════════════════════════════════════════════════════
      // Com os coeficientes estimados, calculamos:
      //   z_prev = c + φ₁·z(n) + φ₂·z(n-1) + ... + θ₁·ε(n) + θ₂·ε(n-1) + ...
      // Onde z(n) é o último valor da série diferenciada
      
      // Primeiro, calculamos os resíduos finais para ter ε disponível
      double residuos[];
      CalcularResiduos(serie_diff, residuos);
      
      // Agora a previsão propriamente dita
      double previsao_diff = PreverProximoValor(serie_diff, residuos);

      // ══════════════════════════════════════════════════════════════
      // PASSO 5: Reverter diferenciação — obter preço previsto
      // ══════════════════════════════════════════════════════════════
      // Se d=1: preço_previsto = preço_atual + z_previsto
      // Se d=2: precisa reverter duas vezes
      // Isso transforma nossa previsão de "variação" de volta para "preço"
      
      double preco_previsto = ReverterDiferenciacao(precos, previsao_diff, ARIMA_d);
      double preco_atual    = precos[ArraySize(precos) - 1];
      double diferenca      = preco_previsto - preco_atual;

      // ══════════════════════════════════════════════════════════════
      // PASSO 6: Diagnóstico — mostrar informações no log
      // ══════════════════════════════════════════════════════════════
      
      if(Mostrar_Diagnostico)
      {
         PrintFormat("─── ARIMA(%d,%d,%d) Diagnóstico ───", ARIMA_p, ARIMA_d, ARIMA_q);
         PrintFormat("Preço Atual:   %.%dG", gl_DigitsPrice, preco_atual);
         PrintFormat("Preço Previsto:%.%dG", gl_DigitsPrice, preco_previsto);
         PrintFormat("Diferença:     %.%dG (%.4f%%)", gl_DigitsPrice, diferenca, 
                     (preco_atual != 0) ? (diferenca / preco_atual) * 100.0 : 0.0);
         PrintFormat("Constante c:   %.8f", gl_constante);
         
         string phi_str = "φ = [";
         for(int i = 0; i < ARIMA_p; i++)
            phi_str += StringFormat("%.6f%s", gl_phi[i], (i < ARIMA_p - 1) ? ", " : "");
         phi_str += "]";
         Print(phi_str);
         
         string theta_str = "θ = [";
         for(int i = 0; i < ARIMA_q; i++)
            theta_str += StringFormat("%.6f%s", gl_theta[i], (i < ARIMA_q - 1) ? ", " : "");
         theta_str += "]";
         Print(theta_str);
         Print("────────────────────────────────");
      }

      // ══════════════════════════════════════════════════════════════
      // PASSO 7: Gerar sinal de negociação
      // ══════════════════════════════════════════════════════════════
      // Lógica simples:
      //   preço_previsto > preço_atual + limiar → COMPRA
      //   preço_previsto < preço_atual - limiar → VENDA
      //
      // O limiar evita abrir ordens quando a previsão é muito pequena
      // (potencialmente ruído). Ajuste conforme o ativo.
      
      double limiar_price = Limiar_Sinal * _Point;

      MqlTick tick;
      if(!SymbolInfoTick(_Symbol, tick) || tick.ask == 0 || tick.bid == 0) return;

      ENUM_POSITION_TYPE posicaoAtual = ObterTipoPosicaoAtual();

      // ── Sinal de COMPRA ──
      if(diferenca > limiar_price)
      {
         // Se temos venda aberta, fechamos primeiro (reversão)
         if(posicaoAtual == POSITION_TYPE_SELL)
         {
            if(!FecharPosicaoAtual(POSITION_TYPE_SELL)) return;
            Sleep(100);
            posicaoAtual = ObterTipoPosicaoAtual();
         }
         
         // Abre compra se não temos posição comprada
         if(posicaoAtual != POSITION_TYPE_BUY)
         {
            double sl = 0, tp = 0;
            if(StopLoss_Points > 0)
               sl = NormalizeDouble(tick.ask - StopLoss_Points * _Point, gl_DigitsPrice);
            if(TakeProfit_Points > 0)
               tp = NormalizeDouble(tick.ask + TakeProfit_Points * _Point, gl_DigitsPrice);
            
            Trade.Buy(gl_VolumeOperacional, _Symbol, tick.ask, sl, tp, 
                     StringFormat("ARIMA BUY prev=%.5f", preco_previsto));
         }
      }
      // ── Sinal de VENDA ──
      else if(diferenca < -limiar_price)
      {
         if(posicaoAtual == POSITION_TYPE_BUY)
         {
            if(!FecharPosicaoAtual(POSITION_TYPE_BUY)) return;
            Sleep(100);
            posicaoAtual = ObterTipoPosicaoAtual();
         }
         
         if(posicaoAtual != POSITION_TYPE_SELL)
         {
            double sl = 0, tp = 0;
            if(StopLoss_Points > 0)
               sl = NormalizeDouble(tick.bid + StopLoss_Points * _Point, gl_DigitsPrice);
            if(TakeProfit_Points > 0)
               tp = NormalizeDouble(tick.bid - TakeProfit_Points * _Point, gl_DigitsPrice);
            
            Trade.Sell(gl_VolumeOperacional, _Symbol, tick.bid, sl, tp,
                     StringFormat("ARIMA SELL prev=%.5f", preco_previsto));
         }
      }
   }


   //+══════════════════════════════════════════════════════════════════+
   //|                                                                  |
   //|               FUNÇÕES DO MODELO ARIMA                            |
   //|                                                                  |
   //+══════════════════════════════════════════════════════════════════+


   //+------------------------------------------------------------------+
   //| DIFERENCIAÇÃO — Torna a série estacionária                       |
   //+------------------------------------------------------------------+
   // 
   // Séries de preços têm tendência (não são estacionárias).
   // ARIMA precisa de série estacionária (média e variância constantes).
   //
   // Diferenciação de ordem 1:
   //   z(t) = y(t) - y(t-1)
   //   Isso nos dá as "variações" ou "retornos" entre barras.
   //   Ex: preços [100, 102, 101, 105] → diferenciado [2, -1, 4]
   //
   // Diferenciação de ordem 2:
   //   Aplicamos d=1 duas vezes. Captura aceleração/desaceleração.
   //   Ex: [2, -1, 4] → [-3, 5]
   //
   // Na prática, d=1 é suficiente para a maioria dos ativos financeiros.
   //
   void Diferenciar(const double &original[], double &resultado[], int ordem)
   {
      // Copia a série original
      int n = ArraySize(original);
      ArrayResize(resultado, n);
      ArrayCopy(resultado, original);
      
      // Aplica diferenciação 'ordem' vezes
      for(int d = 0; d < ordem; d++)
      {
         int tam = ArraySize(resultado);
         double temp[];
         ArrayResize(temp, tam - 1);
         
         for(int i = 0; i < tam - 1; i++)
            temp[i] = resultado[i + 1] - resultado[i];
         
         ArrayResize(resultado, tam - 1);
         ArrayCopy(resultado, temp);
      }
   }


   //+------------------------------------------------------------------+
   //| ESTIMAÇÃO CSS — Conditional Sum of Squares                       |
   //+------------------------------------------------------------------+
   //
   // Este é o coração do modelo. Estimamos os coeficientes φ (AR) e θ (MA)
   // minimizando a soma dos quadrados dos resíduos:
   //
   //   Minimizar: Σ ε(t)²
   //
   // Onde ε(t) = z(t) - [c + φ₁·z(t-1) + ... + φₚ·z(t-p) 
   //                          + θ₁·ε(t-1) + ... + θq·ε(t-q)]
   //
   // MÉTODO: Gradiente Descendente
   //   Para cada coeficiente, calculamos a derivada parcial da função
   //   de custo e atualizamos na direção que reduz o erro.
   //
   //   ∂(Σε²)/∂φᵢ = -2·Σ ε(t)·z(t-i)    → gradiente AR
   //   ∂(Σε²)/∂θⱼ = -2·Σ ε(t)·ε(t-j)    → gradiente MA (aproximado)
   //   ∂(Σε²)/∂c  = -2·Σ ε(t)            → gradiente constante
   //
   // NOTA: O gradiente MA é uma aproximação (tratamos ε passados como fixos
   // em cada iteração). Isso é o "Conditional" do CSS.
   //
   void EstimarCoeficientesCSS(const double &serie[])
   {
      int n = ArraySize(serie);
      int inicio = MathMax(ARIMA_p, ARIMA_q); // Índice a partir do qual temos dados suficientes
      
      if(inicio >= n - 1)
      {
         Print("Série muito curta para estimar ARIMA");
         return;
      }

      // ── Inicializa coeficientes ──
      // Começamos com valores pequenos próximos de zero
      ArrayInitialize(gl_phi, 0.0);
      ArrayInitialize(gl_theta, 0.0);
      gl_constante = 0.0;
      
      // Array de resíduos (erros) — necessário para o componente MA
      double epsilon[];
      ArrayResize(epsilon, n);
      ArrayInitialize(epsilon, 0.0);

      // ── Loop de otimização ──
      for(int iter = 0; iter < Iteracoes_Treino; iter++)
      {
         // Taxa de aprendizado adaptativa — diminui com o tempo
         // para convergência mais estável
         double lr = Taxa_Aprendizado / (1.0 + 0.001 * iter);
         
         // ── Forward pass: calcula resíduos com coeficientes atuais ──
         for(int t = inicio; t < n; t++)
         {
            double previsao = gl_constante;
            
            // Componente AR: φ₁·z(t-1) + φ₂·z(t-2) + ... + φₚ·z(t-p)
            for(int i = 0; i < ARIMA_p; i++)
            {
               if(t - 1 - i >= 0)
                  previsao += gl_phi[i] * serie[t - 1 - i];
            }
            
            // Componente MA: θ₁·ε(t-1) + θ₂·ε(t-2) + ... + θq·ε(t-q)
            for(int j = 0; j < ARIMA_q; j++)
            {
               if(t - 1 - j >= 0)
                  previsao += gl_theta[j] * epsilon[t - 1 - j];
            }
            
            // Resíduo: diferença entre valor real e previsto
            epsilon[t] = serie[t] - previsao;
         }
         
         // ── Backward pass: calcula gradientes e atualiza coeficientes ──
         
         // Gradientes acumulados
         double grad_c = 0.0;
         double grad_phi[];
         ArrayResize(grad_phi, ARIMA_p);
         ArrayInitialize(grad_phi, 0.0);
         double grad_theta[];
         ArrayResize(grad_theta, ARIMA_q);
         ArrayInitialize(grad_theta, 0.0);
         
         int contagem = 0;
         for(int t = inicio; t < n; t++)
         {
            double e = epsilon[t];
            
            // Gradiente da constante: -ε(t) (queremos minimizar ε²)
            grad_c -= e;
            
            // Gradientes AR: -ε(t) · z(t-i)
            for(int i = 0; i < ARIMA_p; i++)
            {
               if(t - 1 - i >= 0)
                  grad_phi[i] -= e * serie[t - 1 - i];
            }
            
            // Gradientes MA: -ε(t) · ε(t-j)
            for(int j = 0; j < ARIMA_q; j++)
            {
               if(t - 1 - j >= 0)
                  grad_theta[j] -= e * epsilon[t - 1 - j];
            }
            
            contagem++;
         }
         
         // Normaliza gradientes pela quantidade de amostras
         if(contagem > 0)
         {
            double inv_n = 1.0 / contagem;
            grad_c *= inv_n;
            for(int i = 0; i < ARIMA_p; i++) grad_phi[i]   *= inv_n;
            for(int j = 0; j < ARIMA_q; j++) grad_theta[j]  *= inv_n;
         }
         
         // ── Atualização dos coeficientes (gradiente descendente) ──
         // coeficiente = coeficiente - lr × gradiente
         gl_constante -= lr * grad_c;
         
         for(int i = 0; i < ARIMA_p; i++)
            gl_phi[i] -= lr * grad_phi[i];
         
         for(int j = 0; j < ARIMA_q; j++)
            gl_theta[j] -= lr * grad_theta[j];
         
         // ── Clipping: limita coeficientes para estabilidade ──
         // Sem isso, os coeficientes podem explodir (divergir)
         for(int i = 0; i < ARIMA_p; i++)
            gl_phi[i] = MathMax(-2.0, MathMin(2.0, gl_phi[i]));
         for(int j = 0; j < ARIMA_q; j++)
            gl_theta[j] = MathMax(-2.0, MathMin(2.0, gl_theta[j]));
         gl_constante = MathMax(-1000.0, MathMin(1000.0, gl_constante));
      }
   }


   //+------------------------------------------------------------------+
   //| CALCULAR RESÍDUOS — Erros com os coeficientes finais             |
   //+------------------------------------------------------------------+
   //
   // Após estimar os coeficientes, recalculamos todos os resíduos.
   // Eles são necessários para a previsão (o componente MA usa ε passados).
   //
   // ε(t) = z(t) - [c + Σᵢ φᵢ·z(t-i) + Σⱼ θⱼ·ε(t-j)]
   //
   void CalcularResiduos(const double &serie[], double &residuos[])
   {
      int n = ArraySize(serie);
      int inicio = MathMax(ARIMA_p, ARIMA_q);
      
      ArrayResize(residuos, n);
      ArrayInitialize(residuos, 0.0);
      
      for(int t = inicio; t < n; t++)
      {
         double previsao = gl_constante;
         
         for(int i = 0; i < ARIMA_p; i++)
         {
            if(t - 1 - i >= 0)
               previsao += gl_phi[i] * serie[t - 1 - i];
         }
         
         for(int j = 0; j < ARIMA_q; j++)
         {
            if(t - 1 - j >= 0)
               previsao += gl_theta[j] * residuos[t - 1 - j];
         }
         
         residuos[t] = serie[t] - previsao;
      }
   }


   //+------------------------------------------------------------------+
   //| PREVISÃO — Calcula o próximo valor da série diferenciada         |
   //+------------------------------------------------------------------+
   //
   // Com coeficientes estimados e resíduos calculados, prevemos:
   //
   //   z_futuro = c + φ₁·z(n) + φ₂·z(n-1) + ... + φₚ·z(n-p+1)
   //                + θ₁·ε(n) + θ₂·ε(n-1) + ... + θq·ε(n-q+1)
   //
   // Onde n é o último índice da série.
   // Note: ε(n+1) = 0 pois é o erro futuro (desconhecido).
   //
   double PreverProximoValor(const double &serie[], const double &residuos[])
   {
      int n = ArraySize(serie);
      
      double previsao = gl_constante;
      
      // Componente AR: usa os últimos p valores da série
      for(int i = 0; i < ARIMA_p; i++)
      {
         int idx = n - 1 - i;
         if(idx >= 0)
            previsao += gl_phi[i] * serie[idx];
      }
      
      // Componente MA: usa os últimos q resíduos
      for(int j = 0; j < ARIMA_q; j++)
      {
         int idx = n - 1 - j;
         if(idx >= 0)
            previsao += gl_theta[j] * residuos[idx];
      }
      
      return previsao;
   }


   //+------------------------------------------------------------------+
   //| REVERTER DIFERENCIAÇÃO — De variação para preço absoluto         |
   //+------------------------------------------------------------------+
   //
   // A previsão z_futuro está no espaço diferenciado.
   // Precisamos reverter para obter o preço previsto.
   //
   // Se d=1: preço_previsto = preço_atual + z_futuro
   //   (a variação prevista é somada ao último preço)
   //
   // Se d=2: precisamos reverter duas vezes:
   //   1. Recuperar a "primeira diferença" mais recente
   //   2. preço_previsto = preço_atual + ultima_diff_1 + z_futuro
   //
   double ReverterDiferenciacao(const double &precos_originais[], 
                                 double previsao_diff, int ordem)
   {
      int n = ArraySize(precos_originais);
      
      if(ordem == 0)
         return previsao_diff; // Sem diferenciação, previsão já é o preço
      
      if(ordem == 1)
      {
         // z_futuro = preço_futuro - preço_atual
         // preço_futuro = preço_atual + z_futuro
         return precos_originais[n - 1] + previsao_diff;
      }
      
      if(ordem == 2)
      {
         // Primeira diferença dos preços originais
         double diff1_ultimo = precos_originais[n - 1] - precos_originais[n - 2];
         // previsao_diff é a segunda diferença prevista
         // nova_primeira_diff = ultima_primeira_diff + previsao_diff
         double nova_diff1 = diff1_ultimo + previsao_diff;
         // preço_futuro = preço_atual + nova_primeira_diff
         return precos_originais[n - 1] + nova_diff1;
      }
      
      // Para d > 2 (raro), usa apenas d=1 como fallback
      return precos_originais[n - 1] + previsao_diff;
   }


   //+══════════════════════════════════════════════════════════════════+
   //|                                                                  |
   //|               FUNÇÕES AUXILIARES DE TRADING                      |
   //|                                                                  |
   //+══════════════════════════════════════════════════════════════════+


   //+------------------------------------------------------------------+
   //| Obter tipo da posição atual (BUY, SELL, ou -1 se sem posição)    |
   //+------------------------------------------------------------------+
   ENUM_POSITION_TYPE ObterTipoPosicaoAtual()
   {
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong ticket = PositionGetTicket(i);
         if(ticket > 0 && PositionSelectByTicket(ticket))
         {
            if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
               PositionGetInteger(POSITION_MAGIC) == MagicNumber)
            {
               return (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            }
         }
      }
      return (ENUM_POSITION_TYPE)-1;
   }


   //+------------------------------------------------------------------+
   //| Fechar posição atual de um tipo específico                       |
   //+------------------------------------------------------------------+
   bool FecharPosicaoAtual(ENUM_POSITION_TYPE tipo)
   {
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong ticket = PositionGetTicket(i);
         if(ticket > 0 && PositionSelectByTicket(ticket))
         {
            if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
               PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
               PositionGetInteger(POSITION_TYPE) == tipo)
            {
               if(Trade.PositionClose(ticket, Slippage_Points))
                  return true;
               else
               {
                  Print("Erro ao fechar posição: ", Trade.ResultRetcodeDescription());
                  return false;
               }
            }
         }
      }
      return true; // Sem posição para fechar = OK
   }


   //+------------------------------------------------------------------+
   //| Ajustar volume aos limites do símbolo                            |
   //+------------------------------------------------------------------+
   double AjustarVolume(double volume_desejado)
   {
      double min_vol  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
      double max_vol  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
      double step_vol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
      
      if(volume_desejado < min_vol) volume_desejado = min_vol;
      if(volume_desejado > max_vol) volume_desejado = max_vol;
      
      if(step_vol > 0)
      {
         volume_desejado = MathRound(volume_desejado / step_vol) * step_vol;
         // Determinar casas decimais do step
         int digitos_vol = 0;
         if(step_vol < 1.0)
         {
            string s = DoubleToString(step_vol, 8);
            int dot = StringFind(s, ".");
            if(dot >= 0)
            {
               // Remove zeros à direita para contar dígitos significativos
               int len = StringLen(s);
               while(len > dot + 1 && StringGetCharacter(s, len - 1) == '0') len--;
               digitos_vol = len - dot - 1;
            }
         }
         volume_desejado = NormalizeDouble(volume_desejado, digitos_vol);
      }
      
      if(volume_desejado < min_vol) volume_desejado = min_vol;
      return volume_desejado;
   }
   //+------------------------------------------------------------------+
