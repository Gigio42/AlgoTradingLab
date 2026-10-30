# Ferramentas: índice

Programas de apoio. Nenhum deles faz parte do robô: servem para importar dados,
rodar as baterias de testes, conferir o código e gerar o material do TG. O uso de
cada script está no comentário do início do arquivo.

Os scripts `.sh` rodam em **bash** (no zsh a separação de palavras não funciona e
os testes rodam com parâmetros errados, sem erro). Os caminhos do MetaTrader
ficam em `scripts/comum.sh`.

## Programas MQL5 (`*.mq5`)

| Arquivo | Para que serve |
|---|---|
| `Import_B3_Custom.mq5` | Importa os CSVs de `dados/series/` como símbolos personalizados (`PETR4_OFICIAL` etc.). |
| `ExportarHistoricoCorretora.mq5` | Exporta o histórico diário da corretora, só para conferir contra a B3. |
| `CompararModelos.mqh` / `.mq5` / `CompararModelosEA.mq5` | Teste pareado entre duas estratégias a partir das curvas diárias. A versão EA roda no testador, sem abrir gráfico. |
| `ReplicaAlmeidaEA.mq5` | Porta do robô do anexo de Almeida (2016), para a segunda réplica. |
| `ValidacaoAlgoLab.mq5` | Recuperação de parâmetros em séries artificiais e o pipeline completo na PETR4. |
| `ValidarGarchT_EA.mq5` | Validação do GARCH com erros t de Student. |
| `ValidarMVArima_EA.mq5`, `VerificarMV_EA.mq5` | Validação do ARIMA por máxima verossimilhança. |
| `MetodosIlustrados.mq5` | Gera os dados dos gráficos que explicam os métodos (`apresentacao/graficos_metodos/`). |
| `HannanRissanenDetalhado.mq5` | Gera os dados do relatório sobre o Hannan-Rissanen (`ia/relatorios/hannan-rissanen/`). |
| `TestesFormulas.mq5` | Testes das funções do robô contra as fórmulas (identidades e simulações), para o relatório `ia/relatorios/testes-do-codigo/`. |

## Scripts (`scripts/`)

**Base, usada pelos outros**

| Script | Para que serve |
|---|---|
| `comum.sh` | Caminhos do MetaTrader e da pasta de trabalho. |
| `rodar.sh` | Um backtest. |
| `otimizar.sh` | Uma otimização (grade). |
| `importar.sh` | Importa séries como símbolos personalizados. |

**Conferência do código**

| Script | Para que serve |
|---|---|
| `regressao_codigo.sh` | Roda 13 casos e compara byte a byte com a execução anterior. Rodar depois de toda mudança que não deveria alterar resultado. |
| `validar.sh` | Roda o `ValidacaoAlgoLab.mq5` e guarda a saída em `dados/verificacao/`. |
| `validar_garch_t.sh`, `validar_mv.sh`, `verificar_mv.sh` | Rodam os validadores das opções experimentais. |
| `medir_d0.sh` | Mede o efeito da correção do d = 0 (05/10/2026). |

**Geração do material do TG**

| Script | Para que serve |
|---|---|
| `codigo_apendice.sh`, `sem_comentarios.sh` | Geram as listagens dos Apêndices A e B a partir do código que roda (chamados pelo `tg/Makefile`). |
| `citacoes_abnt.pl` | Ajusta as citações do `.bbl` para a caixa mista da NBR 6023:2025 (chamado pelo `Makefile` e pelo `.latexmkrc`). |
| `dados_cru.sh` | Gera os dados do Cap. III a partir da refação de 05/10/2026. |
| `graficos_cru.sh` | Compila os gráficos de `tg/graficos/cru/`. |
| `metodos_ilustrados.sh` | Roda o `MetodosIlustrados.mq5` e guarda a saída em `dados/resultados/metodos_ilustrados_2026-10-30/`. |
| `robo_em_acao.sh` | Resume o traço da refação de 05/10/2026 para as figuras 08 a 14 de `apresentacao/graficos_metodos/` (só lê arquivos). |
| `hannan_rissanen.sh` | Roda o `HannanRissanenDetalhado.mq5`, guarda a saída em `dados/resultados/hannan_rissanen_2026-10-30/` e confere os pregões reais contra o traço. |
| `testes_formulas.sh` | Roda o `TestesFormulas.mq5` e guarda a saída em `dados/verificacao/testes_formulas_2026-10-30/`. |

**Experimentos (rodam o testador)**, agrupados pela pasta de `dados/resultados/` onde gravam

| Pasta de resultado | Scripts |
|---|---|
| `refeito_2026-10-05/` (vigente) | `refazer_calibracoes.sh`, `refazer_testes.sh`, `sensibilidade_longos.sh`, `camadas_proventos_b3.sh`, `outras_acoes_mm.sh` |
| `replica_almeida_v2_2026-10-21/` | `series_replica_almeida.sh` (monta as séries), `replica_almeida_v2.sh`, `replica_almeida_v2b.sh`, `replica_almeida_v2c.sh`, `replica_almeida_v2d.sh` |
| `garch_t_2026-10-13/` | `garch_t.sh` |
| `bateria_2026-10-15/` | `bateria_2026_10_15.sh`, `exploratorio_estimacao.sh` |
| `janelas_240_500_2026-10-26/` | `janelas_240_500.sh` |
| `fatores_500_2026-10-27/` | `fatores_500.sh` |
| históricos (rodadas 4 a 6, cenário de Almeida, traço) | `bateria_ativos.sh`, `calib_2014_2016.sh`, `teste_2017_2024.sh`, `periodos_longos.sh`, `cenario_almeida.sh`, `gerar_traco.sh` |

**Análise (só leem os CSVs, não rodam o testador)**

| Script | Para que serve |
|---|---|
| `escolher.sh`, `escolher_rf.sh` | Aplicam o critério de escolha do protocolo a uma calibração. |
| `parear.sh`, `analisar_grades.sh` | Juntam calibração × teste configuração a configuração e analisam a grade. |
| `comparar.sh` | Teste pareado entre curvas (roda o `CompararModelosEA` no testador). |
| `resumo_testes.sh`, `anual.sh`, `recorte_ano.sh` | Uma linha por teste; retorno por ano; retorno e queda dentro de um ano. |
| `protecao.sh`, `seletividade.sh`, `resumo_volatilidade.sh` | Queda máxima, volatilidade e seletividade do GARCH contra a gêmea. |
| `outras_acoes.sh` | Resultado das configurações escolhidas em VALE3, USIM5 e POMO4. |
| `proventos_b3.sh` | Monta a série de proventos da PETR4 a partir da lista oficial da B3. |
| `resumo_garch_t.sh`, `resumo_bateria.sh`, `resumo_exploratorio.sh` | Tabelas dos estudos à parte. |
| `comparar_janelas.sh`, `efeito_janela_garch.sh`, `efeito_fatores.sh`, `estudo_janelas_dados.sh` | Análises dos estudos de 26 e 27/10/2026. |
| `resumo_replica_almeida.sh`, `meses_replica_almeida.sh`, `saldo_mt5.sh` | Leem os relatórios `.htm` do testador (réplicas de Almeida). |
| `traco_resumo.sh` | Resume o traço por barra num intervalo de datas. |
