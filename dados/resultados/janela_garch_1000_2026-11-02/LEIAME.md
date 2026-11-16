# GARCH com 1000 resíduos (02/11/2026) — estudo à parte, NÃO está no TG

Pedido do autor em 02/11/2026: refazer os testes dos períodos da parte
principal do Cap. III (PETR4) com o GARCH estimado sobre os 1000 resíduos mais
recentes (ARIMA continua em 240) e comparar com o TG e com o estudo de 500
(`../janelas_240_500_2026-10-26/`). **O TG não muda**: no texto, a janela do
GARCH fica como limitação (decisão do autor). Protocolo escrito antes de rodar:
`PROTOCOLO.md`. 2004–2006, 2007–2011 e o período longo rodam no
`PETR4_DESDE1999`, a série oficial da B3 estendida a 1999
(`dados/FONTES.md`, item 14), por decisão do autor.

## O que tem aqui

| Arquivo | Conteúdo |
|---|---|
| `calibracao/PETR4_C*.csv` | as 156 passagens de cada otimização (C1 2004–06, C2 2010–12, C3 2022–24, C4 2014–16) |
| `escolhas/` | GS, GC, AS e gêmeas escolhidas por `escolher.sh so_compra` |
| `testes/` | métricas e curvas dos 28 testes (as médias móveis são cópia da refação de 05/10) |
| `relatorios_mt5/` | relatório e curva do MT5 de cada teste |
| `traco/traco_R6_GS.csv` | traço por barra do GS de 2017–2024 |
| `cru/` | `dados_cru.sh` com `RES=` esta pasta: tabelas, efeito do GARCH, recortes de 2008 e 2020, retorno anual |
| `comparacao_tg.txt` | TG × 500 × 1000, robô a robô (`comparar_janelas.sh` com `C=`) |
| `grades/` | as sub-grades de C4 (as outras janelas só mudam `Inicio_Operacao`) |
| `execucao_*.log`, `testes/execucao.log` | o que rodou e quando |

Refazer: `bash ferramentas/scripts/janela_garch_1000.sh <pasta> calibrar testar`
(~25 min; precisa do símbolo `PETR4_DESDE1999` importado).

## Conferências (todas passaram)

- 156 passagens em cada uma das quatro otimizações.
- Passagens sem GARCH idênticas às do estudo de 500 em C2, C3 e C4; e, nos
  testes, todo robô sem GARCH com a mesma configuração dá o mesmo resultado nos
  dois estudos, inclusive 2007–2011 no `PETR4_DESDE1999`. O aquecimento de
  quatro anos e a série estendida não alteram nada fora do GARCH.
- `PETR4_DESDE1999` × `PETR4_OFICIAL` na sub-grade arima de C2: iguais.
- Traço do GS de 2017–2024: nenhum dos 1.983 pregões sem volatilidade prevista.
- Lucro do relatório do MT5 = 100.000 × `ret_puro` (7 testes conferidos).

## Resultado (camada 1, crua; números de `comparacao_tg.txt` e `cru/`)

ARIMA-GARCH × a mesma configuração sem GARCH (`cru/efeito_garch.txt`): 12
linhas, das quais em 2017–2024 GS e GC são a mesma configuração (11 distintas).
Com 1000, queda menor em 11 das 12 linhas e volatilidade menor em 11; retorno
maior em 9. A exceção é o GS de 2013–2016: limiar absoluto, sem zerar no veto,
a posição ficou comprada congelada e acompanhou a ação (2013 −16,0%, 2014
−26,8%, 2015 −32,4%, 2016 +112,6%; PETR4 −15,2%, −40,1%, −34,5%, +123,3%),
queda de 81,0% contra 51,9% da gêmea. No TG: 11 de 11 em queda e volatilidade,
7 em retorno. No estudo de 500: 9 e 8 de 12, 7 em retorno.

| Período | robô | TG | 500 | 1000 |
|---|---|---|---|---|
| 2007–2011 | GS ret / queda | −8,4% / 17,5% | +31,4% / 13,5% | −0,1% / 10,7% |
| | GC | −8,4% / 17,5% | +1,7% / 10,1% | −5,5% / 12,1% |
| 2013–2016 | GS | −13,8% / 28,6% | −24,5% / 77,6% | −11,7% / 81,0% |
| | GC | −6,8% / 15,5% | −9,6% / 40,5% | −4,7% / 49,4% |
| 2025–2026 | GS | −13,7% / 17,6% | +9,3% / 21,1% | +7,1% / 13,6% |
| | GC | −7,4% / 12,2% | +5,3% / 15,4% | +2,3% / 15,7% |
| 2017–2024 | GS | +199,5% / 27,2% | +64,6% / 37,0% | +12,7% / 8,5% |
| | GC | +42,9% / 40,2% | −15,4% / 21,6% | +12,7% / 8,5% |
| 2005–2026 | GS | +74,2% / 36,4% | +63,0% / 79,6% | +232,7% / 61,7% |
| | GC | +33,5% / 24,4% | +32,1% / 44,3% | +111,2% / 31,6% |
| 2017–2024 (config. fixa) | GS | +19,9% / 31,9% | +29,3% / 62,5% | +11,1% / 30,8% |
| | GC | +7,5% / 18,4% | +7,9% / 31,6% | +7,1% / 16,5% |

Anos de crise (`cru/recorte_2008.txt`, `recorte_2020.txt`): em 2008 o GS fez
−0,95% com queda de 2,07% (TG −4,42% / 11,25%) e o GC ficou o ano inteiro fora
do mercado (0,00%); a PETR4 caiu 47,33%. Em 2020 o GS (= GC) fez −4,06% com
queda de 4,53% (TG +1,02% / 20,26%).

## Leitura

1. A proteção contra a gêmea se repete com 1000 (11 de 12), mais perto do TG
   do que o estudo de 500.
2. Ela vem, em boa parte, de ficar fora do mercado: a otimização escolheu o
   limiar absoluto de 2% com zerar no veto em várias janelas, e com 1000
   resíduos a volatilidade prevista da PETR4 fica acima de 2% quase sempre (no
   GS de 2017–2024, 1.764 vetos em 1.983 pregões, exposição média 4%). Em
   2017–2024 isso custou retorno: +12,7% contra +95,7% da gêmea.
3. Quando a escolha é não zerar no veto, a posição congela e não protege
   (2013–2016, e o 61,7% de queda do GS em 2005–2026), o mesmo que as rodadas
   antigas já mostravam.
4. Todas as escolhas mudaram em relação ao TG e ao estudo de 500; a diferença
   mistura o efeito da janela com o da seleção entre 156 candidatas. Nenhum
   teste estatístico foi feito aqui.
