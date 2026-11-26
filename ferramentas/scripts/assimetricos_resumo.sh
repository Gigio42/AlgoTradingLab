#!/bin/bash
# assimetricos_resumo.sh [pasta]  (18/11/2026)
#
# Le o que o assimetricos.sh gravou e escreve em <pasta>/cru/:
#   testes.csv   uma linha por teste fora da amostra: etapas na ordem do Cap. III
#                (bruto -> + custos -> + proventos -> + Selic), queda maxima e
#                volatilidade anualizada de cada etapa, referencias do periodo
#   pares.csv    a grade inteira de cada calibracao: cada variante contra a base,
#                passagem a passagem (mesmos parametros), so as com GARCH
#   conferencias.txt
# Nada e rodado no MetaTrader. As etapas saem da curva diaria como no
# camadas_ordem_proventos.sh: parado = 1 - min(1, |exposicao|);
# custos = r(camada 3) - parado x selic do dia; + proventos = r(camada 4) - parado x selic.
# Volatilidade = desvio-padrao do retorno diario x raiz(252).
set -euo pipefail
export LC_ALL=C
S="$(cd "$(dirname "$0")" && pwd)"; A="$(cd "$S/../.." && pwd)"
P="${1:-$A/dados/resultados/assimetricos_2026-11-18}"; mkdir -p "$P/cru"

valor(){ tr -d '\r' < "$1" | awk -F';' -v c="$2" 'NR==1{for(i=1;i<=NF;i++) if($i==c) k=i; next} NR==2{print (k ? $k : "")}'; }

