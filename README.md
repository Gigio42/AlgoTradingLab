# AlgoTradingLab: ARIMA-GARCH em MQL5

Trabalho de Graduação do curso de Análise e Desenvolvimento de Sistemas da
FATEC Indaiatuba, de Bruno Rocha Pereira e Giovanni Silva Loose, com orientação
da Profa. Simone Mendes da Silva (2026).

Este repositório contém um algoritmo de negociação para o MetaTrader 5, escrito
em MQL5, que combina dois modelos estatísticos: o **ARIMA**, que prevê a direção
do preço, e o **GARCH**, que estima a volatilidade e decide se vale a pena operar.
O algoritmo foi comparado com a estratégia de médias móveis de Almeida (2016),
outro trabalho da FATEC Indaiatuba, do qual este é continuação.

O texto completo do trabalho está em [`tg/main.pdf`](tg/main.pdf).

## A ideia

Em 2016, Almeida testou no MetaTrader 5 um robô baseado no cruzamento de médias
móveis de 10 e 20 dias. A estratégia funcionou em mercado estável, mas acumulou
prejuízo no período da crise de 2008, e o autor sugeriu, como trabalho futuro,
usar modelos de volatilidade como o GARCH.

O GARCH sozinho não serve para operar, porque ele diz quanto o preço deve
oscilar, mas não para que lado. Por isso este trabalho divide as tarefas entre
dois modelos:

- **ARIMA, a direção.** A cada dia, estima o retorno esperado a partir dos
  retornos passados. Se a previsão é de alta, o sinal é de compra.
- **GARCH, o risco.** Estima a volatilidade do dia seguinte. Ele nunca cria um
  sinal. Só pode vetar a operação proposta pelo ARIMA, quando a volatilidade
  prevista está alta, ou reduzir o tamanho da posição.

Há um único Expert Advisor, com uma chave (`UsarGARCH`) que liga e desliga o
GARCH. Com a chave desligada, o mesmo código roda o ARIMA sozinho. Isso permite
comparar cada configuração com a sua **gêmea**, que usa exatamente o mesmo ARIMA
sem o GARCH. Assim, qualquer diferença entre as duas vem do GARCH, e não de um
detalhe de implementação.

## O que foi implementado

Não existe ARIMA nem GARCH pronto na biblioteca do MQL5, então os dois modelos
foram escritos neste projeto. A biblioteca numérica ALGLIB, que já vem com o
MetaTrader 5, entra só nas contas de álgebra linear e de otimização.

- **ARIMA**, estimado pelo método de Hannan-Rissanen, que usa só mínimos
  quadrados e não depende de taxa de aprendizado nem da escala do preço.
- **Escolha automática das ordens do ARIMA:** a ordem de diferenciação pelo
  teste ADF aplicado em sequência, e as ordens p e q (de 0 a 4) pelo critério de
  Akaike, comparando todos os candidatos sobre as mesmas observações.
- **GARCH(1,1)**, estimado por máxima verossimilhança com as restrições do
  modelo impostas dentro do otimizador.
- **Três formas de usar o GARCH na decisão:** filtro (veta acima de um limiar),
  ajuste do tamanho da posição pela volatilidade, e intervalo de confiança
  (só opera quando a previsão supera o ruído).
- **Médias móveis de Almeida (2016)**, reimplementadas para servir de termo de
  comparação.
- **Avaliação no testador:** custos de corretagem, rendimento do caixa parado
  pela Selic, índices de Sharpe e Calmar, queda máxima e testes estatísticos
  pareados entre estratégias.

Os modelos foram conferidos em séries artificiais com parâmetros conhecidos. Por
exemplo, num GARCH simulado com α = 0,090 e β = 0,890, o estimador obteve 0,0825
e 0,8941 (`dados/verificacao/validacao_numerica_2026-10-05.txt`).

## Como foi testado

- **Dados oficiais:** cotações diárias da B3 (arquivo COTAHIST), corrigidas só
  pelos desdobramentos, e a taxa Selic diária do Banco Central (série 11 do SGS).
  A origem de cada arquivo, com data de obtenção e conferência, está em
  [`dados/FONTES.md`](dados/FONTES.md).
- **Ativo principal:** PETR4, em barras diárias. VALE3, USIM5 e POMO4 foram
  usadas para verificar se o efeito se repete em outras ações.
- **Calibração separada do teste:** os parâmetros foram escolhidos nos três anos
  anteriores a cada período de teste e só depois aplicados a ele. O protocolo foi
  escrito antes de os resultados existirem
  ([`PROTOCOLO.md`](dados/resultados/refeito_2026-10-05/PROTOCOLO.md)).
- **Períodos:** a crise de 2007 a 2011, a queda e a recuperação de 2013 a 2016,
  o teste principal de 2017 a 2024, o período recente de 2025 a 2026 e o
  intervalo completo de 2005 a 2026.

## Principais resultados

No teste principal, de 2017 a 2024, com custos e o caixa rendendo a Selic:

