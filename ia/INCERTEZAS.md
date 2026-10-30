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
2. **[dado] Custo de 0,03% por execução: CONFERIDO em 21/10/2026** com a
   tabela oficial da B3 (FONTES, item 8): 0,0300% para ações à vista, sem day
   trade, ADTV até R$ 3 milhões. Continua valendo a ressalva: Emolumentos mudaram ao longo de
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
    título. Foram corrigidos conferindo autor e ano (ver `ia/bibliografia/BUSCA.md`).
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
    análise quantitativa — está justificada em `ia/NORMAS-FATEC.md`, seção 5, mas
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
    (backup em `ia/rascunhos/antes_refacao_2026-10-06/`). O que mudou de
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
    dados errados")**; backup em `ia/rascunhos/antes_revisao_2026-10-12/`:
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
    abstract. Backup em `ia/rascunhos/antes_foco_risco_2026-10-13/`. Números em
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
    `ia/rascunhos/antes_legibilidade_2026-10-14/`.
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
    `ia/rascunhos/antes_reestruturacao_2026-10-14/`.
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
    `ia/rascunhos/antes_simplificacao_2026-10-14/`.
61. **[texto] Varredura do autor (15/10/2026), lista colada na conversa.** Backup
    em `ia/rascunhos/antes_varredura_autor_2026-10-15/`. TG com 52 páginas,
    0 estouros, sem referência quebrada.
    - Cap. I: figuras e tabelas fixas no lugar (REVOGADO em 22/10/2026, a pedido do autor: ilustrações em `[htbp]`, pacote `float` retirado; ver item 76) (`[H]`, pacote `float` carregado
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

64. **[código e texto] Sessão de 18/10/2026: limpeza do código e preparação da
    entrega à orientadora**, a pedido do autor. Resumo e pendências em
    `ia/PENDENCIAS.md`, seção 0.
    - **Código**: reorganizado sem mudar resultado. Regressão byte a byte em 13
      casos (`ferramentas/scripts/regressao_codigo.sh`, 29 arquivos idênticos) e
      os três validadores em EA repetiram os arquivos de `dados/verificacao/`.
      Commit anterior à limpeza: `a3b21b9`. A limpeza ainda não foi commitada.
    - **Texto**: validação do código retirada (o autor: foge do escopo
      apresentado); seção estatística oculta com `\iffalse` (`OCULTO-18/10`);
      considerações, resumo e abstract apoiados só no que ficou visível (11 de 11
      em risco, 9 de 11 em retorno contra a mesma configuração sem GARCH);
      objetivo específico "implementar e validar" virou "implementar" (**a
      confirmar com a orientadora**: o PTG pode ter "validar"); título novo;
      caderno de delineamentos da FATEC-ID citado.
    - **Não confirmado**: o gradiente descendente da versão antiga divergir com a
      escala do preço é dedução, nunca medida (PENDENCIAS, item 1). O Wazlawick
      definir "quase experimental": não verificável sem o livro, por isso não foi
      citado para isso. A gestão de dinheiro do Almeida voltar ao volume fixo com
      stop zero: lembrança do livro, não conferida.
    - **Sem fonte**: a convenção de 252 dias úteis (procurada em todas as obras
      do projeto e na página da Selic do BCB).
65. **[leitura] Almeida (2016) e a Selic (19/10/2026, pergunta do autor).** Almeida
    afirma que, fora da crise, a PETR4 rendeu "superior a taxa da SELIC" (resultados e
    conclusão). O resultado dele em 2013-2016 foi +R$ 10.430 sobre R$ 50 mil,
    ou +20,9% em três anos, comparado no texto dele com a Selic anual de 14,25%
    (2016). A Selic acumulada no mesmo intervalo, 22/05/2013 a 23/05/2016, calculada
    de `dados/series/selic_diaria.csv` (SGS 11, 757 pregões), foi de **+39,3%**.
    Leitura nossa, **não confirmada com o autor**: ele parece ter comparado o
    retorno de três anos com a taxa de um ano. Nos testes deste TG, as médias móveis
    reproduzidas ficaram acima da Selic em 4 de 5 períodos, mas em outras condições
    (95% do patrimônio, só compra, caixa na Selic), nenhuma com p < 0,05. Nada disso
    está no texto do TG.
66. **[resultado] A camada do retorno nas tabelas do Cap. III (19/10/2026).**
    As Tabelas 3 a 6 e os Gráficos 1 a 3 usam `ret_selic`/`dd_selic`/`vol_selic`
    (camada 3: retorno puro − custos + fração parada × Selic do dia,
    `robos/Include/Desempenho.mqh`, linhas 362-366). Proventos não entram em nenhuma
    tabela (só na nota da Tabela 5). As Tabelas 1 e 2 são puras. O autor tinha
    pedido "pura primeiro", e a bateria de 15/10 seguiu isso, mas o Cap. III é da
    refação de 05/10 e continuou na camada 3. Efeito: favorece quem fica fora do
    mercado (exposição média GARCH 0,09-0,44 × MM/ARIMA 0,43-0,62). Na camada
    pura (`ret_puro`, `dd_puro`, `vol_puro` dos mesmos `metricas_*`): risco 11 de
    11 mantido; retorno GARCH > mesma configuração sem ele cai de 9 para 7 de 11;
    2007-2011 GARCH −8,4% (texto +28,7%); 2008 −4,4% (texto +5,0%); fixas
    2005-2026 B +33,5% (camada 3 +669,9%), MM +305,5% (camada 3 +985,2%), Selic
    +795,8%. Contra a Selic, a comparação certa é a camada 3: o ARIMA-GARCH
    passa em 2 de 11 testes (2017-2024, A e B), nenhum com p < 0,05 (melhor
    p = 0,085). **Decisão do autor pendente.** Nesta conversa, eu tinha passado
    ao autor números de longo prazo na camada 3 sem dizer qual era a camada
    (corrigido na mesma conversa).
67. **[referência] Busca dos PDFs das obras citadas (19/10/2026, pedido do autor).**
    Baixados e conferidos pela 1ª página: Bollerslev (1986) e Araya (2024), em
    `bibliografia/pdfs/` (procedência em `ia/bibliografia/OBRAS-DO-TG.md`). Dois erros
    no `tg/referencias.bib`, **ainda não corrigidos** (decisão do autor):
    (a) `araya2024`: autores e periódico errados. Confirmado no PDF e no Crossref:
    Araya, Hailabe T.; Aduda, Jane; Berhane, Tesfahun, *Journal of Applied
    Mathematics*, v. 2024, Article ID 6305525. No texto sairia "Araya, Aduda e
    Berhane (2024)".
    (b) `fernandes2014`: a editora "Campus" **provavelmente está errada**. Pela busca
    (Skoob, Magazine Luiza), o livro é edição do próprio autor, Alexandre Fernandes
    (marca Palex), Rio de Janeiro, 1ª ed. 2014, 2ª ed. 2017, ISBN
    978-85-917091-0-6. **Não confirmado** em fonte oficial (Biblioteca Nacional,
    ficha catalográfica) nem em qual edição o ISBN se aplica.
    Os três livros (Elder 2002, Fernandes 2014, Wazlawick 2014) não têm cópia legal
    aberta. O que o texto atribui a eles (Cap. I, l. 57, 71, 73, 92, 99; Cap. II,
    l. 58 e 69; introdução, l. 103) **não pôde ser conferido** contra as obras nesta
    sessão. Todas essas citações são indiretas, sem página.
    **Atualização (19/10/2026, mais tarde):** o autor obteve os PDFs do Wazlawick e
    do Fernandes (ver `ia/bibliografia/OBRAS-DO-TG.md`). O Fernandes confirmou (b):
    editor é o próprio autor, não a Campus, 1. ed. 2014, ISBN 978-85-917091-0-6.
    O Wazlawick é a **3. ed. (LTC, 2021)**, não a 2. ed. (Elsevier, 2014) do `.bib`.
    Feito a pedido do autor: `.bib` corrigido nas três entradas (`araya2024`,
    `fernandes2014`, `wazlawick2014` → `wazlawick2021`), chave trocada no
    `cap0` e no `cap2`, TG recompilado (47 p., sem citação indefinida). Conferido
    contra os PDFs: os quatro trechos do Fernandes e as definições de explicativa
    e experimental do Wazlawick batem. Duas ressalvas para o autor decidir:
    (1) na 3. ed., "quanto à natureza" é primária/secundária/terciária (seção 4.1);
    "empírica" e "aplicada" vêm da classificação das **ciências** (2.2 e 2.3), não
    da pesquisa. A frase da introdução ("Quanto à natureza, a pesquisa é empírica")
    mistura as duas. (2) A seção 4.3 define quase experimento (objetos não
    selecionados aleatoriamente), o que pode sustentar a frase marcada "sem fonte"
    no `cap2` (l. 72). Não inserido: o autor lê e decide (regra nº 3).
    Elder (2002) continua sem PDF e sem conferência.
68. **[texto] Cap. III na camada crua (19/10/2026), decisão do autor sobre o item 66.**
    O autor pediu a comparação dos modelos crua primeiro e custos, Selic e
    proventos depois, um período por seção, sem tabelas juntas e com mais
    gráficos. Feito: tabelas e gráficos dos períodos na camada 1
    (`refeito_2026-10-05/cru/`, LEIAME); seção nova "Efeito dos custos, da Selic e
    dos proventos" com uma tabela por período; Tabela 8 com as onze comparações
    com e sem GARCH; gráficos do saldo do MT5 (ARIMA × ARIMA-GARCH) por período;
    gráfico da exposição em 2007-2011. Frases que mudaram: 2007-2011 deixou de ser
    "único com retorno positivo" (cru −8,4%, ainda o que menos perdeu); 2008 de
    +5,0% para −4,4%; retorno maior que a mesma configuração sem GARCH de 9 para
    **7 de 11**; risco 11 de 11 mantido; quatro ações com as faixas cruas. Cap. II
    (plano experimental) descreve as quatro camadas e diz que a escolha foi na
    camada 3. Considerações ajustadas (2008, "sete das onze", Selic "considerados
    os custos e a remuneração do caixa", proventos). Na conferência dos gráficos do
    MT5 pelos relatórios `.htm`, duas frases do rascunho estavam erradas e foram
    corrigidas antes de entrar: o mínimo do ARIMA em 2007-2011 é R$ 70,5 mil, e a
    queda perto da negociação 67 em 2017-2024 é de junho de 2018 (PETR4 −47,9%),
    não da pandemia. Os gráficos antigos de `tg/graficos/rodada3/` deixaram de ser
    usados. A seção estatística oculta continua na camada 3.
    **Nome no texto (19/10, pedido do autor):** a camada 1 se chama "resultado
    bruto" no TG (antes "cru"), no mesmo sentido do "lucro bruto" de Almeida:
    antes de custos. Não confundir com o "Lucro Bruto" do relatório do MT5, que é
    a soma das operações ganhadoras. Pastas e scripts continuam com `cru`.
    **Nomes das versões (19/10, pedido do autor):** "versão A/B" virou
    "ARIMA-GARCH Sharpe/Calmar" no Cap. II, no Cap. III (prosa, tabelas, seção
    oculta) e nas legendas dos gráficos. O Cap. II diz que o nome indica só o
    critério de escolha, não o resultado no teste. Backup em
    `ia/rascunhos/antes_nomes_sharpe_calmar_2026-10-19/`. Ao fazer esse backup,
    o de `antes_cap3_cru_2026-10-19/` foi sobrescrito por engano (cap2 e cap3);
    restaurado do histórico de arquivos da sessão (cap2) e de duas reconstruções
    independentes que deram idênticas (cap3).
    **Grade no Cap. II (19/10, pedido do autor):** voltou um Quadro com as 344
    configurações (8 de base × parâmetros de cada forma), conferido contra
    `refeito_2026-10-05/grades/r3_*.txt`, e o texto passou a dizer que elas foram
    geradas pelo otimizador do testador do MT5 (algoritmo completo), uma forma
    por vez, com o critério aplicado sobre os arquivos que o robô gravou. Backup em
    `ia/rascunhos/antes_grade_cap2_2026-10-19/`.
    **Outras ações no Cap. III (19/10, pedido do autor):** seção curta "Outras
    ações", no fim do capítulo, com VALE3, USIM5 e POMO4 (resultado bruto das
    escolhas só compra, `cru/outras_acoes.txt`). Três escolhas não operaram no
    teste (VALE3 2025-26 Sharpe, USIM5 2025-26 Sharpe e Calmar); o motivo não foi
    investigado (não confirmado se foi veto permanente ou previsão mínima). Sem
    médias móveis nessas ações. Backup em `ia/rascunhos/antes_outras_acoes_2026-10-19/`.
69. **[texto] Hannan e Rissanen (1982) citado no Cap. II (20/10/2026), autorizado
    pelo autor** para o funcionamento do método. Dados conferidos no Crossref
    (DOI 10.2307/2335856; o Crossref só dá a página inicial, 81; o fim, 94, vem do
    resumo da Oxford). O texto original não foi lido (pago). Para o porquê da
    escolha, recomendado só Gómez e Maravall (1998), p. 10 e 27-28, ainda **não
    inserido**: falta o autor ler. Backup em
    `ia/rascunhos/antes_citar_hannan_2026-10-20/`.
    **Atualização (20/10):** Gómez e Maravall (1998) inserido no Cap. II, a pedido
    do autor, como a única referência do porquê (frase no fim do parágrafo do HR).
    No `.bib` como `@book` com `series` (o `@techreport` do abntex2 perdia a
    editora) e acentos em comando LaTeX (UTF-8 saía "GóMEZ" na lista). Backup em
    `ia/rascunhos/antes_citar_gomez_2026-10-20/`.
70. **[texto] Formas de uso do GARCH explicadas e Harvey et al. (2018) citado
    (21/10/2026, pedido do autor).** O autor achava que todos os robôs do Cap. III
    usavam só o filtro; o texto nunca dizia a forma de cada um. Conferido nos
    arquivos de escolha (`refeito_2026-10-05/escolhas/r3_C*.txt`, `r6_C4.txt`) e
    nas métricas dos testes: todos os escolhidos da PETR4 usam o filtro; o Calmar
    é filtro e ajuste da posição em todos os períodos; o Sharpe é filtro e ajuste
    em 2007-11 e 2013-16 e só filtro em 2017-24 e 2025-26; as fixas são filtro e
    ajuste; o cenário de Almeida é só filtro, sem encerrar no veto. Nas outras
    ações o intervalo de confiança foi escolhido 5 vezes. O ajuste da posição
    sozinho nunca foi escolhido.
    - **Cálculo exploratório, não está no TG:** se a escolha fosse restrita ao
      filtro (mesmas grades, nada simulado de novo), a queda máxima do Sharpe em
      2007-11 iria de 17,5% para 41,4% (ARIMA 45,1%). Script no scratchpad,
      descartado. O autor decidiu manter as formas como estão.
    - **Harvey et al. (2018)** citado para a definição de volatility targeting e
      a persistência da volatilidade (p. 14; regra alvo/volatilidade na p. 16,
      igual à do EA). PDF da página do próprio autor em Duke, em
      `bibliografia/pdfs/Harvey-2018.pdf` (sha256 16052c1d...). **Citado a pedido
      do autor antes de ele ler: leitura indicada das p. 14 a 16.** Moreira e Muir
      (2017) não entrou (escalam pela variância, não pela volatilidade).
    - Cap. II: Quadro "Formas de uso do GARCH"; escolha explicada em três passos,
      refeita em cada período; 252 dias apoiado só na média de 248 pregões da
      série; custo de 0,03% declarado como premissa; Wazlawick (2021) passou a
      sustentar a frase do quase experimento; COTAHIST cita `b3Cotahist`.
    - Cap. III: Quadro "Forma de uso do GARCH em cada robô escolhido"; frase do
      Calmar 2017-24 corrigida (dizia "proteção mais consistente quando o robô
      reduz a posição", mas esse robô também ajusta a posição; o que o distingue é
      não encerrar no veto); a frase das quatro ações explica os dois grupos do
      `analisar_grades.sh` (`Gred` = ajuste ou encerrar no veto) e não liga mais o
      resultado ao Calmar 2017-24, que pertence ao primeiro grupo. Cap. IV com a
      mesma correção.
    - O sumário ocupa duas páginas (desde a seção "Outras ações", de 19/10), não
      por causa desta mudança.
    Backup em `ia/rascunhos/antes_formas_garch_2026-10-21/`.
    **Atualização (21/10, mais tarde), pedido do autor:** o Quadro "Formas de uso
    do GARCH" saiu ("fica feio"). O conceito (filtro, volatility targeting com
    Harvey, combinação) foi para o Cap. I, nova subseção 1.4.4 "Uso da
    volatilidade prevista na operação", com a frase dos 60+ ativos (Harvey, p. 14).
    A seção 2.4 do Cap. II virou sete subseções (preparação dos preços, ARIMA,
    GARCH, janela, funcionamento do robô, uso do GARCH na decisão, parâmetros do
    robô), só com o "como foi implementado". Texto novo, sem número novo; a frase
    "restrições impostas dentro da rotina de otimização" vem do `Garch.mqh`
    (MinBLEICSetBC/SetLC). O sumário passou a ter 7 linhas a mais. Backup em
    `ia/rascunhos/antes_subtopicos_implementacao_2026-10-21/`.
