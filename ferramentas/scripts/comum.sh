# Configuracao comum dos scripts de experimento (bash; ver CLAUDE.md).
# TRAB = pasta de trabalho (ini, logs); nao vai para o repositorio.
N="$HOME/.wine-mt5-novo/drive_c/Program Files/MetaTrader 5"
COMUM="$HOME/.wine-mt5-novo/drive_c/users/dark/AppData/Roaming/MetaQuotes/Terminal/Common/Files/AlgoLab"
TRAB="${TRAB:-/tmp/algolab-trabalho}"; mkdir -p "$TRAB"
CONTA=$'[Common]\r\nLogin=1199505191\r\nServer=ClearInvestimentos-DEMO\r\n[Experts]\r\nAllowLiveTrading=1\r\nEnabled=1\r\n'
matar(){ WINEPREFIX=~/.wine-mt5-novo wineserver -k 2>/dev/null; }
limpar_cache(){ rm -rf "$N"/Tester/cache/* "$N"/Tester/bases/*/history/"$1"* 2>/dev/null; }
esperar(){ # esperar <arquivo> <segundos>
  local t0=$(date +%s); while [ ! -s "$1" ]; do sleep 5; [ $(( $(date +%s)-t0 )) -gt $2 ] && { echo "TIMEOUT $1"; return 1; }; done; }
rodar_ini(){ cd "$N"; WINEPREFIX=~/.wine-mt5-novo wine terminal64.exe "/config:Z:$(echo "$1" | tr / '\\')" >/dev/null 2>&1 & }