| Algoritmo | Retorno | Queda máxima |
|---|---|---|
| ARIMA-GARCH (configuração escolhida pelo Sharpe) | +273,8% | 26,1% |
| O mesmo ARIMA sem o GARCH | +114,6% | 40,6% |
| Médias móveis de Almeida | +90,4% | 36,7% |
| Selic | +86,1% | |
| PETR4, só a variação do preço | +143,6% | |

O que os experimentos mostram, em resumo:

- **O GARCH reduziu o risco de forma consistente.** Em todas as 11 comparações
  entre uma configuração com GARCH e a sua gêmea, a queda máxima foi menor com o
  GARCH, e o retorno foi maior em 9 delas. Nas quatro ações, as variantes que
  reduzem a exposição diminuíram a queda máxima na maior parte das configurações
  testadas.
- **Ele não melhorou a previsão.** A taxa de acerto da direção ficou perto do
  acaso com e sem o GARCH (55,7% e 58,8% em 2017–2024). O ganho veio de operar
  menos e em dias mais calmos, e não de prever melhor.
- **A maior parte das diferenças não é estatisticamente significativa.** Só 1 das
  11 comparações com a gêmea teve p < 0,05, e nenhuma vantagem sobre a Selic ou
  sobre as médias móveis passou nesse critério.
- **Os retornos não incluem dividendos.** Com os proventos da PETR4, a compra e
  manutenção da ação rende +726,5% em 2017–2024 e passa à frente de todos os
  algoritmos. A comparação entre o GARCH e a gêmea não muda.

As tabelas completas estão no Capítulo III do trabalho e em
[`dados/resultados/refeito_2026-10-05/`](dados/resultados/refeito_2026-10-05/LEIAME.md).

## Estrutura do repositório

| Pasta | Conteúdo |
|---|---|
| `ARIMA-GARCH/` | o Expert Advisor (`ARIMA_GARCH_EA.mq5`) |
| `Include/` | os módulos: ARIMA, GARCH, estatística (ADF, Ljung-Box, AIC), seleção de ordens, estratégia e avaliação de desempenho |
| `MediasMoveis2/` | a estratégia de médias móveis de Almeida (2016), reimplementada |
| `ferramentas/` | importador de séries, comparador de estratégias, validações e os scripts que rodam as baterias de testes (`scripts/`) |
| `dados/` | dados brutos (`fontes/`), séries prontas para o MetaTrader (`series/`), conferências (`verificacao/`) e resultados dos experimentos (`resultados/`) |
| `tg/` | o texto do trabalho em LaTeX e o PDF final |
| `legado/` | a primeira implementação, substituída. Guardada só para consulta |

## Como reproduzir

Precisa do MetaTrader 5 (Windows, ou Linux pelo Wine) com uma conta conectada,
mesmo que de demonstração, porque o testador exige conexão com uma corretora.

1. Copie esta pasta para `MQL5/Experts/AlgoTradingLab` dentro da pasta de dados
   do MetaTrader 5.
2. Importe a série como símbolo personalizado com
   `ferramentas/Import_B3_Custom.mq5`. O importador lê `<TICKER>.csv` de uma
   pasta dentro de `MQL5/Files/` (input `InpDataDir`) e acrescenta um sufixo ao
   nome (input `InpSufixo`). Para obter o `PETR4_OFICIAL` usado no trabalho,
   copie `dados/series/PETR4_OFICIAL.csv` como `PETR4.csv` nessa pasta e use o
   sufixo `_OFICIAL`.
3. Compile `ARIMA-GARCH/ARIMA_GARCH_EA.mq5` no MetaEditor.
4. No Testador de Estratégias, escolha o símbolo importado (por exemplo
   `PETR4_OFICIAL`), barras diárias e o modelo "somente preços de abertura".
   Ao final, o EA mostra no log as métricas contra a Selic e contra a compra e
   manutenção. Preencha o input `Rotulo` para gravar também as métricas e a
   curva diária em CSV.

Os scripts em `ferramentas/scripts/` automatizam as baterias completas pela linha
de comando. Eles foram escritos para o ambiente dos autores (MetaTrader sob
Wine), então os caminhos no início de `comum.sh` precisam ser ajustados.

## Teste adicional: GARCH com distribuição t de Student

Depois de concluído o trabalho, foi testada uma variante do GARCH com erros t de
Student, que trata dias extremos como mais prováveis do que a distribuição
normal (input `DistribuicaoGARCH`). Ela **não faz parte do TG**, e o padrão do EA
continua sendo a normal. Com as mesmas configurações, a t vetou menos operações
e teve retorno menor em 9 de 12 casos, mas manteve a queda máxima abaixo da
gêmea em todos. Detalhes em
[`dados/resultados/garch_t_2026-10-13/`](dados/resultados/garch_t_2026-10-13/LEIAME.md).

## Referência

ALMEIDA, F. L. R. **Técnicas de previsão da bolsa com MetaTrader 5**. Trabalho de
Graduação (Tecnologia em Banco de Dados), Faculdade de Tecnologia de Indaiatuba,
2016.
