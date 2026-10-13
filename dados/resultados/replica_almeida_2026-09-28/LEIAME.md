# Réplica de Almeida (2016) com as datas e parâmetros do trabalho original

Rodado em 28/09/2026, depois da leitura do PDF original
(`bibliografia/pdfs/Almeida-2016.pdf`). Substitui as réplicas anteriores, que usavam
datas supostas.

## Como foi rodado

- EA `MediasMoveis2`, médias móveis **simples 10 e 20** sobre o **fechamento**,
  **sem StopLoss e sem TakeProfit**, **compra e venda** (long-short), como no
  anexo `EA_TG_2016.mq5` do trabalho dele.
- Depósito R$ 50.000, volume fixo, **custo zero** (ele diz que "o método não
  inclui de nenhuma forma taxas de corretagem").
- D1, modelo "somente preços de abertura".
- Série `PETR4_OFICIAL` (COTAHIST da B3, corrigida por desdobramento) e, para
  comparação, `PETR4_OFBRUTO` (a mesma sem corrigir o desdobramento de 2008).
- Reprodução: `ferramentas/scripts/rodar.sh` com os inputs de
  `../rodada3_b3_oficial/testes/in_mm.txt`.

## Resultados (coluna `ret_puro` dos `metricas_*.csv`, sobre R$ 50 mil)

| Rótulo | Série | Período | Volume | Op. | Acerto | FL | Resultado |
|---|---|---|---|---|---|---|---|
| `fl13of` / `fl13br` | OFICIAL = BRUTO | 22/05/2013–24/05/2016 | 1.000 | 37 | 33,3% | 1,38 | **+R$ 10.050 (+20,1%)** |
| `flcr_of100` | OFICIAL | 02/01/2007–29/12/2011 | 100 | 63 | 33,9% | 0,83 | **−R$ 1.274 (−2,5%)** |
| `flcr_of1000` | OFICIAL | idem | 1.000 | 63 | 33,9% | 0,83 | −R$ 12.740 (−25,5%) |
| `flcr_br100` | BRUTO | idem | 100 | 65 | 31,3% | 0,50 | −R$ 7.041 (−14,1%) |
| `flcr_br1000` | BRUTO | idem | 1.000 | 18 | 22,2% | 0,22 | −R$ 32.260 (−64,5%) |
| `fl0810_100` | OFICIAL | 02/01/2008–30/12/2010 | 100 | **37** | 37,8% | 0,86 | **−R$ 575 (−1,2%)** |
| `fl0810_1000` | OFICIAL | idem | 1.000 | **37** | 37,8% | 0,86 | −R$ 5.750 (−11,5%) |

`fl13of` e `fl13br` são idênticos porque a PETR4 não teve desdobramento entre
2013 e 2016: nesse trecho as duas séries são a mesma.

## O que Almeida relatou

| | Operações | Resultado |
|---|---|---|
| 2013–2016, 1.000 ações | 38 | +R$ 10.430 (mais de 20%) |
| 2007–2011 | 52 | bruto +R$ 3.363, perdas −R$ 5.905, líquido **−R$ 2.542** |
| 2008–2010 | 37 | bruto +R$ 2.855, líquido **−R$ 1.595** |

## Leitura

1. **2013–2016 fecha.** Uma operação de diferença e 3,6% no lucro. É a validação
   da reimplementação da MM, da série da B3 e do arcabouço de backtest.
2. **2008–2010 fecha na contagem exata**: 37 operações nos dois. O prejuízo dele
   é maior (−R$ 1.595 contra −R$ 575), mas o sinal, a contagem e a ordem de
   grandeza batem, e a taxa de acerto (37,8%) é compatível com o padrão dele.
3. **2007–2011 bate em sinal e ordem de grandeza, não em contagem** (62 saídas
   contra 52). Como 2008–2010 fecha exatamente, a diferença está em 2007 e 2011,
   não na lógica da média móvel. As hipóteses estão em `notas/INCERTEZAS.md`, item 7.
4. **A série dele já era ajustada por desdobramento.** No preço bruto o prejuízo
   de 2007–2011 fica 3× a 13× maior que o dele.
5. **O resultado escala com o volume, e o risco também**: em 2007–2011 com 1.000
   ações no preço bruto a margem estourou e o teste parou em 18 operações.

## Arquivos

- `metricas_<rotulo>.csv` — uma linha, todas as métricas do `Desempenho.mqh`.
- `curva_<rotulo>.csv` — patrimônio diário em base 1, para os gráficos.
