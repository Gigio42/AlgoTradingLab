#!/bin/bash
# traco_resumo.sh <traco.csv> <de> <ate>
#
# Resumo do traço por barra (Arquivo_Traco) num intervalo de datas (AAAA.MM.DD,
# inclusive): quantos pregões, em quantos o ADF indicou d = 1, e como o GARCH
# saiu estimado (mediana de alfa1, beta1 e persistência, e quantos pregões com a
# persistência encostada no limite de 1, acima de 0,999). Feito para o estudo das
# janelas 240/500 de 26/10/2026 (comparar o GARCH sobre 240 e sobre 500 resíduos).
[ -s "$1" ] && [ -n "$3" ] || { echo "uso: $0 <traco.csv> <de> <ate>" >&2; exit 1; }
LC_ALL=C awk -F';' -v de="$2" -v ate="$3" '
function mediana(v, n,   i, j, t) { for(i = 2; i <= n; i++) { t = v[i]; for(j = i - 1; j >= 1 && v[j] > t; j--) v[j + 1] = v[j]; v[j + 1] = t }
  return (n % 2) ? v[(n + 1) / 2] : (v[n / 2] + v[n / 2 + 1]) / 2 }
NR == 1 { for(i = 1; i <= NF; i++) h[$i] = i; next }
$1 < de || $1 > ate { next }
{ n++; d1 += ($h["d"] == 1)
  if($h["usa_garch"] == 1 && $h["garch_persist"] != "") { g++; a[g] = $h["garch_alpha1"]; b[g] = $h["garch_beta1"]; p[g] = $h["garch_persist"]
    lim += ($h["garch_persist"] > 0.999) }
  vet += ($h["vetou"] == 1); env += ($h["ordem_enviada"] == 1) }
END { printf "intervalo %s a %s: %d pregões\n", de, ate, n
  printf "d = 1: %d (%.1f%%)\n", d1, 100 * d1 / n
  if(g) printf "GARCH estimado em %d pregões: mediana alfa1 %.4f, beta1 %.4f, persistência %.4f; persistência > 0,999 em %d (%.1f%%)\n",
                g, mediana(a, g), mediana(b, g), mediana(p, g), lim, 100 * lim / g
  printf "vetos: %d; ordens enviadas: %d\n", vet, env }' "$1"
