# Bateria de 15/10/2026 — o que foi rodado e o que saiu

Pedido do autor (15/10): rodar todos os testes combinados, guardar e, se
possível, analisar. **O texto do TG não foi alterado por esta bateria**: a
decisão sobre o que entra é do autor. Protocolo escrito antes dos testes de
mercado: `PROTOCOLO.md`. Execução: 03:11 a 03:36 (`execucao.log`).

Todos os números abaixo saem de `resumo.txt` (gerado por
`ferramentas/scripts/resumo_bateria.sh`) e dos arquivos citados. **Camada 1 =
resultado "cru"** (sem custo, sem caixa na Selic, sem proventos), como o
Almeida e o relatório do MT5. As outras camadas estão em `resumo.txt`.

## 0. Conferências antes de confiar nos números

- **O código novo não mudou o caminho do Hannan-Rissanen.** O teste principal
  da refação (versão A, 2017–2024) rodado de novo deu 0 campos diferentes e
  curva diária idêntica byte a byte (rótulo `REGR_R6_GS`, 15/10 03:10).
- **O ambiente não mudou.** As médias móveis reproduzidas saíram com curva
  idêntica byte a byte às de 05/10 em T1, T2, T3, 2017–2024 e 2005–2026, e o
  cenário de Almeida de 2013–2016 repetiu R$ 24.020 (ARIMA-GARCH) e
  −R$ 8.100 (ARIMA).
- Todas as passagens gravaram `MetodoARIMA=0` e `DistribuicaoGARCH=0`; cada
  otimização teve as 344 passagens; as comparações tiveram 32 e 31 pares, os
  esperados.

## 1. Máxima verossimilhança no ARIMA: testada e NÃO adotada

`dados/verificacao/validacao_mv_arima_2026-10-15.txt` (EA
`ferramentas/ValidarMVArima_EA.mq5`). Pelo critério escrito antes
(`PROTOCOLO.md`, seção 6), fica o Hannan-Rissanen:

- precisão melhor em só 2 de 4 casos, e **muito pior** quando AR e MA quase se
  anulam (erro de 0,48 contra 0,27), que é o caso típico de retornos;
- com a MV, **o AIC acertou a ordem verdadeira muito menos** (12% x 40% e 8% x
  58%);
- de 6 a 196 vezes mais lenta por ajuste; convergência boa (0,34% de volta ao
  HR).

Para o texto, isso muda a defesa do Hannan-Rissanen: deixa de ser só "decisão
de projeto" e passa a ser "comparado com a máxima verossimilhança condicional
em séries sintéticas, foi mais estável e levou o AIC a escolher a ordem certa
com mais frequência". A opção continua no EA (`MetodoARIMA`), desligada.

## 2. A escolha pelo fator de recuperação

`escolhas/rf_C*.txt`. Nas cinco otimizações, a configuração escolhida usa o
GARCH como **filtro com ajuste do tamanho da posição** (`Estrategia=3`).
Ela coincidiu com escolhas antigas em quatro períodos:

| Otimização → teste | Fator de recuperação escolheu | Fecha a posição no veto? |
|---|---|---|
| 2004–2006 → 2007–2011 | a antiga versão A (= B) | sim |
| 2010–2012 → 2013–2016 (e fixas) | a antiga versão A | sim |
| 2022–2024 → 2025–2026 | a antiga versão B | sim |
| 2014–2016 → 2017–2024 (principal) | **a antiga versão B** | **não** |
| 2017–2019 → 2020–2021 (pandemia, novo) | nova | **não** |

A guarda de 12 negociações agiu: em 2014–2016, só 217 das 336 configurações
com GARCH a cumpriam.

## 3. Risco (camada 1)

| Período | Queda máx. GR / sem GARCH / ARIMA / MM / PETR4 | Volatilidade GR / sem GARCH / ARIMA / MM |
|---|---|---|
| 2007–2011 | 17,5 / 38,1 / 45,1 / 64,6 / 67,2 | 10,5 / 28,2 / 27,5 / 28,7 |
| 2013–2016 | 28,6 / 51,9 / 54,5 / 42,0 / 83,1 | 14,1 / 35,1 / 37,8 / 40,4 |
| 2017–2024 | 40,2 / 79,3 / 40,5 / 37,9 / 64,2 | 16,3 / 31,4 / 32,0 / 30,9 |
| 2025–2026 | 12,2 / 20,1 / 20,1 / 31,1 / 25,1 | 9,2 / 22,0 / 22,0 / 22,7 |
| 2020–2021 | 34,5 / 53,7 / 60,0 / 30,4 / 64,2 | 18,6 / 37,8 / 39,0 / 32,6 |

(em %; GR = ARIMA-GARCH escolhido; "sem GARCH" = a mesma configuração com o
GARCH desligado; MM = médias móveis reproduzidas)

- **Com GARCH x sem GARCH:** queda menor em 7 de 7 comparações (contando as
  fixas, 2005–2026 e 2017–2024) e volatilidade menor em 7 de 7. Pitman-Morgan
  com valor-p praticamente zero em todas (`testes/comparacoes_puro.csv`).
- **Com GARCH x médias móveis:** volatilidade menor em todos os períodos, com
  valor-p praticamente zero. Queda máxima menor em 2007–2011, 2013–2016,
  2025–2026 e nas fixas; **maior em 2017–2024 (40,2 x 37,9) e na pandemia
  (34,5 x 30,4)**.
