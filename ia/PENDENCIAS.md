# Pendências

Lista de trabalho do TG, por ordem de prioridade. **Atualizada em 18/10/2026**,
ao fim da sessão que preparou a entrega à orientadora. Detalhes e números de
cada decisão ficam em `ia/INCERTEZAS.md` (o de hoje é o item 64).

## VERSÃO FINAL (25/11/2026)

Pedido do autor: verificar tudo e deixar PDF e Word prontos, com a folha de
aprovação. `make` em `tg/` gera os quatro arquivos: `main.pdf` e `main.docx` (sem
a folha), `main-aprovacao.pdf` e `main-aprovacao.docx` (com ela). Detalhes em
INCERTEZAS item 120.

- **Falta do autor:** preencher à mão os dois avaliadores e a data da defesa
  (decidido deixar em branco), ou preencher em `tg/conteudo/folha-aprovacao.tex`
  e rodar `make`.
- **Fechado em 25/11:** orientadora aceitou "quase experimental"; Almeida e Biometrika
  ficam como estão (decisão do autor). TG pronto para entrega.

## Prazos

| Quando | O quê |
|---|---|
| 19 a 26/10 | **orientadora** envia a nota de orientação (0 a 10, 20% da nota final) e autoriza a entrega. Não há entrega formal do aluno à coordenação nessa data. |
| 09 a 13/11 | entrega à coordenação: monografia em PDF **e em Word**, Termos de Ciência e de Autorização em PDF, apresentação (20 a 30 min) |
| 23 a 27/11 | banca (Workshop de Monografias) |
| até 14/12 | monografia corrigida em PDF e resumo em Word, por e-mail |

Fonte: `dados/fontes/normas-fatec/TG-Cronograma-2o-2026.pdf` (conferido em 18/10).

## FEITO: GARCH 500 e 1000 só com filtro e ajuste, mantendo × encerrando no veto (13–15/11/2026) — estudo, fora do TG

Pedido do autor (13/11): refazer os testes do TG com o GARCH em 500 (ARIMA fixo
em 240), todo robô com filtro e ajuste (`Estrategia=3`), em duas versões
rodadas separadas: **M** mantém a posição no veto, **E** encerra. Relatório
comparando com o TG, com tabela do que a otimização escolheu. Em 15/11: terminar
e fazer o mesmo com 1000. Interrompido em 13/11 a pedido do autor, retomado em
15/11 à 1h50; tudo terminou às 4h24.

- **Relatório:** `ia/relatorios/filtro-ajuste-500-1000/relatorio.pdf` (9 páginas;
  `make dados && make`). Cinco versões lado a lado: TG, 500 M/E, 1000 M/E.
- **Dados:** `dados/resultados/filtro_ajuste_500_2026-11-13/` e
  `dados/resultados/filtro_ajuste_1000_2026-11-15/`. Os números de tudo saem
  em `filtro_ajuste_500_2026-11-13/cru/`.
- **Conferências:** 6 de 6 bateram (`cru/conferencias.txt`).
  - 500 tem 64 otimizações e 1000 tem 52, todas com 52 passagens.
  - A sub-grade sem GARCH é igual nas 4 versões.
  - A PETR4 é igual ao `janelas_garch_2026-11-13/` (32/32).
  - O teste individual é igual à grade (32/32).
  - O ARIMA sem GARCH dá o mesmo resultado nas 4 versões.
  - A escolha do TG, refeita, é igual ao Cap. III (12/12).
- **Resultado:** encerrar no veto protege com as duas janelas; manter falha
  sobretudo em 2013–2016 e 2017–2024.
  - No robô só compra, o veto também bloqueia a saída, e a posição fica
    presa com o tamanho do dia da entrada.
  - Nenhuma versão chega perto do +199,5% do TG em 2017–2024: aquele robô
    era só filtro, e a forma ficou presa aqui.
  - Com 1000 encerrando, o veto chega a 89% dos sinais em 2017–2024, e o
    robô quase não opera.
  - O TG já escolhia encerrar em 7 de 8 robôs da PETR4.
  - Para o texto do TG, nada muda (não foi pedido levar ao `tg/`).
