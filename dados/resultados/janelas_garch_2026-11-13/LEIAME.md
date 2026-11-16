# A janela do GARCH: 120, 240, 500 e 1000 (13/11/2026) — parte no TG desde 15/11/2026 (Cap. III, 3.11.1, Tabela 15)

Pedido do autor em 13/11/2026: um relatório com gráficos sobre o ARIMA-GARCH com
janelas de 120, 240, 500 e 1000, para entender a janela (mais dado é
*overfitting*? janela menor "se acostuma" menos?) e quanto do resultado é a
otimização. Relatório em `ia/relatorios/janela-garch/` (`make dados && make`).
Protocolo escrito antes de rodar: `PROTOCOLO.md`.

ARIMA sempre com janela 240; só `Janela_GARCH` muda (120, 240, 500, 1000).
Quatro anos de aquecimento antes de cada período (`Inicio_Operacao`). 2004–2011
no `PETR4_DESDE1999`.

## O que tem aqui

| Arquivo | Conteúdo |
|---|---|
| `calibracao/<janela>/PETR4_<per>.csv` | as 156 passagens (sub-grades só compra da rodada 3) de cada período: C1 2004–06, T1 2007–11, C2 2010–12, T2 2013–16, C4 2014–16, R6 2017–24, C3 2022–24, T3 2025–set/2026 |
| `grades/` | as sub-grades usadas (com `<janela>` no lugar do valor) |
| `testes/`, `traco/` | métricas, curva e traço por barra da configuração do ARIMA-GARCH Sharpe do TG em 2017–2024 (`refeito_2026-10-05/escolhas/r6_C4.txt`), com `Janela_GARCH` = 0 (resíduos do ARIMA, como no TG), 120, 240, 500 e 1000 |
| `simulacao/` | saída do `JanelaGarchSimulada.mq5`: precisão em 400 séries sem mudança de regime e 20 séries com uma crise artificial (semente fixa) |
| `cru/` | tudo o que o relatório lê, gerado por `ferramentas/scripts/janelas_garch_dados.sh`: tabelas, caixas, pontos, `valores.tex` (cada número do texto) e `conferencias.txt` |
| `execucao.log` | o que a bateria rodou |

Refazer: `bash ferramentas/scripts/janelas_garch.sh <pasta> grades traco` (~3 h
no testador do prefixo novo), `bash ferramentas/scripts/janela_garch_simulada.sh`
(~10 min, prefixo antigo, sem testador) e `bash ferramentas/scripts/janelas_garch_dados.sh`.

## Conferências (`cru/conferencias.txt`)

- 156 passagens em cada uma das 32 otimizações.
- As 4 configurações sem GARCH idênticas nas quatro janelas, em todo período.
- Janela 1000 igual, passagem a passagem, ao estudo de 02/11/2026 em C1–C4;
  janela 500 igual ao de 26/10/2026 nos períodos em comum (só as configurações
  só compra daquele estudo).
- Exemplo da crise artificial idêntico entre a 1ª versão (1 série) e a final (20
  séries): mesma semente, mesma ordem de sorteio.

## Armadilhas desta rodada

- **O prefixo antigo também se atualiza sozinho.** Às 13:49 o LiveUpdate baixou
  o build 6230; na rodada seguinte o terminal reiniciou para se atualizar e o
  script não foi achado (`script ... not found from start config`). Sem erro
  visível, o `janela_garch_simulada.sh` esperou à toa. Ele agora apaga o `.ex5`
  antes de compilar e para se a compilação falhar.
- **`StringFormat` só com a string de formato não compila** (`wrong parameters
  count`).
- Conferir contra o estudo de 500 exige filtrar `SomenteCompra=1`: aquele estudo
  tinha também as configurações com venda, com a mesma chave.
