#!/bin/bash
# comparar_janelas.sh: resultado bruto de cada robô na versão do TG (refação de
# 05/10/2026) e no estudo das janelas fixas 240/500 (26/10/2026), lado a lado.
# Lê só metricas_*.csv (ret_puro, dd_puro, vol_puro, saidas, exposicao).
# Com C=<pasta de testes>, acrescenta uma terceira coluna (estudo de fatores de
# 27/10/2026). Sem C, a saída é a de 26/10.
# Uso (da raiz): bash ferramentas/scripts/comparar_janelas.sh > <saida>
raiz=$(cd "$(dirname "$0")/../.." && pwd)
A="$raiz/dados/resultados/refeito_2026-10-05/testes"
B="$raiz/dados/resultados/janelas_240_500_2026-10-26/testes"
valores(){ LC_ALL=C awk -F';' 'NR==1{for(i=1;i<=NF;i++)h[$i]=i; next}
  {printf "%+8.1f %5.1f %5.1f %4d %5.2f", 100*$h["ret_puro"], 100*$h["dd_puro"], 100*$h["vol_puro"], $h["saidas"], $h["exposicao"]}' "$1"; }
linha(){ # linha <rótulo>
  local a="$A/metricas_$1.csv" b="$B/metricas_$1.csv"
  [ -s "$a" ] && [ -s "$b" ] || { printf "%-14s (falta)\n" "$1"; return; }
  if [ -n "$C" ]; then [ -s "$C/metricas_$1.csv" ] && printf "%-14s | %s | %s | %s\n" "$1" "$(valores "$a")" "$(valores "$b")" "$(valores "$C/metricas_$1.csv")" || printf "%-14s (falta)\n" "$1"
  else printf "%-14s | %s | %s\n" "$1" "$(valores "$a")" "$(valores "$b")"; fi
}
echo "Resultado bruto (camada 1). Colunas: retorno %, queda máx. %, volatilidade %, saídas, exposição média."
echo "Esquerda: TG atual (refeito_2026-10-05). Direita: janelas fixas ARIMA 240 / GARCH 500."
[ -n "$C" ] && echo "Terceira: $(basename "$(dirname "$C")")."
echo "L1 começa em 03/01/2005 no TG e em 01/02/2005 no estudo."
for p in R3_T1 R3_T2 R3_T3; do
  echo; echo "== $p"; for k in GS GSgemeo GC GCgemeo AS AC MM; do linha ${p}_$k; done
done
echo; echo "== R6"; for k in GS GSgemeo GC GCgemeo ARIMA MM; do linha R6_$k; done
for p in L1 L2; do echo; echo "== $p"; for k in GS GSgemeo GC GCgemeo; do linha ${p}_$k; done; done
