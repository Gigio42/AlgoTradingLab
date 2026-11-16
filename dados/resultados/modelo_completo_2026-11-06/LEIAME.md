# Dados dos relatórios "o modelo inteiro" e "o GARCH funcionando" (06/11/2026)

Pedido do autor: um relatório de figuras com o modelo completo de forma intuitiva
(`ia/relatorios/modelo-completo/`) e outro com o funcionamento do GARCH num
gráfico (`ia/relatorios/garch-funcionando/`). **Não estão no TG.**

## Procedência

- **Programa:** `ferramentas/ModeloCompleto.mq5`, que chama as classes e funções
  do próprio robô (`SelecionarModelo`, `CArima`, `CGarch`, `Percentil`,
  `DecidirOperacao`). Rodado por `ferramentas/scripts/modelo_completo.sh` no
  MetaTrader do prefixo em uso, em 06/11/2026.
- **Série:** `PETR4_OFICIAL` (B3 COTAHIST, `dados/FONTES.md`).
- **Pregões refeitos:** 19/02/2021 (`Sex`, compra liberada) e 22/02/2021 (`Seg`,
  vetada), os da figura 08 da apresentação. Para cada um, os 240 fechamentos até
  a véspera, como o `CopyClose(..., 1, ...)` do EA.
- **Configuração:** a GS de C4 usada no traço da refação de 05/10/2026
  (`gerar_traco.sh`: janela 240, com constante, filtro, percentil 70, zera no
  veto, só compra; o resto vem de `rodada3_b3_oficial/testes/in_r3_base.txt`:
  reseleção a cada 21 pregões, p e q até 4, d até 2, 300 iterações no GARCH).
- **Ordens:** o script acha a última reseleção contando os pregões desde
  01/07/2019 (o primeiro do traço) em passos de 21. Para os dois dias é
  08/02/2021, pregão 399 do teste, e a seleção refeita na janela daquele dia dá
  ARIMA(3,1,0), a do traço. As trocas de ordem no traço caem todas em múltiplos
  de 21 (conferido no `dia_a_dia.csv`).

## Conferência (`conferencia.txt`)

Previsão, volatilidade prevista, limiar, veto, (p,d,q), φ₁, constante, α e β dos
dois pregões coincidem com o que o robô gravou
(`../robo_em_acao_2026-10-30/dia_a_dia.csv`, sha256
`219813f6328761a8f9d1a267adfb3ec00f34ba5d23f10bb335f5b12179bdc93a`, que vem do
traço da refação de 05/10/2026). A recursão do GARCH refeita fora do `CGarch`
com os ω, α e β dele dá a mesma σ (maior diferença 2,8e-17 e 1,4e-17) e a mesma
previsão (`resumo.txt`).

## Arquivos

| Arquivo | Conteúdo |
|---|---|
| `resumo.txt` | log do script: seleção (ADF e grade de AIC), coeficientes, previsão, GARCH e a conferência da recursão |
| `valores.tex` | números das figuras (`\vSex...`/`\vSeg...` com vírgula, `\pSex...`/`\pSeg...` com ponto) |
| `janela_Sex.csv`, `janela_Seg.csv` | uma linha por pregão da janela: fechamento, log-retorno, valor ajustado pelo ARIMA, resíduo e σ (em %), as três parcelas da variância ω, α ε²(t−1) e β σ²(t−1) (em %²) e o limiar. A última linha é o próprio dia: previsão do retorno (coluna `ajustado`), σ prevista e as parcelas dela |
| `aic_Sex.csv`, `aic_Seg.csv` | AIC e distância ao melhor dos 25 modelos na janela da última reseleção |
| `conferencia.txt` | os números do script lado a lado com os do traço |

## Como as colunas foram montadas

- O resíduo `res[j]` do `CArima::ObterResiduos` é o do pregão
  `tempo[240 − nres + j]` (os resíduos terminam no último fechamento).
- `CGarch::ObterSerieVolatilidade` começa no segundo resíduo (`m_inicio = 1`):
  `sig[j−1]` é a σ do pregão do resíduo `res[j]`.
- As parcelas da linha do pregão t usam o resíduo e a σ do pregão t−1. Na
  primeira linha com σ elas ficam vazias, porque a variância anterior é a
  variância amostral de partida, que a classe não expõe.
