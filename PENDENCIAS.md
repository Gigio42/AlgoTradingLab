# Pendências

Lista de trabalho do TG, por ordem de prioridade. **Atualizada em 18/10/2026**,
ao fim da sessão que preparou a entrega à orientadora. Detalhes e números de
cada decisão ficam em `notas/INCERTEZAS.md` (o de hoje é o item 64).

## Prazos

| Quando | O quê |
|---|---|
| 19 a 26/10 | **orientadora** envia a nota de orientação (0 a 10, 20% da nota final) e autoriza a entrega. Não há entrega formal do aluno à coordenação nessa data. |
| 09 a 13/11 | entrega à coordenação: monografia em PDF **e em Word**, Termos de Ciência e de Autorização em PDF, apresentação (20 a 30 min) |
| 23 a 27/11 | banca (Workshop de Monografias) |
| até 14/12 | monografia corrigida em PDF e resumo em Word, por e-mail |

Fonte: `dados/fontes/normas-fatec/TG-Cronograma-2o-2026.pdf` (conferido em 18/10).

## 0a. Sessão de 19/10/2026 (ler antes da seção 0)

**Feito no texto (ainda sem commit; cópia anterior em
`notas/rascunhos/antes_correcoes_coerencia_2026-10-19/`).** Revisão de coerência
pedida pelo autor, depois de o Bruno notar a tensão entre a hipótese 1 e o Cap. III:
- hipótese 1 × "o GARCH foi incluído para controlar o risco": 2.3.2, 3.7 e
  considerações reescritos como "esperava-se melhora indireta no acerto, não
  ocorreu" (a hipótese do PTG não foi mexida); "nem piorou" (diferença máxima de
  3,8 pontos, `metricas_*`, coluna `taxa_acerto`);
- a linha "ARIMA" das tabelas explicada no 3.2 (melhor robô sem GARCH, não a
  versão A desligada; aponta para a 3.6, que ganhou `\label{sec:efeito-garch}`);
- configurações fixas: 2005-2026 inclui a escolha (2010-2012), dito no 2.5;
- "a proteção depende de reduzir a posição" virou "é mais consistente"; as que só
  impedem entradas reduziram a queda em 23% a 67% dos pares
  (`refeito_2026-10-05/analise_grades.txt`, bloco 2, `reduz=nao`);
- 16.512 simulações = 688 configurações (com venda a descoberto), dito no 2.5;
- resumo e abstract: "especialmente útil em quedas prolongadas como a crise de 2008";
- d = 0 explicado no 2.4; "exigida pelas partes AR e MA"; "calibração" →
  "otimização"; "concluída e validada" → "concluída"; nota nos Gráficos 1 e 2
  (versões A e B coincidem em 2007-2011); parágrafo da estatística t do Sharpe
  oculto (`OCULTO-19/10`, volta com a seção estatística);
- referência ao caderno de delineamentos da FATEC retirada (pedido do autor).
TG com 47 páginas, sem referência indefinida.

**RESOLVIDO em 19/10 (INCERTEZAS item 68):** o autor escolheu a camada crua. Cap. III
reorganizado (um período por seção, custos/Selic/proventos no fim, gráficos do MT5),
Elder retirado, "natureza" corrigida (Wazlawick 3. ed.), `.bib` corrigido (Araya,
Fernandes, Wazlawick). TG com 59 páginas. Backup em
`notas/rascunhos/antes_cap3_cru_2026-10-19/`. **O autor precisa ler o Cap. III novo.**
O texto abaixo é o registro da decisão:

~~DECISÃO PENDENTE, a mais importante: camada das tabelas~~ (INCERTEZAS item 66).
As Tabelas 3 a 6, os Gráficos 1 a 3 e as frases que os resumem usam a camada 3
(custos + caixa parado rendendo Selic). Isso favorece o ARIMA-GARCH, que fica de
9% a 28% aplicado (MM e ARIMA, 43% a 62%). Recomendação dada ao autor: retorno
puro nas tabelas e Selic só como referência. Frases que dependem da camada 3:
"único robô com retorno positivo" (2007-2011; puro −8,4%), "ganho de 5,0% em
2008" (puro −4,4%), "nove de onze com retorno maior" (puro: sete de onze). O
risco (queda e volatilidade, 11 de 11) vale nas duas camadas. Próximo passo
combinado: listar ao autor o que muda antes de aplicar.

