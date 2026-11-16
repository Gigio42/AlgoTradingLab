# Otimização × teste (02/11/2026)

Dados do relatório de estudo `ia/relatorios/otimizacao/` (parte 1 de 3, pedido do
autor depois de ver o "Gráfico de otimização" do MetaTrader). **Não está no TG.**

Nada foi rodado no MetaTrader. `ferramentas/scripts/otimizacao_teste.sh` lê os
pareados da refação de 05/10/2026
(`../refeito_2026-10-05/pareados/PETR4_C{1,2,3}_T{1,2,3}.csv`), que já trazem,
configuração a configuração, a passagem da otimização (`_c`) e a do teste (`_t`).

Recorte: a grade do TG, só compra e sem o intervalo de confiança (Estrategia=2
com GARCH), **312 configurações** (304 com GARCH, 8 sem). Métricas: Sharpe e
Calmar das colunas `sharpe` e `calmar` do OnTester, com custos e caixa na Selic,
que são as da escolha (não a camada crua do Cap. III).

| Arquivo | O que é |
|---|---|
| `pontos_T1.csv`, `pontos_T2.csv`, `pontos_T3.csv` | Um ponto por configuração: `garch` (1/0), Sharpe e Calmar na otimização e no teste. T1 = 2004–06 → 2007–11, T2 = 2010–12 → 2013–16, T3 = 2022–24 → 2025–set/2026. |
| `valores.tex` | Macros lidas pelo relatório: coordenadas das escolhidas, posição delas no teste, mediana do teste e Spearman. |
| `resumo.txt` | O mesmo, legível. |

## Conferências

1. A escolha refeita pelo script (maior valor entre as com GARCH; desempate por
   menos negócios) coincide com a oficial (`../refeito_2026-10-05/escolhas/r3_C*.txt`)
   nos três períodos. O script para com erro se não coincidir.
2. Sharpe e Calmar da escolhida no teste, na grade, são iguais aos do teste
   individual (`../refeito_2026-10-05/testes/metricas_R3_T*_G*.csv`), nos seis casos.
3. Com `INCLUIR_IC=1` (344 configurações, o recorte antigo), o Spearman reproduz o
   bloco 5 de `../refeito_2026-10-05/analise_grades.txt`: Sharpe 0,10 / −0,05 / −0,02
   e Calmar 0,46 / 0,28 / 0,37.

O período 2014–2016 → 2017–2024 não entra: a grade não foi rodada inteira em
2017–2024.
