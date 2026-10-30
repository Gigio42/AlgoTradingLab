#!/bin/bash
# dados_cru.sh
#
# Gera, a partir dos testes da refação de 05/10/2026, os dados do Cap. III na
# camada 1 (crua: sem custo, sem Selic no caixa, sem proventos) e a tabela das
# quatro camadas. Nada é simulado de novo: tudo sai de metricas_*.csv e
# curva_*.csv de refeito_2026-10-05/testes.
#
# Saída em dados/resultados/refeito_2026-10-05/cru/:
#   tabelas.txt          por período e robô: negócios, retorno/queda/vol crus,
#                        retorno nas camadas 2, 3 e 4, exposição, acerto
#   efeito_garch.txt     cada versão × a mesma configuração sem GARCH, crua
#   recorte_2008.txt     ano de 2008 dentro de 2007-2011 (recorte_ano.sh, COL=puro)
#   recorte_2020.txt     ano de 2020 dentro de 2017-2024
#   anual_T1.csv, anual_T2.csv, anual_R6.csv, anual_T3.csv  retorno por ano, cru
#   exposicao_T1.csv     fração do patrimônio na ação, média dos 21 pregões
#                        anteriores, e PETR4 base 100 (gráfico do mecanismo)
#   curva_2008.csv, curva_2020.csv  o ano da crise dentro do período, base 100
#                        no fim do ano anterior, e queda dentro do ano
#   exposicao_2008.csv, exposicao_2020.csv  GS × ARIMA no ano, média dos 5
#                        pregões anteriores
#   exposicao_mensal_2020.txt  exposição e retorno de cada mês de 2020
#
# Uso (da raiz do repositório): bash ferramentas/scripts/dados_cru.sh
set -e
raiz=$(cd "$(dirname "$0")/../.." && pwd)
# RES troca a pasta de resultados (padrão: a refação de 05/10, que é a do TG);
# o estudo das janelas 240/500 de 26/10/2026 usa RES=.../janelas_240_500_2026-10-26.
RES="${RES:-$raiz/dados/resultados/refeito_2026-10-05}"
T="$RES/testes"
O="$RES/cru"
S="$raiz/ferramentas/scripts"
mkdir -p "$O"
# Em 2007-2011 a refação escolheu a mesma configuração pelos dois critérios (GC =
# GS); no estudo de 26/10 não. Com curvas diferentes, o GC entra separado.
cmp -s "$T/curva_R3_T1_GS.csv" "$T/curva_R3_T1_GC.csv" && T1GC= || T1GC=1

linha() {  # linha <rotulo do arquivo> <nome na tabela>
  LC_ALL=C awk -F';' -v nome="$2" 'NR==1{for(i=1;i<=NF;i++)c[$i]=i; next}
    {printf "%-26s neg=%4d acerto=%5.1f exp=%4.2f | cru: ret=%+7.1f queda=%5.1f vol=%5.1f | custos=%+7.1f selic=%+7.1f proventos=%+7.1f\n",
       nome, $c["saidas"], 100*$c["taxa_acerto"], $c["exposicao"], 100*$c["ret_puro"], 100*$c["dd_puro"],
       100*$c["vol_puro"], 100*$c["ret_custos"], 100*$c["ret_selic"], 100*$c["ret_completo"]}' "$T/metricas_$1.csv"
}
ref() {  # ref <rotulo de um robô do período>: PETR4 e Selic do período
  LC_ALL=C awk -F';' 'NR==1{for(i=1;i<=NF;i++)c[$i]=i; next}
    {printf "%-26s preço: ret=%+7.1f queda=%5.1f vol=%5.1f | com proventos: ret=%+7.1f queda=%5.1f\n%-26s ret=%+7.1f\n",
       "PETR4", 100*$c["bh_preco"], 100*$c["dd_bh_preco"], 100*$c["vol_bh_preco"], 100*$c["bh_total"], 100*$c["dd_bh_total"],
       "Selic", 100*$c["selic"]}' "$T/metricas_$1.csv"
}

