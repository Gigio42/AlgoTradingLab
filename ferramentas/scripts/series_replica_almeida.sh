#!/bin/bash
# Series da replica de Almeida, rodada 2 (21/10/2026). Ver
# dados/resultados/replica_almeida_v2_2026-10-21/PROTOCOLO.md.
#   VLID3_OFICIAL.csv   COTAHIST sem ajuste (nenhum evento entre 2012 e 2016)
#   CIEL3_ESTIMADO.csv  COTAHIST com as bonificacoes ajustadas por fatores
#                       ESTIMADOS pelo salto de preco (sem fonte oficial)
#   PETR4_DESDE2008.csv PETR4_OFICIAL a partir de 02/01/2008 (hipotese de
#                       historico do servidor comecando em 2008)
A="$(cd "$(dirname "$0")/../.." && pwd)"
F="$A/dados/fontes/b3"; S="$A/dados/series"

linhas_para_csv(){ # campos do layout COTAHIST (ver dados/FONTES.md, item 1)
  awk '{d=substr($0,3,8); o=substr($0,57,13)/100; h=substr($0,70,13)/100; l=substr($0,83,13)/100;
        c=substr($0,109,13)/100; q=substr($0,153,18)+0
        printf "%s.%s.%s,00:00,%.2f,%.2f,%.2f,%.2f,%d\n",substr(d,1,4),substr(d,5,2),substr(d,7,2),o,h,l,c,q}' "$1"
}

linhas_para_csv "$F/VLID3_linhas_COTAHIST_2011_2016.txt" > "$S/VLID3_OFICIAL.csv"

# Data-ex e fator (acoes depois / antes). ESTIMATIVA: razao redonda mais
# proxima do salto fechamento anterior -> abertura (notas/INCERTEZAS.md).
linhas_para_csv "$F/CIEL3_linhas_COTAHIST_2011_2016.txt" | awk -F, -v OFS=, '
  BEGIN{ n=split("2012.04.23 1.2 2013.04.29 1.2 2014.04.01 2.0 2015.04.13 1.2 2016.04.11 1.15",e," ")
         for(i=1;i<=n;i+=2){d[i]=e[i]; f[i]=e[i+1]} }
  $1>="2011.06.01" { k=1; for(i=1;i<=n;i+=2) if($1<d[i]) k*=f[i]
    printf "%s,%s,%.2f,%.2f,%.2f,%.2f,%d\n",$1,$2,$3/k,$4/k,$5/k,$6/k,$7*k }' > "$S/CIEL3_ESTIMADO.csv"

awk -F, '$1>="2008.01.01"' "$S/PETR4_OFICIAL.csv" > "$S/PETR4_DESDE2008.csv"

# PETR4_SET2007: PETR4_OFICIAL a partir de 04/09/2007. Sem historico anterior, o
# testador adia o inicio ate ter 100 barras ("start time changed ... to provide
# data at beginning"), e os dois testes de crise passam a comecar em 07/02/2008.
awk -F, '$1>="2007.09.04"' "$S/PETR4_OFICIAL.csv" > "$S/PETR4_SET2007.csv"

wc -l "$S/VLID3_OFICIAL.csv" "$S/CIEL3_ESTIMADO.csv" "$S/PETR4_DESDE2008.csv" "$S/PETR4_SET2007.csv"

# PETR4_DIVAJ2016: PETR4_OFICIAL a partir de 04/09/2007, ajustada pelos proventos com data-ex ate
# 03/06/2016 (series/proventos_PETR4.csv, Yahoo, NAO OFICIAL), fator
# multiplicativo 1 - provento/fechamento anterior, aplicado a todas as barras
# anteriores a data-ex. Hipotese: o historico da corretora dele (2016) vinha
# ajustado por proventos.
awk -F, 'NR==FNR { if($0 !~ /^#/ && $1<="2016.06.03") { nd++; dd[nd]=$1; vv[nd]=$2 } next }
         { n++; d[n]=$1; h[n]=$2; o[n]=$3; a[n]=$4; b[n]=$5; c[n]=$6; q[n]=$7 }
         END{ for(i=1;i<=n;i++) k[i]=1
              for(j=1;j<=nd;j++){ for(i=2;i<=n && d[i]<dd[j];i++); if(i>n) continue
                f=1-vv[j]/c[i-1]; for(t=1;t<i;t++) k[t]*=f }
              for(i=1;i<=n;i++) if(d[i]>="2007.09.04")
                printf "%s,%s,%.2f,%.2f,%.2f,%.2f,%d\n",d[i],h[i],o[i]*k[i],a[i]*k[i],b[i]*k[i],c[i]*k[i],q[i] }' \
    "$S/proventos_PETR4.csv" "$S/PETR4_OFICIAL.csv" > "$S/PETR4_DIVAJ2016.csv"
wc -l "$S/PETR4_DIVAJ2016.csv"

