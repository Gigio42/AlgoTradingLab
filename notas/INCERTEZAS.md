# Incertezas e limitações conhecidas

O que **não** está confirmado, o que é aproximação e o que pode mudar um
resultado. Atualizar sempre que algo for verificado ou descoberto. Procedência
dos dados em `dados/FONTES.md`.

Legenda: **[dado]** sobre a origem ou a qualidade de um dado · **[método]**
sobre o experimento · **[resultado]** sobre como ler um número.

## Dados

1. **[dado] Proventos vêm de fonte não oficial (Yahoo).**
   - Não há nenhum evento antes de 01/07/2005: a calibração 2004–2006 tem
     proventos incompletos na camada 4.
   - Não há nenhum evento em 2015–2016. É compatível com a suspensão de
     dividendos da Petrobras nesses anos, mas **isso não foi verificado** em
     fonte oficial.
   - Nas 22 datas-ex de 2021–2026, o provento do Yahoo difere do que o ajuste
     da Clear implica: mediana de 0,29 p.p., máximo de 5,5 p.p. em 22/11/2022.
     Nessa data o Yahoo registra R$ 1,75 e o ajuste da Clear sugere um valor
     bem maior.
   - Não se sabe se o JCP está bruto ou líquido de IR em cada fonte.
   - Por isso os proventos ficam só na camada 4 (adendo). A escolha de
     parâmetros e as comparações entre modelos usam a camada 3, sem proventos.
2. **[dado] Custo de 0,03% por execução sem fonte primária.** A tabela de
   tarifas da B3 não foi consultada. Emolumentos mudaram ao longo de
   2003–2026 e o valor usado é o mesmo para todos os anos.
3. **[dado] Desdobramento de 2005** (1→4, 01/09/2005): confirmado pelo Yahoo e
   pelo salto de preço no COTAHIST, mas não aparece na lista da API da B3.
4. **[dado] Arredondamento**: a série corrigida por desdobramento tem 2 casas.
   Em 2003–2005 (R$ 5,8–19) isso dá erro de até ~0,09% por preço.
5. **[dado] Ajuste da Clear** (usada só para conferência) é de método não
   documentado. Ela só tem dados desde 21/09/2021.

## Réplica de Almeida (2016) — resolvida em 28/09/2026

6. **[dado] RESOLVIDO. O trabalho original foi lido.** Datas, capital, volume,
   algoritmo e resultados estão em `dados/FONTES.md`, item 7. O que antes era
   suposição virou dado: o período fora de crise é **22/05/2013 a 24/05/2016**
   (e não o ano cheio de 2013 a 2016, como se havia assumido).
7. **[método] PARCIALMENTE resolvido. A conferência de 29/09 mostrou que a
   réplica reproduz o NÚMERO DE OPERAÇÕES, mas não os valores em reais.**
   Os números abaixo saem dos relatórios do próprio MetaTrader
   (`rel_fl*.htm`), no mesmo formato que Almeida leu dos dele:

   | | Almeida | Réplica | Bate? |
   |---|---|---|---|
   | 2013–2016 · operações | 38 | 37 | sim |
   | 2013–2016 · lucro líquido | +R$ 10.430 | +R$ 10.050 | sim (3,6%) |
   | 2008–2010 · operações | 37 | 38 | sim |
   | 2008–2010 · lucro bruto | +R$ 2.855 | +R$ 4.610 | **não (1,6×)** |
   | 2008–2010 · lucro líquido | −R$ 1.595 | −R$ 575 | **não** |
   | 2007–2011 · operações | 52 | 63 | **não** |
   | 2007–2011 · lucro bruto | +R$ 3.363 | +R$ 6.609 | **não (2,0×)** |
   | 2007–2011 · perda bruta | −R$ 5.905 | −R$ 7.883 | **não** |
   | 2007–2011 · lucro líquido | −R$ 2.542 | −R$ 1.274 | **não** |

   **Leitura honesta:** só o teste de 2013–2016 fecha em operações **e** em
   dinheiro. Em 2008–2010 fecha a contagem e não o valor. Em 2007–2011 só o
   sinal e a ordem de grandeza batem. A afirmação anterior de que "dois dos três
   testes fecham" **era forte demais**: ela valia para a contagem de operações,
   não para o resultado financeiro, e foi corrigida em 29/09.

   **O que explica a diferença, e o que não foi confirmado:**
   - o valor em reais depende do **nível de preço da série**, e a série dele
     (corretora, 2016) foi ajustada por método desconhecido. A nossa é o
     COTAHIST corrigido só por desdobramento. Com lote fixo, qualquer diferença
     de escala vira diferença proporcional de lucro;
   - ele **não informa o volume** dos testes de crise. Observação **não
     confirmada**: como o resultado escala linearmente com o lote (conferido:
     1.000 ações = 10× o de 100), 200 ações dariam −R$ 2.548 em 2007–2011,
     contra os −R$ 2.542 dele — coincidência a 0,24%. Mas isso **não explica** a
     contagem de operações (63 contra 52), então não se pode afirmar que era 200;
   - a contagem diferente em 2007–2011, com 2008–2010 fechando, indica que a
     divergência está nos anos **2007 e 2011**, não na lógica da média móvel.

   **Diagnóstico de 29/09, por conferência offline** (descartável, fora do
   repositório; validada primeiro contra o relatório do MT5 na série OFICIAL,
   com diferença menor que 1% em operações, bruto e líquido):

   | 2008–2010, 100 ações | operações | bruto | líquido |
   |---|---|---|---|
   | Almeida | 37 | +2.855 | −1.595 |
   | série OFICIAL (a nossa) | 37 | +4.485 | −677 |
   | série ajustada por proventos até 05/2016 | 39 | **+3.485** | −837 |

   Ajustar por proventos (como a corretora dele provavelmente fazia) põe a série
   em 81% do nível da nossa e **move o lucro bruto na direção do número dele**,
   de 4.485 para 3.485 contra 2.855. Ou seja: **boa parte da diferença em reais é
   nível de preço da série**, não erro de implementação.
   Mas **a contagem de operações não é explicada por ajuste nenhum**: o
   cruzamento de médias é invariante a escala (multiplicar todos os preços por
   uma constante dá exatamente os mesmos cruzamentos), e no teste acima a
   contagem foi de 62 para 68, afastando-se dos 52 dele. Logo a série de
   fechamentos que ele usou **diferia em forma** da do COTAHIST, ou a execução
   dele (modelo "cada tick", gestão de dinheiro por risco) gerava outras
   entradas. Sem os dados dele, isso **não é determinável**.

   **Consequência para o TG:** a réplica pode ser apresentada como validação de
   que a **reimplementação da estratégia reproduz o comportamento** do algoritmo
   dele (mesma quantidade de sinais em dois dos três períodos), **não** como
   reprodução exata dos resultados financeiros. Escrever o contrário seria
   afirmar mais do que os dados mostram.

