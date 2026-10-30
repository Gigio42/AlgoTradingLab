# Estudo das janelas fixas: ARIMA 240, GARCH 500 (26/10/2026)

Pedido do autor em 26/10/2026, depois da crítica da orientadora sobre a janela do
GARCH (`notas/INCERTEZAS.md`, item 78): refazer os testes com o ARIMA sempre em 240
pregões e o GARCH sobre os 500 resíduos mais recentes, e montar **um PDF à parte**
só com o Cap. III nessas condições. **O TG não foi alterado** (`tg/` intacto).

O protocolo foi escrito antes dos resultados: `PROTOCOLO.md`.

## O que tem aqui

| Caminho | O quê |
|---|---|
| `documento/estudo.pdf` | O PDF (17 páginas): nota inicial + Cap. III no molde do TG |
| `documento/*.tex`, `compilar.sh` | Fonte do PDF. O preâmbulo vem do `tg/main.tex` na hora |
| `grades/` | Sub-grades usadas (r4 = 4 ações, r3 = C4 da PETR4) |
| `calibracao/` | Uma linha por passagem, por ação e janela (312; 156 na C4) |
| `escolhas/` | Saída do `escolher.sh` (GS, GC, AS, AC e gêmeas) |
| `testes/` | `metricas_*.csv` e `curva_*.csv` dos 31 testes individuais e das médias móveis (copiadas da refação, que não dependem da mudança) |
| `relatorios_mt5/` | Relatórios do testador (htm + png do saldo) |
| `traco/traco_R6_GS.csv` | Traço por barra do ARIMA-GARCH Sharpe de 2017 a 2024 |
| `pareados/` | Calibração × teste por configuração (`parear.sh`) |
| `cru/` | Todos os números do PDF (ver abaixo) |
| `comparacao_tg.txt` | Cada robô no TG atual e no estudo, lado a lado |
| `execucao_bateria.log` | Log da bateria, com a interrupção e a retomada |

## Como reproduzir

```bash
# da raiz do repositório, com o MT5 do prefixo novo autenticado
bash ferramentas/scripts/janelas_240_500.sh dados/resultados/janelas_240_500_2026-10-26 calibrar testar
bash ferramentas/scripts/estudo_janelas_dados.sh
bash dados/resultados/janelas_240_500_2026-10-26/documento/compilar.sh
```

O EA precisa ter os inputs `Janela_GARCH` e `Inicio_Operacao` (acrescentados em
26/10, ambos fora do Apêndice A, que continua idêntico). Calibração ≈ 1h30, testes
≈ 10 min.

## Os números do PDF (`cru/`)

| Arquivo | Script | Alimenta |
|---|---|---|
| `tabelas.txt`, `recorte_2008.txt`, `recorte_2020.txt`, `anual_*.csv`, `curva_20*.csv`, `exposicao_*`, `efeito_garch.txt`, `petr4_2018.txt` | `dados_cru.sh` com `RES=` | Tabelas e gráficos de cada período, efeito do GARCH |
| `outras_acoes.txt` | `outras_acoes.sh` com `RES=` | Tabela das outras ações |
| `analise_grades_cru.txt` | `analisar_grades.sh` (`CAMADA=puro SEM_IC=1`) | Dois grupos nas 4 ações (blocos 2 e 6), venda a descoberto (bloco 3) |
| `saldo_mt5.txt` | `saldo_mt5.sh` | Parágrafos do saldo do MT5 |
| `mecanismo.txt` | `estudo_janelas_dados.sh` | Acerto, vetos, sinais, exposição |
| `traco_resumo.txt` | `traco_resumo.sh` | d = 1, persistência do GARCH (240 × 500), 03/04/2020 |
| `efeito_janela_garch.txt` | `efeito_janela_garch.sh` | Mesma configuração com GARCH sobre 240 e sobre 500 resíduos |

## Conferências

