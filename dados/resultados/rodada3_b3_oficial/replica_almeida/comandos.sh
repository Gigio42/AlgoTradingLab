#!/bin/bash
S=$(dirname "$0"); N="$HOME/.wine-mt5-novo/drive_c/Program Files/MetaTrader 5"; MM='MediasMoveis2\MediasMoveis2'
for sim in PETR4_OFBRUTO PETR4_OFICIAL; do for st in "50 100" "0 0"; do set -- $st
 for per in "0711 2007.01.02 2011.12.30 100" "1316 2013.01.02 2016.12.30 1000"; do set -- $st $per
  rot=R_${sim#PETR4_}_sl$1_$3
  bash $S/rodar.sh $rot "$MM" $sim $4 $5 50000 1:100 $S/in_mm.txt Volume_Fixo_Input=$6 Fracao_Capital=0 SomenteCompra=false StopLoss_Points=$1 TakeProfit_Points=$2 Custo_Por_Lado=0 >/dev/null
  python3 - "$S/exp/rel/rel_$rot.htm" "$rot" <<'P'
import sys,re,html
t=open(sys.argv[1],encoding="utf-16").read(); txt=html.unescape(re.sub("<[^>]+>","|",t))
def campo(n):
    m=re.search(re.escape(n)+r"\|+([^|]+)",txt); return m.group(1).strip() if m else "?"
print(f"{sys.argv[2]:26s} lucro {campo('Total Net Profit:'):>10s} | FL {campo('Profit Factor:'):>5s} | negocios {campo('Total Trades:'):>4s}")
P
 done; done; done