## Método

8. **[método] O tester só fornece histórico a partir de 1º de janeiro do ano
   anterior ao início do teste.** As janelas de seleção (240 barras) e de
   estimação foram limitadas por isso.
9. **[método] Execução ao preço de abertura** (modelo "somente preços de
   abertura"), com spread de 1 tick e sem slippage real. Os dados diários não
   permitem simular ticks.
10. **[método] Viés de seleção.** A configuração escolhida é a melhor de
    milhares numa janela de calibração. O número da calibração é otimista por
    construção; só o do período de teste vale como resultado.
11. **[método] Sensibilidade a detalhes de execução.** Na rodada 2, a mesma
    configuração deu Sharpe 1,46 ou 1,66 conforme só o lote (100 ou 1) e o
    arredondamento. Pequenas mudanças trocam sinais do ARIMA. Não é possível
    garantir estabilidade de 2ª casa decimal nos resultados.
12. **[método] Só compra.** Todos os modelos operam sem venda a descoberto no
    cenário justo. A MM de Almeida original é compra e venda (usada assim só
    na réplica).

## Resultados

13. **[resultado] Rodadas 1 e 2 estão superadas** (dados do Yahoo, com
    lacunas). Nenhum número delas deve ir para o TG. Três números ditos em
    conversa na rodada 1 foram **estimativas sem backtest**: "cerca de +25% sem
    a maior operação"; "t ≈ 1,7, p ≈ 0,05"; "−R$ 50 no teste do autor" (o log
    mostrava −R$ 72).
14. **[resultado] Significância.** Um Sharpe positivo não é prova de superar a
    Selic: olhar o p-valor. O mesmo vale para diferenças entre modelos (teste
    de Memmel e t pareado em `CompararModelos`).

## Rodada 3 (dados oficiais B3, calibração por período)

15. **[resultado] O melhor resultado (T2, +325%, Sharpe 0,80) vem de uma
    configuração escolhida com Sharpe NEGATIVO na calibração** (−0,26): era "a
    menos ruim" de 2010–2012. O p do Sharpe é 0,056, acima de 0,05. A outra
    escolha do mesmo período (por Calmar) rendeu +34%. Não apresentar o +325%
    sem essas duas ressalvas.
16. **[resultado] Escolher pelo retorno não se sustenta**: a correlação de
    postos do Sharpe entre calibração e teste ficou entre −0,07 e 0,03. Qualquer
    configuração "campeã" pode ser sorte. O que se sustenta em parte é a
    segurança (Calmar, correlação 0,28–0,41).
17. **[método] A família ARIMA puro tem só 8 configurações na grade**, contra
    336 da família com GARCH. O GARCH teve muito mais chances de ter uma
    campeã. A comparação justa é a pareada (mesma base de ARIMA), que está no
    relatório.
18. **[método] A MM de Almeida não foi calibrada** (fixa em 10/20, como no
    trabalho dele), enquanto ARIMA e ARIMA-GARCH foram. Isso favorece os
    modelos estatísticos na comparação.
19. **[resultado] Em T1 os dois critérios escolheram a mesma configuração**,
    então "Sharpe" e "Calmar" coincidem nesse período. O mesmo vale para o
    ARIMA puro nos três períodos.
20. **[método] Diferenças de Sharpe entre modelos** só foram significativas
    (p < 0,05) em um caso (T2, GS × ARIMA). Nos demais, dizer "teve Sharpe
    maior", nunca "foi melhor", sem o p.

## Rodada 4 (4 ativos, com venda a descoberto)

21. **[dado] Erro corrigido, e o que ele custou.** Na primeira montagem das
    séries de VALE3, USIM5 e POMO4 o desdobramento foi aplicado também no dia
    do evento (a data informada pela fonte já é o primeiro pregão ajustado).
    Isso deixou de 3 a 5 dias por ativo com preço pela metade ou um terço.
    Detectado na auditoria de 24/09 ao reconstruir as séries a partir das
    linhas originais da B3. Séries refeitas e toda a bateria desses ativos
    repetida. A PETR4 não foi afetada.
22. **[método] Conta zerada.** Configurações com venda a descoberto podem
    perder mais que o capital. O código agora marca essas passagens como
    ruína e congela a curva em zero; antes gerava valor não numérico. Na
    rodada 4, isso ocorreu em 0,4% (2007–2011) e 0,8% (2013–2016) das
    configurações com venda a descoberto, e em nenhuma só-compra.
23. **[resultado] O efeito do GARCH depende de qual variante.** Só as que
    **reduzem a posição** (targeting ou zerar no veto) protegem. As que apenas
    congelam a posição mudam a queda máxima em metade dos casos, para mais ou
    para menos. Não escrever "o GARCH reduz risco" sem essa qualificação.
24. **[resultado] Sharpe não melhora.** Mesmo quando o GARCH reduz muito a
    queda máxima e aumenta o retorno, a mediana da diferença de Sharpe fica
    perto de zero. Retorno e risco caem juntos.
25. **[resultado] POMO4 em 2013–2016 é a única exceção** em que a venda a
    descoberto ajudou (mediana +10,7 p.p., melhorou em 64% dos pares). Em
    todos os outros 11 casos ela piorou. Não generalizar a partir dessa
    exceção.

## Bibliografia (28/09/2026)

26. **[método] A triagem das 637 referências candidatas foi feita por leitura de
    título e resumo, não exaustiva.** Obras relevantes podem ter ficado de fora,
    em especial as que a OpenAlex não indexa: TCCs, anais de congresso e
    literatura cinzenta, que só aparecem no Google Scholar.
27. **[dado] Cinco clássicos casaram com obras erradas** na primeira busca por
    título. Foram corrigidos conferindo autor e ano (ver `bibliografia/BUSCA.md`).
    Qualquer referência acrescentada depois precisa passar pela mesma conferência.
