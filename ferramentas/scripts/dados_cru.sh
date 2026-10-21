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
#
# Uso (da raiz do repositório): bash ferramentas/scripts/dados_cru.sh
set -e
raiz=$(cd "$(dirname "$0")/../.." && pwd)
T="$raiz/dados/resultados/refeito_2026-10-05/testes"
O="$raiz/dados/resultados/refeito_2026-10-05/cru"
S="$raiz/ferramentas/scripts"
mkdir -p "$O"

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
  echo "Fonte: refeito_2026-10-05/testes/metricas_*.csv (ret_puro, dd_puro, vol_puro, ret_custos, ret_selic, ret_completo)."
  echo; echo "== 2007 a 2011 (versões A e B são a mesma configuração)"
  linha R3_T1_MM "Médias móveis"; linha R3_T1_AS "ARIMA"; linha R3_T1_GS "ARIMA-GARCH A e B"; ref R3_T1_GS
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
  for par in R3_T1_GS R3_T2_GS R3_T2_GC R6_GS R6_GC R3_T3_GS R3_T3_GC L1_GS L1_GC L2_GS L2_GC; do
    paste -d';' <(sed -n 2p "$T/metricas_$par.csv") <(sed -n 2p "$T/metricas_${par}gemeo.csv") |
    LC_ALL=C awk -F';' -v p="$par" -v h="$(head -1 "$T/metricas_$par.csv")" '
      BEGIN{n=split(h,x,";"); for(i=1;i<=n;i++)c[x[i]]=i}
      {a=$c["ret_puro"]; b=$(n+c["ret_puro"]); qa=$c["dd_puro"]; qb=$(n+c["dd_puro"]); va=$c["vol_puro"]; vb=$(n+c["vol_puro"])
       printf "%-16s %+7.1f%% %+7.1f%% | %6.1f%% %6.1f%% | %6.1f%% %6.1f%% | %-5s %-6s %-4s\n", p, 100*a, 100*b, 100*qa, 100*qb, 100*va, 100*vb,
         (a>b?"sim":"não"), (qa<qb?"sim":"não"), (va<vb?"sim":"não")}'
  done
} > "$O/efeito_garch.txt"

( cd "$T"
  COL=puro bash "$S/recorte_ano.sh" 2008 curva_R3_T1 GS GSgemeo AS MM > "$O/recorte_2008.txt"
  COL=puro bash "$S/recorte_ano.sh" 2020 curva_R6 GS GSgemeo GC GCgemeo ARIMA MM > "$O/recorte_2020.txt" )

bash "$S/anual.sh" "$T" R3_T1_ AB:GS:puro ARIMA:AS:puro MM:MM:puro BH:GS:buyhold > "$O/anual_T1.csv"
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

echo "gerado em $O"
