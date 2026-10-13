# Rodada 4 — quatro ativos, com e sem venda a descoberto (23–24/09/2026)

> **SUPERADO em 06/10/2026** pela refação com o EA corrigido
> (`../refeito_2026-10-05/LEIAME.md`; erros em `notas/INCERTEZAS.md`, itens 43 a
> 47). Os números desta pasta foram produzidos com o EA antigo e não vão para o TG.


Mesmo protocolo da rodada 3 (`../rodada3_b3_oficial/PROTOCOLO.md`), com duas
mudanças:

1. **Quatro ativos**: PETR4 (petróleo), VALE3 (mineração), USIM5 (siderurgia) e
   POMO4 (bens de capital). Critério de escolha dos três novos em
   `../../FONTES.md`, item 9.
2. **Venda a descoberto entra na grade** (`SomenteCompra` varia), dobrando para
   688 as configurações por janela.

24 janelas (4 ativos × 3 calibrações × 3 testes), 168 otimizações, 16.512
passagens. Arquivos: `grades/pareado_<ativo>_<calib>_<teste>.csv` (calibração e
teste lado a lado), `escolhidas_r4.csv` e `analise4_saida.txt`.

**Atenção:** a primeira execução destes três ativos foi descartada por erro nas
séries (desdobramento aplicado no próprio dia do evento). Ver `notas/INCERTEZAS.md`.
Os resultados aqui são da série corrigida, reconferida contra a reconstrução
independente (diferença 0,00) e contra o histórico dentro do MetaTrader
(diferença 0,00).