28. **[dado] Memmel (2003) não está indexado** no Crossref. A correção dele ao
    teste de Jobson-Korkie está implementada no código; no texto, citar Ledoit e
    Wolf (2008) e dizer isso de forma explícita.

## Normas da FATEC-ID (28/09/2026)

29. **[dado] RESOLVIDO em 01/10/2026.** O manual vigente foi localizado em
    `fatecid.com.br/site/index.php/trabalho-de-graduacao/` e baixado
    (`Revisao-manual-normas-Revisao-2026-2028.pdf`, 45 páginas, biênio
    2026-2027). Comparado com o de 2021: formatação, estrutura e ilustrações
    não mudaram; as **citações mudaram** (caixa mista dentro dos parênteses,
    NBR 6023:2025) e isso foi aplicado ao texto. Detalhes em
    `dados/FONTES.md`, item 10.
    **Nova incerteza no lugar:** o manual é internamente inconsistente. O item
    2.3.1 enuncia a caixa mista e os Exemplos 4 e 2.3.5.8 mostram caixa alta.
    O TG seguiu a regra enunciada. **Não confirmado com a orientadora.**
30. **[dado] A URL exata das páginas do site da FATEC-ID não foi registrada.** O
    texto foi repassado pelo autor por cópia e está arquivado literalmente em
    `dados/fontes/normas-fatec/`, mas não há endereço nem data de captura da
    página. Para citar as normas no TG, pegar a URL.
31. **[método] A classificação da pesquisa ainda não está no texto na forma que a
    instituição exige.** O PTG classificou pela taxonomia de Wazlawick (empírica,
    aplicada, hard, nomotética); o Capítulo II precisa declarar **quanto aos
    objetivos** e **quanto ao delineamento** segundo o caderno da FATEC. A
    leitura proposta — quase experimental, explicativa com parte descritiva,
    análise quantitativa — está justificada em `notas/NORMAS-FATEC.md`, seção 5, mas
    **não foi validada pela orientadora**.

## Revisão do texto (05/10/2026)

32. **[dado] Três números do Capítulo III não batiam com os arquivos** e foram
    corrigidos na auditoria de 05/10:
    - queda máxima das médias móveis reproduzidas em 2013–2016 estava como
      **12,9%**; o arquivo (`replica_almeida_2026-09-28/metricas_fl13of.csv`,
      `dd_puro`) dá **15,0%**. Não se achou de onde o 12,9% veio. Junto caiu a
      frase "com menos de um terço da queda máxima", que não vale contra a MM
      (8,7% contra 15,0%);
    - retorno anual da variante filtro com ajuste de posição em 2005–2026:
      9,0% → **9,1%** (`metricas_L1_GT.csv`, 0,091084);
    - retorno anual da MM em 2005–2026: 11,9% → **11,8%** (`metricas_L1_MM.csv`,
      0,118158).
    Lição: conferir cada número contra o arquivo na hora de escrever, e não
    contra o CLAUDE.md ou uma versão anterior do texto.
33. **[dado] A verificação em dados reais do Capítulo III usa a PETR4 da
    corretora**, não a `PETR4_OFICIAL`. O `ValidacaoAlgoLab.mq5` faz
    `CopyClose("PETR4", ...)` com os 500 últimos pregões. O texto diz isso
    explicitamente. Os números são os do arquivo arquivado
    (`dados/verificacao/validacao_numerica_2026-09-29.txt`: ADF 0,12 e −20,83;
    Ljung-Box dos resíduos padronizados ao quadrado p = 0,34). Os que estavam no
    texto antes (−0,95, −21,37, p = 0,79) vinham de uma execução anterior que
    **não está arquivada**, por isso saíram. Para ficar todo em dado oficial,
    reexecutar o script apontando para `PETR4_OFICIAL`.
34. **[resultado] d nem sempre é 1.** No traço de 07/2019 a 06/2021
    (`dados/resultados/traco_demo_2019_2021/`), o ADF sequencial escolheu
    d = 0 em 42 das 496 barras (duas reseleções de 21 barras). O texto não
    afirma que d = 1 sempre; se a banca perguntar, é este o dado.
    **Atualizado em 15/10/2026:** esse número é do EA antigo. Com o EA corrigido
    (`dados/resultados/refeito_2026-10-05/traco_demo/traco_demo_GARCH.csv`, mesma
    janela de 07/2019 a 06/2021), d = 0 em 84 de 496 (16,9%) e d = 1 em 412
    (83,1%). Agora está no Cap. III.
35. **[norma] Decisões de formatação tomadas na revisão de 05/10, não
    confirmadas com a orientadora:**
    - Considerações finais **sem número de capítulo** (a estrutura do Manual é
      Introdução, Capítulos I a III e Considerações Finais);
    - só a abertura de CAPÍTULO I, II e III fica **sem número impresso** (Manual
      1.5 e 4.1.2.10, "entradas de capítulos", e o modelo da Figura 8).
      Introdução, Considerações finais, Referências e Apêndice mostram o número.
      Corrigido em 05/10 depois de o autor perguntar sobre a página das
      Referências, que estava sem número;
    - **lista única de ilustrações** (5 figuras, 2 quadros, 2 gráficos: quadro e
      gráfico têm menos de 5, Manual 4.1.1.10) e lista de tabelas separada;
    - código do apêndice em fonte monoespaçada de 8 pt. O Manual não fala de
      listagem de código; o tamanho 10 vale para tabela, quadro e ilustração.
      Com a listagem reduzida (sem log e diagnóstico) o apêndice tem 7 páginas em 8 pt; em 10 pt teria cerca de 10 (estimativa, não medido);
    - o ponto e vírgula aparece em dois lugares, por exigência de norma: entre
      as palavras-chave (NBR 6028) e entre citações dentro do mesmo parêntese
      (NBR 10520). Fora disso, não há nenhum no texto.
36. **[texto] A folha de rosto diz "Prof. MsC."** O exemplo do Manual usa
    "Prof. Dr."; a abreviação usual de mestre é "Me." ou "Ms.". Não foi mexido:
    é o título do orientador e cabe ao autor confirmar.
37. **[texto] Orientadora trocada em 05/10/2026: Simone Mendes da Silva.** Na
    folha de rosto está "Profa. Simone Mendes da Silva", **sem titulação**
    (Dra., Me.), porque ela não foi informada. **Resolvido em 12/10/2026**: a
    orientadora confirmou que "Profa." está bem. O item 36 (o "MsC." do orientador anterior) deixou de
    se aplicar.
