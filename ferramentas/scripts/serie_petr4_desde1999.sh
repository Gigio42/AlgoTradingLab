#!/bin/bash
# serie_petr4_desde1999.sh <linhas_COTAHIST> [inicio AAAAMMDD]  -> série no formato do importador (stdout)
#
# Monta a série da PETR4 corrigida por eventos societários a partir das linhas
# originais do COTAHIST (filtro: registro 01, BDI 02, código PETR4, mercado 010),
# com a mesma regra do PETR4_OFICIAL (dados/FONTES.md, itens 1 e 2) e mais o
# grupamento de 2000 (02/11/2026, estudo do GARCH com 1000 pregões):
#   - preço = campo / 100 / fator de cotação (fator 1000 até 21/06/2000, depois 1);
#   - grupamento de 100 para 1 (último dia com: 21/06/2000; API da B3,
#     "GRUPAMENTO", fator 0,01): antes de 23/06/2000, preço × 100 e quantidade ÷ 100;
#   - desdobramentos: antes de 28/04/2008, preço ÷ 2; antes de 01/09/2005, ÷ 4
#     adicional; quantidade multiplicada pelo mesmo fator;
#   - preço arredondado a 2 casas, quantidade inteira.
# Rodada sobre as linhas de 2003 a 2026, reproduz dados/series/PETR4_OFICIAL.csv.
f="$1"; ini="${2:-00000000}"
[ -s "$f" ] || { echo "uso: $0 <linhas_COTAHIST> [inicio AAAAMMDD]" >&2; exit 1; }
tr -d '\r' < "$f" | sort -k1.3,1.10 | awk -v ini="$ini" '
  substr($0,1,2)=="01" && substr($0,11,2)=="02" && substr($0,13,12)=="PETR4       " && substr($0,25,3)=="010" {
    d = substr($0,3,8); if (d < ini) next
    fc = substr($0,211,7) + 0
    k = 1 / fc                         # preço por ação
    q = substr($0,153,18) + 0
    if (d < "20000623") { k *= 100; q /= 100 }
    if (d < "20080428") { k /= 2; q *= 2 }
    if (d < "20050901") { k /= 4; q *= 4 }
    o = substr($0,57,13)/100*k; h = substr($0,70,13)/100*k; l = substr($0,83,13)/100*k; c = substr($0,109,13)/100*k
    printf "%s.%s.%s,00:00,%.2f,%.2f,%.2f,%.2f,%d\n", substr(d,1,4), substr(d,5,2), substr(d,7,2), o, h, l, c, q + 0.5
  }'