- **Limitação:** com 1000, VALE3, USIM5 e POMO4 ficam sem o par 2004–06 → 2007–11.
  A série começa em 2003, e estender seria dado novo.

## Relatório da janela do GARCH (13/11/2026)

Pedido do autor (discussão da dupla sobre 500 × 240). `ia/relatorios/janela-garch/relatorio.pdf`
(10 páginas): laboratório com séries artificiais, a grade em quatro períodos com janelas 120 a
1000 e a configuração do TG com cada janela. Fora do TG; não há mudança de texto pedida. Resumo
em INCERTEZAS item 104.

## Pedidos da orientadora de 10/11/2026

Conversa colada pelo autor. Entrega até o dia 27 e semana de apresentação "de 7 a 12"
(prorrogada; o mês não foi dito, provavelmente dezembro, não confirmado). Cópia do texto anterior em
`ia/rascunhos/antes_orientadora_2026-11-10/`.

- **Caracterização da pesquisa** (INCERTEZAS item 98): em 10/11 virou só "experimental",
  sem subseções. Em 11/11, a pedido do autor, voltaram 2.1.1 (explicativa) e 2.1.2
  (quase experimental), que o Manual pede (4.1.2.8), e saiu só o que a norma não pede
  (natureza; parte descritiva). Introdução ajustada. O autor mandou mensagem à
  orientadora perguntando se fica explicativa + experimental + análise quantitativa.
  **Falta:** a resposta dela. Se ela preferir "experimental" em vez de "quase
  experimental", trocar o nome na 2.1.2 e na introdução.
- **Duas figuras (12/11/2026): ENTRARAM no TG no mesmo dia (INCERTEZAS item 100).** Propostas em:
  `ia/relatorios/periodos-amostra/` (linha do tempo só com os períodos de teste, para
  a 2.2, antes da Figura 7) e `ia/relatorios/integracao-arima-garch/` (ARIMA e GARCH
  juntos, para a seção de integração do Cap. I; o autor preferiu a linha da B, e a C, recomendada,
  põe o sinal do ARIMA passando pelo filtro). No TG: fig08 (Figura 6) e fig09 (Figura 7,
  mais baixa que a do relatório). Depois de mexer no texto, rodar
  `ferramentas/scripts/checar_ilustracoes.sh`.
- **Teste complementar sem 2017 a 2024** (INCERTEZAS item 99): rodado
  (`dados/resultados/outras_acoes_2017_2024_2026-11-10/`) e acrescentado no 2.5.8 e na
  seção "Outras ações" do Cap. III (a venda a descoberto saiu dela em 12/11). **Falta do autor:** reler a
  tabela e os dois parágrafos depois dela.
- **Séries e amostra (12/11/2026, INCERTEZAS item 101):** critério das outras ações foi,
  enxuto, para a 2.5.8; frase sumida da 2.5.8 corrigida. (As séries e a Selic mudaram de
  novo em 13/11, item 103.)
- **Venda a descoberto separada das outras ações (12 e 13/11/2026, INCERTEZAS itens 102 e
  103):** seção própria no Cap. III (3.11, antes de 3.12 Outras ações, depois dos
  proventos), com a Tabela 15, e subseção própria no Cap. II (2.5.8, antes do teste
  complementar). "Outras ações" ficou só com os robôs que só compram. **Falta do autor:**
  reler as duas.
- **Modelos estatísticos, Figura 6 e Quadros 3 e 4 (13/11/2026, INCERTEZAS item 103):**
  seção nova 1.4 "Modelos estatísticos de séries temporais" (série, retorno, média e
  variância condicional, com Thomaz, 2019), ARIMA e GARCH como 1.4.1 e 1.4.2, Selic de
  volta à 1.1; Figura 6 refeita como o ciclo de um pregão; Quadro 3 em duas partes;
  Quadro 4 completo. Versões de slide em `ia/relatorios/quadros-slides/` (PNG para o
  PowerPoint). **Falta do autor:** ler a 1.4 (texto novo, regra 3) e as páginas de Thomaz
  citadas (16, 24 e 29-30).