38. **[dado] Introdução com fontes institucionais e jornalísticas
    (05/10/2026).** Por pedido do autor, a abertura cita ANBIMA, B3, CVM e
    notícias (Agência Brasil, InfoMoney), e não artigos. Procedência em
    `dados/FONTES.md`, item 11. Cuidado: o "50% a 60% das negociações por
    algoritmo" é declaração de um superintendente da B3 relatada pela InfoMoney,
    não estatística publicada.
39. **[leitura] `sharpe1994` é artigo e entrou no texto a pedido do autor
    (05/10/2026)**, para definir o índice de Sharpe pelo próprio autor. Pela
    regra nº 3 ele precisa ler: é curto e está aberto em
    `bibliografia/paginas/Sharpe-1994-the-sharpe-ratio.html`. As partes usadas
    são "The Ex Ante Sharpe Ratio" (definição), "Time Dependence" (anualização)
    e o parágrafo da estatística t. Detalhe que a banca pode perguntar: o
    valor-p do trabalho não é o t simples de Sharpe, usa o erro-padrão de Lo
    (2002), que acrescenta a incerteza da estimativa do próprio desvio-padrão
    (`Desempenho.mqh`, linha 122: raiz de (1 + Sharpe²/2) / n).
40. **[texto] Obstáculo da corretora, versão de 05/10/2026.** O Cap. II passou a
    nomear as corretoras: a Rico "deixou de oferecer suporte ao MetaTrader 5" e a
    Clear "disponibiliza cotações apenas a partir de setembro de 2021". A primeira
    afirmação é **relato do autor**, sem documento arquivado; a segunda está
    conferida (`dados/FONTES.md`, item 5). Se a banca pedir comprovação da Rico,
    vale guardar o comunicado ou o e-mail da corretora.
41. **[dado] Segunda auditoria (05/10/2026, tarde): mais três números da
    Tabela 4 corrigidos contra `metricas_R6_*.csv`:** compra e manutenção da
    PETR4 ao ano 11,8% → **12,0%** (`cagr_bh_preco` 0,1198); médias móveis ao
    ano 8,4% → **8,5%** (`cagr_selic_camada` 0,0853); valor-p da gêmea do GC
    0,807 → **0,808** (0,8075). O 11,8% vinha de uma conta feita fora do EA
    (anos de calendário), e não do arquivo.
42. **[pendente] Item 9 da auditoria, adiado pelo autor:** refazer a
    verificação em dados reais da seção 2.4 sobre a `PETR4_OFICIAL` (hoje usa a
    PETR4 da corretora, ver item 33). **Resolvido pelo item 48** (05/10/2026):
    a seção 2.4 já cita a validação sobre a `PETR4_OFICIAL`.
43. **[código] ERRO ACHADO E CORRIGIDO em 05/10/2026: direção errada quando
    o ADF escolhe d = 0.** O EA usava `PreverDiferenciado()` como previsão de
    retorno. Com d = 1 isso está certo (é o log-retorno esperado). Com d = 0 o
    ARIMA modela o NÍVEL do log-preço e essa "previsão" é o próprio nível (~3,2),
    sempre positivo: o EA entendia "alta" todo dia e comprava sempre (sujeito
    ao veto do GARCH). Achado ao desenhar o gráfico do traço de 2019–2021: 42 de
    496 pregões com d = 0 (ago–set/2019 e abr/2021), todos com sinal de compra.
    **Correção:** com d ≠ 1, a direção passa a ser `PreverNivel()` menos o nível
    atual (`ARIMA_GARCH_EA.mq5`, bloco "Previsao do RETORNO do dia"). Para d = 1
    nada muda. **O que afeta:** ARIMA isolado e ARIMA-GARCH, igualmente (a gêmea
    usa o mesmo ARIMA), nos testes em que houve d = 0. Não afeta as médias
    móveis. **Medição:** `ferramentas/scripts/medir_d0.sh` roda os 12 testes
    principais com o EA corrigido e traço, conta os dias com d = 0 e compara as
    métricas com as antigas. Resultado da medição: ver item 44.

44. **[dado] Medição do erro do item 43 (05/10/2026, noite).** Saída de
    `ferramentas/scripts/medir_d0.sh`, guardada em `/tmp/algolab-trabalho/medir_d0.out`
    (temporária; os números estão aqui). Doze testes, só com a correção do
    item 43 (ainda SEM a do item 45):
    - pregões com d = 0: 147 de 1.983 em 2017–2024 e 231 de 5.380 em 2005–2026;
      0 de 743 no cenário de Almeida 2013–2016, que saiu idêntico ao antigo
      (serve de teste de regressão: onde não há d = 0 nada muda);
    - retorno da camada 3, antes → depois: R6_GS 276,1% → 259,5%; gêmea
      106,5% → 106,8%; R6_GC 112,6% → 109,4%; gêmea do GC −43,8% → −51,5%;
      L1 filtro 3.780,7% → 4.842,0%; L1 filtro+targeting 543% → 578%;
      L2 filtro 154,6% → 151,5%; L2 filtro+targeting 118,0% → 103,2%;
    - em todos os pares a versão com GARCH continuou melhor que a gêmea; zero
      falhas de ajuste.
    Conclusão: o erro mexe nos números, não no sentido dos resultados. Mesmo
    assim **todos os experimentos foram refeitos** com o EA corrigido (item 51),
    porque as escolhas de configuração na calibração podem mudar.

45. **[código] Segundo erro com d = 0, corrigido em 05/10/2026:** com d = 0 e
    `IncluirConstante=false`, o ARIMA ajustava o NÍVEL do log-preço sem média.
    Como o log-preço não tem média zero, a previsão saía puxada para baixo
    (sinal de venda espúrio). Agora a constante é obrigatória quando d = 0
    (`CArima::Definir`). Afeta as configurações sem constante, que são a
    maioria das escolhidas. A medição do item 44 NÃO inclui esta correção.

46. **[código] ADF com defasagens escolhidas por AIC sem amostra comum,
    corrigido em 05/10/2026.** Mesmo viés do item da seleção do ARIMA (cada
    número de defasagens somava a verossimilhança sobre um número diferente de
    observações, favorecendo poucas defasagens). Agora o AIC de cada k é
    calculado sobre a mesma amostra e, escolhido k, a estatística é recalculada
    com toda a amostra disponível para ele (`TesteADF` + `RegressaoADF`).

