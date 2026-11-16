# Heterocedasticidade: dados do Gráfico 1 do Cap. I (02/11/2026)

Pedido do autor em 02/11/2026: explicar a heterocedasticidade no Cap. I (no começo
da Seção 1.6, GARCH), com a PETR4 de exemplo e uma série homocedástica ao lado.
Não roda o testador: só lê a série.

| Arquivo | Conteúdo |
|---|---|
| `serie.csv` | `data,petr4,simulada`: 744 pregões de 02/01/2019 a 30/12/2021. `petr4` = 100 × ln(fechamento / fechamento anterior) de `dados/series/PETR4_OFICIAL.csv` (B3 COTAHIST, `dados/FONTES.md` itens 1 e 2). `simulada` = normal de média zero e desvio-padrão igual ao da PETR4 no período (3,2604), semente 20261102. |
| `resumo.txt` | Desvio-padrão do período, de cada ano e de cada mês, maior queda e maior alta, conferência da série simulada. São os números do texto. |

Refazer: `bash ferramentas/scripts/heterocedasticidade.sh` e, em `tg/`, `make`
(a regra `graficos/heterocedasticidade.pdf` do Makefile recompila o gráfico).

A série simulada usa o `rand()` do GNU Awk 5.4.1. Outra versão do awk pode dar
outros números com a mesma semente: o registro é este `serie.csv`.

Desde a 3ª versão do texto (02/11/2026, pedido do autor) **nenhum número
deste resumo vai para o TG**: o Cap. I só mostra o gráfico. Antes, o texto
usava (todos de `resumo.txt`): desvio-padrão diário de 1,85%
em 2019, 4,49% em 2020 e 2,89% em 2021; fechamento de 22,83 para 16,05 em
09/03/2020 (o menor retorno do período, −35,24% em log, −29,70% simples); desvio-padrão
mensal de 12,46% em março de 2020, 3,67% em abril, 3,17% em maio, 2,59% em
junho e 1,90% em julho.
