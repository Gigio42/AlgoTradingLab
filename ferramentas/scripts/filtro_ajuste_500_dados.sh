#!/bin/bash
# filtro_ajuste_500_dados.sh   (13/11/2026; janela de 1000 acrescentada em 15/11)
#
# Números do relatório ia/relatorios/filtro-ajuste-500-1000/ a partir de
# dados/resultados/filtro_ajuste_500_2026-11-13/ e filtro_ajuste_1000_2026-11-15/
# (versões M e E de cada uma; ids M500 E500 M1000 E1000) e dos resultados
# do TG (refeito_2026-10-05 e outras_acoes_2017_2024_2026-11-10). Nada é simulado.
# Saída em <pasta>/cru/: CSVs por tabela, conferencias.txt e valores.tex (cada
# número do texto como \valor{arquivo}{chave}{coluna}).
set -e
A="$(cd "$(dirname "$0")/../.." && pwd)"; S="$A/ferramentas/scripts"
R="$A/dados/resultados/filtro_ajuste_500_2026-11-13"
declare -A PASTA=([500]="$R" [1000]="$A/dados/resultados/filtro_ajuste_1000_2026-11-15")
VERS="${VERS:-M500 E500 M1000 E1000}"   # VERS="M500 E500" antes de a de 1000 terminar
# pasta e versão interna (M ou E) de um id
pasta(){ echo "${PASTA[${1:1}]}/${1:0:1}"; }
TG="$A/dados/resultados/refeito_2026-10-05"
TG4="$A/dados/resultados/outras_acoes_2017_2024_2026-11-10"
JG="$A/dados/resultados/janelas_garch_2026-11-13"
O="$R/cru"; mkdir -p "$O"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export LC_ALL=C

# Linha de parâmetros (a mesma do escolher.sh) e as métricas de uma passagem.
CHAVE='function v(c) { return (c in h) ? $h[c] : "" }
function b(x) { return (x + 0 == 1) ? "true" : "false" }
function chave(   p) { p = "UsarGARCH=" b(v("UsarGARCH"))
  if(v("UsarGARCH") + 0 == 1)
    p = p " Estrategia=" v("Estrategia") " ModoLimiar=" v("ModoLimiar") " Limiar_Percentil=" v("Limiar_Percentil") \
        " Limiar_Absoluto=" v("Limiar_Absoluto") " K_Confianca=" v("K_Confianca") " Vol_Alvo=" v("Vol_Alvo") " ZerarNoVeto=" b(v("ZerarNoVeto"))
  return p " Janela_Estimacao=" v("Janela_Estimacao") " IncluirConstante=" b(v("IncluirConstante")) \
      " Limiar_Sinal=" v("Limiar_Sinal") " SomenteCompra=" b(v("SomenteCompra")) }'