47. **[código] ADF que não podia ser calculado devolvia d = 0 em silêncio,
    corrigido em 05/10/2026.** `DeterminarOrdemD` agora devolve −1 e a seleção
    é adiada (`d indeterminado`), em vez de cair num modelo de nível sem aviso.
    Junto: o (0,d,0) só é pulado sem constante quando d ≠ 0.

48. **[verificação] Validação numérica refeita sobre a série oficial
    (05/10/2026).** O script estava fora do repositório e lia o `PETR4` da
    corretora. Agora é `ferramentas/ValidacaoAlgoLab.mq5`, roda por
    `ferramentas/scripts/validar.sh` sobre `PETR4_OFICIAL`, e a saída está em
    `dados/verificacao/validacao_numerica_2026-10-05.txt`. Os números de dados
    sintéticos não mudaram (ARMA, AR, GARCH). O ADF do passeio aleatório foi de
    −1,48 para −1,41 e o do AR(1) de −17,92 para −26,87 (efeito do item 46; as
    duas decisões continuam as mesmas). Na série oficial (500 barras até
    18/09/2026): ADF do log-preço −0,95, do log-retorno −6,14; Ljung-Box dos
    resíduos do ARIMA(1,1,1) p = 0,009; volatilidade prevista 1,64%; Ljung-Box
    dos resíduos padronizados ao quadrado p = 0,75. **O texto do TG (seção 2.4)
    ainda cita os números antigos.**

49. **[texto] Diferença entre texto e código: o ajuste de posição pela
    volatilidade (targeting) só dimensiona a ENTRADA.** Uma posição já aberta não
    é reduzida quando a volatilidade sobe; quem tira a posição é o "zerar no
    veto". O Cap. III diz "variantes que reduzem a posição, isto é, as que
    ajustam o volume à volatilidade ou encerram a posição no veto" — a primeira
    metade precisa ser reescrita como "dimensionam a entrada pela volatilidade".
    Também falta dizer no texto que o veto pelo percentil veta, na prática, mais
    do que o percentil sugere (ver CLAUDE.md, "Semântica do limiar por percentil").

50. **[texto] Rodada 5: uma das duas configurações fixas NÃO tinha sido
    escolhida em 2010–2012.** O texto diz que as duas foram escolhidas "na
    calibração de 2010 a 2012". O filtro (GF) era a escolha de C2 (2010–2012),
    mas o filtro+targeting (GT) era a escolha de C1 (2004–2006). Na refação
    (item 51) a regra foi declarada antes: as duas são a GS e a GC de C2.

51. **[dado] Refação completa dos experimentos com o EA corrigido (iniciada em
    05/10/2026, 23h08).** Protocolo declarado antes dos resultados em
    `dados/resultados/refeito_2026-10-05/PROTOCOLO.md`. A escolha e as análises
    das grades passaram de Python (fora do repositório) para awk versionado
    (`escolher.sh`, `parear.sh`, `analisar_grades.sh`, `anual.sh`), e o teste
    pareado para `ferramentas/CompararModelos.mq5`. Antes de usar nos dados
    novos, os scripts foram conferidos contra os arquivos antigos: as 12
    escolhas da rodada 3 e as 48 da rodada 4 saíram iguais às do Python, e a
    análise pareada, a de venda a descoberto, as referências, a persistência
    (Spearman), os retornos anuais e a concentração (2018 = 24,6% do retorno
    em log de L1) reproduziram os números antigos. Única diferença: a ruína
    precisou do limiar `ret ≤ −99%` (com −99,9% dava 4 casos em vez de 5).

52. **[dado] Resultado da refação (06/10/2026, 01h).** Detalhe em
    `dados/resultados/refeito_2026-10-05/LEIAME.md`. O Cap. III, as
    Considerações finais e a seção 2.4 foram atualizados com os números novos
    (backup em `notas/rascunhos/antes_refacao_2026-10-06/`). O que mudou de
    conclusão, e que o autor precisa saber para a banca:
    - **Proteção: se manteve.** Queda máxima menor que a gêmea nos 11 pares,
      retorno maior em 9 de 11, e o padrão nos 4 ativos.
    - **Significância: caiu.** GARCH × gêmea de 5 para **1** de 11 com p < 0,05;
      contra a Selic, de 1 para **nenhum**. O "único p < 0,05 contra a Selic"
      (filtro de 2005–2026, p 0,041) era de uma configuração que a calibração
      corrigida não escolhe mais; rodada com o EA corrigido, ela dá p = 0,050
      (pasta `sensibilidade/`). O texto agora explica por que o Sharpe não mostra
      a proteção (abaixo da Selic, menos oscilação deixa o índice mais negativo).
    - **2013–2016 por Sharpe** (+325%, Sharpe 0,80) **desapareceu**: a escolha
      de C2 mudou.
    - **Períodos longos:** as duas configurações agora são filtro+targeting
      (regra declarada no protocolo: GS e GC de C2). Nenhuma supera a Selic em
      21 anos; o ganho sobre a gêmea é grande (79,9% → 602–670%), sem
      significância no Sharpe.
53. **[texto] Erro no texto antigo sobre venda a descoberto.** O Cap. III dizia
    que a mediana piorou "em onze dos doze casos". Nem com os dados antigos isso
    valia: pela mediana do retorno eram 8 piores, 3 melhores e 1 igual; pela do
    Sharpe, 7 e 5. Com os dados novos: 9 piores, 2 melhores, 1 igual (retorno).
    O texto agora diz isso. A origem provável é a análise anterior ter contado
    outra coisa (não foi possível reconstruir; o script era Python fora do
    repositório).
54. **[ambiente] Perfil Default do terminal no limite de 100 gráficos**
    (`MQL5/Profiles/Charts/Default`, prefixo novo): 92 são de símbolos `_OFICIAL`
    e `_OFBRUTO`, deixados por scripts rodados pelo `[StartUp]`. Com o limite
    atingido, nenhum script abre pelo `[StartUp]` ("open charts limit reached"),
    sem erro visível. Não apaguei os gráficos (é estado do terminal do autor;
    a permissão foi negada). Contornado: a comparação roda como EA no testador.
    **O `validar.sh` também usa `[StartUp]` e vai falhar enquanto o perfil
    estiver cheio.** Para liberar: fechar gráficos na interface do MT5.