71. **[escopo] Intervalo de confiança fora do TG (21/10/2026, pedido do autor:
    "só quero F e T, retire tudo que foi testado com essa parte").** Motivo
    declarado: tamanho do escopo, não o resultado. A forma continua no código do
    EA (`INTERVALO_CONFIANCA`, input `K_Confianca`, que aparece numa linha do
    Apêndice A); fica citada só no Cap. I como forma que existe e não foi usada.
    - **As 32 configurações por janela foram simuladas e descartadas antes da
      escolha.** Como cada simulação é independente, escolher entre as 312
      restantes dá o mesmo que rodar só as 312. O texto descreve a grade de 312
      (rodada 4: 624 e 14.976 simulações; eram 344, 688 e 16.512). A decisão veio
      depois de o autor ver onde a forma tinha sido escolhida (5 células das
      outras ações), registrado aqui por transparência.
    - **PETR4 não muda em nada**: `escolher.sh` sem o IC dá as mesmas GS, GC e AS
      em C1 a C4, só compra e com venda (conferido). Tabelas, gráficos, telas do
      MT5, configurações fixas e cenário de Almeida ficam iguais.
    - **Outras ações**: mudam 5 células (VALE3 Sharpe 2007-11, 2013-16 e 2025-26,
      USIM5 Sharpe 2013-16, POMO4 Calmar 2013-16). `outras_acoes.sh` filtra o IC
      por padrão (`SEM_IC=0` reproduz a versão antiga byte a byte, guardada em
      `cru/outras_acoes_com_ic_2026-10-19.txt`). Tabela conferida célula a célula
      (36 de 36). Só USIM5 2025-26 segue sem operar. Texto refeito: Calmar com a
      menor queda em 7 de 9 (exceção da VALE3 2025-26 agora é o Sharpe); Sharpe caiu
      mais que o ARIMA em 3 casos (antes 4), todos mantendo a posição no veto; a
      contagem de retorno saiu porque a POMO4 2013-16 é quase empate (ARIMA
      -20,975%, Calmar -20,996%).
    - **Quatro ações, dois grupos**: `analisar_grades.sh` ganhou `SEM_IC=1` (o
      padrão reproduz `analise_grades_cru.txt` byte a byte). Saída nova em
      `cru/analise_grades_cru_sem_ic.txt`: grupo que reduz 84-92% / 91-98% / 51-95%
      (antes 84-92 / 91-97 / 53-95); grupo que só congela 31-68% (antes 28-65%).
    - A seção estatística oculta ainda tem os números com IC (aviso no `.tex`).
    Backup em `ia/rascunhos/antes_tirar_intervalo_confianca_2026-10-21/`.
