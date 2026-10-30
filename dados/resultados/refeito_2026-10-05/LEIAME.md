# Refação de todos os experimentos com o EA corrigido (05–06/10/2026)

**Resultados vigentes do TG.** Substituem os das rodadas 3, 4, 5 e 6 e o traço
de demonstração (`../rodada3_b3_oficial`, `../rodada4_multiativos`,
`../rodada5_periodos_longos`, `../rodada6_fora_amostra_2017_2024`,
`../traco_demo_2019_2021`), que foram produzidos com o EA antes das correções de
05/10 (`ia/INCERTEZAS.md`, itens 43 a 47). A réplica de Almeida
(`../replica_almeida_2026-09-28`) só usa médias móveis e continua valendo.

Protocolo, escrito antes dos resultados: `PROTOCOLO.md`.

## Como foi rodado

1. `ferramentas/scripts/refazer_calibracoes.sh` (05/10 23h08 → 06/10 00h48):
   4 ativos × 6 janelas × 688 configurações + C4 (2014–2016, 344) =
   **16.856 passagens**, todas presentes (`calibracao/`, um CSV por ativo e janela).
2. `ferramentas/scripts/refazer_testes.sh` (06/10 00h48 → 01h06): pareia
   (`pareados/`), escolhe (`escolhas/`), roda os testes individuais (`testes/`,
   `relatorios_mt5/`), o cenário de Almeida, o traço (`traco_demo/`) e os
   anuais. A comparação pareada falhou nessa execução (ver "Problemas") e foi
   refeita à parte com `comparar.sh` → `testes/comparacoes.csv`.
3. `ferramentas/scripts/analisar_grades.sh` → `analise_grades.txt`.
4. `ferramentas/scripts/sensibilidade_longos.sh` → `sensibilidade/`.
5. Resumo legível de qualquer pasta de testes:
   `ferramentas/scripts/resumo_testes.sh testes`.

## Conferências feitas

- **Scripts novos contra os arquivos antigos** (antes de usar nos novos): a
  escolha reproduziu as 12 escolhas da rodada 3 e as 48 da rodada 4; a análise
  pareada, a de venda a descoberto, as referências, a persistência, os anuais e
  a concentração reproduziram os números do Python. A comparação pareada rodada
  no testador reproduziu `comparacao_modelos_R3.csv` até a 4ª casa.
- **Regressão**: as médias móveis (R3_T1/T2/T3, R6, L1, L2) e o cenário de
  Almeida 2013–2016 saíram **idênticos** aos antigos (curvas byte a byte iguais;
  nas métricas da rodada 3 só aparece a coluna `ruina`, acrescentada ao
  Desempenho.mqh depois daquela rodada). O cenário 2013–2016 não tem nenhum dia
  com d = 0, então nada podia mudar ali.

## O que mudou nas escolhas (camada 3, só compra)

| Calibração | Antes | Agora |
|---|---|---|
| C1 2004–06 | GS = GC: filtro+targeting p90, alvo 1%, zera, J120 | **igual** |
| C2 2010–12 | GS: filtro p50, J120 · GC: filtro+targeting p50, alvo 1%, zera, J240 | GS: filtro+targeting p50, **alvo 2%**, zera, J240 · GC: **igual** |
| C3 2022–24 | GS: f+t p90 alvo 2% zera J240 LS 0,1% · GC: f+t p90 alvo 1% | GS: **filtro p70 zera** J240 LS 0,1% · GC: f+t **p70** alvo 1% |
| C4 2014–16 | GS: filtro p70 zera J240 c/ const · GC: f+t p50 alvo 1% não zera J120 | **iguais** |

## Resultados principais (camada 3)

`resumo_testes.sh testes` dá a tabela completa. Destaques:

- **2017–2024 (resultado principal):** GS +273,8% (antes +276,1%), queda 26,1%,
  Sharpe 0,49 p 0,085; gêmea +114,6% (antes +106,5%), queda 40,6%. GC +114,1%,
  gêmea −46,5%. GC × gêmea p = 0,020 (o único par significativo).
- **Janelas:** T1 GARCH +28,7% / queda 13,3% (antes +17,2% / 19,3%); 2008 +5,0%
  com a PETR4 em −47,3%. T2 por Sharpe +15,8% (antes +325,3%, Sharpe 0,80 —
  **esse resultado desapareceu**, a escolha mudou), por Calmar +34,0% / 6,8%
  (igual ao antigo). T3: as variantes com GARCH ficaram abaixo do ARIMA isolado.
- **Períodos longos (regra nova, GS e GC de C2):** 2005–2026 +602,4% e +669,9%,
  quedas 29,7% e 14,2%; gêmea +79,9% / 80,7%; nenhum supera a Selic (+795,8%);
  nenhum par significativo.
