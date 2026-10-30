# Rodada 5 (30/09/2026) — períodos longos

> **SUPERADO em 06/10/2026** pela refação com o EA corrigido
> (`../refeito_2026-10-05/LEIAME.md`; erros em `ia/INCERTEZAS.md`, itens 43 a
> 47). Os números desta pasta foram produzidos com o EA antigo e não vão para o TG.


Motivo: as rodadas 3 e 4 testaram 2007–2011, 2013–2016 e 2025–2026. **2017–2024
nunca havia sido testado com dados oficiais**, e nunca houve teste de período
único longo. A pergunta era se em alguma janela mais longa o modelo supera a
Selic de forma durável.

## Montagem

- Série `PETR4_OFICIAL` (B3 COTAHIST, só desdobramento). Camada 3: custo B3 de
  0,03% por lado e caixa parado rendendo a Selic diária do BCB.
- R$ 100 mil, alavancagem 1:1, 95% do patrimônio por operação, **só compra**,
  modelo "somente preços de abertura".
- **Configuração fixa, declarada antes e não reotimizada dentro do período** —
  o mesmo espírito das médias 10/20 que Almeida nunca reotimizou. Duas variantes,
  ambas escolhidas pelo protocolo da rodada 3:
  - `GF` — GARCH como **filtro**, percentil 50, janela 120;
  - `GT` — **filtro + targeting**, percentil 90, alvo 1% ao dia, zera no veto,
    janela 120.
  - `AR` — o mesmo ARIMA com o GARCH desligado (gêmeo).
  - `MM` — médias móveis 10/20, só compra, mesmos custos.
- Reprodução: `ferramentas/scripts/periodos_longos.sh`.

## Resultado (camada 3)

| | anos | retorno | Selic | buy-and-hold | Sharpe (p) | queda máx. |
|---|---|---|---|---|---|---|
| **L1 2005–2026** | | | +795,8% | +298,8% | | |
| ARIMA puro | 21,3 | +6,0% | | | −0,19 (0,81) | 82,4% |
| **ARIMA-GARCH filtro** | 21,3 | **+3.780,7%** | | | **0,38 (0,041)** | 56,4% |
| ARIMA-GARCH filtro+targeting | 21,3 | +543,0% | | | −0,11 (0,70) | **27,8%** |
| MM (Almeida) | 21,3 | +985,2% | | | 0,18 (0,20) | 67,5% |
| **L2 2017–2024** | | | +86,1% | +143,6% | | |
| ARIMA puro | 7,9 | −43,8% | | | −0,31 (0,81) | 76,5% |
| ARIMA-GARCH filtro | 7,9 | **+154,6%** | | | 0,29 (0,21) | 57,6% |
| ARIMA-GARCH filtro+targeting | 7,9 | +118,0% | | | 0,26 (0,23) | **14,1%** |
| MM (Almeida) | 7,9 | +90,4% | | | 0,17 (0,32) | 36,7% |

CAGR de L1: modelo 18,7% ao ano · Selic 10,8% · buy-and-hold 6,7%.

## Leitura, com as ressalvas

1. **É o primeiro resultado do projeto com p < 0,05 contra a Selic** (L1 filtro,
   p = 0,041). Mas **a significância vem do tamanho da amostra, não do tamanho
   do efeito**: o Sharpe é 0,38 e o t é 1,74, sobre ~5.300 dias. Em T2 da rodada
   3 o Sharpe foi 0,80 com p = 0,056, porque eram 4 anos. Não escrever "superou
   com significância estatística" sem dizer isso.
2. **Nunca supera o buy-and-hold de forma significativa**: z de
   Jobson-Korkie-Memmel = 1,46, p = 0,14. O alfa contra o buy-and-hold é de
   8,4% ao ano, com t = 1,84.
3. **Concentração alta.** Dos 21 anos, 2018 sozinho responde por 24,6% do
   retorno logarítmico; os dois melhores anos por 45,2%; os cinco melhores por
   **79,5%** (2018, 2016, 2006, 2005 e 2026). Não é vantagem distribuída no
   tempo.
4. **A variante que rende não é a que protege.** O filtro puro rende 3.780% com
   queda máxima de 56,4%; a que reduz posição fica em 543% (abaixo da Selic) com
   27,8%. Em 2017–2024 a diferença é mais nítida ainda: 14,1% de queda máxima
   contra 57,6%. **Retorno e proteção estão em lados opostos**, e isso é
   coerente com o que a rodada 4 já mostrava.
5. **O achado mais robusto não é sobre a Selic.** O mesmo ARIMA, na mesma
   janela, deu +6,0% em 21 anos e −43,8% em 8 anos. Com o filtro do GARCH
   ligado, +3.780,7% e +154,6%. Uma chave de configuração. É a comparação
   pareada mais forte do trabalho.
6. **2017–2024 preenche o buraco**: as duas variantes com GARCH superaram a
   Selic, nenhuma com significância, e ambas ficaram perto ou acima do
   buy-and-hold.
7. **Ressalva de amostra:** a configuração foi escolhida na calibração
   2010–2012 da rodada 3, que está **dentro** de L1. São 3 dos 21 anos, mas o
   teste não é totalmente fora da amostra. L2 (2017–2024) é posterior à
   calibração e, nesse sentido, é o teste mais limpo dos dois.
8. **Ressalva de início de série:** L1 começa em 03/01/2005 e o tester só
   entrega histórico do ano anterior, então a primeira seleção de ordens opera
   com pouco mais de 240 barras. 2005 e 2006 estão entre os cinco melhores anos.
