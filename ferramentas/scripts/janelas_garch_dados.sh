#!/bin/bash
# janelas_garch_dados.sh [pasta]  (13/11/2026)
#
# Números e dados dos gráficos do relatório ia/relatorios/janela-garch/, lidos de
# dados/resultados/janelas_garch_2026-11-13/ (janelas_garch.sh e
# janela_garch_simulada.sh). Não roda nada no MetaTrader. Saída em <pasta>/cru/.
#
#   caixa_<P>_<m>.tex    \addplot do boxplot (p10, p25, mediana, p75, p90) de cada
#                        janela, configurações com GARCH, métrica m no período P
#   pares.csv            mesma configuração, cada janela contra 240
#   pontos_<T>_<jg>.csv  otimização x teste, uma linha por configuração com GARCH
#   otim.csv             Spearman, posição e resultado das escolhidas (GS, GC)
#   traco_resumo.csv, traco_serie.csv, curvas.csv   a configuração fixa
#   sim_resumo.csv, sim_regime.csv                  a simulação
#   conferencias.txt     as conferências do PROTOCOLO
#   valores.tex          macros com os números citados no relatório
set -euo pipefail
RAIZ="$(cd "$(dirname "$0")/../.." && pwd)"
D="${1:-$RAIZ/dados/resultados/janelas_garch_2026-11-13}"
C="$D/cru"; mkdir -p "$C"
JGS="120 240 500 1000"
PARES="C4:R6 C2:T2 C3:T3 C1:T1"
: > "$C/valores.tex"

# chave da configuração e colunas por nome (o CSV do OnTester usa ';')
AWKLIB='
function col(n) { if(!(n in h)) { print "coluna ausente: " n > "/dev/stderr"; exit 1 } return $h[n] }
function chave() { return sprintf("G%s E%s M%s P%s A%s V%s Z%s K%s S%s", col("UsarGARCH"), col("Estrategia"),
  col("ModoLimiar"), col("Limiar_Percentil") + 0, col("Limiar_Absoluto") + 0, col("Vol_Alvo") + 0,
  col("ZerarNoVeto"), col("IncluirConstante"), col("Limiar_Sinal") + 0) }
function q(v, n, p,   w, i, x, k) { for(i = 1; i <= n; i++) w[i] = v[i] + 0; asort(w)
  x = 1 + (n - 1) * p; k = int(x); return (k >= n) ? w[n] : w[k] + (x - k) * (w[k + 1] - w[k]) }
'
arq(){ echo "$D/calibracao/$1/PETR4_$2.csv"; }