- **Análise posterior (não estava no protocolo), com poucos casos:** os dois
  períodos em que a queda do GARCH passou a das médias móveis são exatamente
  os dois em que a configuração escolhida **não fecha a posição no veto**. Nos
  três em que fecha, a queda ficou bem abaixo. É o mesmo padrão já visto nas
  quatro ações (refação de 05/10): a proteção depende de o robô reduzir a
  posição quando a volatilidade sobe.
- ARIMA x médias móveis: volatilidades parecidas, exceto na pandemia (39,0 x
  32,6).

## 4. Retorno: o que muda ao usar o resultado cru

| Período | GR cru | GR com Selic no caixa | MM cru | MM com Selic | Selic |
|---|---|---|---|---|---|
| 2007–2011 | −8,4% | +28,7% | −31,6% | −11,6% | +68,1% |
| 2013–2016 | −13,8% | +15,8% | +100,8% | +150,9% | +53,9% |
| 2017–2024 | +42,9% | +114,1% | +47,8% | +90,4% | +86,1% |
| 2025–2026 | −7,4% | +9,6% | +18,1% | +31,3% | +25,7% |
| 2020–2021 | −17,6% | −14,1% | +19,4% | +22,7% | +7,2% |

- **No cru, as médias móveis rendem mais que o GARCH em 4 dos 5 períodos**; o
  GARCH só ganha em 2007–2011. A razão é a exposição: o GARCH fica, em média,
  com 17% a 25% do patrimônio aplicado, e no cru o resto não rende nada.
  Com o caixa na Selic, a ordem muda em 2017–2024 (114,1% x 90,4%).
- **Isso é importante para a decisão do texto.** Usar o cru como principal
  (pedido de 15/10) deixa o retorno do GARCH bem pior do que nas versões
  anteriores do Cap. III. Não é erro: é o custo da proteção ficar à vista. A
  seção de camadas ("do resultado bruto ao estimado") é onde isso se explica.
- Com GARCH x sem GARCH, retorno cru maior em 4 de 7.
- Taxa de acerto do GR entre 42% e 56%, perto do acaso, como antes.
- **Sharpe na camada 1 não tem sentido** (o caixa parado rende zero e a
  referência é a Selic): os p do Sharpe em `comparacoes_puro.csv` não devem
  ser usados. Para Sharpe, usar `comparacoes_camada3.csv`.

## 5. Pandemia

- **Teste próprio, 2020–2021, com otimização em 2017–2019** (novo): médias
  móveis +19,4%, queda 30,4%; GARCH −17,6%, queda 34,5% (vol 18,6% x 32,6%);
  ARIMA −44,1%, queda 60,0%; sem GARCH −26,2%, queda 53,7%; PETR4 −6,5%,
  queda 64,2%. Gráfico: `graficos/curva_T5.pdf`.
- Recorte de 2020 dentro desse teste (`recorte_2020_T5.txt`): médias móveis
  +31,7% (queda 19,2%), GARCH −21,5% (34,5%), ARIMA −42,9% (52,7%), PETR4
  −7,1% (64,2%).
- Leitura: o GARCH protegeu muito em relação ao ARIMA e à configuração sem ele,
  mas **as médias móveis foram melhores na pandemia**, em retorno e em queda.
  A configuração escolhida para esse período não fecha a posição no veto (ver
  seção 3).

## 6. 2008 (camada 1, `recorte_2008.txt`)

GARCH −4,4% (queda no ano 11,3%); sem GARCH −9,9% (35,1%); ARIMA −27,1%
(45,2%); médias móveis −40,7% (52,5%); PETR4 −47,3% (67,2%).

## 7. O que não foi refeito, e por quê

- **As quatro ações:** a estimação não mudou, e a análise por pares não depende
  do critério de escolha, então valem as de `../refeito_2026-10-05/`.
- **Versões A e B:** não testadas (protocolo, seção 2). Ficam registradas em
  `escolhas/sharpe_calmar_C*.txt`.

## Arquivos

- `calibracao/PETR4_C1..C5.csv` — as 344 passagens de cada otimização
  (colunas novas: `fator_recuperacao_mt5`, `lucro_mt5`, `dd_capital_mt5`,
  `MetodoARIMA`).
- `escolhas/` — escolhas por fator de recuperação e, só para registro, por
  Sharpe e Calmar.
- `testes/metricas_N_*.csv`, `testes/curva_N_*.csv` — cada teste (rótulos:
  `N_<período>_<GR|GRgemeo|AR|MM>`, `N_L1_*` e `N_L2_*` as fixas,
  `N_cenA_*` o cenário de Almeida). `testes/curvas_puras/` — as curvas com a
  camada 1 no lugar da 3, usadas nas comparações "puras".
- `testes/comparacoes_puro.csv` e `comparacoes_camada3.csv` — Pitman-Morgan,
  Sharpe e t pareado.
- `testes/anual_*.csv` — retorno por ano (camada 1). `recorte_*.txt` — um ano.
- `traco/` — traço diário da GR de 2017–2024, jul/2019 a jun/2021, com e sem
  GARCH.
- `relatorios_mt5/` — relatório e gráfico do próprio MetaTrader de cada teste.
- `graficos/` — rascunhos (pandemia, camadas de 2017–2024, risco por período),
  gerados por `graficos/gerar.sh` a partir das métricas.