{
  echo "Camada 1 = crua; custos = camada 2; selic = camada 3; proventos = camada 4 (Yahoo, não oficial)."
  echo "Fonte: $(basename "$RES")/testes/metricas_*.csv (ret_puro, dd_puro, vol_puro, ret_custos, ret_selic, ret_completo)."
  echo; echo "== 2007 a 2011$([ -z "$T1GC" ] && echo " (versões A e B são a mesma configuração)")"
  linha R3_T1_MM "Médias móveis"; linha R3_T1_AS "ARIMA"; if [ -n "$T1GC" ]; then linha R3_T1_GS "ARIMA-GARCH A"; linha R3_T1_GC "ARIMA-GARCH B"; else linha R3_T1_GS "ARIMA-GARCH A e B"; fi; ref R3_T1_GS
  echo; echo "== 2013 a 2016"
  linha R3_T2_MM "Médias móveis"; linha R3_T2_AS "ARIMA"; linha R3_T2_GS "ARIMA-GARCH A"; linha R3_T2_GC "ARIMA-GARCH B"; ref R3_T2_GS
  echo; echo "== 2017 a 2024"
  linha R6_MM "Médias móveis"; linha R6_ARIMA "ARIMA"; linha R6_GS "ARIMA-GARCH A"; linha R6_GC "ARIMA-GARCH B"; ref R6_GS
  echo; echo "== 2025 a 2026"
  linha R3_T3_MM "Médias móveis"; linha R3_T3_AS "ARIMA"; linha R3_T3_GS "ARIMA-GARCH A"; linha R3_T3_GC "ARIMA-GARCH B"; ref R3_T3_GS
} > "$O/tabelas.txt"

{
  echo "Cada versão com GARCH × a mesma configuração sem GARCH, camada 1 (crua)."
  printf "%-16s %8s %8s | %7s %7s | %7s %7s | ret>  queda<  vol<\n" teste ret_G ret_sem queda_G q_sem vol_G v_sem
  for par in R3_T1_GS ${T1GC:+R3_T1_GC} R3_T2_GS R3_T2_GC R6_GS R6_GC R3_T3_GS R3_T3_GC L1_GS L1_GC L2_GS L2_GC; do
    paste -d';' <(sed -n 2p "$T/metricas_$par.csv") <(sed -n 2p "$T/metricas_${par}gemeo.csv") |
    LC_ALL=C awk -F';' -v p="$par" -v h="$(head -1 "$T/metricas_$par.csv")" '
      BEGIN{n=split(h,x,";"); for(i=1;i<=n;i++)c[x[i]]=i}
      {a=$c["ret_puro"]; b=$(n+c["ret_puro"]); qa=$c["dd_puro"]; qb=$(n+c["dd_puro"]); va=$c["vol_puro"]; vb=$(n+c["vol_puro"])
       printf "%-16s %+7.1f%% %+7.1f%% | %6.1f%% %6.1f%% | %6.1f%% %6.1f%% | %-5s %-6s %-4s\n", p, 100*a, 100*b, 100*qa, 100*qb, 100*va, 100*vb,
         (a>b?"sim":"não"), (qa<qb?"sim":"não"), (va<vb?"sim":"não")}'
  done
} > "$O/efeito_garch.txt"

( cd "$T"
  COL=puro bash "$S/recorte_ano.sh" 2008 curva_R3_T1 GS GSgemeo ${T1GC:+GC GCgemeo} AS MM > "$O/recorte_2008.txt"
  COL=puro bash "$S/recorte_ano.sh" 2020 curva_R6 GS GSgemeo GC GCgemeo ARIMA MM > "$O/recorte_2020.txt" )

bash "$S/anual.sh" "$T" R3_T1_ $([ -n "$T1GC" ] && echo A:GS:puro B:GC:puro || echo AB:GS:puro) ARIMA:AS:puro MM:MM:puro BH:GS:buyhold > "$O/anual_T1.csv"
bash "$S/anual.sh" "$T" R3_T2_ A:GS:puro B:GC:puro ARIMA:AS:puro MM:MM:puro BH:GS:buyhold > "$O/anual_T2.csv"
bash "$S/anual.sh" "$T" R6_ A:GS:puro B:GC:puro ARIMA:ARIMA:puro MM:MM:puro BH:GS:buyhold > "$O/anual_R6.csv"
bash "$S/anual.sh" "$T" R3_T3_ A:GS:puro B:GC:puro ARIMA:AS:puro MM:MM:puro BH:GS:buyhold > "$O/anual_T3.csv"

