//+------------------------------------------------------------------+
//| ReplicaAlmeidaEA.mq5 - diagnostico da replica de Almeida (2016)   |
//| (21/10/2026). Porta a logica do OnTick do anexo EA_TG_2016.mq5:   |
//| opera so na barra nova (a primeira chamada do CNewBar nao conta), |
//| le as medias na barra 1 e compra quando a rapida esta acima da    |
//| lenta e a posicao nao e comprada (venda simetrica). Nao e o robo  |
//| do TG: serve so para medir o que muda em relacao ao MediasMoveis2.|
//+------------------------------------------------------------------+
#property copyright "TG - FATEC Indaiatuba (ADS)"
#property version   "1.00"

#include <Trade\Trade.mqh>

input int    RapidaMM_Periodo   = 10;
input int    DevagarMM_Periodo  = 20;
input double Volume             = 100;   // Acoes por operacao
input int    ModoEntrada        = 0;     // 0 = estado (anexo), 1 = so no cruzamento (MediasMoveis2)
input int    ModoReversao       = 0;     // 0 = uma ordem com o volume somado (livro), 1 = fecha e abre
input bool   PularPrimeiraBarra = true;  // CNewBar do livro nao sinaliza na primeira chamada
input bool   ArredondarMedias   = false; // CIndicator::Main do livro (Young, 2013) faz NormalizeDouble(valor,_Digits)

CTrade g_trade;
int    g_rapida, g_lenta;
bool   g_ordem_compra = false, g_ordem_venda = false;
datetime g_ultima_barra = 0;

int OnInit()
  {
   g_rapida = iMA(_Symbol, _Period, RapidaMM_Periodo, 0, MODE_SMA, PRICE_CLOSE);
   g_lenta  = iMA(_Symbol, _Period, DevagarMM_Periodo, 0, MODE_SMA, PRICE_CLOSE);
   if(g_rapida == INVALID_HANDLE || g_lenta == INVALID_HANDLE)
      return(INIT_FAILED);
   g_trade.SetDeviationInPoints(3);
   return(INIT_SUCCEEDED);
  }

bool BarraNova()
  {
   datetime t = (datetime)SeriesInfoInteger(_Symbol, _Period, SERIES_LASTBAR_DATE);
   bool primeira = (g_ultima_barra == 0);
   if(t <= g_ultima_barra)
      return(false);
   g_ultima_barra = t;
   return(!(primeira && PularPrimeiraBarra));
  }

double Media(int handle, int barra)
  {
   double v[1];
   if(CopyBuffer(handle, 0, barra, 1, v) != 1)
      return(EMPTY_VALUE);
   return(ArredondarMedias ? NormalizeDouble(v[0], _Digits) : v[0]);
  }

long TipoPosicao()
  {
   if(!PositionSelect(_Symbol))
      return(-1);
   return(PositionGetInteger(POSITION_TYPE));
  }

bool Abrir(ENUM_ORDER_TYPE tipo)
  {
   double volume = Volume;
   if(PositionSelect(_Symbol))
     {
      long atual = PositionGetInteger(POSITION_TYPE);
      bool oposta = (tipo == ORDER_TYPE_BUY && atual == POSITION_TYPE_SELL) ||
                    (tipo == ORDER_TYPE_SELL && atual == POSITION_TYPE_BUY);
      if(oposta)
        {
         if(ModoReversao == 0)
            volume += PositionGetDouble(POSITION_VOLUME);
         else if(!g_trade.PositionClose(_Symbol))
            return(false);
        }
     }
   return(tipo == ORDER_TYPE_BUY ? g_trade.Buy(volume, _Symbol) : g_trade.Sell(volume, _Symbol));
  }

void OnTick()
  {
   if(!BarraNova())
      return;
   double r1 = Media(g_rapida, 1), l1 = Media(g_lenta, 1);
   double r2 = Media(g_rapida, 2), l2 = Media(g_lenta, 2);
   if(r1 == EMPTY_VALUE || l1 == EMPTY_VALUE || r2 == EMPTY_VALUE || l2 == EMPTY_VALUE)
      return;

   bool compra, venda;
   if(ModoEntrada == 0)
     {
      compra = (r1 > l1 && TipoPosicao() != POSITION_TYPE_BUY && !g_ordem_compra);
      venda  = (r1 < l1 && TipoPosicao() != POSITION_TYPE_SELL && !g_ordem_venda);
     }
   else
     {
      compra = (r1 > l1 && r2 <= l2 && TipoPosicao() != POSITION_TYPE_BUY);
      venda  = (r1 < l1 && r2 >= l2 && TipoPosicao() != POSITION_TYPE_SELL);
     }

   if(compra)
     {
      g_ordem_compra = Abrir(ORDER_TYPE_BUY);
      if(g_ordem_compra)
         g_ordem_venda = false;
     }
   if(venda)
     {
      g_ordem_venda = Abrir(ORDER_TYPE_SELL);
      if(g_ordem_venda)
         g_ordem_compra = false;
     }
  }
