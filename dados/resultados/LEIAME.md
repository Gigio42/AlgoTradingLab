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
| [`janela_garch_1000_2026-11-02/`](janela_garch_1000_2026-11-02/LEIAME.md) | A parte principal do Cap. III (PETR4) com o GARCH sobre 1000 resíduos, comparada com o TG e com o estudo de 500. 2004–2006 e 2007–2011 na série oficial estendida a 1999. |
| [`janelas_garch_2026-11-13/`](janelas_garch_2026-11-13/LEIAME.md) | A janela do GARCH (120, 240, 500, 1000) com ARIMA 240: grade de 156 configurações em quatro pares otimização→teste, traço da configuração do TG e laboratório com séries artificiais. Dados do relatório `ia/relatorios/janela-garch/`. **Parte no TG desde 15/11/2026**: medianas de 2013-2016, 2017-2024 e 2025-2026 (240, 500, 1000) e o traço da configuração do TG, no Cap. III, 3.11.1, Tabela 15 (INCERTEZAS 108). |
| [`assimetricos_2026-11-18/`](assimetricos_2026-11-18/LEIAME.md) | GARCH 500 com GJR, EGARCH, t de Student, janela expansiva do ARIMA e BIC, um por vez e juntos, nos testes do TG e em 2005–2010, com as etapas de custos, proventos e Selic. Validação teórica em `validacao/`. Relatório `ia/relatorios/assimetricos/`. **Fora do TG.** |
| [`filtro_ajuste_500_2026-11-13/`](filtro_ajuste_500_2026-11-13/LEIAME.md) | GARCH 500 (ARIMA 240) com todo robô em filtro e ajuste, em duas versões: mantém (M) e encerra (E) no veto; 4 ações, os períodos do TG. Completo em 15/11; números (das duas janelas) em `cru/`, relatório em `ia/relatorios/filtro-ajuste-500-1000/`. **Estudo, fora do TG.** |
| [`filtro_ajuste_1000_2026-11-15/`](filtro_ajuste_1000_2026-11-15/LEIAME.md) | O mesmo estudo com o GARCH em 1000 (outras ações sem o par 2004–06 → 2007–11). Números no `cru/` da pasta de 500. **Estudo, fora do TG.** |
| [`heterocedasticidade_2026-11-02/`](heterocedasticidade_2026-11-02/LEIAME.md) | Dados do Gráfico 1 do Cap. I (Seção 1.6, GARCH): retorno diário da PETR4 de 2019 a 2021 e uma série simulada com variância constante. **Está no TG.** |
| [`serie_exemplo_2026-11-13/`](serie_exemplo_2026-11-13/LEIAME.md) | Série de preços de exemplo para a Seção 1.4: os últimos 20 pregões da PETR4 (fechamento e retorno) e o fechamento de 2019 a 2021. **Proposta, fora do TG** (`ia/relatorios/serie-precos/`). |
| [`metodos_ilustrados_2026-10-30/`](metodos_ilustrados_2026-10-30/LEIAME.md) | Dados dos gráficos que explicam os métodos (`apresentacao/graficos_metodos/`), na janela da validação numérica. |
| [`robo_em_acao_2026-10-30/`](robo_em_acao_2026-10-30/LEIAME.md) | Dados dos gráficos do robô funcionando (`apresentacao/graficos_metodos/`, figuras 08 a 14), lidos do traço da refação de 05/10/2026. |
| [`modelo_completo_2026-11-06/`](modelo_completo_2026-11-06/LEIAME.md) | Dois pregões (19 e 22/02/2021) refeitos com as funções do robô e conferidos contra o traço: dados dos relatórios `ia/relatorios/modelo-completo/` e `garch-funcionando/`. |
| [`outras_acoes_2017_2024_2026-11-10/`](outras_acoes_2017_2024_2026-11-10/LEIAME.md) | **Vigente (Cap. II 2.5.8 e Cap. III "Outras ações")**: o teste complementar nas quatro ações em 2017–2024 (calibração 2014–2016), que faltava na refação de 05/10. Pergunta da orientadora. |
| [`hannan_rissanen_2026-10-30/`](hannan_rissanen_2026-10-30/LEIAME.md) | Dados do relatório de estudo sobre o Hannan-Rissanen (`ia/relatorios/hannan-rissanen/`): séries simuladas, mil simulações e dois pregões reais refeitos e conferidos contra o traço. |
| [`otimizacao_teste_2026-11-02/`](otimizacao_teste_2026-11-02/LEIAME.md) | Dados do relatório de estudo sobre a otimização (`ia/relatorios/otimizacao/`): as 312 configurações da PETR4 na otimização e no teste, lidas dos pareados da refação de 05/10/2026. Nada foi rodado de novo. |

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
