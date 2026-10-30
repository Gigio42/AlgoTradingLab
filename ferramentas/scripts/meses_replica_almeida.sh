#!/bin/bash
# meses_replica_almeida.sh <rel_*.htm> [volume_de_referencia]
# A partir da lista de negocios do relatorio do testador, soma por mes do ano
# (todos os anos juntos) as entradas, o lucro e a perda, como nos graficos
# "Entradas por mes" e "Lucros e perdas por mes" de Almeida (2016).
# Com volume_de_referencia, o lucro e a perda sao reescalados para esse volume.
f=$1; ref=${2:-0}
iconv -f UTF-16LE -t UTF-8 "$f" | tr -d '\r\n' | sed 's/<\/tr>/\n/g; s/<[^>]*>/|/g' |
  sed -E 's/\|[[:space:]]+/|/g' | tr -s '|' |
  awk -F'|' -v ref="$ref" '
    /\|Deals\|/ {neg=1}
    neg && $2 ~ /^20[0-9][0-9]\./ && ($6=="in" || $6=="out" || $6=="in/out") {
      m=substr($2,6,2)+0; vol=$7; k=(vol ~ /K/)?1000:1; gsub(/[^0-9.]/,"",vol); vol*=k; if($6=="in/out") vol/=2
      lucro=$12; gsub(/ /,"",lucro); lucro+=0
      if($6=="in" || $6=="in/out") ent[m]++
      if($6=="out" || $6=="in/out") { if(ref>0) lucro*=ref/vol
                                      if(lucro>0) g[m]+=lucro; else p[m]-=lucro } }
    END{ printf "mes     "; for(m=1;m<=12;m++) printf "%7d",m; printf "\nentradas"
         for(m=1;m<=12;m++) printf "%7d",ent[m]; printf "\nlucro   "
         for(m=1;m<=12;m++) printf "%7.0f",g[m]; printf "\nperda   "
         for(m=1;m<=12;m++) printf "%7.0f",p[m]; printf "\n" }'