- **Significância:** GARCH × gêmea significativo em **1 de 11** (antes 5 de 11),
  nenhum pior; × médias móveis 0 de 9 (p de 0,11 a 0,92); contra a Selic, nenhum
  p < 0,05 (antes havia um, o filtro de 2005–2026 com p 0,041).
- **O que se manteve:** em todos os 11 pares a versão com GARCH teve queda máxima
  menor que a gêmea, e em 9 de 11, retorno maior. Nos 4 ativos, as variantes que
  limitam a exposição reduziram a queda em 85–93% (2007–11), 92–98% (2013–16) e
  52–96% (2025–26) dos pares.

## Sensibilidade (`sensibilidade/`)

As três configurações fixas da rodada 5 original (GF, GT, AR), rodadas com o EA
corrigido, só para separar o efeito da correção do efeito da nova escolha:
L1 filtro (GF) +3.253,9%, Sharpe 0,36, **p = 0,050** (antes 0,041); GF × AR
p = 0,002. Ou seja: o filtro continua forte contra a gêmea, mas o resultado
"único p < 0,05 contra a Selic" estava no limite e não sobrevive à correção. Pela
regra declarada no protocolo, o TG usa a GS e a GC de C2, não estas.

## Problemas na execução (resolvidos)

- **Arquivos antigos copiados por engano**: o glob `L1_*` pegou `L1_GF/GT/AR`
  de 30/09 que estavam em Common. Removidos daqui; o `refazer_testes.sh` agora
  copia só os rótulos rodados na mesma execução.
- **"open charts limit reached"**: o script de comparação via `[StartUp]` não
  rodou porque o perfil Default do terminal chegou a 100 gráficos (92 deles de
  símbolos `_OFICIAL`, deixados pelas automações). A limpeza do perfil não foi
  feita (pedido de permissão negado; fica para o autor decidir). A comparação
  passou a rodar como EA no testador (`ferramentas/CompararModelosEA.mq5`), que
  não abre gráfico.

## Traço

`traco_demo/`: configuração GS de C4 (a mesma de antes), PETR4, jul/2019 a
jun/2021. Linha `2020.04.03` de `traco_demo_GARCH.csv`: `prev_dif` = 0,02658,
`vol_prevista` = 0,07575, `limiar` = 0,02544, vetou.

sha256:
- traco_demo_ARIMA.csv f6bf7f50392493f5120711e56f79a1852b1100b26b15db063b49b2236a20cc59
- traco_demo_GARCH.csv 6719270bbedc6e18e6ba77b00ae3715312589909bcd7c686e9fc21d629723859

## Medidas de risco acrescentadas em 13/10/2026 (texto com foco em volatilidade)

O Cap. III passou a ter a volatilidade e a queda máxima como medidas centrais.
Arquivos novos, todos sobre os mesmos testes desta pasta (nada foi rodado de novo):

- `testes/comparacoes_risco.csv`: os pares de `testes/pares.txt` mais o cenário de
  Almeida contra as médias móveis reproduzidas (`testes/pares_risco.txt`), com cinco
  colunas novas, `vol_a`, `vol_b` e o teste de Pitman-Morgan (`r_pm`, `t_pm`,
  `p_pm`), calculado em MQL5 (`CompararCurvas`, `robos/Include/Desempenho.mqh`). As 12
  colunas antigas saíram idênticas às de `comparacoes.csv` (conferido com `diff`).
  O t do Pitman-Morgan reproduziu o `protecao_pitman_morgan.txt` (awk exploratório).
- `analise_grades.txt`, bloco 6: volatilidade pareada GARCH × gêmea nos 4 ativos.
  Blocos 1 a 5 idênticos aos anteriores (conferido com `diff`).
- `seletividade.txt` (`ferramentas/scripts/seletividade.sh`): oscilação da parte em
  ações dividida pela que se teria com a mesma exposição em dias quaisquer. A última
  linha (`fl13of`, médias móveis nas condições de Almeida) vem de
  `../replica_almeida_2026-09-28/`.
- `volatilidade_grafico.csv` e `reducao_volatilidade.txt` (14/10/2026,
  `ferramentas/scripts/resumo_volatilidade.sh`): volatilidade por janela para o
  gráfico de barras do Cap. III e redução da volatilidade (%) do ARIMA-GARCH contra
  a gêmea e contra as médias móveis, com o t de Pitman-Morgan. As volatilidades vêm
  das métricas (`vol_selic`; no cenário de Almeida, `vol_puro`), não do
  `comparacoes_risco.csv`, que grava só 4 casas.
