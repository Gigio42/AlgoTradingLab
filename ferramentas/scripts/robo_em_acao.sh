#!/bin/bash
# robo_em_acao.sh (30/10/2026): dados dos gráficos que mostram o ARIMA-GARCH
# operando (apresentacao/graficos_metodos/, figuras 08 a 14). Não roda o
# MetaTrader: só lê o traço por barra da refação de 05/10/2026
# (dados/resultados/refeito_2026-10-05/traco_demo/, configuração GS de C4,
# PETR4, jul/2019 a jun/2021) e o resumo do MetodosIlustrados (parâmetros do
# GARCH da janela de validação, para a figura 14).
#
# Convenções do traço (robos/ARIMA-GARCH/Diagnostico.mqh):
#   data = pregão em que a decisão é tomada (na abertura);
#   preco = fechamento do pregão anterior;
#   prev_dif = retorno previsto para o fechamento de "data";
#   ordem_enviada = 1 só quando houve compra ou venda nova (fechar não conta).
# Por isso o retorno realizado da linha i é ln(preco[i+1] / preco[i]).
export LC_ALL=C
S="$(cd "$(dirname "$0")" && pwd)"; A="$(cd "$S/../.." && pwd)"
T="$A/dados/resultados/refeito_2026-10-05/traco_demo"
M="$A/dados/resultados/metodos_ilustrados_2026-10-30/resumo.txt"
SAIDA="$A/dados/resultados/robo_em_acao_2026-10-30"
mkdir -p "$SAIDA"; cd "$SAIDA" || exit 1

# As duas execuções têm de ter as mesmas datas e a mesma previsão do ARIMA
paste -d';' <(cut -d';' -f1,22 "$T/traco_demo_GARCH.csv") <(cut -d';' -f1,22 "$T/traco_demo_ARIMA.csv") |
  awk -F';' 'NR>1 && ($1!=$3 || $2!=$4){n++} END{if(n){print "traços não casam: " n " linhas"; exit 1}}' || exit 1

# Dias da figura 08 (um pregão liberado e o seguinte, vetado)
DIA_LIB=2021.02.19; DIA_VET=2021.02.22
# Parâmetros da janela de validação (figura 14), tirados do resumo
read -r V_OMEGA V_ALFA V_BETA <<< "$(sed -n 's/.*GARCH(1,1) omega=\([0-9.e+-]*\) alpha1=\([0-9.e+-]*\) beta1=\([0-9.e+-]*\).*/\1 \2 \3/p' "$M" | head -1)"
V_CHOQUE=$(sed -n 's/.*Maior residuo: [0-9-]* eps=\([0-9.+-]*\)%.*/\1/p' "$M" | head -1)

awk -F';' -v lib="$DIA_LIB" -v vet="$DIA_VET" -v vo="$V_OMEGA" -v va="$V_ALFA" -v vb="$V_BETA" -v choque="$V_CHOQUE" '
function iso(d){ return substr(d,1,4) "-" substr(d,6,2) "-" substr(d,9,2) }
function br(d){ return substr(d,9,2) "/" substr(d,6,2) "/" substr(d,1,4) }
function sg(x){ return x>0 ? 1 : (x<0 ? -1 : 0) }
function v(nome, fmt, x,   s){ s=sprintf(fmt,x); p=s; gsub(/\./,"{,}",s); sub(/^-/,"\\ensuremath{-}",s)
  printf "\\def\\vR%s{%s}\n\\def\\pR%s{%s}\n", nome, s, nome, p > "valores.tex" }
function vt(nome, s){ printf "\\def\\vR%s{%s}\n", nome, s > "valores.tex" }
FNR==1 { arq++; next }
arq==1 { a_sinal[FNR]=$34; a_ord[FNR]=$37; a_pos[FNR]=$38; next }
{ n++; d[n]=$1; pr[n]=$2; p_[n]=$4; d_[n]=$5; q_[n]=$6; c[n]=$7; phi1[n]=$8; phi2[n]=$9; phi3[n]=$10
  th1[n]=$12; prev[n]=$22; om[n]=$24; al[n]=$25; be[n]=$26; pe[n]=$27
  vol[n]=$31; vat[n]=$32; lim[n]=$33; si[n]=$34; vt_[n]=$36; og[n]=$37; pg[n]=$38
  sa[n]=a_sinal[FNR]; oa[n]=a_ord[FNR]; pa[n]=a_pos[FNR] }