# Exposição: média móvel de 21 pregões (cerca de um mês) da coluna exposicao.
paste -d, "$T/curva_R3_T1_GS.csv" "$T/curva_R3_T1_AS.csv" | LC_ALL=C awk -F, '
  NR==1{n=NF/2; for(i=1;i<=n;i++)c[$i]=i; print "data,petr4,exp_garch,exp_arima"; next}
  {k=(NR-2)%21; sg+=$c["exposicao"]-bg[k]; bg[k]=$c["exposicao"]; sa+=$(n+c["exposicao"])-ba[k]; ba[k]=$(n+c["exposicao"])
   m=(NR-1<21?NR-1:21); printf "%s,%.2f,%.1f,%.1f\n", $1, 100*$c["buyhold"], 100*sg/m, 100*sa/m}' > "$O/exposicao_T1.csv"

# Exposição média de cada mês de 2008 e 2009 e retorno da PETR4 no mês
# (último pregão do mês / último pregão do mês anterior), texto do mecanismo.
paste -d, "$T/curva_R3_T1_GS.csv" "$T/curva_R3_T1_AS.csv" | LC_ALL=C awk -F, '
  NR==1{n=NF/2; for(i=1;i<=n;i++)c[$i]=i; print "mes exposicao_garch exposicao_arima retorno_petr4"; next}
  {m=substr($1,1,7); if(m!=mc){if(mc!="") fecha[mc]=ult; mc=m} ult=$c["buyhold"]}
  substr($1,1,4)>=2008 && substr($1,1,4)<=2009 {g[m]+=$c["exposicao"]; a[m]+=$(n+c["exposicao"]); q[m]++
    if(!(m in o)){o[m]=++k; ord[k]=m; ant[m]=(k==1 ? fecha[prev] : 0)} }
  {prev=m}
  END{fecha[mc]=ult; base=""; for(i=1;i<=k;i++){m=ord[i]; if(i==1) b0=ant[m]; else b0=fecha[ord[i-1]]
      printf "%s %5.1f%% %5.1f%% %+6.1f%%\n", m, 100*g[m]/q[m], 100*a[m]/q[m], 100*(fecha[m]/b0-1)}}' > "$O/exposicao_mensal_T1.txt"

# Queda da PETR4 em maio e junho de 2018 (maior para menor valor no intervalo).
LC_ALL=C awk -F, 'NR>1 && $1>="2018-05-01" && $1<="2018-06-30" {v=$6+0; if(mx==""||v>mx){mx=v; dmx=$1} if(mn==""||v<mn){mn=v; dmn=$1}}
  END{printf "PETR4 (buyhold, base 1 em 02/01/2017), maio e junho de 2018: máximo %.3f em %s, mínimo %.3f em %s, queda %.1f%%\n", mx, dmx, mn, dmn, 100*(1-mn/mx)}' \
  "$T/curva_R6_GS.csv" > "$O/petr4_2018.txt"

