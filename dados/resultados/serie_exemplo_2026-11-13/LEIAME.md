# Série de preços de exemplo (13/11/2026)

Pedido do autor em 13/11/2026: uma série de preços para dar de exemplo, como figura,
na seção 1.4 (Modelos estatísticos de séries temporais). **Proposta, fora do TG**:
as figuras estão em `ia/relatorios/serie-precos/`. Não roda o testador: só lê a série.

| Arquivo | Conteúdo |
|---|---|
| `curta.csv` | `indice,data,rotulo,fechamento,retorno`: os últimos 20 pregões de `dados/series/PETR4_OFICIAL.csv` (B3 COTAHIST, `dados/FONTES.md` itens 1 e 2), de 24/08/2026 a 21/09/2026. `fechamento` = campo 6 da série; `retorno` = 100 × ln(fechamento / fechamento do pregão anterior), em %, o primeiro sobre o fechamento de 21/08/2026; `rotulo` = dd/mm, para o eixo. |
| `longa.csv` | `data,fechamento`: 744 pregões de 02/01/2019 a 30/12/2021, o mesmo período do Gráfico 1 do Cap. I (os retornos estão em `heterocedasticidade_2026-11-02/serie.csv`). |

Refazer: `bash ferramentas/scripts/serie_exemplo.sh`.
