# Camada 4 com os proventos da B3 (21/10/2026)

Pedido do autor: o trabalho não usa mais o Yahoo. Os 15 testes das tabelas de
camadas do Cap. III (`tab:camadas-*`) foram refeitos com
`dados/series/proventos_PETR4.csv` gerado da API oficial da B3
(`ferramentas/scripts/proventos_b3.sh`, `dados/FONTES.md` item 3), pelo
`ferramentas/scripts/camadas_proventos_b3.sh`, com as mesmas configurações de
`../testes/execucao.log`.

Conferência: comparadas coluna a coluna pelo nome com `../testes/`, as métricas
só mudaram nas colunas que dependem de proventos (`ret_completo`, `bh_total` e
derivadas: `cagr_*`, `excesso_completo`, `dd_completo`, `sharpe_completo*`,
`sharpe_bh_total`); nas curvas diárias, só `completo` e `buyhold_total`.
Bruto, custos, Selic, operações, queda e volatilidade são idênticos.

Valores antes (Yahoo) e depois (B3): `tabelas_camadas.txt`.

## Ordem bruto → custos → proventos → Selic (17/11/2026)

Pedido do autor: a coluna antes da Selic passa a ser o capital de fora num saldo
que não rende, e a última, numa conta remunerada. `camadas_ordem_proventos.txt`,
gerado por `ferramentas/scripts/camadas_ordem_proventos.sh` a partir das curvas
desta pasta (nada rodado no MT5). Conferência: a coluna "+ custos" recalculada
bate com `ret_custos` do EA (diferença ≤ 0,001 p.p.); a última coluna é
`ret_completo`, que não depende da ordem.

## 2005–2026 com os proventos da B3 (17/11/2026)

Pergunta do autor: o período mais longo com custos, proventos e Selic. Os quatro
testes L1 (GS, GC, gêmea, MM) refeitos por `ferramentas/scripts/camadas_proventos_b3_longo.sh`
(`execucao_longo.log`). Conferência: comparadas por nome com `../testes/metricas_L1_*`,
todas as colunas que não dependem de proventos são idênticas. A tabela por etapa
está em `camadas_ordem_proventos.txt` (linhas L1). A 1ª tentativa da MM falhou
porque o `MediasMoveis2.ex5` do prefixo novo estava velho (sem `Rotulo` e
`Fracao_Capital`); recompilado e rodado de novo (INCERTEZAS item 119).