# Ano da crise dentro do período de teste (2008 em 2007-2011 e 2020 em 2017-2024,
# acrescentado em 22/10/2026), com a mesma base do recorte_ano.sh (último
# fechamento do ano anterior = 100) e a queda medida só dentro do ano. Os valores
# do último pregão batem com recorte_2008.txt e recorte_2020.txt.
# curva_ano <ano> <saída> <GS> <GC> <ARIMA> <MM> (em 2007-2011 o GC é o próprio GS)
curva_ano() {
  paste -d, "$T/$3" "$T/$4" "$T/$5" "$T/$6" | LC_ALL=C awk -F, -v ano="$1" '
    NR==1{n=NF/4; for(i=1;i<=n;i++)c[$i]=i
          print "data,petr4,mm,arima,gs,gc,dd_petr4,dd_mm,dd_arima,dd_gs,dd_gc"; next}
    {v[1]=$c["buyhold"]; v[2]=$(3*n+c["puro"]); v[3]=$(2*n+c["puro"]); v[4]=$c["puro"]; v[5]=$(n+c["puro"])}
    substr($1,1,4)<ano {d0=$1; for(i=1;i<=5;i++){b[i]=v[i]; p[i]=v[i]}; next}
    substr($1,1,4)==ano {
      if(!ini){ini=1; printf "%s,100,100,100,100,100,0,0,0,0,0\n", d0}
      s=$1; q=""
      for(i=1;i<=5;i++){if(v[i]>p[i])p[i]=v[i]; s=s sprintf(",%.2f", 100*v[i]/b[i]); q=q sprintf(",%.2f", -100*(1-v[i]/p[i]))}
      print s q}' > "$O/$2"
}
curva_ano 2008 curva_2008.csv curva_R3_T1_GS.csv curva_R3_T1_$([ -n "$T1GC" ] && echo GC || echo GS).csv curva_R3_T1_AS.csv curva_R3_T1_MM.csv
curva_ano 2020 curva_2020.csv curva_R6_GS.csv curva_R6_GC.csv curva_R6_ARIMA.csv curva_R6_MM.csv

# Exposição no ano da crise, ARIMA-GARCH × ARIMA das tabelas (em 2017-2024 o
# ARIMA é a mesma configuração do GS com o GARCH desligado; em 2007-2011, não):
# média dos 5 pregões anteriores, cerca de uma semana, porque as quedas duraram
# semanas e a média de um mês as esconderia.
# exposicao_ano <ano> <saída> <GS> <ARIMA>
exposicao_ano() {
  paste -d, "$T/$3" "$T/$4" | LC_ALL=C awk -F, -v ano="$1" '
    NR==1{n=NF/2; for(i=1;i<=n;i++)c[$i]=i; print "data,petr4,exp_garch,exp_arima"; next}
    {k=(NR-2)%5; sg+=$c["exposicao"]-bg[k]; bg[k]=$c["exposicao"]; sa+=$(n+c["exposicao"])-ba[k]; ba[k]=$(n+c["exposicao"])
     m=(NR-1<5?NR-1:5)}
    substr($1,1,4)<ano {b0=$c["buyhold"]; next}
    substr($1,1,4)==ano {printf "%s,%.2f,%.1f,%.1f\n", $1, 100*$c["buyhold"]/b0, 100*sg/m, 100*sa/m}' > "$O/$2"
}
exposicao_ano 2008 exposicao_2008.csv curva_R3_T1_GS.csv curva_R3_T1_AS.csv
exposicao_ano 2020 exposicao_2020.csv curva_R6_GS.csv curva_R6_ARIMA.csv
paste -d, "$T/curva_R6_GS.csv" "$T/curva_R6_ARIMA.csv" | LC_ALL=C awk -F, '
  NR==1{n=NF/2; for(i=1;i<=n;i++)c[$i]=i; print "mes exposicao_garch exposicao_arima retorno_petr4 ret_garch ret_arima"; next}
  {m=substr($1,1,7); if(m!=mc){if(mc!=""){fb[mc]=ub; fg[mc]=ug; fa[mc]=ua; ord[++k]=mc} mc=m}
   ub=$c["buyhold"]; ug=$c["puro"]; ua=$(n+c["puro"])}
  substr($1,1,4)=="2020" {g[m]+=$c["exposicao"]; a[m]+=$(n+c["exposicao"]); q[m]++}
  END{fb[mc]=ub; fg[mc]=ug; fa[mc]=ua; ord[++k]=mc
      for(i=2;i<=k;i++){m=ord[i]; p=ord[i-1]; if(substr(m,1,4)!="2020") continue
        printf "%s %5.1f%% %5.1f%% %+6.1f%% %+6.1f%% %+6.1f%%\n", m, 100*g[m]/q[m], 100*a[m]/q[m],
          100*(fb[m]/fb[p]-1), 100*(fg[m]/fg[p]-1), 100*(fa[m]/fa[p]-1)}}' > "$O/exposicao_mensal_2020.txt"

echo "gerado em $O"
