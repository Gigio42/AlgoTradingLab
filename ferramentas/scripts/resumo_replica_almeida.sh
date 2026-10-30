#!/bin/bash
# resumo_replica_almeida.sh <pasta com rel_*.htm>
# Uma linha por relatorio do testador: operacoes, operacoes com lucro, lucro
# bruto, perda bruta, liquido e a maior sequencia de ganhos (quantidade e R$).
printf "%-28s %5s %5s %10s %10s %10s %s\n" relatorio oper ganho bruto perda liquido "seq.ganhos"
for f in "$1"/rel_*.htm; do
  iconv -f UTF-16LE -t UTF-8 "$f" | tr -d '\r\n' | sed 's/<\/tr>/\n/g; s/<[^>]*>/|/g' | sed -E 's/\|[[:space:]]+/|/g' | tr -s '|' |
  awk -F'|' -v n="$(basename "$f" .htm | sed 's/^rel_//')" '
    function v(x){gsub(/ /,"",x); sub(/\(.*/,"",x); return x}
    { for(i=1;i<=NF;i++){ gsub(/^[ \t]+|[ \t]+$/,"",$i) }
      for(i=1;i<NF;i++){
        if($i=="Total Trades:") t=v($(i+1))
        if($i=="Gross Profit:") gp=v($(i+1))
        if($i=="Gross Loss:") gl=v($(i+1))
        if($i=="Total Net Profit:") np=v($(i+1))
        if($i=="Profit Trades (% of total):") w=v($(i+1))
        if($i=="Maximal consecutive profit (count):") mc=$(i+1)
      } }
    END{ printf "%-28s %5s %5s %10s %10s %10s %s\n", n,t,w,gp,gl,np,mc }'
done