72. **[texto] Fóruns do MetaTrader 5 (21/10/2026, pedido do autor).** O autor leu
    artigos e fóruns da comunidade MQL5 durante o desenvolvimento, sem anotar
    todos. Entrou uma frase genérica, sem referência, na abertura da seção 2.4 do
    Cap. II ("foram consultados artigos e fóruns da comunidade do MetaTrader 5 para
    entender como esses métodos podem ser escritos em MQL5"). Recusado escrever
    que o código foi "validado" ou "feito" pelos fóruns: a validação foi com séries
    sintéticas (fora do texto desde 18/10), e os métodos vêm da literatura citada.
    Os dois artigos que ele confirmou ter lido (Dube, 2023, ARIMA por Powell; Dube,
    2024, ADF) chegaram a entrar como citação e saíram a pedido dele; ficam num
    comentário do `.tex` para a banca. Nenhum rastro deles no código. Backup em
    `ia/rascunhos/antes_citar_dube_2026-10-21/`.
    **Atualização (21/10):** a pedido do autor, a frase passou a dizer que o
    conteúdo da comunidade de desenvolvedores do MetaTrader 5 foi "uma das
    principais fontes" para entender como implementar os métodos em MQL5, sem
    enumerar tipos de material (ele não quis a lista).
    **Atualização 2 (21/10):** a frase passou ao plural ("os conteúdos produzidos e
    compartilhados pela comunidade") e ganhou a documentação oficial da linguagem
    como a outra fonte principal, citada como `metaquotesMql5` (Manual MQL5,
    https://www.mql5.com/pt/docs; cópia em `bibliografia/paginas/`, registrada em
    `dados/FONTES.md`). Com duas entradas da MetaQuotes de 2026, as citações saem
    "2026a" (Manual) e "2026b" (Relatório de teste), automaticamente.
    **Atualização 3 (21/10):** abertura da 2.4 reescrita em três parágrafos, a
    pedido do autor ("não foi do zero"): a implementação se apoiou na documentação
    e em exemplos e trechos de código da comunidade, adaptados (afirmação do autor
    sobre o processo; não há rastro de código copiado no repositório). Entrou o
    robô de médias móveis: reescrito a partir do algoritmo do anexo de Almeida
    (2016), com o `iMA` da plataforma, compartilhando `Negociacao.mqh` e
    `Desempenho.mqh` com o ARIMA-GARCH (conferido em `MediasMoveis2.mq5`).
73. **[texto] Plano experimental em subseções (21/10/2026, pedido do autor).** A
    seção 2.5 do Cap. II virou sete subseções, na ordem do Cap. III: condições das
    simulações, medição dos resultados, reprodução do estudo de referência
    (antes era o último parágrafo, "Antes de tudo isso"), configurações testadas,
    escolha da configuração, robôs comparados (novo agrupamento: ARIMA, médias
    móveis, compra e manutenção e a mesma configuração sem GARCH) e testes
    complementares. Nenhum fato ou número novo; saiu a frase repetida sobre a
    comparação no resultado bruto. Backup em
    `ia/rascunhos/antes_subtopicos_plano_2026-10-21/`.
74. **[réplica] Tentativa de chegar aos números de Almeida (21/10/2026, pedido do
    autor: "tente de tudo").** Resultados em
    `dados/resultados/replica_almeida_v2_2026-10-21/LEIAME.md`. O que é fato e o
    que é hipótese:
    - **Fato (log do testador):** sem histórico suficiente antes da data inicial,
      o testador adia o início até ter 100 barras ("start time changed ... to
      provide data at beginning"), sem erro. Com histórico desde 02/01/2008, os
      testes de 2007 e 2008 começam em 02/06/2008.
    - **Não confirmado:** que o servidor MetaBrazil-Demo tivesse a PETR4 só a
      partir do início de 2008. É a explicação que melhor reproduz a Figura 13
      (entradas de julho a dezembro iguais), mas a contagem 52/37 também sai de
      outras datas de início (com uma data livre, é fácil acertar).
    - **Não confirmado:** que a série dele fosse ajustada por proventos. Melhora o
      lucro bruto em todos os testes (a menos de 6% do dele) e acerta a contagem
      de T2, T3 e CIEL3, mas piora o desenho mensal de CIEL3 e VLID3.
    - **Estimativa:** os fatores das bonificações da CIEL3 (a API da B3 não traz
      2012 a 2016) e a leitura das barras das figuras dele.
    - **Sem explicação:** a perda bruta dele é 4% a 15% maior que a nossa em todos
      os testes; nenhum custo uniforme fecha os cinco ao mesmo tempo. E 4
      operações a mais em T1, num zigue-zague de 03 a 08/06/2011.
    - **Contagem do LEIAME antigo:** `replica_almeida_2026-09-28` comparava as
      "saídas" do EA (37) com as 37 dele em 2008–2010, mas o relatório do MT5
      conta também o fechamento forçado no fim (38). Os números de operações
      desta rodada são todos o "Total Trades" do relatório, como os dele.
    - **Figuras dele inconsistentes:** a Figura 14 (por dia da semana) soma 22
      entradas, não 37; as Figuras 15 e 16 (MFE/MAE, ~350 pontos com lucro de
      ±100) não podem ser do teste de 38 operações com 1.000 ações.
    - **Ambiente:** a importação usa o perfil de gráficos `AlgoLab`
      (`PERFIL=AlgoLab` no `importar.sh`), porque o Default está no limite de 100
      gráficos (item 54); o `Config/common.ini` do autor é devolvido e conferido.
      A armadilha do zsh (`set -- $p` sem separar palavras) voltou a acontecer e
      reimportou os `_B3` com os mesmos CSVs (sem dano). O
      `MQL5/Files/import_OFICIAL_resultado.txt` do prefixo novo foi sobrescrito
      pela importação da VLID3 (mesmo sufixo; é só log).
    - **Módulos do anexo conferidos (21/10, tarde):** o código-fonte oficial do
      livro de Young (2013), de onde vêm os `.mqh` que o anexo inclui e não traz,
      foi obtido (FONTES, item 13). O anexo é o EA "Moving Average Cross" do
      livro com os nomes traduzidos. Confirmado: com `StopLoss = 0` a gestão de
      dinheiro devolve o volume fixo (0,1, elevado ao mínimo do símbolo pelo
      `VerifyVolume`); a inversão soma o volume da posição; a barra nova ignora a
      primeira chamada. Diferença achada: o `CIndicator::Main` arredonda a média
      para `_Digits` antes da comparação. Acrescentado ao `ReplicaAlmeidaEA`
      (`ArredondarMedias`, padrão desligado) e rodado nas 14 séries (`_n1`):
      muda de 0 a 2 operações e até R$ 1.940; resultado misto em relação a ele.
      **Não confirmado** que o volume mínimo da PETR4 no servidor dele fosse 100
      nem que ele usasse o módulo sem alterar.
    - **TG (21/10, noite, pedido do autor):** a Tabela 1 continua a mesma; o
      parágrafo seguinte agora explica o adiamento do testador e o ajuste por
      proventos, com 54, 37 e 38 operações (linhas `_n1`), e diz que nada disso
      pode ser confirmado.
    - **TG (29/10/2026, pedido do autor): a coluna da hipótese passou a ser só o
      histórico desde 2008**, sem proventos e sem arredondar as médias (linhas
      `ra_T1d8`/`ra_T2d8_m2_e0_r0` e `ra_T3d8_m2_e0_r0`, este rodado em 29/10 com
      `replica_almeida_v2d.sh` e igual ao `ra_T3of`). Líquido: 50 · −2.530,
      35 · −1.482 e 37 · +10.050, contra 52 · −2.542, 37 · −1.595 e 38 · +10.430
      dele. É a combinação mais próxima no líquido (soma das distâncias 505,
      contra 1.061 com arredondamento e 1.562 com proventos e arredondamento).
      **O líquido bate por compensação**: lucro bruto 1.003 e 844 acima do dele,
      prejuízo bruto 991 e 731 acima. O texto diz isso, diz que proventos e
      arredondamento foram testados sem aproximar o conjunto, e chama o início em
      2008 de hipótese. O arredondamento está no código do livro de Young e foi
      deixado de fora por escolha do autor, por não aproximar o resultado.

75. **[dado/texto] Sem Yahoo no TG; custo e proventos com fonte oficial; seção
    estatística e intervalo de confiança removidos (21/10/2026, pedido do autor).**
    - **Custo de 0,03%:** conferido na tabela oficial da B3 (item 2, FONTES item 8)
      e citado no Cap. II (`b3Tarifas`). A frase "premissa não conferida" saiu.
      Continua sendo a tabela de 2026 aplicada a todos os anos (dito no texto).
    - **Proventos:** a camada 4 passou do Yahoo para a B3 (FONTES item 3). Os 15
      testes das tabelas de camadas foram refeitos
      (`refeito_2026-10-05/proventos_b3/`); só as colunas de proventos mudaram.
      Maiores mudanças: PETR4 com proventos em 2017–2024 +726,5% → +777,9%;
      ARIMA 2017–2024 +331,1% → +356,6% (passa a GS, +353,0%); PETR4 2007–2011
      −1,2% → +2,0%. 2013–2016 não muda na primeira casa decimal.
    - **Desdobramento de 2005:** o texto cita o comunicado da Petrobras (Form 6-K,
      SEC) no lugar do Yahoo. O arquivo não foi guardado (a SEC bloqueia download
      automático sem e-mail; FONTES item 2). `yahooPetr4` saiu do `.bib`. O Yahoo
      só aparece no Quadro 1, como fonte de dados de Xing e de Araya (fato sobre
      eles).
    - **Seção estatística oculta: removida** (não só oculta). Ficaram as frases
      alternativas que já apareciam no PDF. Cópia anterior dos `.tex` em
      `ia/rascunhos/antes_remover_estatistica_2026-10-21/`. As colunas de
      teste continuam no código e nos resultados (`comparacoes*.csv`).
    - **Intervalo de confiança: retirado do código** (`Estrategia.mqh`, input
      `K_Confianca`, coluna `K_Confianca` das métricas, caso `RG_intervalo` da
      regressão). `FILTRO_E_TARGETING` continua valendo 3. CSVs antigos têm a
      coluna, os novos não; os scripts leem por nome. Regressão: ver
      `/tmp/algolab-trabalho/regressao_*_ic` (resultado no fim deste item).
      **Resultado (21/10, 23:02):** os 12 casos restantes saíram idênticos byte a
      byte (12 curvas, 3 traços, 3 métricas das médias móveis) e as 9 métricas do
      EA idênticas depois de tirar a coluna `K_Confianca` da versão anterior. EA
      compilado no prefixo novo com 0 erros e 0 avisos; listagem do Apêndice A
      regenerada (294 linhas). **O clone do prefixo novo está com os arquivos
      copiados, não com `git pull`**: depois do commit, fazer `git checkout -- .`
      e `git pull` lá.
    - **Seção de camadas do Cap. III removida (21/10, pedido do autor).** As
      quatro tabelas (custos, Selic, proventos) saíram; o Cap. III fica só com o
      resultado bruto. O Cap. II diz que custo e Selic entraram apenas na escolha
      das configurações (Sharpe e Calmar). Nas Considerações saíram a frase da
      Selic e a de "janela curta para o GARCH"; o limite dos proventos virou uma
      frase. Os números das camadas continuam em `refeito_2026-10-05/cru/tabelas.txt`
      e `proventos_b3/tabelas_camadas.txt`. Cópia anterior dos `.tex` em
      `ia/rascunhos/antes_auditoria_2026-10-21/`.

76. **[texto] Hipóteses e objetivos reescritos; polimento da auditoria (22/10/2026,
    pedido do autor).** Cópia anterior dos `.tex` em
    `ia/rascunhos/antes_polimento_2026-10-22/`.
    - **REVERTIDO no mesmo dia, a pedido do autor: as hipóteses voltaram às do
      PTG** (texto idêntico ao de antes, inclusive "formuladas antes dos
      experimentos", que vale para elas), assim como a frase da taxa de acerto no
      Cap. II e os parágrafos das hipóteses nas Considerações (H1 parcialmente
      confirmada, H2 confirmada quanto ao risco). Ficou só a correção "a única
      escolhida na PETR4". O registro abaixo é da tentativa, guardado como histórico.
    - **Hipóteses diferentes das do PTG (desfeito).** O PTG (1.2.1) esperava "maior eficácia,
      aferida em termos de potencial de acerto e adequação ao risco"; a 1.2.2,
      avanço sobre as médias móveis com o ARIMA "com maior refinamento" na
      direção e o GARCH no risco. O texto agora diz: H1 = o GARCH reduz o risco
      (volatilidade e queda máxima) **sem alterar o acerto direcional**, deduzida
      da função de cada modelo (Cap. I); H2 = o ARIMA-GARCH tem risco menor que as
      médias móveis de Almeida, sobretudo em crise. Ambas confirmadas (H2 com duas
      ressalvas: GC 2017–2024 e a pandemia). **A frase "formuladas antes dos
      experimentos" saiu**, porque estas não foram: a mudança veio depois dos
      resultados e tem de ser dita à orientadora (o PTG aprovado tem as outras).
      A H2 é um recorte da 1.2.2 do PTG (a parte do GARCH e do risco); a H1 muda
      o sentido da expectativa sobre o acerto.
    - **Objetivos específicos** sem repetir o geral: estimadores e ordens; formas
      de uso da volatilidade; reprodução de Almeida conferida com os números dele;
      comparação de risco e retorno.
    - **Justificativa**: o mercado brasileiro como diferença em relação aos
      estudos relacionados (Xing, NVIDIA; Araya, Apple, ambos nos EUA, conforme o
      Quadro 1), resultados como referência para outras pesquisas.
    - **Auditoria aplicada**: custo nas limitações (resultado sem custo favorece
      quem negocia mais, o ARIMA; conferido: ARIMA tem mais negociações que o GS
      nos quatro períodos); "única escolhida" → "único escolhido na PETR4"; "não
      tende a repetir" → "nem sempre repetiu"; 2018 (outros robôs +50,1% a +53,9%,
      `cru/anual_R6.csv`); "perda bruta" → "soma das negociações com prejuízo";
      venda a descoberto com resultado no Cap. III (bloco 3 de
      `cru/analise_grades_cru_sem_ic.txt`: mediana, queda maior nos 12 casos,
      retorno menor em 7) e a escolha só compradora dita no Cap. II; parágrafo do
      intervalo de confiança fora do Cap. I; "observou-se" no histórico do
      testador; ADF a 5%; "Sharpe" no saldo de 2025–2026; Apêndice A com o envio
      de ordens; resumo e abstract com "e com quanto".
    - **Mantido**: PETR4 −48,6% na introdução (fechamento de 30/12/2019 a
      02/04/2020, FONTES); a Tabela de 2020 mede outra coisa (pior queda no ano,
      64,2%). As duas estão certas.
    - **Aviso de identificadores repetidos do LaTeX**: testado sem `hypcap` e com
      `hypertexnames=false`, não some; as duas âncoras ficam na página da própria
      ilustração (Figura 1, p. 12), então o link não erra. Deixado como está.
    - **Gráficos da pandemia (22/10, pedido do autor).** Dois gráficos novos na
      seção de 2020 do Cap. III (patrimônio e queda; preço e patrimônio aplicado),
      dados de `cru/curva_2020.csv`, `cru/exposicao_2020.csv` e
      `cru/exposicao_mensal_2020.txt` (`dados_cru.sh`; a rodada inteira do script
      não alterou nenhum arquivo antigo). Valores finais e quedas batem com
      `recorte_2020.txt`. Achado que entrou no texto: **em março de 2020 o ARIMA
      sozinho já estava quase todo fora (8,6% aplicado)**; o efeito do GARCH no GS
      foi manter o robô fora em abril e maio, e o ano terminou empatado (+1,0% ×
      +0,7%). A proteção grande do GARCH em 2020 é a do Calmar (37,7% × 59,2%).
      A exposição usa média de 5 pregões (e não 21, como em 2008) porque a queda
      durou um mês; está dito na nota do gráfico.
    - **Menos espaço em branco (22/10, pedido do autor).** Todas as ilustrações
      passaram de `[H]` (fixas, pedido do autor em 15/10, item 61) para `[htbp]`,
      com `\usepackage[section]{placeins}` e frações de float no `main.tex`; os
      saldos do MT5 foram a 85% da largura; o parágrafo dos Gráficos de
      2025–2026 passou para antes deles. TG de 64 para 60 páginas, sem estouro.
      Conferido por script (texto de cada página): 18 ilustrações na mesma página
      da primeira citação, 14 na seguinte, 1 a duas páginas (Gráfico 9, o
      terceiro gráfico grande seguido de 2017–2024, depois de uma página só de
      texto); nenhuma antes da citação nem fora da sua seção. Buracos que sobram:
      fins de capítulo e fins de seção. Cópia anterior em
      `ia/rascunhos/antes_ajuste_paginas_2026-10-22/`. **Para voltar ao fixo**:
      trocar `[htbp]` por `[H]` nos `.tex` (e opcionalmente tirar o placeins).

      **Adendo (22/10/2026, pedido do autor): Cap. III com subseções nos anos de
      crise.** 3.3 vira 3.3.1 O período completo e 3.3.2 O ano de 2008; 3.5 vira
      3.5.1 O período completo e 3.5.2 O ano de 2020 (a antiga seção da pandemia).
      A seção 3.2 explica que o ano da crise é recorte do mesmo teste, sem nova
      simulação, medido a partir do fechamento do ano anterior. Novo em 2008:
      Tabela "Resultado em 2008" (de `cru/recorte_2008.txt`), gráficos
      `curva_2008.pdf` e `exposicao_2008.pdf` (de `cru/curva_2008.csv` e
      `cru/exposicao_2008.csv`, gerados por `dados_cru.sh`), e o texto de outubro
      (0,0% × 56,4%, de `cru/exposicao_mensal_T1.txt`). O gráfico de exposição de
      2007–2011 saiu da seção "Como o GARCH protege", que agora remete aos dois
      anos e dá a média do período (20,1% × 45,6% da gêmea, das métricas). Os
      gráficos dos anos de crise ficaram mais baixos (6,2 + 3,9 cm e 4,6 + 4,6 cm)
      para caberem dois por página, e há `\FloatBarrier` antes de cada "O ano de",
      para os gráficos do período completo não invadirem o ano. TG com 62 páginas.
      Cópia anterior: `ia/rascunhos/antes_ajuste_paginas_2026-10-22/cap3-resultados_antes_subsecoes.tex`.
      Atenção: o `Makefile` do `tg/` não depende dos PDFs dos gráficos; depois
      de rodar `graficos_cru.sh`, dar `touch main.tex` antes do `make`.

      **Adendo 2 (22/10/2026, pedido do autor): regra das figuras fixas retirada.**
      O pacote `float` saiu do `main.tex` (nenhuma ilustração usa mais `[H]`).
      Ficam `[htbp]`, o `[section]` do placeins e os `\FloatBarrier` do Cap. III.
      Para caber mais por página, todos os gráficos de patrimônio ficaram com a
      mesma altura dos anos de crise (6,2 + 3,9 cm; antes 7,5 + 4,5) e os de retorno
      por ano com 6 cm (antes 7). Em 2025–2026, o parágrafo que citava os dois
      gráficos foi dividido, e cada parte ficou antes do seu gráfico (mesmo texto e
      mesmos números). Medido por script: 61 páginas, todas as ilustrações na
      página da citação ou na seguinte, nenhuma antes da citação. Os vãos que
      sobram são fins de capítulo e um de 28% no fim de 2008. Testado e
      descartado: placeins sem `[section]` (ilustração antes da citação). Cópia
      anterior em `ia/rascunhos/antes_imagens_2026-10-22/`.

77. **[texto] Tabela "Risco nas condições originais, 2013 a 2016" retirada
    (22/10/2026, pedido do autor).** O teste punha o ARIMA e o ARIMA-GARCH nas
    condições de execução de Almeida (R$ 50 mil, mil ações, sem custos, compra e
    venda), mas os parâmetros do modelo (limiar, forma de uso, janela) não podiam
    vir dele, que não fez ARIMA nem GARCH: vinham da configuração padrão do EA,
    fixada numa calibração antiga, fora do protocolo. Era um terceiro tipo de
    teste, híbrido, que exigiria explicar a origem da configuração. A seção 3.1
    fica só com a reprodução das médias móveis (Tabela 1 e o parágrafo das
    hipóteses da réplica de 21/10, item 74). Saíram também o parágrafo
    correspondente do Cap. II ("Por fim, o ARIMA e o ARIMA-GARCH foram executados
    nas condições declaradas...") e o trecho "inclusive nas condições originais
    do estudo de referência" das Considerações. Os números continuam em
    `refeito_2026-10-05/testes/metricas_cenA_1316_*`. Compila sem referência
    quebrada, 61 páginas; a antiga Tabela 3 virou a 2. Cópia anterior em
    `ia/rascunhos/antes_remover_condicoes_originais_2026-10-22/`.

      **Adendo 3 (22/10/2026, tarde, pedido do autor): figuras do Cap. III
      rearrumadas de novo.** Gráficos de patrimônio 5,6 + 3,5 cm (antes 6,2 + 3,9),
      exposição 4,0 + 4,0 cm (antes 4,6 + 4,6), painéis do MetaTrader 5 com 0,7 da
      largura do texto (antes 0,85). Em 2013–2016, o parágrafo que citava os
      Gráficos de patrimônio e de saldo foi dividido, cada parte antes do seu
      gráfico (mesmo texto). Página só de ilustrações agora empilha a partir do
      topo (`\@fptop` = 0 no `main.tex`). Resultado medido por script: 60 páginas
      (antes 61), Cap. III sem vão maior que 29% fora de fim de capítulo, nenhuma
      ilustração antes da citação; duas ficam duas páginas depois da citação
      (saldos do MT5 de 2007–2011 e 2017–2024), logo após uma página cheia de
      gráficos anteriores. Testados e descartados: `\floatpagefraction` 0,85 e 0,6.
      Cópia anterior em `ia/rascunhos/antes_imagens2_2026-10-22/`.

78. **[método] Janelas fixas: ARIMA 240 e GARCH 500 (26/10/2026, crítica da
    orientadora e pedido do autor).** A orientadora apontou que o GARCH estimado
    por máxima verossimilhança precisa de séries de 500 a 1.000 observações e que
    o robô usa no máximo 240. Conferido: o GARCH não tem janela própria, herda a
    do ARIMA (`Janela_Estimacao`, 120 ou 240 pela grade), e várias configurações
    escolhidas usam 120. No traço de 2019–2021 (janela 240) o β variou de 0,12 a
    0,92 e a persistência encostou em 1 em 159 de 496 dias.
    Nenhuma obra que já estava no projeto dá o tamanho da janela. O que existe:
    - Hwang e Valls Pereira (2006; versão de trabalho de 2003 em
      `bibliografia/pdfs/Hwang-2003.pdf`, baixada em 26/10): GARCH(1,1) por MV
      precisa de pelo menos 500 observações (resumo, p. 4 do PDF; conclusão,
      p. 30 do PDF / 26 impressa). Só fala de ARCH e GARCH, não de ARIMA.
    - Gómez e Maravall (1998, p. 28 impressa / 30 do PDF), já citado: o AR longo
      do 1º estágio de Hannan-Rissanen tem ordem log²(N) (com HR 1982, p. 88). Com
      240 pregões são 30 defasagens sobre ~209 equações; com 120, 22 sobre ~97.
    - Brooks e Persand (2003; `Brooks-2002.pdf`, p. 8 do PDF, não está no .bib):
      janela longa o bastante para estimar, curta o bastante para não usar dado
      que já não vale. Eles usam 1.250 dias.
    - Bollerslev (1986) estimou o GARCH(1,1) de exemplo com 143 observações
      trimestrais (contexto, não argumento).
    Proposta (plano A): ARIMA com 240 fixo (acompanha o mercado; HR se resolve),
    GARCH com 500 fixo (Hwang), janela fora da grade (312 → 156 configurações),
    aquecimento antes de cada teste para o testador ter os 500 pregões. Plano B,
    só texto: manter os testes e declarar a janela do GARCH como limitação.
    **Em 26/10 o autor pediu o estudo do plano A em separado**, sem mexer no TG:
    testes refeitos e um PDF só com o Cap. III nessas condições. Pasta:
    `dados/resultados/janelas_240_500_2026-10-26/` (PROTOCOLO e LEIAME lá).
    **Resultado (26/10, noite).** Bateria completa: 25 janelas de calibração com
    312 passagens (156 na C4) e 31 testes individuais. PDF em
    `documento/estudo.pdf` (17 páginas, Cap. III no mesmo molde). Números todos em
    `cru/`, gerados por `ferramentas/scripts/estudo_janelas_dados.sh`.
    - **Correção do que está acima:** "persistência encostou em 1 em 159 de 496
      dias" não se reproduz. Com o corte > 0,999 (`traco_resumo.sh`) são 144 de
      496 (29,0%); com ≥ 0,99, 171. O estudo usa 144 (29,0%).
    - **A janela de 500 melhora a estimação do GARCH:** no mesmo intervalo
      (07/2019 a 06/2021), persistência > 0,999 em 2,2% dos pregões, contra 29,0%
      com os resíduos da janela do ARIMA. α₁ mediano 0,22 contra 0,31 (0,12 em
      2017–2024 inteiro).
    - **Para a MESMA configuração, a janela quase não muda o resultado:** 3.648
      pares (4 ações × 3 períodos, ARIMA de 240): a queda máxima com 500 foi
      menor em 46,8%, igual em 9,4% e maior em 43,8%; mediana da diferença entre
      −2,8 e +1,8 p.p. em 22 de 24 grupos. As 96 passagens sem GARCH são
      idênticas nas duas versões (o aquecimento não muda nada).
    - **O que mudou foi a escolha.** A otimização passou a escolher, em 7 de 10
      casos, configurações que mantêm a posição no veto. GARCH × gêmea: queda
      menor em 9 de 12 (antes 11 de 11), volatilidade menor em 8 de 12. As
      quatro exceções são todas do ARIMA-GARCH Sharpe com só o filtro e mantendo a
      posição (2013–2016, 2025–2026 e as duas fixas). Nas oito em que o GARCH
      ajusta o tamanho ou encerra no veto, queda e volatilidade sempre menores.
    - Nas quatro ações, todas as configurações: o grupo que reduz a posição baixou
      a queda em 86–95% (2007–2011) e 86–100% (2013–2016) dos pares, 48–86% em
      2025–2026 (TG: 84–92, 91–98, 51–95). O outro grupo, 21–88%, sem padrão.
    - Números de destaque (bruto): 2007–2011 Sharpe +31,4% / queda 13,5% (TG
      −8,4% / 17,5%); 2013–2016 Sharpe −24,5% / 77,6% (TG −13,8% / 28,6%);
      2017–2024 Sharpe +64,6% / 37,0% (TG +199,5% / 27,2%), Calmar −15,4% / 21,6%
      com 4,4% de exposição média (limiar fixo de 2%).
    - Leitura (para o autor decidir, não confirmado como conclusão): a crítica da
      orientadora procede na estimação, e a janela de 500 a resolve. O efeito do
      GARCH sobre o risco continua onde ele reduz a posição. Os números das
      configurações escolhidas mudam muito, mas isso vem da fragilidade da escolha
      entre muitas configurações parecidas, já registrada (item sobre
      persistência entre calibração e teste), e não da janela.
    - Hwang e Valls Pereira (2006) está citado só no `estudo.bib` do documento do
      estudo. O autor ainda não leu a obra: ler p. 4 e p. 30 do PDF antes de levar
      ao TG.
    - Armadilha nova (CLAUDE.md): na otimização, linha sem `||` herda a marca Y do
      `.set`. A 1ª tentativa desta bateria foi interrompida por isso na C3 da
      PETR4 e retomada com faixa explícita; C1, T1, C2 e T2 da PETR4 foram
      conferidas (312 cada) e mantidas.
    - **Correção (27/10).** A leitura "vem da escolha, e não da janela" vale para 7
      dos 8 robôs. No ARIMA-GARCH Sharpe de 2017–2024 a configuração é a MESMA nas
      duas versões (`escolhas/r6_C4.txt` da refação e do estudo: filtro, pct 70,
      zera no veto, com constante, janela 240), e +199,5% → +64,6% vem só da janela
      do GARCH (e do limiar calculado sobre 500 dias). Os 3.648 pares cobrem só T1,
      T2 e T3. Dito errado ao autor em 27/10 e corrigido na mesma conversa; PDF do
      estudo e LEIAME corrigidos. De onde veio a diferença em 2017–2024: não
      confirmado.
    - Venda a descoberto com GARCH 500 (bloco 3 de `cru/analise_grades_cru.txt`):
      aumentou a queda máxima nos 12 casos e melhorou o retorno em 5 de 12.

79. **[método] Estudo de fatores com GARCH 500 (27/10/2026, pedido do autor).**
    Fora do TG. Pasta `dados/resultados/fatores_500_2026-10-27/` (PROTOCOLO
    escrito antes, LEIAME). Janelas fixas de 26/10 (item 78), só compra, e três
    fatores na grade: t de Student × normal, BIC × AIC, reseleção 63 × 21.
    1.232 passagens por janela, 25 janelas, 01h00 a 06h54. Passagens
    normal/AIC/21 idênticas às de 26/10 (conferido em todas as grades).
    - **Efeito pareado (grades de teste, 4 ações)**: t de Student com queda menor
      em 37,5% dos pares e maior em 37,7% (neutro; ν mediano 7 a 11, então as
      caudas pesadas existem, mas não mudam a decisão). BIC: menor 30,3%, maior
      43,3% (pior; retorno mediano de −12 a −23 p.p. em 2007–2011 na PETR4 e na
      VALE3). Reseleção 63: menor 37,6%, maior 45,0% (sem padrão).
    - **Robôs escolhidos (PETR4, `comparacao.txt`)**: contra o TG atual, queda
      menor em 5 de 12 e retorno maior em 6 de 12. Contra o estudo de 26/10,
      queda menor em 7 de 12. Com GARCH, queda menor que a da mesma configuração
      sem GARCH em 9 de 12 (as exceções: 2013–2016 Sharpe, 2005–2026 Calmar,
      2017–2024 fixa Sharpe). Em 2017–2024 os dois critérios escolheram a mesma
      configuração (filtro e ajuste com limiar fixo, t de Student), que ficou 8%
      do tempo exposta: −8,8%, queda 21,2%.
    - **Leitura**: nenhum dos três fatores melhora o robô de forma consistente.
      Somar opções à grade não estabilizou a escolha. O que se mantém nos três
      estudos é a proteção do GARCH em relação à mesma configuração sem ele.
    - Os modelos assimétricos (GJR) ficaram para depois da faxina do código.

80. **[texto] Correções da leitura da orientadora (27/10/2026, pedido do autor).**
    Backup do `tg/` em `ia/rascunhos/antes_correcoes_orientadora_2026-10-27/`.
    - **Proventos de volta, só B3** (Cap. II 2.3.1 e Medição; Cap. III, seção
      "Efeito dos custos, da Selic e dos proventos", Tabelas 9 a 12; números de
      `refeito_2026-10-05/proventos_b3/metricas_*.csv`). **Estimativa**: valor =
      percentual da B3 × fechamento da série corrigida na data-com, creditado na
      data-ex na proporção da exposição; sem imposto (JCP) e sem o prazo até o
      pagamento. Conferido em 27/10: a ordem dos robôs na queda máxima é a mesma
      em `dd_puro`, `dd_selic` e `dd_completo` nos quatro períodos, e só
      2017–2024 muda a ordem do retorno entre as etapas.
    - **Tabela 1 com a coluna das condições prováveis** (réplica v2, linhas
      `_n1`: 38/+11.100, 37/−1.202, 54/−2.043). As três condições (histórico
      desde 2008 com início adiado pelo testador, ajuste por proventos da B3,
      médias arredondadas em 2 casas) **não estão confirmadas** (item 74). A
      contagem é "Total Trades" do relatório do MT5 nas duas colunas nossas.
    - **Apêndice B**: Arima, SelecaoModelo, Garch e Estrategia reduzidos pelos
      mesmos marcadores do EA (`//@omitir`, `//@apendice:`), sem t de Student,
      BIC, máxima verossimilhança, janela própria do GARCH, mensagens de erro e
      relatório. Os `.mqh` mudaram só em comentário (saída do
      `sem_comentarios.sh` idêntica antes e depois, nos quatro e no EA). EA
      reduzido + quatro `.mqh` reduzidos compilam juntos: 0 erros, 0 avisos.
    - "A biblioteca padrão não traz modelos de séries temporais" virou "não traz
      os modelos ARIMA e GARCH" (Intro e Cap. II): a ALGLIB da plataforma tem SSA
      (`SSACreate` em `Math/Alglib/dataanalysis.mqh`); nenhuma ocorrência de
      ARIMA ou GARCH em `MQL5/Include` (grep em 27/10, build 6090).
    - Retirada a oração "aprofundando o conhecimento sobre a relação entre
      variáveis" (Cap. II 2.1.1), que não está em Wazlawick (2021).
    - Venda a descoberto: motivo no Cap. II (Condições) e no Cap. III (Outras
      ações); MM long-only dito em "Robôs comparados". Assimetria do GARCH em
      trabalhos futuros (Cap. I e Considerações). Janela do GARCH: **pendente**,
      decisão do autor.

81. **[texto] Apêndice A sem as opções que os experimentos não usam (29/10/2026,
    pedido do autor: "deixar puramente só o que está no texto").**
    - Marcadores novos no `ARIMA_GARCH_EA.mq5` (só comentário; saída do
      `sem_comentarios.sh` idêntica antes e depois, no EA e no `Garch.mqh`):
      saem `#property tester_file`, `ENUM_TRANSFORMACAO` / `ENUM_MODO_VOLUME` /
      `ENUM_MODO_ORDENS`, os inputs `Transformacao`, `ModoOrdens`,
      `ARIMA_p/d/q`, `GARCH_p/q`, `ModoVolume`, `StopLoss_Points`,
      `TakeProfit_Points`, `PermitirReversao` e o `Print` da validação. Na
      listagem: série sempre em log, ordens sempre por ADF e AIC,
      `g_garch.Definir(1, 1)`, ordens sem stop. No `Garch.mqh`, o
      `#include "Estatistica.mqh"` (só servia ao AIC/BIC do GARCH, já omitidos).
    - **Ficaram, porque estão no texto**: filtro, ajuste da posição (targeting)
      e os dois combinados (Quadro 2 do Cap. II e Quadro 5 do Cap. III), limiar
      fixo e por percentil, previsão mínima, constante, `SomenteCompra` (a venda
      a descoberto foi simulada) e `ZerarNoVeto`.
    - Listagem do EA de 293 para 231 linhas. EA reduzido + quatro `.mqh`
      reduzidos compilam juntos (build 6090, prefixo antigo): 0 erros, 0 avisos.
      O Apêndice A ganhou uma frase dizendo o que foi retirado. TG com 79 páginas.
    - **Segunda passada no mesmo dia** ("a forma mais pura da parte escrita"):
      saem os `input group`, a validação dos parâmetros no `OnInit`,
      `Iteracoes_GARCH` (fica `DefinirOtimizador(300)`), o guarda de preço do
      `VolumeDesejado` (o `Executar` já exige preço positivo), o parâmetro do
      tipo de ADF (sempre `ADF_CONSTANTE`), o campo `aic` do `ResultadoSelecao`
      (ninguém lia) e os destrutores do `CArima`, `CGarch` e `CDadosGarch` (só
      liberavam vetores dinâmicos, que a linguagem libera sozinha). EA 216
      linhas, Arima 373, Garch 300, Seleção 100, Estratégia 80. Código sem
      comentários idêntico nos cinco arquivos; listagem reduzida compila com 0
      erros e 0 avisos.
    - **Ficou de propósito**: o GARCH genérico (p, q) dentro da classe, que o EA
      chama com (1, 1); reescrever a classe só para (1, 1) faria o apêndice
      diferente do código que rodou.

82. **[método] Gráficos que explicam os métodos (30/10/2026, pedido do autor).**
    - `ferramentas/MetodosIlustrados.mq5` roda as funções do robô (MQO,
      `CArima`, `MenosLogVerossimilhancaGarch`, o MinBLEIC com as opções do
      `CGarch::Ajustar`, `TesteLjungBox`, `TesteADF`, `BuscarMelhorPQ`) na
      janela da validação numérica (PETR4_OFICIAL, 500 pregões até 18/09/2026).
      Dados em `dados/resultados/metodos_ilustrados_2026-10-30/`, figuras em
      `apresentacao/graficos_metodos/`. **Conferido**: ADF, ARIMA(1,1,1),
      GARCH(1,1), volatilidade prevista e os dois Ljung-Box idênticos aos da
      validação de 05/10; os dois estágios do Hannan-Rissanen refeitos passo a
      passo dão os mesmos φ e θ do `CArima`; o otimizador refeito com registro
      das iterações chega aos mesmos ω, α e β do `CGarch`. Não estão no TG.
    - **Escolha de ilustração**: os gráficos usam ARIMA(1,1,1) (o da validação)
      para o Hannan-Rissanen ter os dois estágios. Nessa janela o AIC escolheria
      (4,0); a figura do AIC mostra isso, e o (1,1) fica a 2,7 de AIC do melhor.
    - **Observação 1, não investigada**: na grade do AIC, modelos maiores podem
      ter log L **menor** que menores (ex.: (2,2) com 1338,0 contra (0,0) com
      1341,4). Esperado, porque o Hannan-Rissanen é MQO em dois estágios e não
      maximiza a verossimilhança; é o mesmo motivo de a máxima verossimilhança
      ter sido testada como opção (item 62). Pode virar pergunta da banca.
    - **Observação 2, não investigada**: no traço vigente
      (`refeito_2026-10-05/traco_demo/traco_demo_GARCH.csv`, jul/2019 a
      jun/2021), a persistência α + β está no limite da restrição (≥ 0,9998,
      limite 0,9999) em 140 de 496 pregões. Ou seja, em boa parte dos dias o
      otimizador para na parede da restrição. Possível causa (não confirmada):
      a janela inclui a crise de 2020. Não se verificou se isso muda alguma
      decisão do robô.

83. **[método] Gráficos do robô funcionando (30/10/2026, pedido do autor).**
    Figuras 08 a 14 de `apresentacao/graficos_metodos/`, lidas do traço da
    refação de 05/10 por `ferramentas/scripts/robo_em_acao.sh` (dados em
    `dados/resultados/robo_em_acao_2026-10-30/`). Não estão no TG.
    - **`ordem_enviada` conta só entradas.** O contador de `CNegociacao` só sobe
      em `Comprar` e `Vender`; `Fechar` não conta. Então "o EA enviou ordem"
      (72 com GARCH, 76 sem, nesta janela) quer dizer **entrou**; as saídas
      (71 e 75) só aparecem pela passagem de `posicao` de 1 para 0. O
      `.claude/CLAUDE.md` foi ajustado para dizer isso.
    - **Na queda de março de 2020 o GARCH não fez diferença nesta janela.** O
      ARIMA puro deu sinal de venda em 27/02/2020, o mesmo pregão em que o GARCH
      começou a vetar, e as duas versões ficaram fora durante a queda. A
      diferença entre elas está em 56 pregões em que só o ARIMA puro estava
      comprado (abril de 2020 e fevereiro de 2021, entre outros). Cuidado ao
      falar de "proteção na crise" com base no traço: ela não vem daqui.
    - **Acerto de direção do ARIMA no traço**: 249 de 490 pregões (50,8%), sem
      teste formal. Coerente com o walk-forward antigo (51,0%).
    - **O exemplo da figura 8 (19 e 22/02/2021) foi escolhido** por mostrar o
      mecanismo com o mesmo ARIMA(3,1,0) nos dois dias. Não é representativo do
      resultado: o GARCH reagiu à queda de sexta, não previu a de segunda.

84. **[método] Relatório de estudo sobre o Hannan-Rissanen (30/10/2026, pedido
    do autor).** `ia/relatorios/hannan-rissanen/relatorio.pdf`, dados em
    `dados/resultados/hannan_rissanen_2026-10-30/`. Não está no TG.
    - **Conferido**: os pregões de 13/05/2021 (ARIMA(0,1,1)) e 05/06/2020
      (ARIMA(0,1,4)), refeitos fora do robô, dão constante, θ e previsão
      idênticos aos do traço da refação de 05/10.
    - **O código não faz o terceiro passo** (correção do viés) que Gómez e
      Maravall (1998, p. 29) descrevem quando há MA, estima o AR longo por MQO
      em vez de Durbin-Levinson e usa a ordem max(⌊ln² N⌋, p+q+1), limitada a
      N/5, em vez de max(⌊log² N⌋, 2 max(p,q)). Nas mil simulações de ARMA(1,1)
      com θ = 0,4, o θ do HR teve média 0,380 (desvio 0,089) e o da máxima
      verossimilhança 0,410 (0,074). São escolhas de implementação, não erros,
      mas podem virar pergunta da banca.
    - **Ordem do AR longo numa janela pequena, não investigado**: com N = 239 a
      regra dá m = 29 (com d = 0, N = 240 e m = 30; o item 78 fala em "30
      defasagens sobre ~209 equações", que é o caso d = 0 arredondado). Numa série
      simulada, a qualidade dos erros estimados caiu à medida que m cresceu
      (correlação com o erro verdadeiro 0,99 com m = 4, 0,92 com m = 29). É uma
      série só, com coeficientes maiores que os da PETR4. Não se testou se uma
      ordem menor mudaria alguma decisão do robô.
    - **Tamanho do θ do robô**: num MA(1) simulado com o θ do pregão real
      (−0,093), o desvio da estimativa foi 0,077 e o sinal saiu certo em 90%
      das séries. O θ que o robô estima é do tamanho do próprio erro de
      estimação.
    - **Onde o HR roda**: no traço, os dois estágios rodaram em 105 de 496
      pregões (q > 0); nos outros, MQO direto ou média. Na seleção de ordens,
      20 dos 25 candidatos passam pelos dois estágios.

85. **[método] Relatório dos testes do código (30/10/2026, pedido do autor).**
    `ia/relatorios/testes-do-codigo/relatorio.pdf`, dados em
    `dados/verificacao/testes_formulas_2026-10-30/`
    (`ferramentas/TestesFormulas.mq5`). Não está no TG (validação fora do texto
    desde 18/10).
    - **Conferido**: 20 identidades entre o código do robô e a conta refeita à
      parte (MQO, ADF, valor crítico, Ljung-Box, log L e AIC do ARIMA, amostra
      comum, ARIMA(2,0,0) × MQO, log L e previsão do GARCH, previsão no nível,
      percentil). 11 com diferença zero; as outras até 3,1e-14. O GARCH na
      janela da validação deu os mesmos α = 0,126435 e β = 0,587799 do arquivo
      de 05/10. Grade 41 × 41 em volta do ótimo: nenhum ponto com log L maior.
    - **ADF um pouco acima de 5%**: com as defasagens pelo AIC, rejeitou 5,6% de
      5000 passeios aleatórios (desvio 0,3 p.p.); com zero defasagens, 5,0%. A
      conta e o valor crítico estão certos; o excesso vem da escolha das
      defasagens em amostra pequena (estimativa, não investigado).
    - **Ljung-Box com desconto de p+q rejeita demais nos resíduos do robô**:
      7,9% em 2000 ARMA(1,1) ajustados pelo CArima (3,8% sem o desconto). Causa
      **não confirmada**; hipótese: a regra foi deduzida para estimativas de
      máxima verossimilhança e o HR é menos eficiente. O EA não usa o
      Ljung-Box para decidir; afeta só a leitura dos diagnósticos (o p = 0,009
      da validação de 05/10 continua significativo).
    - **GARCH com 240 pontos**: em 300 séries com β = 0,89, β médio 0,824
      (desvio 0,142) e 3,3% no limite α + β = 1; com 1000 pontos, 0,884
      (0,027). Propriedade do tamanho da janela, não do código. **Não testado**
      se o limiar por percentil é sensível a esse erro de β.
    - **AIC**: ordem verdadeira escolhida em 70,8% (AR(1), φ = 0,5) e 74,6%
      (passeio); quando erra, em geral põe termos a mais.
