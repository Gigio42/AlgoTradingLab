# Camada crua do Cap. III (19/10/2026)

Pedido do autor em 19/10/2026: Cap. III com a comparação dos modelos no resultado
cru (camada 1: sem custos, sem Selic no caixa, sem proventos), um período por
seção, e custos, Selic e proventos numa seção própria no fim.

**Nada aqui foi simulado de novo.** Tudo sai dos testes da refação de 05/10
(`../testes/metricas_*.csv`, `../testes/curva_*.csv`, `../pareados/`,
`../relatorios_mt5/`), por três scripts versionados:

- `ferramentas/scripts/dados_cru.sh` → `tabelas.txt`, `efeito_garch.txt`,
  `recorte_2008.txt`, `recorte_2020.txt`, `anual_*.csv`, `exposicao_T1.csv`,
  `exposicao_mensal_T1.txt`, `petr4_2018.txt`
- `ferramentas/scripts/analisar_grades.sh` com `CAMADA=puro` →
  `analise_grades_cru.txt` (sem `CAMADA`, a saída é idêntica à
  `../analise_grades.txt`, conferido com `diff` em 19/10)
- `ferramentas/scripts/saldo_mt5.sh ../relatorios_mt5/rel_*.htm` → `saldo_mt5.txt`
  (saldo após cada negociação, o que o gráfico "Balance" do MT5 desenha)

Os gráficos ficam em `tg/graficos/cru/` (`ferramentas/scripts/graficos_cru.sh`).

Conferências: o recorte de 2008 na camada 3 reproduz o texto anterior (+4,99%,
6,88%); o recorte cru de 2008 (−4,42%) é igual ao ano de 2008 em `anual_T1.csv`;
o saldo final de cada relatório do MT5 bate com `ret_puro`.

A escolha das configurações continua sendo a da otimização na camada 3 (Sharpe
sobre o excesso da Selic e Calmar), como diz o PROTOCOLO. Só a apresentação mudou.

## outras_acoes.txt (19/10/2026)

Gerado por `ferramentas/scripts/outras_acoes.sh`. Para VALE3, USIM5 e POMO4 (e
PETR4 como conferência), aplica `escolher.sh ... so_compra` à calibração de cada
janela e lê a mesma configuração na grade rodada no período de teste
(`calibracao/<ATIVO>_T<k>.csv`). Camada 1. A PETR4 bate com `tabelas.txt` nos três
períodos. Alimenta a Tabela "Retorno e queda máxima em outras ações" do Cap. III
(conferida célula a célula contra este arquivo). As médias móveis não foram
rodadas nessas ações.

## Sem o intervalo de confiança (21/10/2026)

A pedido do autor, o intervalo de confiança (`Estrategia=2`) saiu do escopo do
TG. `outras_acoes.sh` passou a descartar essas passagens antes da escolha
(`SEM_IC=0` reproduz a versão anterior, guardada em
`outras_acoes_com_ic_2026-10-19.txt`). `analisar_grades.sh` com `SEM_IC=1
CAMADA=puro` gera `analise_grades_cru_sem_ic.txt`; sem `SEM_IC`, a saída continua
idêntica a `analise_grades_cru.txt`. A PETR4 não muda. Detalhes em
`notas/INCERTEZAS.md`, item 71.
