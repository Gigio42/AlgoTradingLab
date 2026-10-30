# Testes das fórmulas do código (30/10/2026)

Pedido do autor: um relatório que mostre, com dados, que as funções em MQL5 do
robô calculam o que as fórmulas dizem. O relatório está em
`ia/relatorios/testes-do-codigo/relatorio.pdf`. **Não é parte do TG** (a
validação do código saiu do texto em 18/10/2026).

## Procedência

- **Programa:** `ferramentas/TestesFormulas.mq5`, rodado por
  `ferramentas/scripts/testes_formulas.sh` no MetaTrader do prefixo em uso.
  Chama as mesmas funções do robô (`robos/Include/`): `MQO`, `RegressaoADF`,
  `TesteADF`, `ValorCriticoADF5`, `DeterminarOrdemD`, `TesteLjungBox`,
  `CArima`, `BuscarMelhorPQ`, `CGarch`, `Percentil`.
- **Dados reais:** PETR4_OFICIAL, 500 fechamentos até 18/09/2026, em
  log-preço (a janela da validação numérica de 05/10/2026). Resíduos reais = os
  do ARIMA(1,1,1) com constante nessa janela.
- **Simulações:** normais por Box-Muller, semente 20261031. Séries de 240 pontos
  (239 retornos), o tamanho da janela do robô. Rodado três vezes (a 2ª e a 3ª
  só mudaram o formato de `identidades.csv` e separaram `garch_mc_*.csv`):
  `valores.tex` idêntico nas três.

## Arquivos

| Arquivo | Conteúdo |
|---|---|
| `resumo.txt` | Saída completa, teste a teste. |
| `valores.tex` | Macros `\vT...` (texto) e `\pT...` (coordenada) que o relatório lê. |
| `identidades.csv` | As 20 comparações código × fórmula refeita à parte (separador `;`); `log10` = −17 quando a diferença é zero. |
| `adf_h0.csv` | Estatística ADF em 5000 passeios aleatórios (defasagens pelo AIC). |
| `adf_poder.csv` | Rejeição do ADF em AR(1) com φ de 0,80 a 0,98 (2000 séries cada) e em φ = 1. |
| `adf_ordem_d.csv` | d escolhido pelo `DeterminarOrdemD` em 1000 séries I(0), I(1) e I(2). |
| `lb_h0.csv`, `lb_densidade.csv` | Q de Ljung-Box em 5000 ruídos brancos e a densidade qui-quadrado(10). |
| `aic_selecao_ar1.csv`, `aic_selecao_passeio.csv` | Frequência de cada (p,q) escolhido pela grade do AIC (500 séries cada). |
| `hr_recuperacao.csv` | Média e desvio do φ (AR(1)) e do θ (MA(1)) estimados pelo `CArima`, 500 séries por valor. |
| `garch_grade.csv` | log L do GARCH em 41 × 41 pares (α, β) em volta do ponto estimado, ω fixo; `dl` = diferença para o ponto do robô (limitada em −60). |
| `garch_perturbacao.csv` | Variação do log L ao mexer um parâmetro de cada vez. |
| `garch_mc_240.csv`, `garch_mc_1000.csv` | Parâmetros estimados em 300 séries GARCH(1,1) simuladas de cada tamanho. |

## O que deu (detalhes no relatório e em `ia/INCERTEZAS.md`, item 85)

- As 20 identidades passam: 11 com diferença zero, as outras até 3,1e-14; a do
  valor crítico (2,9e-9) é o termo b1/T da fórmula com T = 1e9.
- Tamanho: ADF 5,6% (5,0% sem defasagens), Ljung-Box 5,5%.
- Ljung-Box nos resíduos de ARMA(1,1) ajustado: 7,9% com o desconto de p+q
  graus de liberdade, 3,8% sem.
- GARCH com 240 pontos: β médio 0,824 (desvio 0,142) para β verdadeiro 0,89;
  com 1000 pontos, 0,884 (0,027).
