//+------------------------------------------------------------------+
//|                                                   Estrategia.mqh |
//|                            Trabalho de Graduacao - FATEC Indaiatuba|
//+------------------------------------------------------------------+
//|                                                                  |
//|  COMO O GARCH PROTEGE O CAPITAL                                  |
//|                                                                  |
//|  O ARIMA responde "PARA ONDE o preco vai".                       |
//|  O GARCH responde "QUANTA INCERTEZA existe nessa resposta".      |
//|                                                                  |
//|  O GARCH nunca gera sinal de direcao. Ele so decide SE vale a    |
//|  pena operar e COM QUANTO. Essa separacao de papeis e o que      |
//|  torna o modelo combinado defensavel: acrescentar o GARCH nao    |
//|  pode inventar operacoes novas, apenas suprimir ou redimensionar |
//|  as que o ARIMA ja propos.                                       |
//|                                                                  |
//|  As tres abordagens sao as descritas na fundamentacao teorica:   |
//|                                                                  |
//|  1) FILTRO DE VOLATILIDADE                                       |
//|     Nao opera quando a volatilidade prevista passa de um limiar. |
//|     Evita mercados turbulentos. E a mais conservadora e a que a  |
//|     fundamentacao aponta como mais prudente para ativos          |
//|     volateis.                                                    |
//|                                                                  |
//|  2) VOLATILITY TARGETING                                         |
//|     Sempre opera, mas dimensiona a posicao para manter o RISCO   |
//|     constante:  volume = volume_base * (vol_alvo / vol_prevista) |
//|     Dobrou a volatilidade, corta o volume pela metade.           |
//|                                                                  |
//|  3) INTERVALO DE CONFIANCA                                       |
//|     So opera quando a previsao do ARIMA e grande em relacao ao   |
//|     ruido:  |previsao| > k * volatilidade                        |
//|     Traduz "o sinal precisa superar o ruido para valer a pena".  |
//|                                                                  |
//+------------------------------------------------------------------+
#ifndef ALGOTRADINGLAB_ESTRATEGIA_MQH
#define ALGOTRADINGLAB_ESTRATEGIA_MQH

//+------------------------------------------------------------------+
//| Como o GARCH e usado na decisao                                  |
//+------------------------------------------------------------------+
enum ENUM_ESTRATEGIA_GARCH
  {
   EST_FILTRO_VOLATILIDADE = 0,   // Filtro de volatilidade
   EST_VOLATILITY_TARGETING = 1,  // Volatility targeting (dimensiona volume)
   EST_INTERVALO_CONFIANCA = 2,   // Intervalo de confianca
   EST_FILTRO_E_TARGETING = 3     // Filtro + targeting combinados
  };

//+------------------------------------------------------------------+
//| Como o limiar de volatilidade e definido                         |
//+------------------------------------------------------------------+
//|                                                                  |
//|  ABSOLUTO  — valor fixo. So faz sentido se a serie estiver em    |
//|              log-retornos, onde 0,02 significa "2% ao dia" para  |
//|              qualquer ativo e qualquer preco.                    |
//|                                                                  |
//|  PERCENTIL — o limiar e um percentil da propria volatilidade     |
//|              historica estimada pelo GARCH. Ex.: percentil 70    |
//|              significa "opere nos 70% de dias mais calmos".      |
//|              Adapta-se sozinho ao ativo e ao regime de mercado.  |
//|                                                                  |
//+------------------------------------------------------------------+
enum ENUM_MODO_LIMIAR
  {
   LIMIAR_ABSOLUTO = 0,   // Valor absoluto
   LIMIAR_PERCENTIL = 1   // Percentil da volatilidade historica
  };

//+------------------------------------------------------------------+
//| Decisao produzida a cada barra                                   |
//+------------------------------------------------------------------+
struct DecisaoOperacao
  {
   int      sinal;              // +1 compra, -1 venda, 0 nada
   double   volume;             // volume sugerido (antes do ajuste do simbolo)
   double   previsao;           // previsao do ARIMA no espaco diferenciado
   double   vol_prevista;       // volatilidade prevista pelo GARCH
   double   limiar_efetivo;     // limiar aplicado nesta barra
   bool     bloqueou_garch;     // o GARCH vetou a operacao?
   string   motivo;             // explicacao legivel, para o log
  };

//+------------------------------------------------------------------+
//| Percentil de uma amostra (interpolacao linear)                   |
//+------------------------------------------------------------------+
double Percentil(const double &x[], const double pct)
  {
   int n = ArraySize(x);
   if(n <= 0)
      return(0.0);
   if(n == 1)
      return(x[0]);

   double copia[];
   ArrayResize(copia, n);
   ArrayCopy(copia, x);
   ArraySort(copia);

   double p = MathMax(0.0, MathMin(100.0, pct)) / 100.0;
   double pos = p * (double)(n - 1);

   int i = (int)MathFloor(pos);
   double frac = pos - (double)i;

   if(i >= n - 1)
      return(copia[n - 1]);

   return(copia[i] * (1.0 - frac) + copia[i + 1] * frac);
  }