END {
  printf "" > "valores.tex"
  # --- dia a dia (uma linha por pregão) ---
  f="dia_a_dia.csv"
  print "data,preco,real,absreal,prev,vol,lim,razao,persist,p,d,q,phi1,theta1,const,sinal,vetou,ordem,pos,sinal_a,ordem_a,pos_a,limite,alfa,beta" > f
  for(i=1;i<=n;i++){
    real = (i<n) ? 100*log(pr[i+1]/pr[i]) : "nan"
    abs_ = (i<n) ? (real<0 ? -real : real) : "nan"
    printf "%s,%.2f,%s,%s,%.5f,%.5f,%.5f,%.5f,%.6f,%d,%d,%d,%.6f,%.6f,%.6f,%d,%d,%d,%d,%d,%d,%d,%d,%.6f,%.6f\n",
      iso(d[i]), pr[i], (i<n?sprintf("%.5f",real):"nan"), (i<n?sprintf("%.5f",abs_):"nan"),
      100*prev[i], 100*vol[i], 100*lim[i], vol[i]/lim[i], pe[i], p_[i], d_[i], q_[i],
      phi1[i], th1[i], 100*c[i], si[i], vt_[i], og[i], pg[i], sa[i], oa[i], pa[i], (pe[i]>=0.9998), al[i], be[i] > f
  }
  vt("Inicio", br(d[1])); vt("Fim", br(d[n])); v("N","%d",n)

  # --- previsão x realizado (figura 09); a previsão é a mesma nas duas execuções ---
  for(i=1;i<n;i++){ r=100*log(pr[i+1]/pr[i]); x=100*prev[i]
    if(sg(r)!=0 && sg(x)!=0){ nv++; if(sg(r)==sg(x)) ac++ }
    sx+=x; sxx+=x*x; sr+=r; srr+=r*r; m++
    if(x>0) npos++
    arq_q = (sg(r)==sg(x)) ? "prev_acerto.csv" : "prev_erro.csv"
    if(!(arq_q in cab)){ print "prev,real" > arq_q; cab[arq_q]=1 }
    printf "%.5f,%.5f\n", x, r > arq_q }
  dpx=sqrt(sxx/m-(sx/m)^2); dpr=sqrt(srr/m-(sr/m)^2)
  v("PrevN","%d",nv); v("PrevAcertos","%d",ac); v("PrevTaxa","%.1f",100*ac/nv)
  v("PrevDP","%.2f",dpx); v("RealDP","%.2f",dpr); v("RazaoDP","%.0f",dpr/dpx)
  v("PrevPos","%d",npos); v("PrevPosPct","%.0f",100*npos/m)

  # --- reestimação (figura 10) ---
  for(i=1;i<=n;i++){ k=p_[i] "," d_[i] "," q_[i]; if(!(k in mod)){ mod[k]=1; nmod++ }
    if(i>1 && k!=ant) trocas++; ant=k
    if(d_[i]==0) nd0++; if(p_[i]==0 && q_[i]==0 && d_[i]==1) n010++ }
  v("Modelos","%d",nmod); v("Trocas","%d",trocas); v("DiasDzero","%d",nd0); v("DiasPasseio","%d",n010)
  # faixas com d = 0
  print "ini,fim" > "faixas_d0.csv"
  for(i=1;i<=n;i++){ if(d_[i]==0 && (i==1 || d_[i-1]!=0)) ini=iso(d[i])
    if(d_[i]==0 && (i==n || d_[i+1]!=0)) print ini "," iso(d[i]) > "faixas_d0.csv" }

  # --- GARCH no tempo e decisão (figuras 11 e 12) ---
  for(i=1;i<=n;i++){
    if(vt_[i]) nvet++; if(si[i]==1) ncompra++; if(si[i]==-1) nvenda++
    if(sa[i]==1) ncompra_a++; if(sa[i]==-1) nvenda_a++
    if(vt_[i] && sa[i]==1) vet_compra++; if(vt_[i] && sa[i]==-1) vet_venda++
    if(pe[i]>=0.9998) nlim++
    # regra do filtro reconstruída a partir das colunas: veta se vol > limiar
    regra = (vol[i]>lim[i]) ? 1 : 0; if(regra!=vt_[i]) incoer++
    cls = vt_[i] ? "vetada" : (prev[i]>0 ? "compra" : "venda")
    if(!(cls in cab)){ print "prev,razao" > ("decisao_" cls ".csv"); cab[cls]=1 }
    printf "%.5f,%.5f\n", 100*prev[i], vol[i]/lim[i] > ("decisao_" cls ".csv")
    if(vol[i]/lim[i] > rmax) rmax=vol[i]/lim[i]
  }
  v("Vetos","%d",nvet); v("VetosPct","%.0f",100*nvet/n); v("Compras","%d",ncompra); v("Vendas","%d",nvenda)
  v("ComprasA","%d",ncompra_a); v("VendasA","%d",nvenda_a); v("VetoCompra","%d",vet_compra); v("VetoVenda","%d",vet_venda)
  v("DiasLimite","%d",nlim); v("Incoerentes","%d",incoer+0); v("RazaoMax","%.1f",rmax)
  # dias vetados, para sombrear
  print "data" > "dias_vetados.csv"; for(i=1;i<=n;i++) if(vt_[i]) print iso(d[i]) > "dias_vetados.csv"
  # o dia de maior vol prevista
  for(i=1;i<=n;i++) if(vol[i]>vmax){ vmax=vol[i]; imax=i }
  vt("DiaVolMax", br(d[imax])); v("VolMax","%.1f",100*vmax); v("LimVolMax","%.1f",100*lim[imax])

  # --- exposição (figura 13) ---
  for(i=1;i<=n;i++){ if(pg[i]==1) dg++; if(pa[i]==1) da++; eg+=og[i]; ea+=oa[i]
    if(pa[i]==1 && pg[i]==0) soa++; if(pg[i]==1 && pa[i]==0) sog++
    if(i>1 && pg[i-1]==1 && pg[i]==0) sg_++; if(i>1 && pa[i-1]==1 && pa[i]==0) sa_++ }
  v("DiasCompradoG","%d",dg); v("DiasCompradoA","%d",da); v("EntradasG","%d",eg); v("EntradasA","%d",ea)
  v("SaidasG","%d",sg_); v("SaidasA","%d",sa_); v("DiasSoArima","%d",soa); v("DiasSoGarch","%d",sog+0)
  for(k=1;k<=2;k++){ nome=(k==1?"faixas_comprado_garch.csv":"faixas_comprado_arima.csv"); print "ini,fim" > nome
    for(i=1;i<=n;i++){ x=(k==1?pg[i]:pa[i]); xa=(i>1?(k==1?pg[i-1]:pa[i-1]):0); xp=(i<n?(k==1?pg[i+1]:pa[i+1]):0)
      if(x==1 && xa!=1) ini=iso(d[i]); if(x==1 && xp!=1) print ini "," iso(d[i]) > nome } }
  print "data,preco" > "entradas_garch.csv"; print "data,preco" > "entradas_arima.csv"
  for(i=1;i<=n;i++){ if(og[i]) print iso(d[i]) "," pr[i] > "entradas_garch.csv"; if(oa[i]) print iso(d[i]) "," pr[i] > "entradas_arima.csv" }

  # --- os dois pregões da figura 08 ---
  for(i=1;i<=n;i++){ if(d[i]==lib) il=i; if(d[i]==vet) iv=i }
  for(k=1;k<=2;k++){ i=(k==1?il:iv); s=(k==1?"Lib":"Vet")
    vt("Dia" s, br(d[i])); v("Preco" s,"%.2f",pr[i]); v("D" s,"%d",d_[i]); v("P" s,"%d",p_[i]); v("Q" s,"%d",q_[i])
    v("PhiUm" s,"%.3f",phi1[i]); v("PhiDois" s,"%.3f",phi2[i]); v("PhiTres" s,"%.3f",phi3[i]); v("Const" s,"%.3f",100*c[i])
    v("Prev" s,"%.2f",100*prev[i]); v("Alfa" s,"%.3f",al[i]); v("Beta" s,"%.3f",be[i]); v("Persist" s,"%.3f",pe[i])
    v("Vol" s,"%.2f",100*vol[i]); v("Lim" s,"%.2f",100*lim[i]); v("Pos" s,"%d",pg[i]); v("PosA" s,"%d",pa[i])
    v("Real" s,"%.1f",100*log(pr[i+1]/pr[i])) }
  for(i=iv;i<=n;i++) if(pa[i]==0){ vt("DiaSaidaA", br(d[i])); break }

  # --- memória do GARCH (figura 14): validação x pregão liberado da figura 08 ---
  omg[1]=vo; alf[1]=va; bet[1]=vb; omg[2]=om[il]; alf[2]=al[il]; bet[2]=be[il]
  e=choque/100
  for(k=1;k<=2;k++){ P=alf[k]+bet[k]; vlp=omg[k]/(1-P); s=(k==1?"Val":"Rob")
    v("MemPersist" s,"%.3f",P); v("MemSigLP" s,"%.2f",100*sqrt(vlp)); v("MemMeiaVida" s,"%.1f",log(0.5)/log(P))
    v("MemAlfa" s,"%.3f",alf[k]); v("MemBeta" s,"%.3f",bet[k])
    nome="memoria_impacto_" s ".csv"; print "eps,sigma" > nome
    for(x=-8;x<=8.0001;x+=0.1) printf "%.2f,%.5f\n", x, 100*sqrt(omg[k]+alf[k]*(x/100)^2+bet[k]*vlp) > nome
    nome="memoria_decaimento_" s ".csv"; print "h,sigma,lp" > nome
    s1=omg[k]+alf[k]*e*e+bet[k]*vlp; v("MemSigUm" s,"%.2f",100*sqrt(s1))
    for(h=1;h<=40;h++) printf "%d,%.5f,%.5f\n", h, 100*sqrt(vlp+P^(h-1)*(s1-vlp)), 100*sqrt(vlp) > nome }
  v("MemChoque","%.2f",choque)
}' "$T/traco_demo_ARIMA.csv" "$T/traco_demo_GARCH.csv"

echo "gravado em $SAIDA"; ls "$SAIDA"