55. **[texto] Auditoria de 12/10/2026: Cap. III conferido número a número** contra
    `refeito_2026-10-05/` (tabelas de reprodução, condições originais, principal,
    janelas, ativos, longo, significância e mecanismo, 2008, 03/04/2020,
    concentração, venda a descoberto, persistência): todos conferem. Dois pontos
    de texto, **ainda não corrigidos, aguardando o autor**:
    - **Compra e manutenção sem proventos.** A Tabela principal e a do horizonte
      longo usam `bh_preco` (+143,6% em 2017–2024). O texto diz que a escolha por
      Sharpe rendeu mais que "a compra e manutenção do ativo". Com proventos
      (`bh_total`, `ret_completo` de `metricas_R6_*.csv`, proventos do Yahoo, não
      oficial): compra e manutenção +726,5%, médias móveis +396,1%, GS +353,4%,
      gêmea +331,1%, GC +212,1%, gêmea do GC +2,1%. GARCH × gêmea mantém o
      sentido; GS × médias móveis e GS × compra e manutenção se invertem.
    - **Considerações finais: "Selic superada em alguns períodos"** pelo
      ARIMA-GARCH. Só em 2017–2024 (GS e GC); em T1, T2, T3, L1 e L2, não.
    Achado lateral: no cenário de Almeida 2013–2016, GARCH × ARIMA tem p = 0,040
    (`comparacoes.csv`, linha cenA_1316), que o texto não menciona.
    **CORRIGIDO em 12/10/2026, a pedido do autor ("o que eu menos quero é mostrar
    dados errados")**; backup em `notas/rascunhos/antes_revisao_2026-10-12/`:
    - cap2 (2.3.2): proventos fora da medida para algoritmos e compra e
      manutenção (só preço); proventos do Yahoo usados em duas verificações;
    - cap3: notas das tabelas principal, janelas e longo dizem "sem proventos" /
      "pela variação do preço"; a frase da escolha por Sharpe diz que a vantagem
      depende de os proventos ficarem fora; 5º item nas limitações com os números
      acima. Conferido também: com proventos, GARCH × gêmea mantém queda menor em
      11/11 e retorno maior em 9/11 (as duas exceções, T3 GS e GC, são as mesmas
      sem proventos);
    - cap3, × médias móveis: de 9 para **12 comparações** (faltava 2017–2024, que
      o texto da Tabela principal remetia a esta seção sem que ela a mostrasse);
      p de 0,11 a **0,95** (R6_GC × R6_MM 0,9457);
    - cap4: "Selic superada em alguns períodos" → só em 2017–2024; limitações
      citam os proventos.
    Os números com proventos foram conferidos antes de usar: em T2, as variantes
    com GARCH têm `ret_completo` = `ret_selic` porque estavam fora do mercado nas
    duas datas-ex do período (30/04/2013 e 03/04/2014, `curva_R3_T2_*.csv`,
    `exposicao` 0), não por erro. O achado lateral (p = 0,040) continua fora do
    texto: decisão do autor.
56. **[resultado] GARCH com erros t de Student testado em 13/10/2026, a pedido do
    autor (depois de ler Thomaz, 2019). NÃO está no TG.** Opção nova no EA,
    `DistribuicaoGARCH` (padrão normal, linha marcada `//@omitir`; o Apêndice A
    não mudou). Validação sintética, regressão byte a byte e resultado em
    `dados/resultados/garch_t_2026-10-13/LEIAME.md`. Em resumo, trocando só a
    distribuição nas 12 configurações do TG (sem recalibrar): retorno menor em
    9, queda máxima maior em 9 (0,4 a 3,6 pontos), Sharpe menor em 9, nenhuma
    diferença t × normal significativa. A proteção contra a gêmea se mantém
    (queda menor em 12 de 12). A t vetou menos (7 de 8 configurações
    distintas): fica mais permissiva. ν estimado de 4,6 a 10,5 em 2017–2026
    (caudas grossas, como em Thomaz). **Não testado:** recalibrar a grade com a
    t. Decisão do autor se isso entra no texto (ex.: como verificação de
    robustez ou em trabalhos futuros).
57. **[texto] Parte final reescrita com foco em risco (13/10/2026), a pedido do
    autor**: "o GARCH não foi feito para dar lucro... ter o objetivo central em
    Selic não faz sentido". Cap. II (2.3.2: volatilidade e queda como medidas
    centrais, Pitman-Morgan, Sharpe como complementar), Cap. III (tabelas com
    volatilidade no lugar de Sharpe e p, nova tabela de volatilidade com
    Pitman-Morgan, seletividade no mecanismo, 1ª limitação), Considerações (risco
    primeiro, parágrafo sobre a sugestão de Almeida, hipóteses), resumo e
    abstract. Backup em `notas/rascunhos/antes_foco_risco_2026-10-13/`. Números em
    `refeito_2026-10-05/LEIAME.md`, seção de 13/10. TG com 51 páginas.
    **Pendente do autor:** ler Pitman (1939) e Morgan (1939) (marcação
    `% REFERÊNCIA` no Cap. II) e dominar duas coisas novas para a banca: o teste
    de Pitman-Morgan (correlação entre soma e diferença) e a razão de
    seletividade. **Ressalva escrita no texto:** o Pitman-Morgan supõe retornos
    independentes no tempo; os p são otimistas (t de −5 a −157).
58. **[texto] Cap. III reorganizado para ficar legível (14/10/2026), a pedido do
    autor** ("não entendo mais nada da parte escrita"). Sem mudar protocolo nem
    número: (1) "escolha por Sharpe/Calmar" virou **versão A/B**, definidas uma
    vez no Cap. II (2.5, protocolo) e num **Quadro de termos** no início do Cap. III;
    (2) gêmea explicada como grupo de controle; (3) tabelas de risco só com
    volatilidade, queda e exposição; (4) **Gráfico de volatilidade** novo
    (`tg/graficos/rodada3/volatilidade.tex`); (5) tabela de significância com
    redução em % no lugar do t (o t foi para a nota, de −5 a −157); (6) retorno,
    Sharpe, Selic, venda a descoberto, concentração e proventos numa seção
    **"Complemento: retorno financeiro e taxa Selic"** antes das limitações.
    Também: Cap. II define a razão de seletividade (equação) e cita a suposição de
    normalidade do Pitman-Morgan (com Thomaz, 2019). Legendas dos gráficos de
    curva e anual dizem "versão A/B". TG com 53 páginas, 0 estouros. Backup em
    `notas/rascunhos/antes_legibilidade_2026-10-14/`.
    **Arredondamento conferido com 3 casas**: L2 versão B × gêmea = 73,497% → 73%.
