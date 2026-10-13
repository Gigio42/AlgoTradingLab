#!/bin/bash
# Roda a grade (com e sem venda a descoberto) nas 3 janelas de calibracao e nas 3 de teste,
# para cada ativo. Resultados em $TRAB/g/<SIMBOLO>_<janela>/
source "$(dirname "$0")/comum.sh"
JAN=("C1 2004.01.02 2006.12.30" "T1 2007.01.02 2011.12.30" "C2 2010.01.04 2012.12.29"
     "T2 2013.01.02 2016.12.30" "C3 2022.01.03 2024.12.31" "T3 2025.01.02 2026.09.19")
for ativo in "$@"; do
  for g in arima filtro_abs filtro_pct targ ic ft_abs ft_pct; do
    sed "s|^Arquivo_Proventos=.*|Arquivo_Proventos=proventos_${ativo}.csv|" "$TRAB/sub/$g.txt" > "$TRAB/sub/${ativo}_$g.txt"
  done
  for j in "${JAN[@]}"; do set -- $j
    for g in arima filtro_abs filtro_pct targ ic ft_abs ft_pct; do
      bash "$(dirname "$0")/otimizar.sh" "$1" "${ativo}_OFICIAL" "$2" "$3" "$TRAB/sub/${ativo}_$g.txt"
    done
  done
done
echo FIM