## 0. Estado em 18/10/2026

**Commits.** O último é `a3b21b9` (estado antes da limpeza do código). **Tudo o
que está abaixo, em "Feito em 18/10", ainda NÃO foi commitado**: limpeza do
código, módulos novos, script de regressão, mudanças no texto e nos scripts do
TG. Fazer o commit quando o autor pedir.

**O TG** compila com 47 páginas, sem referência quebrada, citações em caixa
mista. Título novo: "Desenvolvimento e comparação de modelos de negociação
algorítmica: ARIMA-GARCH e médias móveis".

### Feito em 18/10

- **Código limpo e reorganizado** (pedido do autor: sem código-documentação,
  nomes por extenso, log fora do EA). Estrutura nova no `CLAUDE.md`, seção
  "Arquitetura". Log e traço em `ARIMA-GARCH/Diagnostico.mqh`, avaliação no
  testador em `ARIMA-GARCH/Avaliacao.mqh`, opções experimentais em
  `Include/ArimaVerossimilhanca.mqh` e `Include/GarchDistribuicao.mqh`,
  negociação em `Include/Negociacao.mqh` (usada pelos dois EAs). 4.849 linhas
  (1.148 de comentário) viraram 3.710 (206). Inputs e colunas dos CSVs com os
  mesmos nomes.
- **Regressão byte a byte passou**: `ferramentas/scripts/regressao_codigo.sh`, 13
  casos que cobrem todos os caminhos dos dois EAs; 29 arquivos (métricas, curvas,
  traços) idênticos antes e depois. Os três validadores em EA
  (`validar_mv.sh`, `verificar_mv.sh`, `validar_garch_t.sh`) repetiram os
  arquivos guardados em `dados/verificacao/`. Tudo compila com 0 erros e 0
  avisos (EA, MM, ferramentas, listagem do apêndice com 295 linhas).
  **Não rerodado:** `ValidacaoAlgoLab.mq5` (é script; scripts não abrem com o
  perfil de 100 gráficos, INCERTEZAS 54). Compila.
- **Defeitos corrigidos de passagem:** `validar_garch_t.sh` não apagava o
  relatório antigo e encerrava o teste antes de rodar; `citacoes_abnt.pl` lia o
  `.bbl` linha a linha e deixava em caixa alta citação de nome longo (agora lê o
  arquivo inteiro); `codigo_apendice.sh`/`sem_comentarios.sh` tiram linha que só
  tinha comentário e as chaves de um `if` que ficou com uma instrução.
- **Texto** (pedidos do autor, backups em `notas/rascunhos/antes_*_2026-10-18/`):
  - saiu a validação do código (seção do Cap. II, seção e Tabela do Cap. III,
    menções na introdução, nas considerações e no resumo/abstract). O parágrafo
    "o d variou" (83,1%) ficou, movido para "Como o GARCH protege";
  - **objetivo específico mudado**: "implementar e validar os modelos" virou
    "implementar os modelos" (o autor disse que o foco é comparar);
  - seção "Verificação estatística e testes complementares" **oculta** (ver
    item 5);
  - considerações, resumo e abstract reescritos sem estatística (11 de 11 em
    risco, 9 de 11 em retorno, sem vantagem consistente contra as médias);
  - *volatility targeting* explicado no Cap. II (volatilidade-alvo, tamanho da
    posição × alvo/volatilidade prevista, com limites);
  - caderno de delineamentos da FATEC-ID citado no Cap. II e RETIRADO em 19/10
    (pedido do autor: nenhuma referência da própria faculdade; a frase dos
    "casos típicos" e o "etapas previstas" saíram junto, o Wazlawick ficou);
  - quatro "microdetalhes" do Cap. II retirados (amostra comum do AIC,
    restrições no otimizador, veto maior que o percentil, conferência das barras);
  - o autor tirou do apêndice a frase sobre o que foi omitido da listagem.

