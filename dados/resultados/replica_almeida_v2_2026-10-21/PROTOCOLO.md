# Réplica de Almeida (2016), rodada 2 — protocolo

Escrito em 21/10/2026, a pedido do autor ("testar de todas as formas, com outras
séries, para chegar onde ele chegou"). **Aviso de transparência:** este protocolo
foi escrito **depois** de uma primeira exploração offline (simulador descartável,
fora do repositório), que já indicou a hipótese H3 abaixo. O que ele fixa daqui
em diante é a regra de aceitação e a confirmação no MetaTrader.

## Alvos (números do trabalho dele, `bibliografia/pdfs/Almeida-2016.pdf`, p. 56–59)

| Teste | Ativo, período | Volume | Operações | Lucro bruto | Perda bruta | Líquido |
|---|---|---|---|---|---|---|
| T1 | PETR4, 01/01/2007–31/12/2011 | não informado (100 suposto) | 52 | 3.363 | 5.905 | −2.542 |
| T2 | PETR4, 01/01/2008–31/12/2010 | não informado (100 suposto) | 37 | 2.855 | 4.450 (deduzida) | −1.595 |
| T3 | PETR4, 22/05/2013–24/05/2016 | 1.000 | 38 | — | — | +10.430 |
| T4 | CIEL3, 04/06/2012–04/06/2016 | não informado | 51 (21 com lucro) | 45.590 | 31.940 (deduzida) | +13.650 |
| T5 | VLID3, 04/06/2012–04/06/2016 | não informado | 49 (25 com lucro) | 63.760 | 38.250 (deduzida) | +25.510 |

Além disso, T3 informa "3 negociações com lucro consecutivo de R$ 7.530", e a
Figura 13 (T1) traz as entradas por mês do ano, somadas nos cinco anos. A leitura
das barras da figura é **estimativa** (leitura visual): 3, 4, 4, 3, 1, 5, 4, 4,
8, 4, 7, 5 (soma 52, igual ao texto).

Condições declaradas por ele: MetaTrader 5 build 1340, servidor
**MetaBrazil-Demo**, modelo "Every tick", R$ 50 mil, alavancagem 1:100 em T1,
médias simples de 10 e 20 no fechamento, sem StopLoss e TakeProfit, gestão de
dinheiro do livro de Young com `Volume_Fixo = 0,1` por padrão.

## Medidas

- Contagem de operações (o que o relatório do MT5 chama de "Total Trades",
  incluindo o fechamento forçado no fim do teste).
- Lucro bruto e perda bruta (Gross Profit / Gross Loss do relatório).
- Fator de lucro: não depende do volume, então serve onde o volume não foi
  informado.

## Hipóteses

| | Hipótese | Apoio independente |
|---|---|---|
| H1 | Entrada por estado (anexo dele: compra se rápida > lenta e não está comprado), em vez de esperar o cruzamento | código do anexo |
| H2 | Inversão numa ordem só, com o volume somado (classe de negociação do livro) | o laço `while(PositionSelect()==false)` do anexo trava se a ordem só zerar a posição |
| H3 | Histórico da PETR4 no servidor dele começando em 2008 | nenhum direto; sugerido pela Figura 13 e por T1 − T2 = 15 operações |
| H4 | Série ajustada por proventos (dividendos e JCP) | corretoras costumam ajustar; não confirmado |
| H5 | Spread, modelo de ticks, defasagem de uma barra | modelo "Every tick" declarado |
| H6 | CIEL3 com bonificações ajustadas | o preço bruto tem saltos de 15% a 50% em cada bonificação |

## Regra de aceitação

Uma combinação só "explica" a diferença se for **a mesma nos cinco testes** e
tiver apoio independente (texto, anexo ou comportamento da plataforma). Ajustar
um parâmetro livre por teste não conta. Todas as variantes testadas são
relatadas, inclusive as que pioram.

## Execução

1. Simulador offline (descartável), validado contra os relatórios do MT5 da
   rodada 1: mesmas operações, datas e lucro, centavo a centavo.
2. Confirmação no testador do MetaTrader com `ferramentas/ReplicaAlmeidaEA.mq5`
   (porta literal do OnTick do anexo, com chaves para H1 e H2), nos símbolos
   `PETR4_OFICIAL`, `PETR4_DESDE2008`, `VLID3_OFICIAL` e `CIEL3_ESTIMADO`
   (`ferramentas/scripts/series_replica_almeida.sh`), nos modelos "preços de
   abertura" e "todos os ticks".
3. O robô do TG (`MediasMoveis2`) não é alterado nesta rodada.