- **Série de preços de exemplo (13/11/2026): só proposta, fora do TG.** Relatório em
  `ia/relatorios/serie-precos/relatorio.pdf`: A, os últimos 20 pregões da PETR4
  (fechamento em pontos e retorno em barras, recomendada), e B, o fechamento de 2019 a
  2021 (mesmo período do Gráfico 1). Dados em `dados/resultados/serie_exemplo_2026-11-13/`
  (`ferramentas/scripts/serie_exemplo.sh`). **Falta do autor:** escolher se entra, e qual.
- **Auditoria completa do TG (13/11/2026): só relatório, texto NÃO alterado.**
  `ia/relatorios/auditoria-2026-11-13.md`: 5 problemas de prioridade alta (resultado
  novo nas Considerações, "mercado estável" no resumo, venda a descoberto sem fechamento,
  "teste principal" com dois sentidos, Figura 6 e o veto que encerra a posição), coerência,
  normas e aparência. **Falta do autor:** decidir quais itens aplicar.
- **Slides:** com o Bruno.

## O modelo inteiro e o GARCH funcionando (06/11/2026)

**Só proposta, fora do TG.** Dois relatórios novos:
`ia/relatorios/modelo-completo/relatorio.pdf` (um pregão do começo ao fim, 22/02/2021,
com as séries reais em cada passo, e o caminho dos 496 pregões de 2019-2021 pelo
ARIMA e pelo GARCH) e `ia/relatorios/garch-funcionando/relatorio.pdf` (a σ da janela,
a variância montada em ω + memória + choque, e a sexta × a segunda). Dados de
`ferramentas/ModeloCompleto.mq5`, conferidos contra o traço
(`dados/resultados/modelo_completo_2026-11-06/`). **Falta do autor:** ler e decidir se
algo entra no TG ou nos slides. Observação nova: de 19 para 22/02/2021 o α do GARCH
caiu de 0,215 para 0,064 com a janela andando um pregão (não investigado).

## Figuras dos períodos, da janela e da escolha (05/11/2026)

INCERTEZAS item 92. **Só proposta, fora do TG** (o autor mandou desfazer a
inserção direta). Relatório em `ia/relatorios/figuras-cap2/relatorio.pdf`: o
Quadro 4 como linha do tempo, a janela deslizante e os passos da escolha.
**Linha do tempo aplicada no TG em 05/11 (item 94)**: substituiu o Quadro 4, e as listas
viraram a "LISTA DE ILUSTRAÇÕES" única. Janela e escolha continuam só no relatório;
**falta do autor** decidir se entram.

## Alternativas ao Quadro 3 (05/11/2026)

INCERTEZAS item 95. Relatório em `ia/relatorios/quadro3-grade/relatorio.pdf`, duas propostas
(grade desenhada ou barras). **Falta do autor:** escolher se alguma entra no TG.

## Apêndice C enxugado (06/11/2026)

INCERTEZAS item 97. As explicações saíram do apêndice e foram para o Cap. II
(Implementação dos modelos, dois parágrafos sobre o robô de médias móveis).
**Falta do autor:** reler esses dois parágrafos.

## Validação dos estimadores de volta ao TG (06/11/2026)

INCERTEZAS item 96. Só a recuperação de parâmetros em séries artificiais: subseção
2.5.4 no Cap. II e seção 3.2 (Tabela 2) no Cap. III. **Falta do autor:** reler os dois
trechos e ter na ponta da língua por que três casos (AR(2) = uma regressão,
ARMA(1,1) = as duas do Hannan-Rissanen, GARCH = otimizador).

## Configurações fixas como testes adicionais (05/11/2026)