## 1. Comparação dos três métodos de estimação do ARIMA (próximo teste)

Pedido do autor em 18/10. **Ainda não implementado.**

- [ ] Implementar o **gradiente descendente** como terceira opção, num módulo
      próprio (ex.: `Include/ArimaGradiente.mqh`), fiel ao `legado/ARIMA_EA.mq5`
      (taxa 0,001, 300 iterações, linhas 60, 90–91 e 414–420 do legado), sem
      entrar no Apêndice A.
- [ ] Rodar o mesmo validador nos três (HR, MV, GD): precisão, tempo, acerto de
      ordem, PETR4, e um **teste de escala** (mesma série com o preço × 10) que
      só o gradiente precisa. Hoje "a taxa que converge em R$ 36 diverge em
      R$ 5" é **estimativa**: não há medida.
- [ ] Texto, se o autor quiser: "foram considerados três métodos" na ordem
      lógica (gradiente, máxima verossimilhança, Hannan-Rissanen), **sem
      cronologia** (a real foi GD → HR → MV, e o git mostra). Cuidados: o
      gradiente é conhecido em aprendizado de máquina, não é o padrão para ARIMA;
      a nossa MV é a **condicional** (Thomaz, p. 42–43, descreve a exata).
      Atenção: o autor tirou os testes do código do texto em 18/10; decidir onde
      essa comparação entra antes de escrever.
- Já existe (HR × MV): `dados/verificacao/validacao_mv_arima_2026-10-15.txt` e
  `verificacao_mv_arima_2026-10-15.txt`, mais o exploratório de mercado
  (`bateria_2026-10-15/exploratorio_estimacao/`).

## 2. Bateria de 15/10: levar ao texto (decisão do autor)

`dados/resultados/bateria_2026-10-15/` (LEIAME, PROTOCOLO, resumo). Critério único
= fator de recuperação; resultado principal cru; pandemia 2017–2019 → 2020–2021.
O texto atual ainda usa a refação de 05/10. Falta:

- [ ] Decidir se o resultado principal passa a ser o cru (camada 1). No cru o
      retorno do GARCH fica bem pior que o das médias móveis (LEIAME, seção 4).
- [ ] Seção "Do resultado bruto ao estimado" no fim do Cap. III (e slide):
      teste de 2017–2024 em quatro camadas (`ret_puro`, `ret_custos`,
      `ret_selic`, `ret_completo`). Frase obrigatória: mesmo a camada 4 é
      estimativa (fora slippage, liquidez e imposto).
- [ ] Gerar relatório e gráficos do MT5 de cada teste final (como Almeida).
- [ ] "Zerar no veto" como achado posterior; frase de robustez do exploratório
      (proteção em 20 de 20 combinações de estimação e critério).

## 3. Reprodução de Almeida (2016): feita em 21/10/2026

Tudo o que dava para tentar foi feito (`dados/resultados/replica_almeida_v2_2026-10-21/LEIAME.md`,
INCERTEZAS item 74): anexo comparado com o código do livro de Young (2013),
gestão de dinheiro conferida, série com proventos da B3, histórico desde 2008
(adiamento do testador). O parágrafo do 3.1 foi atualizado. Contato com Almeida
não é possível (autor, 21/10).

## 4. Pequenas camadas no texto

- [ ] Apêndice A: a frase "rotinas ... em arquivos de inclusão próprios" não cita
      a negociação (`Negociacao.mqh`), que agora também está fora do EA.
- Os opcionais (por que MQL5, literatura no Cap. III, Thomaz no Quadro 1, GARCH t
  nos trabalhos futuros) **não serão feitos** (autor, 21/10).

## 5. Seção estatística: removida em 21/10/2026

Pedido do autor. Cópia anterior em `notas/rascunhos/antes_remover_estatistica_2026-10-21/`.
Pitman, Morgan, Lo, Jobson e Korkie e Memmel deixaram de ser pendência.

## 6. Leituras e citações (nenhuma citação entra antes da leitura)