sem_ic(){ awk -F';' 'NR == 1 { for(i = 1; i <= NF; i++) h[$i] = i; print; next }
  !($h["UsarGARCH"] + 0 == 1 && $h["Estrategia"] + 0 == 2)' "$1"; }

# escolhe <versão> <ativo> <k> <calibração> <teste|-> : linhas da tabela de escolhas
# (com o resultado na grade do teste, se houver)
escolhe(){ local ver=$1 at=$2 k=$3 cal=$4 tst=$5
  sem_ic "$cal" > "$T/cal.csv"
  bash "$S/escolher.sh" "$T/cal.csv" so_compra | grep -E '^(GS|GC|AS) ' > "$T/esc.txt"
  while IFS= read -r l; do
    rob=${l%% *}; par=${l#*| }; met=${l%% |*}
    idx=$(echo "$met" | sed -n "s/.*$([ $rob = GC ] && echo calmar || echo sharpe)=\([^ ]*\).*/\1/p")
    echo "$par" | awk -v ver=$ver -v at=$at -v k=$k -v rob=$rob -v idx="$idx" -v tst="$tst" '
      { for(i = 1; i <= NF; i++) { split($i, kv, "="); P[kv[1]] = kv[2] } }
      # rótulos prontos para o texto (o % vai escapado para o LaTeX)
      END { g = (P["UsarGARCH"] == "true"); e = P["Estrategia"] + 0
        forma = !g ? "sem GARCH" : (e == 0 ? "filtro" : (e == 1 ? "ajuste" : (e == 3 ? "filtro e ajuste" : "forma " e)))
        lim = (!g || e == 1) ? "--" : (P["ModoLimiar"] == 1 ? "percentil " P["Limiar_Percentil"] + 0 : "fixo " 100 * P["Limiar_Absoluto"] "\\%")
        alvo = (!g || e == 0) ? "--" : 100 * P["Vol_Alvo"] "\\%"
        veto = (!g || e == 1) ? "--" : (P["ZerarNoVeto"] == "true" ? "encerra" : "mantém")
        pm = P["Limiar_Sinal"] + 0 == 0 ? "zero" : sprintf("%g", 100 * P["Limiar_Sinal"]) "\\%"; sub(/\./, "@V@", pm)
        curto = !g ? "--" : ((e == 0 ? "F" : (e == 3 ? "FA" : forma)) " " (lim == "--" ? "" : lim) (alvo == "--" ? "" : " \\textperiodcentered{} " alvo) (veto == "encerra" ? " E" : (veto == "mantém" ? " M" : "")))
        sub(/percentil /, "p", curto); sub(/fixo /, "f", curto)
        printf "%s,%s,T%s,%s,%s,%s,%s,%s,%s,%s,%s,%.2f,%s", ver, at, k, rob, forma, lim, alvo, veto,
          P["Janela_Estimacao"], P["IncluirConstante"] == "true" ? "sim" : "não", pm, idx, curto }'
    if [ "$tst" != - ]; then
      awk -F';' -v alvo="$par" "NR == 1 { for(i = 1; i <= NF; i++) h[\$i] = i; next } $CHAVE
        chave() == alvo && !achou { achou = 1; printf \",%.1f,%.1f,%.1f,%d,%s\\n\", 100*v(\"ret_puro\"), 100*v(\"dd_puro\"), 100*v(\"vol_puro\"), v(\"saidas\"),
          (v(\"saidas\") + 0 == 0 ? \"sem operações\" : fmt(100*v(\"ret_puro\"), 1) \" / \" fmt(100*v(\"dd_puro\"), 0)) }
        function fmt(x, s,   t) { t = sprintf(s ? \"%+.1f\" : \"%.1f\", x); sub(/\\./, \"@V@\", t); sub(/^-/, \"\$-\$\", t); return t }
        END { if(!achou) print \",NA,NA,NA,NA,NA\" }" "$tst"
    else echo ",,,,,"; fi
  done < "$T/esc.txt"; }

# ---- 1. Escolhas (todas as ações) e resultado na grade do teste ----
{ echo "versao,ativo,per,robo,forma,limiar,alvo,veto,janela,constante,prev_min,indice,curto,ret,dd,vol,saidas,rd"
  for a in PETR4 VALE3 USIM5 POMO4; do for k in 1 2 3 4; do
    if [ $k = 4 ]; then escolhe TG $a 4 "$TG4/calibracao/${a}_C4.csv" "$TG4/calibracao/${a}_T4.csv"
    else escolhe TG $a $k "$TG/calibracao/${a}_C$k.csv" "$TG/calibracao/${a}_T$k.csv"; fi
    for id in $VERS; do d=$(pasta $id)
      [ -s "$d/calibracao/${a}_C$k.csv" ] || continue   # 1000: outras ações sem o par C1/T1
      escolhe $id $a $k "$d/calibracao/${a}_C$k.csv" "$d/calibracao/${a}_T$k.csv"
    done
  done; done; } > "$O/escolhas.csv"

# ---- 2. Testes individuais da PETR4 ----
met(){ awk -F';' -v ver=$1 -v per=$2 -v rob=$3 'NR == 1 { for(i = 1; i <= NF; i++) h[$i] = i; next }
  { printf "%s,%s,%s,%.1f,%.1f,%.1f,%d,%.1f,%.1f,%d,%d,%.1f,%.1f\n", ver, per, rob, 100*$h["ret_puro"], 100*$h["dd_puro"],
      100*$h["vol_puro"], $h["saidas"], 100*$h["exposicao"], ($h["sinais"] > 0 ? 100*$h["vetos"]/$h["sinais"] : 0),
      $h["vetos"], $h["sinais"], 100*$h["bh_preco"], 100*$h["dd_bh_preco"] }' "$4"; }
{ echo "versao,per,robo,ret,dd,vol,saidas,exposicao,veto_pct,vetos,sinais,bh,dd_bh"
  for k in 1 2 3; do for r in GS GSgemeo GC GCgemeo AS; do met TG T$k $r "$TG/testes/metricas_R3_T${k}_$r.csv"; done; done
  for r in GS GSgemeo GC GCgemeo; do met TG T4 $r "$TG/testes/metricas_R6_$r.csv"; done
  met TG T4 AS "$TG/testes/metricas_R6_ARIMA.csv"
  for L in L1 L2; do for r in GS GSgemeo GC GCgemeo; do met TG $L $r "$TG/testes/metricas_${L}_$r.csv"; done; done
  for id in $VERS; do d=$(pasta $id); v=${id:0:1}
    for k in 1 2 3 4; do for r in GS GSgemeo GC GCgemeo AS; do met $id T$k $r "$d/testes/metricas_${v}_T${k}_$r.csv"; done; done
    for L in L1 L2; do for r in GS GSgemeo GC GCgemeo; do met $id $L $r "$d/testes/metricas_${v}_${L}_$r.csv"; done; done
  done; } > "$O/petr4.csv"
# médias móveis (iguais em todas as versões; refação de 05/10)
{ echo "per,ret,dd,vol"
  for x in "T1 R3_T1" "T2 R3_T2" "T3 R3_T3" "T4 R6" "L1 L1" "L2 L2"; do set -- $x
    awk -F';' -v per=$1 'NR == 1 { for(i = 1; i <= NF; i++) h[$i] = i; next }
      { printf "%s,%.1f,%.1f,%.1f\n", per, 100*$h["ret_puro"], 100*$h["dd_puro"], 100*$h["vol_puro"] }' "$TG/testes/metricas_$2_MM.csv"
  done; } > "$O/mm.csv"
# gráfico de barras: um arquivo por robô, uma linha por período, as cinco versões lado a lado
awk -F, -v vers="TG M500 E500 M1000 E1000" 'NR > 1 && $2 ~ /^T/ { k = $2 "," $3; r[k, $1] = $4; d[k, $1] = $5; s[k, $1] = $6 }
  END { n = split("T1 T2 T4 T3", P, " "); m = split("AS GS GC", B, " "); nv = split(vers, V, " ")
    for(j = 1; j <= m; j++) { f = dir "/barras_" B[j] ".csv"; h = "per,x"
      for(t = 1; t <= 3; t++) for(i = 1; i <= nv; i++) h = h "," (t == 1 ? "ret" : (t == 2 ? "dd" : "vol")) "_" V[i]
      print h > f
      for(i = 1; i <= n; i++) { k = P[i] "," B[j]; l = P[i] "," i
        for(t = 1; t <= 3; t++) for(q = 1; q <= nv; q++) l = l "," (t == 1 ? r[k, V[q]] : (t == 2 ? d[k, V[q]] : s[k, V[q]]))
        print l > f } } }' dir="$O" "$O/petr4.csv"
# com × sem GARCH (gêmea), como a Tabela do efeito no TG: contagens por versão
awk -F, -v vers="TG $VERS" 'NR > 1 { k = $1 "," $2 "," $3; r[k] = $4; d[k] = $5; s[k] = $6 }
  END { print "versao,grupo,n,dd_menor,vol_menor,ret_maior"
    nv = split(vers, V, " ")
    for(i = 1; i <= nv; i++) for(gr = 1; gr <= 2; gr++) { n = dm = vm = rm = 0
      lista = (gr == 1 ? "T1 T2 T3 T4" : "L1 L2"); np = split(lista, P, " ")
      for(j = 1; j <= np; j++) for(b = 1; b <= 2; b++) { rob = (b == 1 ? "GS" : "GC")
        c = V[i] "," P[j] "," rob; g = c "gemeo"; if(!(c in r)) continue
        n++; dm += (d[c] < d[g]); vm += (s[c] < s[g]); rm += (r[c] > r[g]) }
      printf "%s,%s,%d,%d,%d,%d\n", V[i], (gr == 1 ? "principais" : "adicionais"), n, dm, vm, rm } }' \
  "$O/petr4.csv" > "$O/efeito.csv"

# ---- 3. Grade inteira dos testes: M × E em pares (mesma configuração, só o veto muda) ----
for j in 500 1000; do for v in M E; do for a in PETR4 VALE3 USIM5 POMO4; do for k in 1 2 3 4; do
  f="${PASTA[$j]}/$v/calibracao/${a}_T$k.csv"; [ -s "$f" ] || continue
  awk -F';' -v j=$j -v vv=$v -v a=$a -v k=$k "NR == 1 { for(i = 1; i <= NF; i++) h[\$i] = i; next } $CHAVE
    v(\"UsarGARCH\") + 0 == 1 { c = chave(); sub(/ ZerarNoVeto=[a-z]*/, \"\", c)
      printf \"%s;%s;%s;T%s;%s;%.6f;%.6f;%.6f\\n\", j, vv, a, k, c, v(\"ret_puro\"), v(\"dd_puro\"), v(\"vol_puro\") }" "$f"
done; done; done; done > "$T/grade.txt"
mediana(){ sort -g | awk '{ x[NR] = $1 } END { print (NR % 2 ? x[(NR+1)/2] : (x[NR/2] + x[NR/2+1]) / 2) }'; }
col(){ awk -F';' -v j=$1 -v v=$2 -v a=$3 -v p=$4 -v c=$5 '$1 == j && $2 == v && $3 == a && $4 == p { print 100*$c }' "$T/grade.txt"; }
{ echo "ativo,per,jg,n,dd_menor_E,ret_maior_E,vol_menor_E,med_dd_M,med_dd_E,med_ret_M,med_ret_E,min_dd_M,max_dd_M,min_dd_E,max_dd_E,dd_igual"
  for j in 500 1000; do for a in PETR4 VALE3 USIM5 POMO4; do for k in 1 2 3 4; do
    [ -n "$(col $j M $a T$k 7 | head -1)" ] || continue
    awk -F';' -v j=$j -v a=$a -v p=T$k '$1 == j && $3 == a && $4 == p { if($2 == "M") { r[$5] = $6; d[$5] = $7; s[$5] = $8 } else { R[$5] = $6; D[$5] = $7; V[$5] = $8 } }
      END { for(c in r) if(c in R) { n++; dm += (D[c] < d[c]); rm += (R[c] > r[c]); vm += (V[c] < s[c]) }
        printf "%s,%s,%s,%d,%.0f,%.0f,%.0f", a, p, j, n, 100*dm/n, 100*rm/n, 100*vm/n }' "$T/grade.txt"
    printf ",%.1f,%.1f,%.1f,%.1f" $(col $j M $a T$k 7 | mediana) $(col $j E $a T$k 7 | mediana) $(col $j M $a T$k 6 | mediana) $(col $j E $a T$k 6 | mediana)
    printf ",%.1f,%.1f,%.1f,%.1f" $(col $j M $a T$k 7 | sort -g | sed -n '1p;$p') $(col $j E $a T$k 7 | sort -g | sed -n '1p;$p')
    awk -F';' -v j=$j -v a=$a -v p=T$k '$1 == j && $3 == a && $4 == p { if($2 == "M") d[$5] = $7; else D[$5] = $7 } END { for(c in d) if(c in D) { n++; eq += (D[c] == d[c]) } printf ",%.0f\n", 100*eq/n }' "$T/grade.txt"
  done; done; done; } > "$O/grade_ME.csv"
# resumo da grade_ME por janela: em quantas células (ação × período) E vence a maioria dos pares,
# M vence a maioria, e a queda mediana de E é menor que a de M
awk -F, 'NR > 1 { n[$3]++; e[$3] += ($5 > 50); m[$3] += (100 - $5 - $16 > 50); q[$3] += ($9 < $8) }
  END { print "jg,celulas,E_maioria,M_maioria,mediana_E_menor"
    for(j = 500; j <= 1000; j += 500) printf "%d,%d,%d,%d,%d\n", j, n[j], e[j], m[j], q[j] }' "$O/grade_ME.csv" > "$O/grade_resumo.csv"
# o que cada versão escolheu, em contagem (robôs com GARCH; escopo PETR4 ou todas as ações)
awk -F, 'NR > 1 && $4 != "AS" { for(s = 1; s <= 2; s++) { if(s == 1 && $2 != "PETR4") continue
    k = $1 "," (s == 1 ? "PETR4" : "todas"); n[k]++; enc[k] += ($8 == "encerra"); fil[k] += ($5 == "filtro")
    j120[k] += ($9 == "120"); fix[k] += ($6 ~ /^fixo/); pct[k] += ($6 ~ /^percentil/); a1[k] += ($7 == "1\\%")
    sem[k] += ($18 == "sem operações"); if(!(k in vis)) { vis[k]; ord[++no] = k } } }
  END { print "versao,escopo,n,encerra,so_filtro,janela120,fixo,percentil,alvo1,sem_operacoes"
    for(i = 1; i <= no; i++) { k = ord[i]; printf "%s,%d,%d,%d,%d,%d,%d,%d,%d\n", k, n[k], enc[k], fil[k], j120[k], fix[k], pct[k], a1[k], sem[k] } }' \
  "$O/escolhas.csv" > "$O/contagens.csv"

# ---- 4. Conferências ----
chaves(){ awk -F';' -v f="$2" "NR == 1 { for(i = 1; i <= NF; i++) h[\$i] = i; next } $CHAVE
  f == \"semgarch\" && v(\"UsarGARCH\") + 0 != 0 { next }
  { print chave(), v(\"ret_puro\"), v(\"dd_puro\"), v(\"sharpe\"), v(\"calmar\") }" "$1" | sort; }
{ echo "Conferências ($(date '+%F %T'))"
  echo; echo "1. Passagens por otimização (esperado 52; 500: 64 otimizações, 1000: 52):"
  for j in 500 1000; do for v in M E; do for f in "${PASTA[$j]}/$v"/calibracao/*.csv; do [ -s "$f" ] || continue;
    echo "$j $(( $(wc -l < "$f") - 1 ))"; done; done; done | awk '{ c[$1 " " $2]++ } END { for(x in c) { split(x, p, " ")
    print "   janela " p[1] ": " c[x] " otimizações com " p[2] " passagens" } }' | sort
  echo; echo "2. Sub-grade sem GARCH idêntica em M500, E500, M1000 e E1000 (mesma ação e janela):"
  for f in "$R/M"/calibracao/*.csv; do b=$(basename "$f")
    x=$(for id in $VERS; do g="$(pasta $id)/calibracao/$b"; [ -s "$g" ] && chaves "$g" semgarch | md5sum; done | uniq | wc -l)
    m=$(for id in $VERS; do [ -s "$(pasta $id)/calibracao/$b" ] && echo x; done | wc -l)
    [ "$x" = 1 ] && echo "   $b: igual nas $m versões" || echo "   $b: DIFERE"; done
  echo; echo "3. PETR4 contra janelas_garch_2026-11-13 (mesma janela, Estrategia=3, mesmo ZerarNoVeto, e as 4 sem GARCH):"
  for j in 500 1000; do for v in M E; do z=$([ $v = E ] && echo 1 || echo 0); for k in 1 2 3 4; do for c in C T; do
    o=$c$k; [ $o = T4 ] && o=R6; [ -s "${PASTA[$j]}/$v/calibracao/PETR4_$c$k.csv" ] || continue
    a=$(chaves "${PASTA[$j]}/$v/calibracao/PETR4_$c$k.csv")
    b=$(awk -F';' -v z=$z "NR == 1 { for(i = 1; i <= NF; i++) h[\$i] = i; next } $CHAVE
      v(\"UsarGARCH\") + 0 == 0 || (v(\"Estrategia\") + 0 == 3 && v(\"ZerarNoVeto\") + 0 == z) { print chave(), v(\"ret_puro\"), v(\"dd_puro\"), v(\"sharpe\"), v(\"calmar\") }" "$JG/calibracao/$j/PETR4_$o.csv" | sort)
    [ "$a" = "$b" ] && echo "   $j $v $c$k: igual ($(echo "$a" | wc -l) passagens)" || echo "   $j $v $c$k: DIFERENTE"
  done; done; done; done
  echo; echo "4. Teste individual = passagem da grade do teste (PETR4, GS e GC, ret,dd):"
  awk -F, 'FNR == 1 { next } FILENAME ~ /escolhas/ && $1 != "TG" && $2 == "PETR4" && $4 != "AS" { g[$1","$3","$4] = $14","$15 }
    FILENAME ~ /petr4/ && ($3 == "GS" || $3 == "GC") && $1 != "TG" && $2 ~ /^T/ { k = $1","$2","$3; print "   " k ": grade " g[k] " | individual " $4","$5 (g[k] == $4","$5 ? "  igual" : "  DIFERENTE") }' \
    "$O/escolhas.csv" "$O/petr4.csv"
  echo; echo "5. ARIMA sem GARCH (AS) igual nas quatro versões (teste individual, ret,dd):"
  awk -F, 'NR > 1 && $3 == "AS" && $1 != "TG" { print $2, $4 "," $5 }' "$O/petr4.csv" | sort -u |
    awk '{ c[$1]++; x[$1] = x[$1] " " $2 } END { for(p in c) print "   " p ":" x[p] (c[p] == 1 ? "  igual" : "  DIFERE") }' | sort
  echo; echo "6. TG reconstruído: escolha refeita (escolhas.csv, PETR4) contra os testes do TG (metricas_R3/R6):"
  awk -F, 'FNR == 1 { next } FILENAME ~ /escolhas/ && $1 == "TG" && $2 == "PETR4" { g[$3","$4] = $14","$15 }
    FILENAME ~ /petr4/ && $1 == "TG" && $2 ~ /^T/ && ($3 == "GS" || $3 == "GC" || $3 == "AS") { k = $2","$3; print "   " k ": grade " g[k] " | teste do TG " $4","$5 (g[k] == $4","$5 ? "  igual" : "  DIFERENTE") }' \
    "$O/escolhas.csv" "$O/petr4.csv"
} > "$O/conferencias.txt"

# ---- 5. valores.tex: \V{arquivo}{chave}{coluna}, chave = colunas de identificação unidas por "-" ----
{ echo "% Gerado por ferramentas/scripts/filtro_ajuste_500_dados.sh em $(date '+%F %T'). Não editar."
  emite(){ awk -F, -v arq=$1 -v nk=$2 'NR == 1 { for(i = 1; i <= NF; i++) h[i] = $i; next }
    { k = $1; for(i = 2; i <= nk; i++) k = k "-" $i
      for(i = nk + 1; i <= NF; i++) { x = $i; if(x == "-0.0") x = "0.0"
        if(x ~ /^-?[0-9]+\.[0-9]+$/) { neg = (x ~ /^-/); gsub(/-/, "", x); sub(/\./, "{,}", x); x = (neg ? "$-$" : "") x }
        gsub(/@V@/, "{,}", x)
        printf "\\expandafter\\def\\csname v@%s@%s@%s\\endcsname{%s}\n", arq, k, h[i], x } }' "$O/$1.csv"; }
  emite escolhas 4; emite petr4 3; emite mm 1; emite grade_ME 3; emite efeito 2; emite grade_resumo 1; emite contagens 2
} > "$O/valores.tex"
echo "gerado em $O"; cat "$O/conferencias.txt"
