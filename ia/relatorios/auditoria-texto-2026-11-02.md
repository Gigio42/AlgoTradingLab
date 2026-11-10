# Auditoria do texto do TG — 02/11/2026

> **Aplicada em 02/11/2026** (INCERTEZAS item 86), com as decisões do autor:
> A1 só como limitação, A2 fora do texto. Ficaram B6 (versão final), B8 (Figura 1,
> captura do autor) e a obra do Calmar.

Pedido do autor: inspeção completa do trabalho escrito (conteúdo, coerência,
normas, formatação, o que falta dizer). Nada foi alterado no `tg/`.

Base: `tg/` do commit `1089cd3` (os `.tex` não mudaram desde então), PDF
recompilado numa cópia em scratchpad (78 páginas, 0 overfull, 0 referência
indefinida, só o aviso inofensivo do `brazil` no babel). Normas conferidas no
`dados/fontes/normas-fatec/Manual-de-Normas-2026-2028.pdf`. Números conferidos
contra `dados/resultados/refeito_2026-10-05/cru/` e `proventos_b3/`.

**O que está certo e foi conferido:** todas as linhas das Tabelas 2 a 12
batem com `cru/tabelas.txt` e `proventos_b3/`; "sete de onze" (Tabela 8),
"sete dos nove" e "três casos" (Tabela 13) batem; o retorno igual em "+ Selic"
e "+ proventos" do ARIMA-GARCH em 2013–2016 é real (estava fora do mercado nas
duas datas-ex do período, 29/04/2013 e 02/04/2014); estrutura do Cap. II
(2.1 a 2.3.2), Considerações na ordem do manual, citações em caixa mista,
letras 2026a/b/c no texto.

---

## A. Conteúdo e coerência (o que mais pode custar na banca)

A1. **Janela do GARCH: a crítica da orientadora não aparece no texto.**
INCERTEZAS item 78 ("pendente, decisão do autor"). O GARCH herda a janela do
ARIMA (120 ou 240); a orientadora apontou que MV precisa de 500 a 1.000
observações. Nada sobre isso no Cap. II nem nas limitações
(`cap4-consideracoes.tex:111-113` fala só de "no máximo 240 pregões" e
atribui ao testador). Agravantes já medidos: persistência na parede em 29% dos
dias em 2019–2021; e o número de destaque do Cap. III, ARIMA-GARCH Sharpe
2017–2024 +199,5%, cai para +64,6% **com a mesma configuração** e janela 500
(item 78, correção de 27/10). Decisão do autor: plano A (refazer) ou plano B
(declarar como limitação, com a obra que sustenta o 500 — Hwang e Valls
Pereira, ainda não lida).