- [ ] **Tarifas da B3** (`b3Tarifas`, Cap. II): já citada a pedido do autor;
      ele precisa abrir a página e conferir os quatro números (0,00500% +
      0,02240% + 0,0026% = 0,0300%).
- [ ] **Comunicado da Petrobras de 2005** (`petrobras2005`, Cap. II): salvar a
      página da SEC pelo navegador em `dados/fontes/petrobras/` (o download
      automático foi bloqueado).
- Hwang e Valls Pereira (janela curta do GARCH), Glosten/Nelson (GARCH
  assimétrico nos trabalhos futuros), Pardo e a ajuda do testador (teste
  *forward*) e Dickey-Fuller/Akaike: **as frases que pediam essas obras saíram**
  (21/10, pedido do autor: só referência que tapa um "de onde veio isso?").
  Deixaram de ser pendência.
- 252 dias úteis: o autor decidiu não acrescentar referência (21/10).

## 7. Entrega e organização

- [ ] Mandar o PDF à orientadora com um parágrafo do que mudou: Yahoo fora,
      seção estatística e de camadas fora, reprodução de Almeida refeita,
      objetivo específico mudado, Word para novembro.
- [ ] Confirmar com a orientadora: o título novo e o objetivo específico sem
      "validar" (o PTG pode ter "validar").
- [ ] Commit de tudo o que foi feito em 18/10.
- [ ] Termos de Ciência e de Autorização (modelo em `dados/fontes/normas-fatec/`).
- [ ] Apresentação de 20 a 30 min (modelo da FATEC em `dados/fontes/normas-fatec/`).
- [ ] Versão em Word (depois que o texto fechar).
- [ ] Corrigir a ordem no `.gitignore` (`!dados/resultados/**/execucao.log` vem
      antes de `*.log` e é anulado).
- Aviso de identificadores repetidos do LaTeX: inofensivo (INCERTEZAS item 76).

## 8. Intervalo de confiança: removido do código em 21/10/2026

INCERTEZAS item 75. Regressão em `/tmp/algolab-trabalho/regressao_*_ic`.

## 9. Seção de camadas do Cap. III: removida em 21/10/2026

Pedido do autor. O Cap. III fica só com o resultado bruto. O Cap. II (medição
dos resultados) diz que custo de 0,03% e Selic entraram apenas na escolha das
configurações. INCERTEZAS item 75. Cópia anterior em
`notas/rascunhos/antes_auditoria_2026-10-21/`.

## 10. Auditoria de 21/10/2026: aplicada em 22/10/2026

Todos os achados aplicados a pedido do autor, junto com objetivos específicos e
justificativa novos (INCERTEZAS item 76). As hipóteses chegaram a ser trocadas e
voltaram às do PTG no mesmo dia. **Falta**: o autor reler a introdução e as
considerações.

## Lembretes técnicos

- **PDF final:** `make` dentro de `tg/`. O VS Code recompila sozinho (inclusive
  quando o `make` grava arquivos) e, rodando junto, os dois corrompem o
  `main.aux` e o `make` falha. Fechar o PDF no VS Code ou desligar a compilação
  automática antes. A compilação do VS Code usa o `.latexmkrc`, que aplica o
  mesmo `citacoes_abnt.pl`.
- **Mudou código que não deveria mudar resultado?** Rodar
  `bash ferramentas/scripts/regressao_codigo.sh <pasta>` antes e depois e
  `--comparar` (uns 5 min cada; referência de 18/10 em
  `/tmp/algolab-trabalho/regressao_antes`, que some no reboot: rodar de novo a
  partir do commit, se preciso).
- Testes rodam no prefixo `~/.wine-mt5-novo`, que tem um clone próprio: copiar
  `Include/`, `ARIMA-GARCH/` e `MediasMoveis2/` para lá e recompilar. As
  ferramentas em EA ficam em `MQL5/Experts/` desse prefixo.
- O terminal precisa estar autenticado na conta demo da Clear (última
  autenticação vista: 15/10).
- Otimização refeita com os mesmos parâmetros vem do cache: apagar
  `Tester/cache/` antes.
- Laços de teste sempre dentro de `bash`, nunca direto no zsh.