59. **[texto] Capítulos II e III reestruturados (14/10/2026), a pedido do autor**
    ("parece que os capítulos têm coisas mescladas, metodologia no resultado,
    resultado na metodologia", quadro de termos "menos elegante", "enchendo
    linguiça", "manter o tom original do projeto"). Nenhum número mudou.
    - Cap. II só diz COMO: versão A/B, gêmea, ARIMA isolado, janelas de
      calibração, configurações fixas, análise por pares nos 4 ativos, condições
      da réplica e das condições originais vieram para o plano experimental. A
      validação virou seção própria (2.5) só com o procedimento. Equação do
      Sharpe repetida saiu (remete à eq. do Cap. I). Hannan-Rissanen mais curto.
    - Cap. III reescrito do zero, uma seção por pergunta: validação (tabela e
      ADF/Ljung-Box da PETR4, vindos do Cap. II, com comparação com Xing, 2024) →
      reprodução de Almeida → efeito sobre o risco (principal, janelas, 2008,
      significância e ativos e fixas em um parágrafo cada) → mecanismo → retorno.
      Sem quadro de termos e sem seção de limitações (ficam só nas considerações).
    - Apêndice B novo (`tg/conteudo/apendice-b.tex`): tabelas de redução da
      volatilidade, ativos e fixas, e o gráfico anual 2007–2011.
    - Cap. I: saiu a frase que antecipava resultado ("Como se verá no Cap. III").
    - Citações de Thomaz (2019) inseridas no Cap. II para ADF, AIC e máxima
      verossimilhança (o autor já leu a obra; conferir p. 40, 43, 44 e 47).
      **Pendente de leitura:** Hannan e Rissanen (1982) ou Brockwell e Davis;
      Pitman/Morgan (1939); Gil (2010).
    - Frase nova conferida: ARIMA isolado × médias móveis (Pitman-Morgan) não
      significativo em T1 (p 0,100), T3 (0,426) e condições originais (0,662);
      em T2 o ARIMA oscilou menos (0,020) e em 2017–2024 mais (0,036)
      (`testes/comparacoes_risco.csv`).
    TG com 49 páginas, 0 estouros, sem referência quebrada. Backup em
    `notas/rascunhos/antes_reestruturacao_2026-10-14/`.
60. **[texto] Simplificação no molde do Almeida (14/10/2026, à noite), a pedido do
    autor** ("algo simples que nem o do Almeida", "sem parecer mestrado", "foco
    em risco, lucro secundário"). Nenhum experimento novo.
    - Cap. III: um período por seção (crise 2007–2011, fora da crise 2013–2016,
      recente 2017–2024 e 2025–2026), com MM, ARIMA, versões A e B e PETR4 lado a
      lado (retorno, queda, volatilidade, negociações). Depois "O efeito vem do
      GARCH?" (11 de 11 com queda e volatilidade menores, 9 de 11 com retorno
      maior, raciocínio da moeda, quatro ações, fixas) e "Como o GARCH protege"
      (acerto de 41% a 59%, diferença com/sem GARCH de até 4 pontos, vetos,
      exposição, 03/04/2020). Retorno não tem mais seção própria.
    - Números novos no texto, todos de `refeito_2026-10-05/testes/`: ARIMA, MM e
      PETR4 em cada período (`metricas_R3_T*`, `R6_*`: ret_selic, dd_selic,
      vol_selic, saidas, bh_preco, dd_bh_preco, vol_bh_preco); MM +208,1% em 2016
      e GARCH +17,4%/+16,4% (`anual_R3_T2.csv`); PETR4 −15,4% em 2025 e +57,5% em
      2026 (`anual_R3_T3.csv`); Almeida, 3 negociações somando R$ 7.530 (PDF,
      seção 3.3).
    - Saíram do corpo: Pitman-Morgan, razão de seletividade, testes de Sharpe e
      a palavra "gêmea" (agora "mesma configuração com o GARCH desligado").
      Pitman-Morgan e testes de retorno ficam só no Apêndice B, como
      verificação. "Calibração" virou "otimização" com o princípio do teste
      forward (marcação `% REFERÊNCIA`: ajuda do MT5 e Pardo, 2008).
    - **Próximas camadas combinadas com o autor:** testes novos com otimização e
      forward do MT5 por critério único de risco (fator de recuperação, no lugar
      de Sharpe e Calmar); referências (Harvey et al., 2018; Pardo, 2008; Hwang e
      Valls Pereira, 2006; brasileiras); janela limitada pelo histórico do
      testador como justificativa.
    - Armadilha: o VS Code (LaTeX Workshop) compila sozinho quando um .tex muda e
      apaga o .log; se rodar junto com o `make`, o `main.aux` sai corrompido.
      Esperar ele terminar e rodar `make` sem salvar .tex.
    TG com 50 páginas, 0 estouros, citações em caixa mista. Backup em
    `notas/rascunhos/antes_simplificacao_2026-10-14/`.
61. **[texto] Varredura do autor (15/10/2026), lista colada na conversa.** Backup
    em `notas/rascunhos/antes_varredura_autor_2026-10-15/`. TG com 52 páginas,
    0 estouros, sem referência quebrada.
    - Cap. I: figuras e tabelas fixas no lugar (`[H]`, pacote `float` carregado
      DEPOIS dos `\newfloat` do Quadro e do Gráfico no `main.tex`; carregado
      antes, desmontou os dois); figuras 1 a 3 menores; "pregão" definido; ADF
      (raiz unitária, valor-p) e AIC explicados com Thomaz (p. 28, 40-41,
      44-45); ARMA e AR como casos do ARIMA (Thomaz, p. 33); citação
      "(Xing; Araya; Araya)" virou narrativa (estava certa pela ABNT, mas
      confusa); saiu a remissão às considerações; as três formas de usar o GARCH
      foram para o Cap. II como decisão de projeto (sem fonte; volatility
      targeting marcado para leitura); "Medidas de desempenho e risco" virou
      "Métricas de avaliação", com quadro de todas as métricas e a raiz de 252
      explicada (Sharpe, 1994, regra da raiz do tempo, arquivado em
      `bibliografia/paginas/`; 252 = convenção, **marcado para fonte**; média de
      247,8 pregões/ano em `dados/series/PETR4_OFICIAL.csv`, 2004-2025).
    - Cap. II: Wazlawick citado em 2.1.1 e 2.1.2 (definições do PTG); critério
      real dos ativos (qualidade de dado e setores, NÃO volatilidade, FONTES item
      9); desdobramento com datas, fatores e quedas (FONTES itens 1 e 2);
      logaritmo justificado com Thomaz (p. 28-29); GARCH(1,1) com Xing (p. 5 do
      PDF); janela deslizante comparada com Xing (expansiva foi melhor para o
      ARIMA deles) e limitada pelo histórico do testador; validação reescrita
      (AR(2) = um estágio, ARMA(1,1) = dois estágios, GARCH(1,1); 4.000, 6.000 e
      2.000 observações; semente fixa, `ferramentas/ValidacaoAlgoLab.mq5`);
      plano experimental com Quadro de períodos e menos detalhe; sem
      "equação (x.y)".
    - Cap. III: "médias móveis reproduzidas" em tabelas e gráficos (legendas
      regeradas; "ARIMA isolado" virou "ARIMA"; "gêmea" virou "sem GARCH" no
      gráfico de volatilidade); d varia (traço da versão A: d = 1 em 412 de 496,
      83,1%); queda máxima dentro de 2008 (`refeito_2026-10-05/recorte_2008.txt`:
      GARCH 6,9%, ARIMA 44,3%, MM 50,4%, PETR4 67,2%); **nova seção da
      pandemia**, recorte de 2020 do teste de 2017-2024
      (`refeito_2026-10-05/recorte_2020.txt`): MM +29,4%/18,8%, ARIMA −0,7%/23,2%,
      versão A +0,6%/19,7%, versão B −12,0%/37,7% (sem GARCH −50,3%/59,8%),
      PETR4 −7,2%/64,2%. **Leitura honesta: em 2020 as médias móveis protegeram
      tanto quanto a versão A e renderam mais.** Script novo
      `ferramentas/scripts/recorte_ano.sh`, conferido contra `anual_R6.csv` e
      `anual_R3_T1.csv` (retornos idênticos). O Apêndice B virou a última seção
      do Cap. III ("Verificação estatística e testes complementares").
    - Considerações: pandemia; janela curta para o GARCH (Hwang e Valls Pereira,
      **marcado para leitura**); janela expansiva como trabalho futuro (Xing).
    - `tg/.latexmkrc` novo: a compilação automática do VS Code (latexmk) não
      rodava o `citacoes_abnt.pl` e saía "(ALMEIDA, 2016)"; testado numa cópia
      isolada, com e sem o arquivo.
62. **[resultado] Bateria de 15/10/2026 (madrugada), a pedido do autor ("rode
    todos os testes que falamos").** Tudo em `dados/resultados/bateria_2026-10-15/`
    (LEIAME, PROTOCOLO escrito antes dos testes, resumo.txt). **O texto do TG
    não foi alterado: decisão do autor.**
    - **Máxima verossimilhança condicional no ARIMA: implementada (opção
      `MetodoARIMA` do EA, desligada, `//@omitir`), validada e NÃO adotada**
      pelo critério do protocolo: melhor em 2 de 4 casos, muito pior com raízes
      quase canceladas (0,48 x 0,27), AIC acertando a ordem bem menos (12% x 40%;
      8% x 58%), 6 a 196 vezes mais lenta
      (`dados/verificacao/validacao_mv_arima_2026-10-15.txt`). Isso dá ao texto
      uma defesa testada do Hannan-Rissanen.
    - Regressão: caminho HR idêntico byte a byte (R6 GS refeito); médias móveis
      idênticas às de 05/10; cenário de Almeida 2013-2016 igual.
    - Critério único, fator de recuperação do MT5 (>= 12 negociações): escolheu
      sempre filtro + ajuste do tamanho (`Estrategia=3`) e reescolheu a antiga
      versão A em 2013-2016 e nas fixas, a antiga B em 2025-2026 e **no teste
      principal (2017-2024)**, e a que era A e B em 2007-2011. Pandemia
      (otimização 2017-2019, teste 2020-2021) é nova.
    - Risco, camada 1: com GARCH x sem GARCH, queda e volatilidade menores em
      7 de 7 (Pitman-Morgan p ~ 0). x médias móveis: volatilidade menor em
      todos; queda maior em 2017-2024 (40,2 x 37,9) e na pandemia (34,5 x 30,4).
      **Análise posterior:** esses dois são exatamente os períodos em que a
      configuração escolhida não fecha a posição no veto.
    - Retorno cru: médias móveis rendem mais que o GARCH em 4 de 5 períodos
      (exposição do GARCH de 17% a 25%, caixa sem rendimento no cru). Com a
      Selic no caixa, o GARCH passa em 2017-2024 (114,1% x 90,4%). **Usar o cru
      como principal piora bastante o retorno do GARCH no texto; é o custo da
      proteção e precisa ser explicado na seção de camadas.**
    - Pandemia: médias móveis melhores em retorno e em queda; GARCH protegeu
      muito em relação ao ARIMA (queda 34,5% x 60,0%).
    - Sharpe na camada 1 não tem sentido (caixa rende zero); usar camada 3.
63. **[resultado] Exploratório da estimação (15/10/2026, manhã), curiosidade do
    autor.** `dados/resultados/bateria_2026-10-15/exploratorio_estimacao/LEIAME.md`.
    Implementação da MV conferida contra busca exaustiva (19 de 20 no mínimo; 1
    ótimo local). O HR "escolhe melhor" a ordem porque é impreciso nos modelos
    grandes (ganho de logL do (4,4): +1,09 x +7,16 da MV), o que trava o
    sobreajuste do AIC; MV + BIC acerta mais (103 x 89 de 150). Opção nova
    `SelecaoPorBIC` (`//@omitir`, padrão AIC; regressão byte a byte ok). Mercado,
    mesmos robôs: nenhuma combinação domina; o retorno muda muito com a
    estimação (previsão frágil); **a proteção do GARCH vale em 20 de 20
    combinações (queda e volatilidade)**. Candidato a frase de robustez no TG,
    decisão do autor.
