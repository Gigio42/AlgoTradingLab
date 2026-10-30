# Dados do relatório sobre o Hannan-Rissanen (30/10/2026)

Pedido do autor: um relatório para entender o Hannan-Rissanen e como ele operou
no robô. O relatório está em `ia/relatorios/hannan-rissanen/relatorio.pdf`.
**Não é parte do TG.**

## Procedência

- **Programa:** `ferramentas/HannanRissanenDetalhado.mq5`, rodado por
  `ferramentas/scripts/hannan_rissanen.sh` no MetaTrader do prefixo em uso.
  Refaz os dois estágios com as regras do `CArima::HannanRissanen` para expor os
  passos intermediários, e confere contra o próprio `CArima`.
- **Séries simuladas:** ARMA(1,1) com φ = 0,6 e θ = 0,4 (os da validação
  numérica) e MA(1) com o θ estimado no pregão real; 239 retornos (o tamanho da
  série do robô com janela 240 e d = 1); semente 20261030. Mil réplicas cada.
- **Pregões reais:** PETR4_OFICIAL, a mesma janela que o EA usou (240
  fechamentos antes do pregão) em 13/05/2021, ARIMA(0,1,1), e 05/06/2020,
  ARIMA(0,1,4), ambos com constante. São pregões do traço da refação de
  05/10/2026 (`refeito_2026-10-05/traco_demo/traco_demo_GARCH.csv`, configuração
  ARIMA-GARCH Sharpe de C4) em que o modelo em uso tinha termo MA.
- **Contagem do traço** (`\vHTracoN`, `\vHTracoDois`...): acrescentada ao
  `valores.tex` pelo script, a partir da coluna `q` do traço.

## Conferências (no fim do `resumo.txt`)

- Série simulada: os dois estágios refeitos dão os mesmos φ e θ do `CArima`.
- Pregões reais: constante, θ₁ a θ_q e previsão refeitos são **idênticos** aos
  gravados no traço (maior diferença absoluta: 0), nos dois pregões.
- Rodado duas vezes com a mesma semente: mesmos números.

## Arquivos

| Arquivo | Conteúdo |
|---|---|
| `resumo.txt` | log completo e as conferências |
| `valores.tex` | números citados no relatório (`\vH...` com vírgula, `\pH...` com ponto) |
| `real_matrizes.tex` | primeiras linhas das matrizes dos dois estágios no pregão real |
| `sint_serie.csv` | série simulada: z, erro verdadeiro, erro do estágio 1, resíduo final |
| `sint_pesos.csv` | pesos do AR infinito verdadeiro × AR longo estimado |
| `sint_ordem.csv` | φ, θ e qualidade dos erros estimados para cada ordem do AR longo (1 a 47) |
| `mc_arma.csv`, `mc_ma.csv` | as mil estimativas por HR, máxima verossimilhança e AR(1) sem MA |
| `real_serie.csv` | pregão real: datas, fechamentos, retornos, erros do estágio 1 e resíduos finais (em %) |
| `real_pesos.csv` | os 29 coeficientes do AR longo no pregão real |
| `real_estagio2.csv` | a regressão do estágio 2 no pregão real (erro estimado de ontem × retorno) |

Observações: `ia/INCERTEZAS.md`, item 84.