INCERTEZAS item 93. Saíram do Cap. II e ficaram numa tabela própria no Cap. III.
O retorno do GARCH × mesma configuração sem ele passou de 7 em 11 para 3 em 7, e
resumo, abstract e Considerações foram ajustados. **Falta do autor:** reler esses
trechos e preparar a resposta para "por que o robô é reescolhido a cada período e
as médias de Almeida não?" (antes respondida pelo teste fixo).

## Apêndice C, robô de médias móveis (02/11/2026)

INCERTEZAS item 90. **Falta do autor:** reler o texto do apêndice e a frase
nova do Cap. II sobre a segunda forma da reprodução (regra de entrada do anexo).

## Heterocedasticidade no começo da Seção 1.6 GARCH (02/11/2026)

Pedido do autor. Texto novo no Cap. I, dentro da Seção 1.6 (sem subseção), com o Gráfico 1 (série simulada com
variância constante × retorno da PETR4 de 2019 a 2021), INCERTEZAS item 89.
**Falta do autor:** reler e reescrever com as próprias palavras (regra nº 3);
os gráficos do Cap. III passaram a ser numerados a partir do 2.

## Auditoria do texto de 02/11/2026

Relatório em `ia/relatorios/auditoria-texto-2026-11-02.md`. **Aplicada no mesmo
dia** (INCERTEZAS item 86), 82 páginas. Falta do autor: trocar a Figura 1 por uma
captura própria do MT5 em português com a PETR4; reler o 3.3, o 3.8, o 3.10 e as
limitações das Considerações, que mudaram; abrir o `.docx` no Word.

## Crédito do código e trabalhos relacionados do MQL5 (02/11/2026) — APLICADO NO CAP. II

Tudo em `ia/bibliografia/creditos-codigo-2026-11-02.md` (links, autores e datas conferidos).
**Aplicado em 02/11/2026, a pedido do autor (INCERTEZAS item 91):** a seção "Implementação
dos modelos" do Cap. II cita um artigo por conceito, na versão em português: Dube (2023,
ARIMA), Dube (2024, ADF) e Chernish (2024, GARCH). As perguntas abertas abaixo foram
respondidas. Falta só a explicação, que o autor vai escrever. Os demais artigos NÃO entram.
Resumo:
- **Nenhum trecho dos apêndices é cópia** de fórum, Code Base ou artigo; o crédito é ao
  método (Hannan e Rissanen, Gómez e Maravall, Bollerslev, Akaike, Dickey e Fuller,
  MacKinnon) e à ALGLIB. Faltam no `.bib`: Akaike (1974), Dickey e Fuller (1979) ou Said e
  Dickey (1984), MacKinnon (2010) e a ALGLIB como software. Schwert (1989) não confirmado.
- **Trabalhos relacionados na comunidade MQL5**: sugestão de 4 a 6 para o Cap. I, depois de
  Almeida: Dube (2023, ARIMA), Chernish (2025, GARCH com MinBLEIC), Dube (2024, ADF),
  Sandoval Espinosa (2026, AutoARIMA), Kirichenko (2011). Não há Hannan-Rissanen em MQL5
  nem ARIMA+GARCH num EA.
- **Perguntas abertas ao autor:** (1) leu Chernish (2025) ou Dube (2024)? Se sim, eles são o
  "conteúdo da comunidade" que o Cap. II (l. 189–191) cita sem nomear; se nada específico
  foi consultado, a frase deve sair. (2) Quais obras entram e onde (regra nº 3: ele lê antes).

## Relatório do Hannan-Rissanen, versão 2 (02/11/2026)

`ia/relatorios/hannan-rissanen/relatorio.pdf` reescrito a pedido do autor: Parte I só o conceito,
Parte II o caminho do dado no código (trechos lidos de `tg/codigo/`, mesma numeração dos Apêndices
A e B; o `Makefile` para se um trecho sair do lugar), Parte III simulações e literatura. Versão 1
em `ia/rascunhos/hannan_rissanen_v1_2026-10-30/`. **Falta o autor ler.**

