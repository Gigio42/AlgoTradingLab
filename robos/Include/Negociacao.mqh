//+------------------------------------------------------------------+
//| Negociacao.mqh                                                   |
//| Ordens, posicao aberta e volume, para um simbolo e um numero     |
//| magico. Usado pelos dois EAs.                                    |
//+------------------------------------------------------------------+
#ifndef ALGOTRADINGLAB_NEGOCIACAO_MQH
#define ALGOTRADINGLAB_NEGOCIACAO_MQH

#include <Trade\Trade.mqh>

#define SEM_POSICAO ((ENUM_POSITION_TYPE)-1)

class CNegociacao
  {
private:
   CTrade   m_trade;
   string   m_simbolo;
   ulong    m_magico;
   int      m_desvio_pontos;
   long     m_ordens_enviadas;

public:
                     CNegociacao(void) : m_magico(0), m_desvio_pontos(10), m_ordens_enviadas(0) {}

   void     Configurar(const string simbolo, const ulong magico, const int desvio_pontos);

   ENUM_POSITION_TYPE PosicaoAtual(void);
   bool     Fechar(const ENUM_POSITION_TYPE tipo);
   bool     Comprar(const double volume, const double preco, const double stop_loss,
                    const double take_profit, const string comentario);
   bool     Vender(const double volume, const double preco, const double stop_loss,
                   const double take_profit, const string comentario);

   //--- Arredonda ao passo de volume e respeita o minimo e o maximo do simbolo
   double   AjustarVolume(double volume) const;
   long     OrdensEnviadas(void) const { return(m_ordens_enviadas); }
  };

void CNegociacao::Configurar(const string simbolo, const ulong magico, const int desvio_pontos)
  {
   m_simbolo = simbolo;
   m_magico = magico;
   m_desvio_pontos = desvio_pontos;
   m_trade.SetExpertMagicNumber(magico);
   m_trade.SetDeviationInPoints(desvio_pontos);
   m_trade.SetTypeFillingBySymbol(simbolo);
  }

ENUM_POSITION_TYPE CNegociacao::PosicaoAtual(void)
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL) == m_simbolo &&
         (ulong)PositionGetInteger(POSITION_MAGIC) == m_magico)
         return((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE));
     }
   return(SEM_POSICAO);
  }

//--- Verdadeiro tambem quando nao havia posicao desse tipo
bool CNegociacao::Fechar(const ENUM_POSITION_TYPE tipo)
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL) == m_simbolo &&
         (ulong)PositionGetInteger(POSITION_MAGIC) == m_magico &&
         PositionGetInteger(POSITION_TYPE) == tipo)
        {
         if(m_trade.PositionClose(ticket, m_desvio_pontos))
            return(true);
         Print("Falha ao fechar posicao: ", m_trade.ResultRetcodeDescription());
         return(false);
        }
     }
   return(true);
  }

bool CNegociacao::Comprar(const double volume, const double preco, const double stop_loss,
                          const double take_profit, const string comentario)
  {
   if(!m_trade.Buy(volume, m_simbolo, preco, stop_loss, take_profit, comentario))
     {
      Print("Falha na compra: ", m_trade.ResultRetcodeDescription());
      return(false);
     }
   m_ordens_enviadas++;
   return(true);
  }

bool CNegociacao::Vender(const double volume, const double preco, const double stop_loss,
                         const double take_profit, const string comentario)
  {
   if(!m_trade.Sell(volume, m_simbolo, preco, stop_loss, take_profit, comentario))
     {
      Print("Falha na venda: ", m_trade.ResultRetcodeDescription());
      return(false);
     }
   m_ordens_enviadas++;
   return(true);
  }

double CNegociacao::AjustarVolume(double volume) const
  {
   double minimo = SymbolInfoDouble(m_simbolo, SYMBOL_VOLUME_MIN);
   double maximo = SymbolInfoDouble(m_simbolo, SYMBOL_VOLUME_MAX);
   double passo  = SymbolInfoDouble(m_simbolo, SYMBOL_VOLUME_STEP);

   if(passo > 0.0)
      volume = MathRound(volume / passo) * passo;
   if(volume < minimo)
      volume = minimo;
   if(maximo > 0.0 && volume > maximo)
      volume = maximo;

   int casas = (passo > 0.0 && passo < 1.0) ? (int)MathCeil(-MathLog10(passo)) : 0;
   return(NormalizeDouble(volume, casas));
  }

//--- Volume que corresponde a uma fracao do patrimonio. Arredonda para baixo ao lote
//--- (para cima a ordem poderia ser recusada por margem); teto de 98%, sem alavancagem.
double VolumePorCapital(const string simbolo, const double fracao, const double preco)
  {
   double contrato = SymbolInfoDouble(simbolo, SYMBOL_TRADE_CONTRACT_SIZE);
   if(contrato <= 0.0)
      contrato = 1.0;
   if(preco <= 0.0)
      return(0.0);

   double fracao_limitada = MathMax(0.0, MathMin(fracao, 0.98));
   double volume = AccountInfoDouble(ACCOUNT_EQUITY) * fracao_limitada / (preco * contrato);

   double passo = SymbolInfoDouble(simbolo, SYMBOL_VOLUME_STEP);
   if(passo > 0.0)
      volume = MathFloor(volume / passo) * passo;
   return(volume);
  }

#endif
