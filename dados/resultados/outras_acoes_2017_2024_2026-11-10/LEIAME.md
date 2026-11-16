# Teste complementar em 2017–2024 (10/11/2026)

Pergunta da orientadora, repassada pelo autor em 10/11/2026: "2.5.8 Teste
complementar (porque não tem o período de 2017 a 2024?)". O teste complementar
da refação de 05/10 (`../refeito_2026-10-05/`) tinha só 2007–2011, 2013–2016 e
2025–2026 para as quatro ações. Esta pasta acrescenta a janela que faltava, com
o mesmo procedimento.

## Como foi rodado

- `ferramentas/scripts/outras_acoes_2017_2024.sh` (10/11/2026, 18h47 → 19h27,
  log em `execucao.log`), no MetaTrader do prefixo em uso.
- PETR4, VALE3, USIM5 e POMO4 (`*_OFICIAL`), calibração **C4 = 2014.01.02 a
  2016.12.30** e teste **T4 = 2017.01.02 a 2024.12.30** (as datas da R6 da refação).
- Grade da rodada 4 (a da rodada 3 + venda a descoberto) **sem o intervalo de
  confiança**: 624 configurações por janela, 6 sub-grades (`grades/`). Toda linha
  fixa vai com `||N` e o `.set` do testador é apagado antes de cada otimização
  (armadilha de 26/10/2026).
- 8 janelas × 624 = 4.992 passagens, todas presentes (`calibracao/`).

## Conferências

- **PETR4 C4, só compra**: as 312 configurações são idênticas às de
  `../refeito_2026-10-05/calibracao/PETR4_C4.csv` (negócios, retornos bruto e
  com Selic, quedas, Sharpe, Calmar e volatilidade, comparados por awk).
- **PETR4 T4**: as três escolhidas (GS, GC e ARIMA) dão o mesmo resultado bruto
  do teste principal do TG (`../refeito_2026-10-05/cru/tabelas.txt`, 2017 a 2024).
- `outras_acoes.sh` com `K` padrão continua gerando
  `../refeito_2026-10-05/cru/outras_acoes.txt` idêntico (`cmp`).

## Arquivos

| Arquivo | Conteúdo |
|---|---|
| `calibracao/<ATIVO>_C4.csv`, `<ATIVO>_T4.csv` | uma linha por passagem (métricas do `OnTester`) |
| `pareados/<ATIVO>_C4_T4.csv` | `parear.sh`: calibração × teste, configuração a configuração |
| `cru/outras_acoes.txt` | `RES=<esta pasta> K=4 bash ferramentas/scripts/outras_acoes.sh`: as escolhidas, camada 1 (linhas "2017 a 2024" da Tabela de outras ações do Cap. III). sha256 `dd3cbb00926ab5b4c260ffc1bb86e97668aa7d40716d334a98e073ed43b08b30` |
| `cru/analise_grades_cru_sem_ic.txt` | `SEM_IC=1 CAMADA=puro analisar_grades.sh` sobre os pareados: proteção (bloco 2), venda a descoberto (bloco 3), ruína (bloco 4) |
| `grades/` | as 6 sub-grades usadas |
| `execucao.log` | passagens e tempo de cada otimização |
