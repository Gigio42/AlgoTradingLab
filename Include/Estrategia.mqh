//+------------------------------------------------------------------+
//| Estrategia.mqh                                                   |
//| Decisao de cada barra. A direcao vem so do ARIMA; o GARCH nunca  |
//| cria operacao, so veta ou redimensiona a que o ARIMA propos.     |
//+------------------------------------------------------------------+
#ifndef ALGOTRADINGLAB_ESTRATEGIA_MQH
#define ALGOTRADINGLAB_ESTRATEGIA_MQH

enum ENUM_ESTRATEGIA_GARCH
  {
   FILTRO_VOLATILIDADE = 0,   // Filtro: nao opera com volatilidade prevista acima do limiar
   VOLATILITY_TARGETING = 1,  // Volatility targeting: volume = base x alvo / volatilidade
   INTERVALO_CONFIANCA = 2,   // Intervalo: so opera se |previsao| > k x volatilidade
   FILTRO_E_TARGETING = 3     // Filtro e targeting juntos
  };

enum ENUM_MODO_LIMIAR
  {
   LIMIAR_ABSOLUTO = 0,   // Valor fixo (0,02 = 2% ao dia)
   LIMIAR_PERCENTIL = 1   // Percentil da volatilidade estimada na janela
  };

struct DecisaoOperacao
  {
   int      sinal;              // +1 compra, -1 venda, 0 nada
   double   volume;             // antes do ajuste ao lote do simbolo
   bool     vetada_pelo_garch;
   string   motivo;
  };

//--- previsao: retorno previsto pelo ARIMA; volatilidade: desvio previsto pelo GARCH, na mesma unidade.
//--- O volume do targeting fica entre fracao_minima e fracao_maxima do volume_base.
void DecidirOperacao(const double previsao,
                     const double volatilidade,
                     const bool usar_garch,
                     const ENUM_ESTRATEGIA_GARCH estrategia,
                     const double limiar,
                     const double volatilidade_alvo,
                     const double k_confianca,
                     const double volume_base,
                     const double fracao_minima,
                     const double fracao_maxima,
                     const double limiar_sinal,
                     DecisaoOperacao &decisao)
  {
   decisao.sinal = 0;
   decisao.volume = volume_base;
   decisao.vetada_pelo_garch = false;
   decisao.motivo = "";

   int direcao = 0;
   if(previsao > limiar_sinal)
      direcao = 1;
   else if(previsao < -limiar_sinal)
      direcao = -1;

   if(direcao == 0)
     {
      decisao.motivo = StringFormat("Previsao %.6f abaixo do limiar de sinal %.6f", previsao, limiar_sinal);
      return;
     }

   if(!usar_garch)
     {
      decisao.sinal = direcao;
      decisao.motivo = "ARIMA puro (GARCH desativado)";
      return;
     }

   if(volatilidade <= 0.0 || !MathIsValidNumber(volatilidade))
     {
      decisao.vetada_pelo_garch = true;
      decisao.motivo = "Volatilidade prevista invalida";
      return;
     }

   bool filtra = (estrategia == FILTRO_VOLATILIDADE || estrategia == FILTRO_E_TARGETING);
   if(filtra && volatilidade > limiar)
     {
      decisao.vetada_pelo_garch = true;
      decisao.motivo = StringFormat("FILTRO: vol prevista %.6f > limiar %.6f - sem operacao", volatilidade, limiar);
      return;
     }

   if(estrategia == INTERVALO_CONFIANCA)
     {
      double exigido = k_confianca * volatilidade;
      if(MathAbs(previsao) <= exigido)
        {
         decisao.vetada_pelo_garch = true;
         decisao.motivo = StringFormat("IC: |previsao| %.6f <= %.1f x vol %.6f = %.6f - sinal dentro do ruido",
                                       MathAbs(previsao), k_confianca, volatilidade, exigido);
         return;
        }
      decisao.sinal = direcao;
      decisao.motivo = StringFormat("IC: |previsao| %.6f > %.6f - sinal supera o ruido", MathAbs(previsao), exigido);
      return;
     }

   bool dimensiona = (estrategia == VOLATILITY_TARGETING || estrategia == FILTRO_E_TARGETING);
   if(dimensiona)
     {
      double fator = MathMax(fracao_minima, MathMin(fracao_maxima, volatilidade_alvo / volatilidade));
      decisao.volume = volume_base * fator;
      decisao.sinal = direcao;
      decisao.motivo = StringFormat("TARGETING: vol %.6f, fator %.3f, volume %.4f", volatilidade, fator, decisao.volume);
      return;
     }

   decisao.sinal = direcao;
   decisao.motivo = StringFormat("FILTRO: vol prevista %.6f <= limiar %.6f - operacao liberada", volatilidade, limiar);
  }

#endif