# PETR4_PROVB3_2008: PETR4_OFICIAL a partir de 02/01/2008, ajustada pelos proventos
# OFICIAIS da B3 (fontes/b3/proventos_PETR_historico_api_b3_2026-10-21/, acao PN,
# dividendo + JCP + rendimento, data-com ate 03/06/2016). Data-ex = pregao seguinte
# a data-com. Valores com data-com antes do desdobramento de 28/04/2008 divididos
# por 2. Fator multiplicativo 1 - provento/fechamento da data-com, aplicado as
# barras anteriores a data-ex. Hipotese: servidor da corretora com historico desde
# o inicio de 2008, ajustado por proventos.
jq -r '.results[] | select(.typeStock=="PN") | [.lastDatePriorEx,.corporateAction,.valueCash] | @tsv' \
   "$F"/proventos_PETR_historico_api_b3_2026-10-21/p*.json |
  awk -F'\t' -v OFS=, '{ split($1,x,"/"); d=x[3]"."x[2]"."x[1]; v=$3; sub(",",".",v); v+=0
         if(d<"2008.04.28") v/=2; s[d]+=v } END{ for(d in s) print d,sprintf("%.6f",s[d]) }' |
  LC_ALL=C sort > "$S/proventos_PETR4_B3.csv"
awk -F, 'NR==FNR { if($1>="2007.01.01" && $1<="2016.06.03") { nd++; dd[nd]=$1; vv[nd]=$2 } next }
         { n++; d[n]=$1; h[n]=$2; o[n]=$3; a[n]=$4; b[n]=$5; c[n]=$6; q[n]=$7 }
         END{ for(i=1;i<=n;i++) k[i]=1
              for(j=1;j<=nd;j++){ for(i=1;i<=n && d[i]<=dd[j];i++); if(i>n || i==1) continue
                f=1-vv[j]/c[i-1]; for(t=1;t<i;t++) k[t]*=f }
              for(i=1;i<=n;i++) if(d[i]>="2008.01.02")
                printf "%s,%s,%.2f,%.2f,%.2f,%.2f,%d\n",d[i],h[i],o[i]*k[i],a[i]*k[i],b[i]*k[i],c[i]*k[i],q[i] }' \
    "$S/proventos_PETR4_B3.csv" "$S/PETR4_OFICIAL.csv" > "$S/PETR4_PROVB3_2008.csv"
wc -l "$S/proventos_PETR4_B3.csv" "$S/PETR4_PROVB3_2008.csv"

# CIEL3_PROVB3 e VLID3_PROVB3: as series acima ajustadas pelos proventos em dinheiro
# OFICIAIS da B3 (fontes/b3/proventos_CIEL_VLID_historico_api_b3_2026-10-21/, acao
# ON, data-com ate 03/06/2016), pelo mesmo metodo da PETR4_PROVB3. Na CIEL3 o valor
# por acao e dividido pelas bonificacoes posteriores a data-com (fatores ESTIMADOS,
# os mesmos da CIEL3_ESTIMADO), para ficar na unidade da serie.
ajustar_prov(){ # <cash_*.json...> -- serie entrada, serie saida, eventos de bonificacao "data fator ..."
  local bon=$1 ent=$2 sai=$3; shift 3
  jq -r '.results[] | select(.typeStock=="ON") | [.lastDatePriorEx,.valueCash] | @tsv' "$@" |
    awk -F'\t' -v OFS=, -v bon="$bon" 'BEGIN{ nb=split(bon,e," ") }
      { split($1,x,"/"); d=x[3]"."x[2]"."x[1]; v=$2; sub(",",".",v); v+=0
        for(i=1;i<=nb;i+=2) if(d<e[i]) v/=e[i+1]; s[d]+=v } END{ for(d in s) print d,sprintf("%.6f",s[d]) }' |
    LC_ALL=C sort > "$TMPPROV"
  awk -F, 'NR==FNR { if($1<="2016.06.03") { nd++; dd[nd]=$1; vv[nd]=$2 } next }
           { n++; d[n]=$1; h[n]=$2; o[n]=$3; a[n]=$4; b[n]=$5; c[n]=$6; q[n]=$7 }
           END{ for(i=1;i<=n;i++) k[i]=1
                for(j=1;j<=nd;j++){ for(i=1;i<=n && d[i]<=dd[j];i++); if(i>n || i==1) continue
                  f=1-vv[j]/c[i-1]; for(t=1;t<i;t++) k[t]*=f }
                for(i=1;i<=n;i++)
                  printf "%s,%s,%.2f,%.2f,%.2f,%.2f,%d\n",d[i],h[i],o[i]*k[i],a[i]*k[i],b[i]*k[i],c[i]*k[i],q[i] }' \
      "$TMPPROV" "$ent" > "$sai"
}
TMPPROV=$(mktemp); PC="$F/proventos_CIEL_VLID_historico_api_b3_2026-10-21"
ajustar_prov "2012.04.23 1.2 2013.04.29 1.2 2014.04.01 2.0 2015.04.13 1.2 2016.04.11 1.15" \
  "$S/CIEL3_ESTIMADO.csv" "$S/CIEL3_PROVB3.csv" "$PC"/cash_CIELO_*.json
ajustar_prov "" "$S/VLID3_OFICIAL.csv" "$S/VLID3_PROVB3.csv" "$PC"/cash_VALID_*.json
rm -f "$TMPPROV"
wc -l "$S/CIEL3_PROVB3.csv" "$S/VLID3_PROVB3.csv"
