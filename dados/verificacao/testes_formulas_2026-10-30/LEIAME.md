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
| `garch_decisao.csv` | Seção H (31/10): concordância da decisão do filtro com parâmetros estimados × verdadeiros, 500 séries por tamanho (240, 500, 1000) e percentil (50, 70). |

## O que deu (detalhes no relatório e em `ia/INCERTEZAS.md`, item 85)

- As 20 identidades passam: 11 com diferença zero, as outras até 3,1e-14; a do
  valor crítico (2,9e-9) é o termo b1/T da fórmula com T = 1e9.
- Tamanho: ADF 5,6% (5,0% sem defasagens), Ljung-Box 5,5%.
- Ljung-Box nos resíduos de ARMA(1,1) ajustado: 7,9% com o desconto de p+q
  graus de liberdade, 3,8% sem.
- GARCH com 240 pontos: β médio 0,824 (desvio 0,142) para β verdadeiro 0,89;
  com 1000 pontos, 0,884 (0,027).

## Seção H, acrescentada em 31/10/2026: quanto os achados pesam nas decisões

Pedido do autor. A seção roda no fim do programa, depois das outras: os números
de A a G não mudaram (conferido no `resumo.txt`).

- Ljung-Box, mesmas séries ajustadas pelos dois estimadores do `CArima`:
  AR(1) 4,55% e 4,55%; MA(1) 7,95% (Hannan-Rissanen) e 4,75% (máxima
  verossimilhança); ARMA(1,1) 7,60% e 4,90%. O excesso vem da estimação do termo
  MA por Hannan-Rissanen, não do teste.
- ADF nas 5.641 janelas de 240 pregões da PETR4_OFICIAL: o log-preço rejeitou
  em 5,53%; 39 janelas (0,69%) caem entre o quantil empírico (−2,918) e o valor
  crítico usado, e só nelas a decisão mudaria. O log-retorno rejeitou em 99,80%.
- GARCH simulado (ω 1e-5, α 0,09, β 0,89): decisão do filtro igual à dos
  parâmetros verdadeiros em 91,8% (240, percentil 50), 96,4% (500) e 98,0%
  (1000); com percentil 70, 95,2%, 95,2% e 97,6%.
- PETR4 real, 1.076 dias (um a cada 5 pregões), GARCH sobre log-retornos menos a
  média: decisão igual com 240 e 500 em 80,4% (percentil 50) e 82,2% (70);
  persistência > 0,999 em 7,9% (240) e 0,3% (500).