#--- testes
{
echo "rotulo,variante,teste,robo,negocios,exposicao,vetos,sinais,p,d,q,gama_medio,nu_medio,janela_arima_media,bruto,custos,proventos,selic_etapa,dd_bruto,dd_custos,dd_proventos,dd_selic_etapa,vol_bruto,vol_custos,vol_proventos,vol_selic_etapa,sharpe,sharpe_p,ref_bh_preco,ref_bh_total,ref_selic,ref_dd_bh_preco,ref_dd_bh_total,ret_custos_ea,ret_completo_ea"
for m in "$P"/testes/metricas_AS_*.csv; do
  rot=$(basename "$m" .csv); rot=${rot#metricas_}; c="$P/testes/curva_$rot.csv"
  [ -s "$c" ] || continue
  r=${rot#AS_}
  if [[ $r == MM_* ]]; then var=MM; tst=${r#MM_}; robo=MM
  else robo=${r##*_}; r=${r%_*}; tst=${r##*_}; var=${r%_*}; fi
  etapas=$(tr -d '\r' < "$c" | awk -F, '
    function acum(k, r) { f[k] *= 1 + r; if(f[k] > pk[k]) pk[k] = f[k]; if(1 - f[k]/pk[k] > dd[k]) dd[k] = 1 - f[k]/pk[k]
                          s[k] += r; q[k] += r*r }
    NR==2 { p1=$4; e3=$2; c4=$5; sl=$3; for(k=1;k<=4;k++){f[k]=1; pk[k]=1; dd[k]=0}; next }
    NR>2 { x=$8; if(x<0)x=-x; if(x>1)x=1; par=1-x; sd=$3/sl-1
           acum(1, $4/p1-1); acum(2, $2/e3-1-par*sd); acum(3, $5/c4-1-par*sd); acum(4, $5/c4-1)
           p1=$4; e3=$2; c4=$5; sl=$3; n++ }
    END { o=""; for(k=1;k<=4;k++) o=o sprintf("%.6f,", f[k]-1)
          for(k=1;k<=4;k++) o=o sprintf("%.6f,", dd[k])
          for(k=1;k<=4;k++) o=o sprintf("%.6f%s", sqrt((q[k]-s[k]*s[k]/n)/(n-1))*sqrt(252), k<4?",":"")
          print o }')
  printf '%s,%s,%s,%s' "$rot" "$var" "$tst" "$robo"
  for col in negocios exposicao vetos sinais p d q gama_medio nu_medio janela_arima_media; do printf ',%s' "$(valor "$m" $col)"; done
  printf ',%s' "$etapas"
  for col in sharpe sharpe_p bh_preco bh_total selic dd_bh_preco dd_bh_total ret_custos ret_completo; do printf ',%s' "$(valor "$m" $col)"; done
  echo
done
} > "$P/cru/testes.csv"

#--- pares na grade (variante x base, mesma configuracao)
CH="UsarGARCH Estrategia ModoLimiar Limiar_Percentil Limiar_Absoluto Vol_Alvo Limiar_Sinal IncluirConstante ZerarNoVeto"
{
echo "variante,calibracao,pares,dd_menor,vol_menor,ret_maior,sharpe_maior,dd_maior,vol_maior,ret_menor,sharpe_menor,med_dif_dd_pp,med_dif_vol_pp,med_dif_ret_pp,med_dif_sharpe"
for d in "$P"/calibracao/*/; do
  v=$(basename "$d"); [ "$v" = base ] && continue
  for f in "$d"PETR4_*.csv; do
    cal=$(basename "$f" .csv); cal=${cal#PETR4_}; b="$P/calibracao/base/PETR4_$cal.csv"; [ -s "$b" ] || continue
    awk -F';' -v ch="$CH" -v v="$v" -v cal="$cal" '
      function chave(  i, s) { s=""; for(i=1;i in K;i++) s=s ";" $h[K[i]]; return s }
      function med(a, n,   i, j, t) { for(i=2;i<=n;i++){t=a[i]; for(j=i-1;j>=1&&a[j]>t;j--) a[j+1]=a[j]; a[j+1]=t}
                                     return n%2 ? a[(n+1)/2] : (a[n/2]+a[n/2+1])/2 }
      FNR==1 { delete h; for(i=1;i<=NF;i++) h[$i]=i; split(ch, K, " "); arq++; next }
      $h["UsarGARCH"]+0 != 1 { next }
      arq==1 { B[chave()] = $h["dd_selic"] ";" $h["vol_selic"] ";" $h["ret_selic"] ";" $h["sharpe"]; next }
      { k=chave(); if(!(k in B)) next; split(B[k], x, ";"); n++
        dd[n]=($h["dd_selic"]-x[1])*100; vo[n]=($h["vol_selic"]-x[2])*100; re[n]=($h["ret_selic"]-x[3])*100; sh[n]=$h["sharpe"]-x[4]
        if(dd[n]<0) a++; if(vo[n]<0) bb++; if(re[n]>0) c++; if(sh[n]>0) e++
        if(dd[n]>0) a2++; if(vo[n]>0) b2++; if(re[n]<0) c2++; if(sh[n]<0) e2++ }
      END { if(!n) exit; printf "%s,%s,%d,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.2f,%.2f,%.2f,%.3f\n", v, cal, n, a/n, bb/n, c/n, e/n, a2/n, b2/n, c2/n, e2/n, med(dd,n), med(vo,n), med(re,n), med(sh,n) }
    ' <(tr -d '\r' < "$b") <(tr -d '\r' < "$f")
  done
done
} > "$P/cru/pares.csv"

#--- conferencias
{
echo "Passagens por grade (esperado 156):"
for f in "$P"/calibracao/*/PETR4_*.csv; do echo "  $(basename "$(dirname "$f")") $(basename "$f" .csv): $(( $(wc -l < "$f") - 1 ))"; done
echo
echo "Base x estudo de 13/11 (janelas_garch_2026-11-13/calibracao/500), passagem a passagem:"
J="$A/dados/resultados/janelas_garch_2026-11-13/calibracao/500"
for cal in C1 C2 C4 C3; do
  b="$P/calibracao/base/PETR4_$cal.csv"; j="$J/PETR4_$cal.csv"; [ -s "$b" ] && [ -s "$j" ] || continue
  awk -F';' -v ch="$CH" '
    function chave(  i, s) { s=""; for(i=1;i in K;i++) s=s ";" $h[K[i]]; return s }
    FNR==1 { delete h; for(i=1;i<=NF;i++) h[$i]=i; split(ch, K, " "); arq++; next }
    arq==1 { J[chave()] = $h["ret_selic"] ";" $h["dd_selic"] ";" $h["negocios"]; next }
    { k=chave(); if(!(k in J)) { falta++; next }; n++
      if(J[k] != $h["ret_selic"] ";" $h["dd_selic"] ";" $h["negocios"]) dif++ }
    END { printf "  %s: %d pares, %d diferentes, %d sem par\n", FILENAME, n, dif+0, falta+0 }
  ' <(tr -d '\r' < "$j") <(tr -d '\r' < "$b") | sed "s|/dev/fd/[0-9]*|$cal|"
done
echo
echo "Testes: ret_custos recalculado da curva x gravado pelo EA (pontos percentuais):"
awk -F, 'NR>1 && $34!="" { d=($16-$34)*100; if(d<0)d=-d; if(d>m)m=d; n++ } END { printf "  %d testes, maior diferenca %.4f p.p.\n", n, m }' "$P/cru/testes.csv"
awk -F, 'NR>1 && $35!="" { d=($18-$35)*100; if(d<0)d=-d; if(d>m)m=d; n++ } END { printf "  etapa final x ret_completo do EA: maior diferenca %.4f p.p.\n", m }' "$P/cru/testes.csv"
echo
echo "Janela media do ARIMA e gama medio nos testes com GARCH:"
awk -F, 'NR>1 && $4!="MM" { k=$2; j[k]=j[k]" "$14; if($4!="GSgemeo" && $12!="") g[k]=g[k]" "$12 } END { for(k in j) print "  " k ": janela" j[k] " | gama" g[k] }' "$P/cru/testes.csv" | sort
} > "$P/cru/conferencias.txt"
cat "$P/cru/conferencias.txt"
