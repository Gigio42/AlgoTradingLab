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
