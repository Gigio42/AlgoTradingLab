# Traço por barra, PETR4, jul/2019 a jun/2021

> **SUPERADO em 06/10/2026** pela refação com o EA corrigido
> (`../refeito_2026-10-05/LEIAME.md`; erros em `ia/INCERTEZAS.md`, itens 43 a
> 47). Os números desta pasta foram produzidos com o EA antigo e não vão para o TG.


Gerado pelo próprio EA (input `Arquivo_Traco`), na configuração `GS` da rodada 6
(filtro, percentil 70, zera no veto, janela 240, com constante), com o GARCH
ligado (`traco_demo_GARCH.csv`) e desligado (`traco_demo_ARIMA.csv`). Série
`PETR4_OFICIAL`. 39 campos por barra; o cabeçalho é a primeira linha.

Reprodução: `ferramentas/scripts/gerar_traco.sh`.

Uso no TG: o episódio de 03/04/2020 do Capítulo III (seção do mecanismo) sai da
linha `2020.04.03` de `traco_demo_GARCH.csv`: `prev_dif` = 0,02159 (previsão de
alta de 2,159%), `vol_prevista` = 0,07926 (7,93%), `limiar` = 0,02555 (2,56%),
`vetou` = 1. O campo `preco` dessa linha (15,51) é o fechamento do pregão
anterior, 02/04/2020: a decisão de 03/04 usa só barras fechadas.

A queda de 48,6% citada no mesmo parágrafo é 15,51 / 30,18 − 1, com 30,18 = fechamento
de 30/12/2019 em `dados/series/PETR4_OFICIAL.csv`.

Também alimenta o painel de demonstração (`~/algolab-anim/painel.py`, fora do
repositório).

sha256:
- traco_demo_ARIMA.csv b34b74652931ec3cb05d10e0e7ccf51253e119f7b021722760c858e6e4a5b9d2
- traco_demo_GARCH.csv 4715a9c4b0e6de38769a49394ccda1f30c178c42d36c8481774cef2d7837ace8