# ---------------------------------------------------------------- caixas
for par in $PARES; do T=${par#*:}
  for m in dd_puro ret_puro vol_puro exposicao veto; do
    out="$C/caixa_${T}_$m.tex"; : > "$out"; x=0
    for jg in $JGS; do x=$((x + 1)); f=$(arq $jg $T); [ -s "$f" ] || continue
      LC_ALL=C gawk -F';' -v m=$m -v x=$x "$AWKLIB"'
        NR == 1 { for(i = 1; i <= NF; i++) h[$i] = i; next }
        col("UsarGARCH") + 0 == 1 { n++; v[n] = (m == "veto") ? ((col("sinais") > 0) ? col("vetos") / col("sinais") : 0) : col(m) }
        END { printf "\\addplot+[boxplot prepared={draw position=%d, lower whisker=%.4f, lower quartile=%.4f, median=%.4f, upper quartile=%.4f, upper whisker=%.4f}] coordinates {};\n",
              x, 100*q(v,n,.10), 100*q(v,n,.25), 100*q(v,n,.5), 100*q(v,n,.75), 100*q(v,n,.90) }' "$f" >> "$out"
    done
  done
done

# medianas por período de teste e janela (com GARCH), e as referências do período:
# o ARIMA sem GARCH (mediana das 4 passagens, iguais nas quatro janelas) e a PETR4
echo "teste,jg,n,ret,dd,vol,exp,veto,ret_arima,dd_arima,petr4,dd_petr4" > "$C/resumo_testes.csv"
for par in $PARES; do T=${par#*:}
  for jg in $JGS; do f=$(arq $jg $T); [ -s "$f" ] || continue
    LC_ALL=C gawk -F';' -v T=$T -v jg=$jg "$AWKLIB"'
      NR == 1 { for(i = 1; i <= NF; i++) h[$i] = i; next }
      col("UsarGARCH") + 0 == 0 { m++; ra[m] = 100*col("ret_puro"); da[m] = 100*col("dd_puro"); bh = 100*col("bh_preco"); dbh = 100*col("dd_bh_preco"); next }
      { n++; r[n] = 100*col("ret_puro"); d[n] = 100*col("dd_puro"); v[n] = 100*col("vol_puro"); e[n] = 100*col("exposicao")
        w[n] = (col("sinais") > 0) ? 100*col("vetos")/col("sinais") : 0 }
      END { printf "%s,%s,%d,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f\n", T, jg, n, q(r,n,.5), q(d,n,.5), q(v,n,.5), q(e,n,.5), q(w,n,.5),
            q(ra,m,.5), q(da,m,.5), bh, dbh }' "$f" >> "$C/resumo_testes.csv"
  done
done

# ---------------------------------------------------------------- pares contra 240
echo "teste,jg,n,frac_dd_menor,med_dif_dd,frac_ret_maior,med_dif_ret,med_dif_exp" > "$C/pares.csv"
for par in $PARES; do T=${par#*:}; b=$(arq 240 $T); [ -s "$b" ] || continue
  for jg in 120 500 1000; do f=$(arq $jg $T); [ -s "$f" ] || continue
    LC_ALL=C gawk -F';' -v T=$T -v jg=$jg "$AWKLIB"'
      FNR == 1 { delete h; for(i = 1; i <= NF; i++) h[$i] = i; arqn++; next }
      col("UsarGARCH") + 0 != 1 { next }
      arqn == 1 { dd[chave()] = col("dd_puro"); rt[chave()] = col("ret_puro"); ex[chave()] = col("exposicao"); next }
      chave() in dd { n++; k = chave(); a[n] = 100*(col("dd_puro") - dd[k]); r[n] = 100*(col("ret_puro") - rt[k])
        e[n] = 100*(col("exposicao") - ex[k]); if(a[n] < 0) menor++; if(r[n] > 0) maior++ }
      END { printf "%s,%s,%d,%.0f,%.1f,%.0f,%.1f,%.1f\n", T, jg, n, 100*menor/n, q(a,n,.5), 100*maior/n, q(r,n,.5), q(e,n,.5) }' "$b" "$f" >> "$C/pares.csv"
  done
done

# ---------------------------------------------------------------- otimização x teste
echo "teste,jg,n,rho_sharpe,rho_calmar,pos_GS,pos_GC,GS_ret,GS_dd,GC_ret,GC_dd,med_ret,med_dd,GS,GC" > "$C/otim.csv"
for par in $PARES; do Cn=${par%:*}; T=${par#*:}
  for jg in $JGS; do fc=$(arq $jg $Cn); ft=$(arq $jg $T); [ -s "$fc" ] && [ -s "$ft" ] || continue
    LC_ALL=C gawk -F';' -v T=$T -v jg=$jg -v pts="$C/pontos_${T}_$jg.csv" "$AWKLIB"'
      function postos(v, r, n,   i, j, k, idx) { for(i = 1; i <= n; i++) idx[i] = i
        for(i = 2; i <= n; i++) { k = idx[i]; j = i - 1
          while(j >= 1 && v[idx[j]] + 0 > v[k] + 0) { idx[j + 1] = idx[j]; j-- } idx[j + 1] = k }
        i = 1; while(i <= n) { j = i; while(j < n && v[idx[j + 1]] + 0 == v[idx[i]] + 0) j++
          for(k = i; k <= j; k++) r[idx[k]] = (i + j) / 2; i = j + 1 } }
      function pearson(a, b, n,   i, ma, mb, sab, saa, sbb) { for(i = 1; i <= n; i++) { ma += a[i]; mb += b[i] } ma /= n; mb /= n
        for(i = 1; i <= n; i++) { sab += (a[i]-ma)*(b[i]-mb); saa += (a[i]-ma)^2; sbb += (b[i]-mb)^2 } return sab / sqrt(saa*sbb) }
      function spearman(a, b, n,   ra, rb) { postos(a, ra, n); postos(b, rb, n); return pearson(ra, rb, n) }
      # regra do escolher.sh: maior valor; desempate por menos negócios, depois a chave
      function melhor(crit, val, k) { if(!(crit in best) || val > best[crit] || (val == best[crit] &&
          (neg[k] < neg[esc[crit]] || (neg[k] == neg[esc[crit]] && k < esc[crit])))) { best[crit] = val; esc[crit] = k } }
      function pos(v, n, x,   i, c) { for(i = 1; i <= n; i++) if(v[i] > x) c++; return c + 1 }
      FNR == 1 { delete h; for(i = 1; i <= NF; i++) h[$i] = i; arqn++; next }
      col("UsarGARCH") + 0 != 1 { next }
      arqn == 1 { k = chave(); sc[k] = col("sharpe") + 0; cc[k] = col("calmar") + 0; neg[k] = col("negocios") + 0
        melhor("S", sc[k], k); melhor("C", cc[k], k); next }
      chave() in sc { n++; k = chave(); K[n] = k; xs[n] = sc[k]; xc[n] = cc[k]; ys[n] = col("sharpe") + 0; yc[n] = col("calmar") + 0
        rt[n] = 100*col("ret_puro"); dd[n] = 100*col("dd_puro"); ind[k] = n }
      END { print "sharpe_otim,calmar_otim,sharpe_teste,calmar_teste,ret,dd" > pts
        for(i = 1; i <= n; i++) printf "%.4f,%.4f,%.4f,%.4f,%.2f,%.2f\n", xs[i], xc[i], ys[i], yc[i], rt[i], dd[i] > pts
        s = ind[esc["S"]]; c = ind[esc["C"]]
        g = pts; sub(/pontos_/, "escolha_", g)   # o ponto do GS e o do GC, para destacar no gráfico
        print "crit,sharpe_otim,calmar_otim,sharpe_teste,calmar_teste" > g
        printf "GS,%.4f,%.4f,%.4f,%.4f\nGC,%.4f,%.4f,%.4f,%.4f\n", xs[s], xc[s], ys[s], yc[s], xs[c], xc[c], ys[c], yc[c] > g
        printf "%s,%s,%d,%.3f,%.3f,%d,%d,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%s,%s\n", T, jg, n, spearman(xs, ys, n), spearman(xc, yc, n),
          pos(ys, n, ys[s]), pos(yc, n, yc[c]), rt[s], dd[s], rt[c], dd[c], q(rt, n, .5), q(dd, n, .5), esc["S"], esc["C"] }' "$fc" "$ft" >> "$C/otim.csv"
  done
done

# ---------------------------------------------------------------- resumo: janela x escolha
# por teste: amplitude entre as medianas das quatro janelas; amplitude entre os GS
# das quatro janelas; largura média (p10 a p90) do retorno dentro da grade de uma
# janela (das caixas); Spearman mínimo e máximo; posição do GS e do GC. Linha
# "todos": as 16 combinações juntas.
LC_ALL=C gawk -F',' '
  FILENAME ~ /otim.csv$/ { if(FNR == 1) next; t = $1; T[t] = 1
    mr[t] = mm(mr[t], $12); gs[t] = mm(gs[t], $8); rs[t] = mm(rs[t], $4); rc[t] = mm(rc[t], $5)
    pg[t] = mm(pg[t], $6); pc[t] = mm(pc[t], $7); if($4 < 0) ns[t]++; nt[t]++
    rs["todos"] = mm(rs["todos"], $4); rc["todos"] = mm(rc["todos"], $5); pg["todos"] = mm(pg["todos"], $6)
    pc["todos"] = mm(pc["todos"], $7); if($4 < 0) ns["todos"]++; nt["todos"]++; next }
  { t = FILENAME; sub(/.*caixa_/, "", t); sub(/_ret_puro.tex$/, "", t)
    match($0, /lower whisker=[-0-9.]+/); lo = substr($0, RSTART + 14, RLENGTH - 14)
    match($0, /upper whisker=[-0-9.]+/); hi = substr($0, RSTART + 14, RLENGTH - 14); larg[t] += hi - lo; nl[t]++ }
  function mm(s, x,   a) { if(s == "") return x " " x; split(s, a, " "); return ((x < a[1]) ? x : a[1]) " " ((x > a[2]) ? x : a[2]) }
  function lo_(s,  a) { split(s, a, " "); return a[1] } function hi_(s,  a) { split(s, a, " "); return a[2] }
  END { print "teste,amp_medianas,amp_gs,largura_grade,rho_s_min,rho_s_max,rho_s_neg,n,rho_c_min,rho_c_max,pos_gs_min,pos_gs_max,pos_gc_min,pos_gc_max"
    T["todos"] = 1
    for(t in T) { if(t == "todos") a = b = l = "" ; else { a = sprintf("%.1f", hi_(mr[t]) - lo_(mr[t])); b = sprintf("%.1f", hi_(gs[t]) - lo_(gs[t])); l = sprintf("%.1f", larg[t]/nl[t]) }
      printf "%s,%s,%s,%s,%.2f,%.2f,%d,%d,%.2f,%.2f,%d,%d,%d,%d\n", t, a, b, l, lo_(rs[t]), hi_(rs[t]), ns[t], nt[t], lo_(rc[t]), hi_(rc[t]),
        lo_(pg[t]), hi_(pg[t]), lo_(pc[t]), hi_(pc[t]) } }' "$C/otim.csv" "$C"/caixa_*_ret_puro.tex > "$C/otim_resumo.csv"

# ---------------------------------------------------------------- traço da configuração fixa
TR="$D/traco"; TS="$D/testes"
if ls "$TR"/traco_JG_*.csv >/dev/null 2>&1; then
  ARQS_TRACO=(); for jg in $JGS; do ARQS_TRACO+=("$TR/traco_JG_$jg.csv"); done   # caminho com espaço: lista em vetor
  ARQS_CURVA=(); for jg in 0 $JGS; do ARQS_CURVA+=("$TS/curva_JG_$jg.csv"); done
  echo "jg,dias,pers_p10,pers_med,pers_p90,frac_pers999,vol_med,lim_med,frac_veto,exposicao,ret,dd,vol" > "$C/traco_resumo.csv"
  for jg in 0 $JGS; do t="$TR/traco_JG_$jg.csv"; [ -s "$t" ] || continue
    met=$(LC_ALL=C gawk -F';' 'NR == 1 { for(i = 1; i <= NF; i++) h[$i] = i; next }
      { printf "%.1f,%.2f,%.2f,%.2f", 100*$h["exposicao"], 100*$h["ret_puro"], 100*$h["dd_puro"], 100*$h["vol_puro"] }' "$TS/metricas_JG_$jg.csv")
    LC_ALL=C gawk -F';' -v jg=$jg -v met="$met" "$AWKLIB"'
      NR == 1 { for(i = 1; i <= NF; i++) h[$i] = i; next }
      col("garch_persist") == "" || col("vol_prevista") + 0 == 0 { next }
      { n++; p[n] = col("garch_persist"); v[n] = 100*col("vol_prevista"); l[n] = 100*col("limiar")
        if(p[n] > 0.999) alto++; if(col("vetou") + 0 == 1) veto++ }
      END { printf "%s,%d,%.4f,%.4f,%.4f,%.1f,%.2f,%.2f,%.1f,%s\n", jg, n, q(p,n,.1), q(p,n,.5), q(p,n,.9), 100*alto/n,
            q(v,n,.5), q(l,n,.5), 100*veto/n, met }' "$t" >> "$C/traco_resumo.csv"
  done
  # série semanal (um pregão a cada cinco): volatilidade prevista, limiar e persistência
  LC_ALL=C gawk -F';' -v jgs="$JGS" '
    FNR == 1 { arqn++; delete h; for(i = 1; i <= NF; i++) h[$i] = i; next }
    { d = $h["data"]; gsub(/\./, "-", d); if(arqn == 1) { nd++; dia[nd] = d }
      vp[arqn, d] = 100*$h["vol_prevista"]; li[arqn, d] = 100*$h["limiar"]; pe[arqn, d] = $h["garch_persist"] }
    END { n = split(jgs, J, " "); printf "data"
      for(j = 1; j <= n; j++) printf ",vp_%s,lim_%s,pers_%s", J[j], J[j], J[j]; print ""
      for(i = 1; i <= nd; i += 5) { d = dia[i]; printf "%s", d
        for(j = 1; j <= n; j++) printf ",%.3f,%.3f,%.4f", vp[j, d], li[j, d], pe[j, d]; print "" } }' \
    "${ARQS_TRACO[@]}" > "$C/traco_serie.csv"
  # curvas (patrimônio base 1) da configuração fixa nas janelas e no TG, e da PETR4
  LC_ALL=C gawk -F',' -v jgs="0 $JGS" '
    FNR == 1 { arqn++; delete h; for(i = 1; i <= NF; i++) h[$i] = i; next }
    { if(arqn == 1) { nd++; dia[nd] = $1; bh[$1] = $h["buyhold"] } e[arqn, $1] = $h["puro"] }
    END { n = split(jgs, J, " "); printf "data,petr4"; for(j = 1; j <= n; j++) printf ",jg_%s", J[j]; print ""
      for(i = 1; i <= nd; i += 5) { d = dia[i]; printf "%s,%.4f", d, bh[d]; for(j = 1; j <= n; j++) printf ",%.4f", e[j, d]; print "" } }' \
    "${ARQS_CURVA[@]}" > "$C/curvas.csv"
fi

# ---------------------------------------------------------------- simulação
S="$D/simulacao"
if [ -s "$S/janela_sim_precisao.csv" ]; then
  echo "jg,reps,falhas,alfa_p10,alfa_med,alfa_p90,beta_p10,beta_med,beta_p90,pers_p10,pers_med,pers_p90,frac_pers999,erro_vol_med,erro_vol_p90" > "$C/sim_resumo.csv"
  for jg in $JGS; do
    LC_ALL=C gawk -F',' -v jg=$jg "$AWKLIB"'
      NR == 1 || $1 != jg { next }
      { r++; if($3 != 1) { f++; next } n++; a[n] = $4; b[n] = $5; p[n] = $6; if($6 > 0.999) alto++
        e[n] = 100*sqrt(($8/$9 - 1)^2) }
      END { printf "%s,%d,%d,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.1f,%.1f,%.1f\n", jg, r, f+0,
            q(a,n,.1), q(a,n,.5), q(a,n,.9), q(b,n,.1), q(b,n,.5), q(b,n,.9), q(p,n,.1), q(p,n,.5), q(p,n,.9), 100*alto/n, q(e,n,.5), q(e,n,.9) }' \
      "$S/janela_sim_precisao.csv" >> "$C/sim_resumo.csv"
    # caixas da persistência estimada (verdade = 0,98)
    LC_ALL=C gawk -F',' -v jg=$jg -v x=$(echo "$JGS" | tr ' ' '\n' | grep -nx "$jg" | cut -d: -f1) "$AWKLIB"'
      NR == 1 || $1 != jg || $3 != 1 { next } { n++; p[n] = $6 }
      END { printf "\\addplot+[boxplot prepared={draw position=%d, lower whisker=%.4f, lower quartile=%.4f, median=%.4f, upper quartile=%.4f, upper whisker=%.4f}] coordinates {};\n",
            x, q(p,n,.1), q(p,n,.25), q(p,n,.5), q(p,n,.75), q(p,n,.9) }' "$S/janela_sim_precisao.csv"
  done > "$C/caixa_sim_pers.tex"
  # regime: em %, e veto (prevista > limiar) por janela
  LC_ALL=C gawk -F',' 'NR == 1 { print "dia,retorno,verd,p120,p240,p500,p1000,l120,l240,l500,l1000,v120,v240,v500,v1000"; next }
    { printf "%d,%.3f,%.3f", $1, 100*$2, 100*$3; for(i = 4; i <= 11; i++) printf ",%.3f", 100*$i
      for(i = 4; i <= 7; i++) printf ",%d", ($i > $(i + 4)) ? 1 : 0; print "" }' "$S/janela_sim_regime.csv" > "$C/sim_regime.csv"
  # média das séries com a mesma mudança de regime (janela_sim_regime_media.csv):
  # fração das séries em que cada janela vetou, dia a dia, em %; e, por fase
  # (antes 1800-1999, crise 2000-2149, logo depois 2150-2299, depois 2300-2600),
  # a média dessa fração e do erro relativo da volatilidade prevista
  M="$S/janela_sim_regime_media.csv"
  if [ -s "$M" ]; then
    # mm_*: média dos últimos 10 dias da mesma fração (só para o gráfico ficar legível)
    LC_ALL=C gawk -F',' 'NR == 1 { print "dia,verd,veto_120,veto_240,veto_500,veto_1000,mm_120,mm_240,mm_500,mm_1000"; next }
      { n++; printf "%d,%.3f", $1, 100*$3; for(i = 4; i <= 7; i++) { printf ",%.1f", 100*$i; h[i, n % 10] = 100*$i }
        for(i = 4; i <= 7; i++) { s = 0; k = (n < 10) ? n : 10; for(j = 0; j < k; j++) s += h[i, (n - j) % 10]; printf ",%.1f", s/k }
        print "" }' "$M" > "$C/sim_media.csv"
    LC_ALL=C gawk -F',' 'NR == 1 { next }
      { f = ($1 < 2000) ? "antes" : ($1 < 2150) ? "crise" : ($1 < 2300) ? "logo_depois" : "depois"; n[f]++; series = $2
        for(j = 0; j < 4; j++) { vet[f, j] += $(4 + j); err[f, j] += $(8 + j) } }
      END { print "fase,dias,series,erro_120,erro_240,erro_500,erro_1000,veto_120,veto_240,veto_500,veto_1000"
        split("antes crise logo_depois depois", F, " ")
        for(i = 1; i <= 4; i++) { f = F[i]; printf "%s,%d,%d", f, n[f], series
          for(j = 0; j < 4; j++) printf ",%.1f", 100*err[f, j]/n[f]; for(j = 0; j < 4; j++) printf ",%.0f", 100*vet[f, j]/n[f]; print "" } }' \
      "$M" > "$C/sim_fases.csv"
  fi
fi

# ---------------------------------------------------------------- valores.tex
# Toda célula dos CSVs-resumo vira uma macro: \val{arquivo}{chave}{coluna}, onde
# a chave é o conteúdo das primeiras colunas (ex.: \val{pares}{R6:120}{med_dif_ret}).
# Números com vírgula decimal; a conta fica nos CSVs, o .tex só lê.
{
  echo '\providecommand{\val}[3]{\csname v:#1:#2:#3\endcsname}'
  emite(){ # emite <arquivo_sem_csv> <número_de_colunas_da_chave>
    [ -s "$C/$1.csv" ] || return 0
    LC_ALL=C gawk -F',' -v a="$1" -v nk="$2" 'NR == 1 { for(i = 1; i <= NF; i++) h[i] = $i; next }
      { k = $1; for(i = 2; i <= nk; i++) k = k ":" $i
        for(i = nk + 1; i <= NF; i++) { x = $i; if(x ~ /^-0(\.0+)?$/) x = substr(x, 2); if(x ~ /^-?[0-9.]+$/) { gsub(/\./, "{,}", x); sub(/^-/, "$-$", x) }
          printf "\\expandafter\\def\\csname v:%s:%s:%s\\endcsname{%s}\n", a, k, h[i], x } }' "$C/$1.csv"; }
  emite pares 2; emite otim 2; emite traco_resumo 1; emite sim_resumo 1; emite sim_fases 1; emite resumo_testes 2; emite otim_resumo 1
} > "$C/valores.tex"

# ---------------------------------------------------------------- conferências
{
  echo "Passagens por otimização (esperado 156):"
  for jg in $JGS; do for f in "$D"/calibracao/$jg/PETR4_*.csv; do [ -s "$f" ] || continue  # glob sem arquivo fica literal
    echo "  JG=$jg $(basename "$f" .csv): $(( $(wc -l < "$f") - 1 ))"; done; done
  echo
  echo "Sub-grade sem GARCH igual nas quatro janelas (ret_puro e dd_puro das 4 passagens):"
  for f in "$D"/calibracao/240/PETR4_*.csv; do [ -s "$f" ] || continue; p=$(basename "$f" .csv)
    ref=$(LC_ALL=C gawk -F';' "$AWKLIB"'NR==1{for(i=1;i<=NF;i++)h[$i]=i;next} col("UsarGARCH")+0==0{print chave(), col("ret_puro"), col("dd_puro")}' "$f" | sort)
    for jg in 120 500 1000; do g="$D/calibracao/$jg/$p.csv"; [ -s "$g" ] || continue
      out=$(LC_ALL=C gawk -F';' "$AWKLIB"'NR==1{for(i=1;i<=NF;i++)h[$i]=i;next} col("UsarGARCH")+0==0{print chave(), col("ret_puro"), col("dd_puro")}' "$g" | sort)
      [ "$ref" = "$out" ] && echo "  $p JG=$jg: igual a 240" || echo "  $p JG=$jg: DIFERENTE de 240"
    done
  done
  echo
  cmp_estudo(){ # cmp_estudo <jg> <periodo> <arquivo_do_estudo>
    [ -s "$3" ] && [ -s "$(arq $1 $2)" ] || return 0
    LC_ALL=C gawk -F';' -v rot="JG=$1 $2 x $(basename "$(dirname "$(dirname "$3")")")" "$AWKLIB"'
      FNR == 1 { delete h; for(i = 1; i <= NF; i++) h[$i] = i; arqn++; next }
      arqn == 1 { if(col("SomenteCompra") + 0 == 1) r[chave()] = col("ret_puro") " " col("dd_puro"); next }  # o estudo de 500 tinha também venda
      chave() in r { n++; if(r[chave()] == col("ret_puro") " " col("dd_puro")) ig++ }
      END { printf "  %s: %d de %d passagens iguais\n", rot, ig, n }' "$3" "$(arq $1 $2)"; }
  echo "Contra os estudos anteriores (mesma configuração, ret_puro e dd_puro):"
  for c in C1 C2 C3 C4; do cmp_estudo 1000 $c "$RAIZ/dados/resultados/janela_garch_1000_2026-11-02/calibracao/PETR4_$c.csv"; done
  for c in C2 C3 C4; do cmp_estudo 500 $c "$RAIZ/dados/resultados/janelas_240_500_2026-10-26/calibracao/PETR4_$c.csv"; done
  for t in T1 T2 T3; do cmp_estudo 500 $t "$RAIZ/dados/resultados/janelas_240_500_2026-10-26/calibracao/PETR4_$t.csv"; done
  if [ -s "$C/traco_resumo.csv" ]; then
    echo
    echo "Traço com Janela_GARCH=0 contra o GS de 2017-2024 do TG (ret_puro):"
    echo "  aqui: $(awk -F, '$1==0{print $11"%"}' "$C/traco_resumo.csv")  TG: $(LC_ALL=C gawk -F';' 'NR==1{for(i=1;i<=NF;i++)h[$i]=i;next}{printf "%.2f%%", 100*$h["ret_puro"]}' "$RAIZ/dados/resultados/refeito_2026-10-05/testes/metricas_R6_GS.csv")"
  fi
} > "$C/conferencias.txt"
cat "$C/conferencias.txt"
