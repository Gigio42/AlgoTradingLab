# Auditoria antes da entrega à orientadora (16/11/2026)

Continua a auditoria de 13/11 (`auditoria-2026-11-13.md`). Os números entre
parênteses são os itens dela. Páginas são as impressas no PDF de 88 páginas.

## Feito nesta auditoria

- Margem inferior de 1,82 cm corrigida para 2 cm (Manual 1.2).
- Uma linha em branco entre as referências (Manual 1.4).
- Números de linha dos apêndices dentro da mancha.
- Branco no Cap. III: de 5 páginas com 20% a 41% para uma só (p. 43, 21%).
- Nenhuma ilustração cortando parágrafo.
- Abertura do Cap. III com os testes complementares.
- Nota da Tabela 15 explica a ausência de 2007 a 2011.
- Conferências automáticas sem problema: 0 estouro de margem, 0 referência
  indefinida, toda ilustração com fonte e chamada no texto, nenhum `;`, travessão
  longo, negrito, lista ou primeira pessoa no corpo, nenhum "Tabela N" digitado,
  todas as 30 obras do `.bib` citadas, nenhuma citação em caixa alta no corpo,
  resumo com 293 palavras e abstract com 300.

## Abertos, por prioridade

### Alta: o leitor percebe (FEITOS em 16/11, pedido do autor; ver INCERTEZAS 110)

1. **Resumo e abstract (2):** dizem que o robô de Almeida foi bem em "períodos de
   mercado estável" ("stable market periods"). O período dele com lucro,
   2013 a 2016, é o que o próprio TG chama de "Queda e recuperação". Também não
   mencionam as outras três ações, a venda a descoberto nem a janela do GARCH.
2. **Considerações finais (3):** a venda a descoberto não aparece. É uma seção do
   Cap. III sem retorno nas conclusões.
3. **"Teste principal" com dois sentidos (4, metade aberta):** em 3.6 é o período
   de 2017 a 2024. Em 2.5.9 (cap2 l. 763) e 3.11.3 (cap3 l. ~1190) é a PETR4 só na
   compra. O Cap. II nunca diz que 2017 a 2024 é o principal.
4. **"Análise complementar" × "testes complementares":** cap2 l. 175 e 501 e
   cap4 l. 144 chamam de "análise complementar" a seção de custos, Selic e
   proventos (3.10). Agora existe a seção 3.11 "Testes complementares", que é
   outra coisa. Sugestão: "na Seção 3.10" no lugar de "na análise complementar".
5. **Figura 6 (5):** "o pregão termina sem ordem". Em 6 dos 7 robôs com GARCH
   escolhidos, o veto encerra a posição, o que é uma ordem.

### Média: coerência

6. **3.10 (9):** "de uma perda de 15,2%" (coluna "+ custos") e "90,4%" (coluna
   "+ Selic") ao lado de números brutos.
7. **Notas dos gráficos do MetaTrader 5 (10):** não dizem qual ARIMA mostram.
8. **Datas (11):** 2.2 diz "21 de setembro de 2026", a nota da Tabela 8 diz
   "18 de setembro".
9. **"2025 e 2026" (12):** 5 vezes no Cap. III (l. ~781, 785, 859, 872, 1197),
   contra "2025 a 2026" no resto.
10. **3.8 × 3.11.3 (8):** o resultado da grade nas outras ações está na 3.8, e o dos
    robôs escolhidos na 3.11.3, sem remissão entre os dois.
11. **Repetições do Cap. I (6, 7):** pesos fixos × estimados e passeio aleatório
    explicados três vezes cada.

### Baixa: acabamento

12. Lista de siglas sem VALE3, USIM5, POMO4 e BBAS3F (13).
13. Referências de periódicos sem padrão de local e editora (15). Datas de acesso
    de 2025 a renovar. MetaQuotes (2024), fonte da Figura 1 nova: data de acesso
    não confirmada (INCERTEZAS 106).
14. Página nas citações de Thomaz (2019) da seção 1.4 (14).
15. Eixos de datas dos gráficos de patrimônio (17). Figuras 7 e 9 parecidas (20).
16. O Manual pede filete de 5 cm para nota de rodapé (o `main.tex` tem 3 cm). Hoje
    não há nota de rodapé, então não aparece.

