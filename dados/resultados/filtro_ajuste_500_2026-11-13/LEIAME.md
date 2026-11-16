# GARCH 500 só com filtro e ajuste, mantendo × encerrando no veto (13–15/11/2026) — estudo, NÃO está no TG

Pedido do autor em 13/11/2026: todos os testes do TG com o GARCH em 500 resíduos
(ARIMA fixo em 240), e todo robô com GARCH usando filtro e ajuste juntos. Duas
versões rodadas separadas: `M/` mantém a posição no veto e `E/` encerra.
Protocolo escrito antes de rodar: `PROTOCOLO.md`. O mesmo estudo com 1000
resíduos está em `../filtro_ajuste_1000_2026-11-15/`.

**Estado: completo.** A bateria foi interrompida a pedido do autor em 13/11, às
19h47, e retomada em 15/11, à 1h50. O log das duas partes está em `execucao.log`.

## O que tem aqui

| Caminho | O quê |
|---|---|
| `M/calibracao/`, `E/calibracao/` | `<AÇÃO>_<janela>.csv`: as 52 passagens de cada janela (4 sem GARCH + 24 limiar fixo + 24 percentil). C1–C4 são otimização e T1–T4 teste (T4 = 2017–2024, o R6 do TG). Nas outras ações, a C1 começa em 01/02/2005 (série desde 2003, e o GARCH de 500 precisa de dois anos) |
| `M/escolhas/`, `E/escolhas/` | O que o `escolher.sh` escolheu em cada otimização da PETR4 |
| `M/testes/`, `E/testes/` | Testes individuais da PETR4: `metricas_<v>_T{1..4}_{GS,GSgemeo,GC,GCgemeo,AS}.csv`, e L1/L2 com as escolhas de 2010–2012 |
| `M/relatorios_mt5/`, `E/relatorios_mt5/` | Relatórios do MT5 desses testes |
| `grades/` | As sub-grades usadas, por versão (`M_ft_pct.txt` etc.) |
| `cru/` | Os números do relatório, das **duas** pastas (500 e 1000) e do TG: `escolhas.csv`, `petr4.csv`, `efeito.csv`, `grade_ME.csv`, `grade_resumo.csv`, `contagens.csv`, `barras_*.csv`, `mm.csv`, `valores.tex` e `conferencias.txt` |
| `execucao.log` | O que a bateria rodou |

Scripts:

- `ferramentas/scripts/filtro_ajuste_500.sh` roda a bateria. Ele pula as
  janelas prontas, então retomar é rodar o mesmo comando.
- `ferramentas/scripts/filtro_ajuste_500_dados.sh` gera o `cru/` e só lê
  arquivos.

Relatório: `ia/relatorios/filtro-ajuste-500-1000/` (`make dados && make`).

## Conferências (cru/conferencias.txt, 15/11/2026): todas bateram

1. 64 otimizações com 52 passagens (e 52 na pasta de 1000).
2. A sub-grade sem GARCH é idêntica em M500, E500, M1000 e E1000.
3. A PETR4 é igual, passagem por passagem, ao subconjunto de
   `janelas_garch_2026-11-13/` com `Estrategia=3` e o mesmo `ZerarNoVeto`
   (16 janelas de 500 e 16 de 1000).
4. O teste individual é igual à passagem da grade (GS e GC, 4 versões × 4
   períodos).
5. O ARIMA sem GARCH dá o mesmo resultado no teste nas quatro versões.
6. A escolha do TG refeita pelo script é igual aos testes do TG (12/12).