//+------------------------------------------------------------------+
//| DECIDIR A OPERACAO                                               |
//+------------------------------------------------------------------+
//|                                                                  |
//|  ENTRADA                                                         |
//|    previsao      — previsao do ARIMA no espaco DIFERENCIADO.     |
//|                    Com log-precos e d=1, e o log-retorno         |
//|                    esperado do proximo periodo.                  |
//|    vol_prevista  — volatilidade prevista pelo GARCH, na MESMA    |
//|                    unidade da previsao. Ignorada se usar_garch   |
//|                    for false.                                    |
//|    limiar        — limiar ja resolvido (absoluto ou vindo do     |
//|                    percentil)                                    |
//|    vol_alvo      — volatilidade de referencia do targeting       |
//|    k_confianca   — quantos desvios-padrao a previsao precisa     |
//|                    superar                                       |
//|    volume_base   — volume padrao                                 |
//|    frac_min/max  — limites do volume como fracao do volume_base, |
//|                    para o targeting nao explodir nem zerar       |
//|    limiar_sinal  — previsao minima (em modulo) para operar.      |
//|                    Filtra ruido mesmo sem GARCH.                 |
//|                                                                  |
//+------------------------------------------------------------------+
void DecidirOperacao(const double previsao,
                     const double vol_prevista,
                     const bool usar_garch,
                     const ENUM_ESTRATEGIA_GARCH estrategia,
                     const double limiar,
                     const double vol_alvo,
                     const double k_confianca,
                     const double volume_base,
                     const double frac_min,
                     const double frac_max,
                     const double limiar_sinal,
                     DecisaoOperacao &d)
  {
   d.sinal = 0;
   d.volume = volume_base;
   d.previsao = previsao;
   d.vol_prevista = vol_prevista;
   d.limiar_efetivo = limiar;
   d.bloqueou_garch = false;
   d.motivo = "";

   //--- ── Direcao: vem SEMPRE e SOMENTE do ARIMA ──
   int direcao = 0;
   if(previsao > limiar_sinal)
      direcao = 1;
   else if(previsao < -limiar_sinal)
      direcao = -1;

   if(direcao == 0)
     {
      d.motivo = StringFormat("Previsao %.6f abaixo do limiar de sinal %.6f",
                              previsao, limiar_sinal);
      return;
     }

   //--- ── Sem GARCH: opera direto no sinal do ARIMA ──
   //--- Este e o caminho do modelo ARIMA puro. Note que ele e
   //--- IDENTICO ao caminho com GARCH ate aqui: a comparacao entre
   //--- os dois modelos isola exatamente o efeito do GARCH.
   if(!usar_garch)
     {
      d.sinal = direcao;
      d.motivo = "ARIMA puro (GARCH desativado)";
      return;
     }

   //--- ── Volatilidade invalida: por seguranca, nao opera ──
   if(vol_prevista <= 0.0 || !MathIsValidNumber(vol_prevista))
     {
      d.bloqueou_garch = true;
      d.motivo = "Volatilidade prevista invalida";
      return;
     }

   //--- ── 1) FILTRO DE VOLATILIDADE ──
   bool aplica_filtro = (estrategia == EST_FILTRO_VOLATILIDADE ||
                         estrategia == EST_FILTRO_E_TARGETING);

   if(aplica_filtro && vol_prevista > limiar)
     {
      d.bloqueou_garch = true;
      d.motivo = StringFormat("FILTRO: vol prevista %.6f > limiar %.6f - sem operacao",
                              vol_prevista, limiar);
      return;
     }

   //--- ── 3) INTERVALO DE CONFIANCA ──
   if(estrategia == EST_INTERVALO_CONFIANCA)
     {
      double exigido = k_confianca * vol_prevista;

      if(MathAbs(previsao) <= exigido)
        {
         d.bloqueou_garch = true;
         d.motivo = StringFormat("IC: |previsao| %.6f <= %.1f x vol %.6f = %.6f - sinal dentro do ruido",
                                 MathAbs(previsao), k_confianca, vol_prevista, exigido);
         return;
        }

      d.sinal = direcao;
      d.motivo = StringFormat("IC: |previsao| %.6f > %.6f - sinal supera o ruido",
                              MathAbs(previsao), exigido);
      return;
     }

   //--- ── 2) VOLATILITY TARGETING ──
   bool aplica_targeting = (estrategia == EST_VOLATILITY_TARGETING ||
                            estrategia == EST_FILTRO_E_TARGETING);

   if(aplica_targeting)
     {
      double fator = vol_alvo / vol_prevista;

      //--- Limita para o volume nao explodir em mercado parado
      //--- nem virar po em mercado agitado
      fator = MathMax(frac_min, MathMin(frac_max, fator));

      d.volume = volume_base * fator;
      d.sinal = direcao;
      d.motivo = StringFormat("TARGETING: vol %.6f, fator %.3f, volume %.4f",
                              vol_prevista, fator, d.volume);
      return;
     }

   //--- ── Filtro puro aprovado ──
   d.sinal = direcao;
   d.motivo = StringFormat("FILTRO: vol prevista %.6f <= limiar %.6f - operacao liberada",
                           vol_prevista, limiar);
  }

#endif // ALGOTRADINGLAB_ESTRATEGIA_MQH
//+------------------------------------------------------------------+