A2. **Médias móveis nas outras ações: rodadas, mas o texto diz que não.**
`cap3-resultados.tex:930-931` ("As médias móveis não foram executadas nessas
ações"). Existe `cru/outras_acoes_mm.txt` (29/10/2026). E esses dados
enfraquecem a hipótese 2 "confirmada quanto ao risco"
(`cap4-consideracoes.tex:81-83`), que hoje vale só para a PETR4: o ARIMA-GARCH
Sharpe caiu mais que as médias móveis em 4 de 9 casos (VALE3 2007–11 40,0 ×
34,0; USIM5 2013–16 80,4 × 57,2; POMO4 2013–16 70,3 × 40,3; POMO4 2025–26
34,5 × 27,3) e oscilou mais em USIM5 2013–16 (58,6% × 45,5%). Ou se inclui a
coluna e se ajusta a conclusão, ou se tira a frase e se diz que a comparação
com as médias é só na PETR4.

A3. **"No retorno não houve padrão" (outras ações) é brando demais.**
`cap3-resultados.tex:966`. O ARIMA sem GARCH rendeu mais que o ARIMA-GARCH
Sharpe em 7 de 9 casos (contando USIM5 2025–26, sem operações, como zero).

A4. **2007–2011: a mesma configuração sem GARCH terminou com +7,2%.**
Tabela 8, `cap3-resultados.tex:693`. O texto do período (3.3) cita a gêmea só
em 2008 (−9,9%, favorável) e não diz que, nos cinco anos, ela terminou com
mais dinheiro que o ARIMA-GARCH (−8,4%). Como a Tabela 8 mostra, a banca pode
notar. Uma frase no 3.3 resolve.

A5. **Escolha com Selic, avaliação bruta.** A escolha usa custos + Selic no
caixa (`cap2-metodologia.tex:589-590`), o que premia ficar fora do mercado; a
avaliação é bruta. Sinais disso: USIM5 2025–26 escolhida sem nenhuma operação,
USIM5 2013–16 Calmar com 2 negociações, exposição média dos ARIMA-GARCH de 9% a
28%. Pergunta provável: "a proteção não é só ter menos dinheiro aplicado? O
ARIMA com 20% do capital também cairia menos". A Tabela 8 responde em parte
(mesma configuração), mas o texto não discute exposição × proteção. Pelo menos
nas limitações; e preparar a resposta para a defesa.

A6. **"11 de 11, como uma moeda".** `cap2-metodologia.tex:178-181` e
`cap3-resultados.tex:720-723`, `cap4:38-39`. As onze comparações não são
independentes (2017–2024 fixa está dentro de 2005–2026; as duas fixas têm a
mesma gêmea; Sharpe e Calmar se sobrepõem no período). A seção estatística saiu
por decisão do autor (21/10); a frase da moeda sugere um teste que não foi
feito. Suavizar ou preparar a resposta.

A7. **"Trechos de código da comunidade serviram de ponto de partida".**
`cap2-metodologia.tex:188-191`, sem citação, e o comentário logo abaixo
(l. 204-207) diz "O código não foi tirado deles". As duas coisas não podem ser
verdade ao mesmo tempo. Se foi só consulta, dizer "consultados"; se houve
adaptação, citar. Risco de integridade.

A8. **Taxa de acerto ≠ acerto direcional.** A hipótese 1 fala em acerto
direcional; a métrica é a proporção de negociações com lucro (Quadro 1,
`cap1:463`), e uma negociação dura vários dias. `cap2:174-175` trata as duas
como a mesma coisa. Dizer "medido pela taxa de acerto das negociações".

## B. Normas (objetivas)

B1. **Listas de ilustrações separadas.** Manual 4.1.1.10: lista própria para
cada tipo com 5 ou mais itens. Hoje: 5 figuras, 5 quadros, 15 gráficos, numa
lista única. O comentário de `main.tex:35-37` ("menos de 5 itens cada") ficou
desatualizado. Tem de virar Lista de figuras, Lista de quadros e Lista de
gráficos.

B2. **Letras na lista de referências.** O texto cita (B3, 2026a/b/c),
(Banco Central do Brasil, 2025a/b/c) e (MetaQuotes Ltd., 2026a–d), mas na lista
os anos saem sem letra ("São Paulo, 2026."). O exemplo do manual põe a letra
na referência também ("AAP. 2020a."). Correção no estilo/`.bbl`.

B3. **URL entre < >.** A NBR 6023 desde 2018 não usa os sinais; o manual
mistura exemplos com e sem, e os que citam a NBR 6023:2025 (observação sobre
matérias de portais, logo antes do item 5.2.7) vêm sem.
Recomendação: tirar. Confirmar com a orientadora.

B4. **Cap. III sem confronto com a literatura.** O manual pede "comparar com
outras pesquisas e com a fundamentação teórica; citar autores que corroboram
ou divergem". O Cap. III cita só Almeida e Araya (uma vez). Harvey et al.
(2018), já lido e no Cap. I, corrobora diretamente o achado de risco; Xing et
al. (2024) dá contraponto (ARIMA-GARCH melhor em erro de previsão). O autor
recusou "literatura no Cap. III" em 21/10; registro aqui porque é exigência
escrita do manual.

B5. **Justificativa sem viabilidade.** Manual 4.1.2.2 pede relevância e
viabilidade. A introdução (l. 98-110) tem relevância; viabilidade (dados
públicos e gratuitos, plataforma e biblioteca gratuitas, testador) não é dita.

B6. **Folha de aprovação** só na versão final (pós-banca, até 14/12):
`main.tex:263` está comentada. Lembrete.

B7. **Voz.** "acreditamos" (`cap3:123`) no meio de um texto todo com "se".
O manual aceita 1ª do plural, mas misturar destoa. "Considera-se".

B8. **Figura 1** (`fig01-interface-metatrader.png`): 475 × 365 px (fica
granulada a 0,72 da largura), interface em inglês, EURUSD/forex. Trocar por uma
captura própria do MT5 em português com a PETR4 ("Fonte: Elaboração própria").

B9. **Gráficos 3, 8, 11 e 15** (saldo do MT5): rótulo "Balance" em inglês,
números sem separador de milhar, eixo sem título. Aceitável como reprodução do
relatório, mas conferir legibilidade no impresso.

B10. **Equações**: ARIMA, GARCH, Sharpe e Calmar numeradas (1)–(4) e nunca
chamadas pelo número; AIC sem número. Padronizar (todas sem número, já que o
texto não as cita).

## C. Código × texto (regra: toda afirmação de método tem contrapartida)

C1. **Sharpe anualizado.** O código multiplica por √252
(`Desempenho.mqh:94`); o Cap. I (`cap1:504-515`) dá S = d̄/σ_d e explica √252
só para a volatilidade. Os valores do Quadro 5 (1,54; 2,83...) são anualizados.

C2. **Ajuste da posição limitado a 98% do patrimônio.**
`VolumePorCapital` (`Negociacao.mqh:135`) corta a fração em 0,98. Com o
limite máximo de 2,0 × 95%, o ajuste na prática **só reduz** a posição (ou
leva a 98%); nunca alavanca. O Cap. I (`cap1:415-417`, "aumentando a posição
quando a volatilidade está baixa") e o Cap. II (`cap2:372-374`, "limites
mínimo e máximo" sem valores) não dizem isso.

C3. **Especificação do ADF não descrita**: regressão com constante,
defasagens escolhidas pelo AIC (INCERTEZAS 85). Pergunta clássica de banca.

C4. **Hannan-Rissanen.** O código não faz o terceiro passo de Gómez e Maravall
e usa outra regra para a ordem do AR longo (INCERTEZAS 84). O texto cita Gómez
e Maravall para "estimativas próximas às de MV". E `cap2:235-237` justifica
por "não exige taxa de aprendizado... não depende da escala" sem dizer contra
qual alternativa (o gradiente do código antigo); como o modelo já trabalha com
log-retorno, o argumento de escala perde força. Preparar resposta.

C5. **Queda máxima.** O Cap. I a identifica com o "rebaixamento relativo" do
relatório do MT5 (`cap1:482-485`); os números das tabelas vêm do patrimônio
diário calculado pelo robô (`dd_puro`). Não confirmado se coincidem com o
relatório; se não, dizer "calculada sobre o patrimônio diário".

C6. **Valores padrão da listagem** (Apêndice A: janela 120, alvo 1,5%,
percentil 50, sem zerar no veto) não correspondem a nenhuma configuração
escolhida. Uma frase no apêndice remetendo ao Quadro 5 evita confusão.

C7. **Natureza da pesquisa** (primária, aplicada, método empírico) está na
introdução (l. 112-115) e não no Cap. II, onde a introdução diz que está o
detalhe.

## D. Consistência e redação (menores)

- 2020: a introdução diz que a PETR4 perdeu 48,6% até início de abril
  (`cap0:48`); a Tabela 6 dá queda máxima de 64,2% no ano. Harmonizar.
- Período recente "termina em 18 de setembro" (Tabela 7) × série até 21/09
  (`cap2:107-108`). Explicar ou harmonizar.
- "Teste principal, por ser o mais longo" (2017–2024): 2005–2026 é mais longo.
  "O mais longo com a escolha feita antes do período".
- 2017–2024 aparece duas vezes no Quadro 4 (escolha própria e fixa); no texto,
  nomear sempre "com configuração fixa".
- Ordem dos gráficos difere entre seções (2007–11 e 2013–16: anual, patrimônio,
  saldo; 2017–24: patrimônio, anual, saldo; 2025–26: sem gráfico anual). A
  seção 3.2 não menciona o gráfico anual.
- Seção 3.2 "Como os resultados são apresentados" é método dentro do Cap. III
  (regra do autor de 14/10).
- ", e não ..." aparece 28 vezes no corpo, 7 nas Considerações (quase um por
  parágrafo). É o tique "não X, mas Y" que o autor pediu para evitar.
- Considerações l. 40-41: "o efeito se repetiu nas outras três ações" vale só
  para o grupo que reduz a posição (o outro, 31% a 68%).
- Limitações (`cap4:113-116`): diz que o bruto favorece quem negocia mais; não
  diz que o bruto também desfavorece o GARCH, que fica mais tempo no caixa
  sem render Selic. Equilibrar.
- Hipótese 1 apoiada em Batista (2024), que combinou indicadores técnicos, não
  modelos de média e variância: apoio fraco.
- Ponte MM → AR (`cap1:272-279`): a MMS é sobre o preço; o AR, com d = 1, é
  sobre o retorno. Preparar a resposta.
- Calmar sem a obra original no `.bib` (não confirmado qual; não inserir sem
  leitura). Estacionariedade definida só por média e variância e sem citação
  (`cap1:247-249`).
- Referência de Araya: "Article ID 6305525" em inglês.

## E. Entrega (09 a 13/11, uma semana)

- PDF e Word (o `.docx` ainda não foi aberto no Microsoft Word), Termos de
  Ciência e de Autorização, apresentação de 20 a 30 min.
- Mandar à orientadora o que mudou e confirmar título e objetivo sem "validar"
  (PENDENCIAS, item 7).
- Autor conferir as tarifas da B3 (0,0300%) e salvar a página da Petrobras de
  2005 em `dados/fontes/petrobras/` (procedência da citação `petrobras2005`).
- Commit do que está pendente (git status com 9 arquivos modificados e
  `tg/main.docx` não versionado).
