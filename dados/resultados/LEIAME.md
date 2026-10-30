# Resultados dos experimentos: índice

Cada pasta tem o seu `LEIAME.md` (ou `RELATORIO.md`) e, quando houve, o
`PROTOCOLO.md` escrito antes de rodar. Esta página só diz o que é cada uma e se
ainda vale.

**Os números do TG vêm de `refeito_2026-10-05/` e das duas réplicas de Almeida.**
O resto é histórico (feito com o EA antes das correções de 05/10/2026, ou com
dados do Yahoo) ou é estudo à parte que não entrou no texto.

## O que o TG usa

| Pasta | O que é |
|---|---|
| [`refeito_2026-10-05/`](refeito_2026-10-05/LEIAME.md) | **Resultado vigente.** Todas as calibrações e testes refeitos com o EA corrigido. Fonte do Cap. III e dos gráficos de `tg/graficos/`. |
| [`replica_almeida_2026-09-28/`](replica_almeida_2026-09-28/LEIAME.md) | Réplica das médias móveis de Almeida (2016) com as datas e parâmetros dele. Só usa médias móveis, então a correção do EA não a afeta. |
| [`replica_almeida_v2_2026-10-21/`](replica_almeida_v2_2026-10-21/LEIAME.md) | Segunda réplica: séries, lógicas de entrada e modelos de tick alternativos. Origem da coluna "condições prováveis" da Tabela 1. |

## Estudos à parte (não estão no TG)

| Pasta | O que é |
|---|---|
| [`garch_t_2026-10-13/`](garch_t_2026-10-13/LEIAME.md) | GARCH com erros t de Student no lugar da normal, nas mesmas configurações. |
| [`bateria_2026-10-15/`](bateria_2026-10-15/LEIAME.md) | Critério único pelo fator de recuperação, e ARIMA por máxima verossimilhança (rejeitado na validação). |
| [`janelas_240_500_2026-10-26/`](janelas_240_500_2026-10-26/LEIAME.md) | ARIMA com janela de 240 e GARCH com 500 resíduos, em PDF separado (`documento/`). Pedido depois da crítica da orientadora. |
| [`fatores_500_2026-10-27/`](fatores_500_2026-10-27/LEIAME.md) | Grade maior sobre o estudo anterior: distribuição do GARCH, BIC e intervalo de reseleção. |
| [`metodos_ilustrados_2026-10-30/`](metodos_ilustrados_2026-10-30/LEIAME.md) | Dados dos gráficos que explicam os métodos (`apresentacao/graficos_metodos/`), na janela da validação numérica. |
| [`robo_em_acao_2026-10-30/`](robo_em_acao_2026-10-30/LEIAME.md) | Dados dos gráficos do robô funcionando (`apresentacao/graficos_metodos/`, figuras 08 a 14), lidos do traço da refação de 05/10/2026. |
| [`hannan_rissanen_2026-10-30/`](hannan_rissanen_2026-10-30/LEIAME.md) | Dados do relatório de estudo sobre o Hannan-Rissanen (`ia/relatorios/hannan-rissanen/`): séries simuladas, mil simulações e dois pregões reais refeitos e conferidos contra o traço. |

## Histórico (superado, não usar no texto)

| Pasta | O que é | Por que saiu |
|---|---|---|
| `rodada1_yahoo_2026-09-21/` | Primeira grade otimizada (calibração 2022–24, validação 2025–26). | Dados do Yahoo, com lacunas. |
| `rodada2_yahoo_2026-09-21/` | Comparação com Almeida e entre modelos. | Dados do Yahoo. |
| [`rodada3_b3_oficial/`](rodada3_b3_oficial/RELATORIO.md) | Primeira rodada com dados da B3, três períodos. **Não mover nem apagar:** as sub-grades em `grades/` continuam sendo a definição da grade do Cap. II, e `testes/in_r3_base.txt` e `testes/in_mm.txt` são os inputs base dos scripts atuais. | Resultados do EA antigo. |
| [`rodada4_multiativos/`](rodada4_multiativos/LEIAME.md) | Quatro ativos (PETR4, VALE3, USIM5, POMO4), com e sem venda a descoberto. | EA antigo. |
| [`rodada5_periodos_longos/`](rodada5_periodos_longos/LEIAME.md) | 2005–2026 e 2017–2024 com configuração fixa. | EA antigo. |
| [`rodada6_fora_amostra_2017_2024/`](rodada6_fora_amostra_2017_2024/LEIAME.md) | Teste fora da amostra em 2017–2024. | EA antigo. |
| [`cenario_almeida_2026-09-30/`](cenario_almeida_2026-09-30/LEIAME.md) | Os modelos nas condições de Almeida (R$ 50 mil, volume fixo, sem custo). | EA antigo. |
| [`traco_demo_2019_2021/`](traco_demo_2019_2021/LEIAME.md) | Traço por barra de jul/2019 a jun/2021, para o painel de demonstração. | EA antigo. |