## Relatório da otimização (02/11/2026)

`ia/relatorios/otimizacao/relatorio.pdf`, separado do TG, pedido do autor. **Parte 1 de 3
feita** (otimização × teste, 312 configurações da PETR4, dados em
`dados/resultados/otimizacao_teste_2026-11-02/`). Partes 2 (mapa de calor percentil ×
alvo) e 3 (queda máxima por forma de uso) só depois de o autor ler a 1.

## 0a. Sessão de 19/10/2026 (ler antes da seção 0)

**Feito no texto (ainda sem commit; cópia anterior em
`ia/rascunhos/antes_correcoes_coerencia_2026-10-19/`).** Revisão de coerência
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
`ia/rascunhos/antes_cap3_cru_2026-10-19/`. **O autor precisa ler o Cap. III novo.**
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
  "Arquitetura". Log e traço em `robos/ARIMA-GARCH/Diagnostico.mqh`, avaliação no
  testador em `robos/ARIMA-GARCH/Avaliacao.mqh`, opções experimentais em
  `robos/Include/ArimaVerossimilhanca.mqh` e `robos/Include/GarchDistribuicao.mqh`,
  negociação em `robos/Include/Negociacao.mqh` (usada pelos dois EAs). 4.849 linhas
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
- **Texto** (pedidos do autor, backups em `ia/rascunhos/antes_*_2026-10-18/`):
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
      próprio (ex.: `robos/Include/ArimaGradiente.mqh`), fiel ao `robos/legado/ARIMA_EA.mq5`
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

Pedido do autor. Cópia anterior em `ia/rascunhos/antes_remover_estatistica_2026-10-21/`.
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
- [ ] Versão em Word (depois que o texto fechar). **Conversor pronto desde
      02/11/2026**: `make docx` em `tg/` gera `tg/main.docx` do LaTeX
      (`ferramentas/scripts/docx/`, pandoc 3.13 em `~/.local/opt/`). Conferido
      contra o PDF no LibreOffice (títulos, legendas, equações e citações iguais);
      **ainda não aberto no Microsoft Word**. Ao abrir, aceitar a atualização dos
      campos (sumário e listas). Corrigir texto sempre no `.tex` e gerar de novo.
- [ ] Corrigir a ordem no `.gitignore` (`!dados/resultados/**/execucao.log` vem
      antes de `*.log` e é anulado).
- Aviso de identificadores repetidos do LaTeX: inofensivo (INCERTEZAS item 76).

## 8. Intervalo de confiança: removido do código em 21/10/2026

INCERTEZAS item 75. Regressão em `/tmp/algolab-trabalho/regressao_*_ic`.

## 9. Seção de camadas do Cap. III: removida em 21/10/2026

Pedido do autor. O Cap. III fica só com o resultado bruto. O Cap. II (medição
dos resultados) diz que custo de 0,03% e Selic entraram apenas na escolha das
configurações. INCERTEZAS item 75. Cópia anterior em
`ia/rascunhos/antes_auditoria_2026-10-21/`.

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
  a pasta `robos/` inteira para lá e recompilar (desde 30/10/2026; antes eram
  `Include/`, `ARIMA-GARCH/` e `MediasMoveis2/` soltas na raiz). As
  ferramentas em EA ficam em `MQL5/Experts/` desse prefixo.
- O terminal precisa estar autenticado na conta demo da Clear (última
  autenticação vista: 15/10).
- Otimização refeita com os mesmos parâmetros vem do cache: apagar
  `Tester/cache/` antes.
- Laços de teste sempre dentro de `bash`, nunca direto no zsh.

## Estudo do GARCH com 1000 resíduos (02/11/2026)

Feito e documentado (`dados/resultados/janela_garch_1000_2026-11-02/LEIAME.md`,
INCERTEZAS item 87). Não entra no TG por decisão do autor (janela do GARCH só
como limitação). Pendente só se o autor pedir: levar algo ao texto ou à defesa.
