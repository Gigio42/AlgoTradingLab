# Dados dos gráficos que explicam os métodos (30/10/2026)

Pedido do autor: gráficos que ajudem a visualizar os métodos por trás do robô.
As figuras ficam em `apresentacao/graficos_metodos/`. **Não estão no TG.**

## Procedência

- **Série:** `PETR4_OFICIAL` (B3 COTAHIST, ver `dados/FONTES.md`), 500 pregões
  de 17/09/2024 a 18/09/2026. É a mesma janela da validação numérica
  (`dados/verificacao/validacao_numerica_2026-10-05.txt`), escolhida para
  que os números pudessem ser conferidos contra ela.
- **Programa:** `ferramentas/MetodosIlustrados.mq5`, que chama as funções do
  próprio robô (`robos/Include/`). Rodado por
  `ferramentas/scripts/metodos_ilustrados.sh` no MetaTrader do prefixo em uso.
- **Nada foi digitado à mão.** Os números que aparecem escritos nas figuras vêm
  de `valores.tex`, gerado pelo mesmo programa.

## Conferência

| O quê | Validação de 05/10 | Este programa |
|---|---|---|
| ADF do log-preço / do log-retorno | −0,9468 / −6,1396 | −0,9468 / −6,1396 |
| ARIMA(1,1,1): φ / θ | 0,139876 / −0,076773 | 0,139876 / −0,076773 |
| GARCH(1,1): α / β | 0,126435 / 0,587799 | 0,126435 / 0,587799 |
| Volatilidade prevista | 0,016432 | 0,016432 |
| Ljung-Box dos resíduos / dos padronizados² | p = 0,0093 / 0,7492 | p = 0,0093 / 0,7492 |

O programa também refaz por conta própria duas contas que o robô faz por dentro.
Os resultados coincidem com os do robô (`resumo.txt`):

- os dois estágios do Hannan-Rissanen, que dão os mesmos φ e θ do `CArima`;
- a otimização do GARCH, com as mesmas opções do `CGarch::Ajustar`, mas
  registrando cada iteração. Ela chega aos mesmos ω, α e β.

## Arquivos

| Arquivo | Conteúdo | Figura |
|---|---|---|
| `resumo.txt` | log completo, com a grade de AIC | — |
| `valores.tex` | números citados nas figuras (`\vX` com vírgula, `\pX` com ponto) | todas |
| `mqo_dispersao.csv`, `mqo_perfil.csv` | AR(1) por MQO: pontos, reta e soma dos quadrados por φ | 1 |
| `hr_ar_longo.csv`, `hr_erros.csv` | estágio 1 (38 coeficientes) e erros estimados dos últimos 60 pregões | 2 |
| `gv_densidade.csv`, `gv_volatilidade.csv` | densidade no dia de maior resíduo; resíduos e σ do GARCH | 3 |
| `gv_superficie.csv`, `ot_caminho.csv` | log-verossimilhança em α × β (ω fixo, cortada em −60; `viavel` = 0 fora da restrição) e as iterações do MinBLEIC | 4 |
| `lb_acf.csv`, `lb_parcelas.csv` | autocorrelações e Q acumulado | 5 |
| `adf_series.csv`, `adf_dispersao_*.csv` | séries e regressão de Dickey-Fuller simples | 6 |
| `aic_grade.csv` | AIC, log L e k dos 25 modelos | 7 |

Observações que surgiram ao montar os gráficos: `ia/INCERTEZAS.md`, item 82.