- **Contagem de passagens**: 312 em todas as 24 janelas das 4 ações e 156 na C4.
- **Aquecimento não muda nada por si só**: o ARIMA sem GARCH de 2017–2024 com
  aquecimento tem curva idêntica à da refação (V1 do protocolo), e as 96
  passagens sem GARCH dos 12 períodos de teste das 4 ações têm retorno e queda
  idênticos aos da refação (`efeito_janela_garch.txt`, fim).
- **GARCH com 500 pregões desde o primeiro dia**: o GS de 2017–2024 não teve
  nenhuma falha de estimação (V2).
- **Passagem da grade = teste individual**: a PETR4 em `outras_acoes.txt` (lida
  das grades) bate com `tabelas.txt` (testes individuais) nos três períodos.
- **Saldo do MT5**: o saldo final de cada relatório = 100.000 × (1 + `ret_puro`).
- **2008**: o último dia de `curva_2008.csv` bate com `recorte_2008.txt`.
- **Scripts alterados** (`dados_cru.sh`, `parear.sh`): rodados sobre uma cópia
  dos testes da refação, reproduzem `refeito_2026-10-05/cru/` byte a byte.
- **Apêndice A**: a listagem gerada do EA continua idêntica a `tg/codigo/`.
- **Regressão do código** (`regressao_codigo.sh`): 27 arquivos idênticos depois
  das mudanças no EA.

## Problema durante a bateria

Na 1ª tentativa, a partir da C3 da PETR4, as grades rodaram com passagens a mais
(C3: 960 em vez de 312). Causa: na otimização, uma linha da grade sem `||` herda
do `MQL5/Profiles/Tester/ARIMA_GARCH_EA.set` a marca de otimizar (Y) e a faixa, e
o `.set` tinha ficado com Y em `Limiar_Percentil`, `Vol_Alvo` e outros. A
bateria foi interrompida, as janelas afetadas apagadas, e a retomada passou toda
linha numérica/lógica com faixa explícita e `N` (função `explicitar` no
`janelas_240_500.sh`) e apaga o `.set` antes de cada otimização. As quatro
janelas já feitas (C1, T1, C2, T2 da PETR4) tinham 312 passagens cada e foram
mantidas. A refação de 05/10 não foi afetada (688 passagens em toda janela).
Registrado no CLAUDE.md, armadilhas do tester.

## Diferenças de montagem em relação ao TG

- Calibração C1: 01/02/2005 a 29/12/2006 (no TG, 2004 a 2006), e período longo
  de 01/02/2005 a 18/09/2026 (no TG, desde 03/01/2005). A série oficial começa em
  02/01/2003 e só reúne 500 pregões no fim de janeiro de 2005.
- Cada teste começa dois anos antes no testador; antes de `Inicio_Operacao` o EA
  não opera e não mede.
- Grade de 156 configurações por janela só-compra (312 com a venda a descoberto):
  a janela do ARIMA saiu da grade.
- As médias móveis não foram rodadas de novo (não dependem da mudança).

## O que o estudo mostrou (resumo; detalhes no item 78 do INCERTEZAS)

- A janela de 500 melhora a estimação do GARCH: persistência > 0,999 em 2,2% dos
  pregões de 07/2019 a 06/2021, contra 29,0% com a janela do ARIMA.
- Para a mesma configuração, o resultado quase não muda (3.648 pares: queda menor
  em 46,8%, maior em 43,8%).
- As configurações escolhidas mudaram em 7 dos 8 casos, e com elas os números do Cap. III.
  A exceção é o GS de 2017–2024: mesma configuração nas duas versões (`escolhas/r6_C4.txt`
  dos dois), e +199,5% → +64,6% vem só da janela. Os 3.648 pares não cobrem 2017–2024. O
  efeito do GARCH sobre o risco se mantém onde ele reduz a posição. As quatro
  comparações em que não se manteve são do Sharpe com só o filtro e mantendo a
  posição.
- Hwang e Valls Pereira (2006) só está no `documento/estudo.bib`, não no TG. O
  autor ainda não leu a obra.
