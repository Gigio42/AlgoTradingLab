#!/bin/bash
# Replica de Almeida, rodada 2, parte d (29/10/2026): o teste de 2013-2016 na serie
# PETR4_DESDE2008 (historico desde 02/01/2008, sem proventos), que faltava para a
# coluna "condicoes provaveis" da Tabela 1 do TG. Mesma configuracao da parte a
# (precos de abertura, entrada por estado, reversao numa ordem, sem arredondar).
source "$(dirname "$0")/comum.sh"
A="$(cd "$(dirname "$0")/../.." && pwd)"
R="$A/dados/resultados/replica_almeida_v2_2026-10-21"
S="$A/ferramentas/scripts"
B="$N/MQL5/Experts/AlgoTradingLab/ferramentas"
cp "$A/ferramentas/ReplicaAlmeidaEA.mq5" "$B/"
(cd "$N" && WINEPREFIX=~/.wine-mt5-novo wine MetaEditor64.exe /compile:"MQL5\Experts\AlgoTradingLab\ferramentas\ReplicaAlmeidaEA.mq5" /log >/dev/null 2>&1)
iconv -f UTF-16LE -t UTF-8 "$B/ReplicaAlmeidaEA.log" | grep "Result:"
printf 'RapidaMM_Periodo=10\nDevagarMM_Periodo=20\nVolume=100\nModoEntrada=0\nModoReversao=0\nPularPrimeiraBarra=true\nArredondarMedias=false\n' > "$TRAB/in_replica_d.txt"
r="ra_T3d8_m2_e0_r0"
limpar_cache PETR4_DESDE2008
MODELO=2 bash "$S/rodar.sh" "$r" 'ferramentas\ReplicaAlmeidaEA' PETR4_DESDE2008 2013.05.22 2016.05.24 50000 1:100 \
  "$TRAB/in_replica_d.txt" Volume=1000 ModoEntrada=0 ModoReversao=0 ArredondarMedias=false >/dev/null 2>&1
cp "$N/rel_$r.htm" "$R/relatorios/" 2>/dev/null || echo "SEM RELATORIO $r"
bash "$S/resumo_replica_almeida.sh" "$R/relatorios" > "$R/resumo.txt"
grep "relatorio\|T3" "$R/resumo.txt"