### A conferir com o autor

- O "240" da Tabela 15 não é o mesmo das outras seções (ARIMA fixo em 240 e
  aquecimento de quatro anos). O Cap. II diz isso, mas é pergunta provável da banca.
- A seção 3.10 (custos, Selic, proventos) fica fora dos testes complementares
  (reconta as mesmas simulações). Decisão do autor.

## Releitura depois das mudanças de 15 e 16/11 (pedido do autor)

Ficou ruim com as alterações:

- **Cap. I, parágrafo da Figura 6:** "Quando a opção de encerrar a posição no veto
  está ligada" fala de uma opção do robô que só é apresentada em 2.4.6. Sugestão:
  "Em algumas configurações, o veto também encerra a posição aberta."
- **3.8, última frase** ("A Seção 3.11.1 verifica se a proteção depende da janela
  do GARCH"): ficou colada a um parágrafo sobre médias móveis. A 3.11 já se
  apresenta. Tirar.
- **3.6:** "O período de 2017 a 2024 é o teste principal, por ser o mais longo com
  escolha própria" repete a frase nova do 2.2. Sugestão: "O período de 2017 a 2024,
  teste principal do trabalho, inclui a queda provocada pela pandemia em 2020."
- **3.11.1:** "como descrito na Seção 2.5.8" repete a remissão da abertura da 3.11,
  duas linhas antes.
- **3.11.3:** "Como complemento" dentro de "Testes complementares", e "A comparação
  com as médias móveis foi feita apenas na PETR4. Como na PETR4, ..." (PETR4 duas
  vezes seguidas).
- **2.5.8, Testes complementares:** o 2º parágrafo fala das "outras três ações" e
  o 3º as apresenta de novo com os setores ("foram incluídas outras três ações,
  VALE3, da mineração..."), que o 2.2 já apresentou.

Dá para reduzir:

- **3.8 × 3.11.3 (item 8 de 13/11):** o parágrafo das outras ações na grade inteira
  (3.8) iria para o início da 3.11.3, junto dos robôs escolhidos.
- **3.11.2 e 3.11.3:** os primeiros períodos repetem o método do 2.5.8 (quais
  ações, quais períodos, otimização nos três anos anteriores). No Cap. III bastaria
  a remissão.
- **A explicação "vender a descoberto deixa o robô mais dependente da direção do
  ARIMA"** aparece três vezes: 2.5.1, 3.11.2 e Considerações. Uma no Cap. III e
  uma nas Considerações bastam.

Pendências antigas que continuam: 3.10 misturando colunas (9), notas dos gráficos
do MT5 (10), datas 18 × 21/09 (11), "2025 e 2026" (12), "variante" × "versão" (12),
repetições do Cap. I (6, 7), siglas (13).

**Aplicado em 16/11, pedido do autor:** todo o "ficou ruim", da redução só a
explicação da venda a descoberto, e as pendências antigas (9, 10, 11, 12, 6, 7,
13, mais o "ordem máxima" do 2.4.7). Detalhes em INCERTEZAS, item 112. Continuam
abertos: 3.8 × 3.11.3 (outras ações em dois lugares), o método repetido no início
da 3.11.2 e da 3.11.3, referências (15), Thomaz (14), eixos e Figuras 7 e 9 (17, 20).

## Auditoria completa em HTML (16/11, pedido do autor)

`ia/relatorios/auditoria-completa-2026-11-16.html`: leitura do PDF inteiro, contas
do texto refeitas sobre as tabelas, citações × `.bib`, normas e bibliografia.
Achados novos: referências de monografia sem ano e folhas (Manual 5.2.2), Hannan e
Harvey sem local (5.2.4), "plano definido antes" × testes complementares, resumo
sem a ressalva das outras ações, "como na PETR4" na 3.11.3 (quem mantém é o
Calmar), soma 0,9765 × 0,9766 na 3.2, frase da IA em 2.4, Tabela 12 sem explicar
os proventos iguais (conferido: `ret_selic` = `ret_completo` em GS e GC de T2).
Nada foi alterado no `tg/`.
