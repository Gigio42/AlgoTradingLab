# Pendências

Lista de trabalho do TG, por ordem de prioridade. Atualizada em 15/10/2026.
Detalhes e números de cada decisão ficam em `notas/INCERTEZAS.md`.

## Prazos

| Quando | O quê |
|---|---|
| 19 a 26/10 | orientadora envia a nota de orientação e autoriza a entrega |
| 09 a 13/11 | entrega: monografia em PDF e em Word, Termos de Ciência e de Autorização em PDF, apresentação (20 a 30 min) |
| 23 a 27/11 | banca (Workshop de Monografias) |
| até 14/12 | monografia corrigida em PDF e resumo em Word, por e-mail |

Fonte: `dados/fontes/normas-fatec/TG-Cronograma-2o-2026.pdf`.

## 1. Próxima sessão de testes: estimação do ARIMA por máxima verossimilhança

**Por quê.** Hoje o ARIMA é estimado por Hannan-Rissanen e o AIC usa a
verossimilhança calculada com essas estimativas (`Include/Arima.mqh`, linhas
411 a 444), que não é a verossimilhança maximizada que a teoria do AIC supõe.
Com a máxima verossimilhança condicional, cada candidato (p, q) é levado ao seu
melhor ajuste antes da comparação, como no procedimento de Thomaz (2019). O
texto ganha referência já lida, e o ARIMA e o GARCH passam a ser estimados do
mesmo jeito.

**Respaldo em Thomaz (2019)**, conferido no PDF:
- p. 42–43: as versões condicional e exata da verossimilhança do ARMA; "ambos
  métodos são consistentes para amostras grandes", e "o método de máxima
  verossimilhança condicional é mais fácil de ser utilizado";
- p. 43: a exata é complexa (remete a Hamilton, 1994); a máxima verossimilhança
  dá resultados consistentes mesmo com dados não normais (Bueno, 2008);
- p. 27: conceito de invertibilidade.

Sem respaldo nele (precauções de engenharia, a medir ou a buscar em outra fonte):
risco de não convergir, lentidão (Thomaz diz que hoje é fácil de implementar em
software pronto; aqui o modelo é reestimado todo dia em milhares de simulações) e
a técnica para impor a invertibilidade com q >= 2 (Hamilton, 1994, a ler).

**Regra de honestidade.** A decisão de adotar ou não é tomada no passo 4, pelo
motivo técnico e pela validação sintética, ANTES de rodar qualquer teste de
mercado. Depois disso, os resultados entram no TG sejam eles quais forem.

- [x] **1. Implementar** em `Include/Arima.mqh` a máxima verossimilhança
      condicional, como OPÇÃO (input escolhendo entre Hannan-Rissanen e máxima
      verossimilhança; o padrão continua Hannan-Rissanen até a decisão).
  - partir das estimativas do Hannan-Rissanen (ponto de partida do otimizador);
  - reaproveitar o otimizador da ALGLIB (MinBLEIC), como no `Garch.mqh`;
  - garantir estacionariedade e invertibilidade por mudança de variáveis (com
    q >= 2 a restrição não entra como limite simples);
  - se o otimizador não convergir, ficar com as estimativas do Hannan-Rissanen;
  - o AIC passa a usar a verossimilhança maximizada;
  - marcar com `//@omitir` o que não for do modelo puro e conferir a listagem do
    Apêndice A.
- [x] **2. Validar** nas mesmas séries sintéticas da Tabela 1 (ARMA(1,1) e
      AR(2)), comparando lado a lado a precisão dos dois métodos
      (`ferramentas/ValidacaoAlgoLab.mq5`, `ferramentas/scripts/validar.sh`).
      Conferir também que o caminho Hannan-Rissanen continua idêntico (regressão
      byte a byte, como no GARCH-t).
- [x] **3. Medir o tempo** de uma simulação com cada método, para estimar a
      duração da bateria completa (hoje cerca de 2 h).
- [x] **4. Decidir** (15/10, 03:10: fica o Hannan-Rissanen; ver
      `dados/resultados/bateria_2026-10-15/PROTOCOLO.md`, seção 6) com os resultados de 2 e 3 e registrar a decisão em
      `notas/INCERTEZAS.md` antes de qualquer teste de mercado.
      **Critério de corte (combinado em 15/10):** ficar com o Hannan-Rissanen,
      e citar a máxima verossimilhança como trabalho futuro, se: (a) na
      validação ela não for mais precisa ou não convergir com frequência; (b) o
      tempo medido tornar a bateria inviável; ou (c) não estiver pronta e
      validada até ~20/10. Nesse caso, a bateria nova roda só com o forward.
- [x] **5. Rodar a bateria nova uma vez só** (15/10, 03:11–03:36,
      `dados/resultados/bateria_2026-10-15/LEIAME.md`). Falta: o autor decidir o
      texto, já com as mudanças do item 2
      abaixo, e atualizar o texto.

## 2. Bateria nova: otimização com teste forward e critério único de risco

**Rodada em 15/10** (`dados/resultados/bateria_2026-10-15/`): fator de
recuperação, camadas, pandemia (2017–2019 → 2020–2021). Os itens abaixo marcados
com [x] estão rodados; o que falta é levar ao texto, quando o autor decidir.
Atenção ao ler: no resultado cru, o retorno do GARCH fica bem pior que o das
médias móveis (LEIAME, seção 4).

Junto com o item 1, para refazer tudo uma vez só.

- [x] Trocar as versões A (Sharpe) e B (Calmar) por **um critério só**: o
      **fator de recuperação** (lucro líquido / rebaixamento máximo), nativo do
      MetaTrader 5. Não usar "rebaixamento mínimo" sozinho: ele escolhe o robô
      que não opera.
- [x] Usar a **otimização com teste forward** do Testador (data de corte
      personalizada), mesmas janelas de hoje: otimização em 2004–2006, 2010–2012,
      2014–2016 e 2022–2024, teste nos períodos seguintes. Escolher a nº 1 pela
      coluna da otimização, antes de olhar o forward.
- [x] Declarar critério e protocolo por escrito ANTES de rodar
      (`dados/resultados/<nova pasta>/PROTOCOLO.md`).
- [ ] Gerar relatório e gráficos do MT5 de cada teste final (como Almeida, 2016).
- [x] **Período próprio para a pandemia** (pedido do autor em 15/10): otimização
      em 2017–2019 e teste em 2020–2021, como janela separada. Hoje o Cap. III tem
      só um recorte de 2020 dentro do teste de 2017–2024
      (`refeito_2026-10-05/recorte_2020.txt`).
- [ ] Atenção: com o critério nativo o caixa parado deixa de render Selic.
- [ ] **Resultado principal "puro", como Almeida (2016)** (pedido do autor em
      15/10): sem custo e sem Selic no caixa, como o relatório do MT5. O EA já
      grava as duas camadas na mesma simulação (`ret_puro`, `dd_puro`,
      `vol_puro` e as colunas `_selic`), então não há rodada extra. Custos de
      0,03% e caixa na Selic viram uma seção curta no fim do Cap. III ("Efeito
      dos custos e do rendimento do caixa"). Cuidados para o texto: sem custo, o
      ARIMA sozinho (centenas de negociações) parece melhor do que é; sem Selic,
      o robô com GARCH (mais tempo fora) fica um pouco prejudicado no retorno. O
      volume continua 95% do patrimônio (lote fixo faz o resultado em reais
      depender do preço da época).
- [ ] **Seção "Do resultado bruto ao estimado"** no fim do Cap. III (e slide da
      apresentação): o teste principal (2017–2024) em quatro camadas, com tabela
      ou gráfico de barras por robô. Colunas já gravadas pelo EA:
      1 cru (`ret_puro`), 2 + custos (`ret_custos`), 3 + caixa na Selic
      (`ret_selic`), 4 + proventos (`ret_completo`). Frase obrigatória: mesmo a
      camada 4 é estimativa. Ficam de fora slippage, liquidez e imposto de renda,
      que só se medem em operação real.

## 3. Pequenas camadas no texto (cada uma lida pelo autor antes da próxima)

- [x] Cap. I: uma frase dizendo que AR e ARMA são casos particulares do ARIMA
      (ARMA = ARIMA com d = 0; AR = ARMA com q = 0), com Thomaz (2019).
- [x] Cap. II: uma frase explicando por que a validação usou AR(2) (um estágio do
      Hannan-Rissanen) e ARMA(1,1) (dois estágios).
- [x] Cap. III: dizer que o d varia. No traço de 2019–2021 (código atual,
      `dados/resultados/refeito_2026-10-05/traco_demo/traco_demo_GARCH.csv`):
      d = 1 em 412 de 496 pregões (83,1%), d = 0 em 84 (16,9%).
- [x] Atualizar o item 34 do `notas/INCERTEZAS.md` (diz 42 de 496, número do
      código antigo; o atual é 84).
- [x] Cap. II: justificar o GARCH(1,1) com Xing et al. (2024, p. 5 do PDF):
      menos parâmetros e escolha predominante na literatura.
- [x] Cap. II: dizer que o tamanho da janela (120/240) foi limitado pelo
      histórico que o Testador entrega (desde 1º de janeiro do ano anterior ao
      teste), e citar Hwang e Valls Pereira (2006) como limitação nas
      Considerações (recomendam 500 observações para o GARCH(1,1)).
- [ ] Cap. II: duas ou três frases sobre por que MQL5 e não Python (o Testador
      só executa robôs em MQL5; continuidade com Almeida; robô pronto para
      operar; modelos implementados e validados).
- [ ] Cap. III: comparar com a literatura (norma 4.1.2.13: citar quem corrobora
      ou diverge): Xing et al. (2024) usaram janela expansiva e ela foi a melhor
      no ARIMA; Batista (2024) combinou técnicas com funções diferentes; Thomaz
      (2019) e o agrupamento de volatilidade.
- [ ] Cap. I, Trabalhos relacionados: incluir Thomaz (2019) na seção e no
      Quadro 1.
- [ ] Considerações finais, trabalhos futuros: GARCH com t de Student (janela
      expansiva já entrou em 15/10); GARCH com t de
      Student (já testado, deu pior, `dados/resultados/garch_t_2026-10-13/`).

## 4. Leituras (nenhuma citação entra antes da leitura)

Prioridade:
- [ ] Harvey et al. (2018), "The Impact of Volatility Targeting", *Journal of
      Portfolio Management*: reduzir exposição quando a volatilidade sobe diminui
      a queda máxima em todas as classes de ativos. É o resultado do TG.
- [ ] Pardo (2008), *The Evaluation and Optimization of Trading Strategies*:
      otimizar num período e testar no seguinte (walk-forward).
- [ ] Hwang e Valls Pereira (2006), *European Journal of Finance*: tamanho
      mínimo de amostra para o GARCH(1,1).

Pendentes no texto (marcações `% REFERÊNCIA` nos `.tex`):
- [ ] Hannan e Rissanen (1982), *Biometrika*, v. 69, p. 81–94 (ou a seção sobre
      o método em Brockwell e Davis).
- [ ] Pitman (1939) e Morgan (1939), teste de volatilidade (Apêndice B).
- [ ] Lo (2002), Jobson e Korkie (1981), Memmel (2003), testes de Sharpe
      (Apêndice B).
- [ ] Gil (2010) ou caderno de delineamentos da FATEC (Cap. II, delineamento).
- [ ] Ajuda do Testador do MetaTrader 5 (otimização e forward).
- [ ] Fonte para o custo de 0,03% por operação (tabela de tarifas da B3).
- [ ] Fonte para a convenção de 252 dias úteis por ano (Banco Central, Selic
      anualizada base 252; a página do BCB só carrega com JavaScript, baixar à mão).
- [ ] Harvey et al. (2018) e Moreira e Muir (2017) também sustentam o
      *volatility targeting* do Cap. II.
- [ ] Glosten, Jagannathan e Runkle (1993) e Nelson (1991), GARCH assimétrico
      (Considerações).

Para comparar no Cap. III (opcional): Moreira e Muir (2017); Oliveira, Montini e
Bergmann (2008, RAM); Galdi e Pereira (BBR, a conferir); Reis (UFJF, PETR4,
ARIMA melhor que GARCH: diverge); Cadernos do IME/UERJ (2009, EGARCH na PETR4).
Livro em português: Morettin, *Econometria Financeira* (Blucher).

## 5. Entrega e organização

- [ ] Levar à orientadora a versão simplificada (antes de 19/10) e confirmar a
      troca de título.
- [ ] Termos de Ciência e de Autorização (modelo em `dados/fontes/normas-fatec/`).
- [ ] Apresentação de 20 a 30 min (modelo da FATEC em `dados/fontes/normas-fatec/`).
- [ ] Versão em Word (pandoc ou conversão manual, depois que o texto fechar).
- [ ] Atualizar o `README.md` para o foco em risco.
- [ ] Corrigir a ordem no `.gitignore` (`!dados/resultados/**/execucao.log` vem
      antes de `*.log` e é anulado).
- [ ] Commit (nada commitado desde 13/10).

## Lembretes técnicos

- PDF final: rodar `make` dentro de `tg/` (é ele que põe as citações em caixa
  mista). O VS Code compila sozinho ao salvar um `.tex` e, se rodar junto com o
  `make`, corrompe o `main.aux`: esperar ele terminar.
- Testes rodam no prefixo `~/.wine-mt5-novo`, que tem um clone próprio do
  repositório: copiar o código para lá e recompilar antes de rodar.
- O terminal precisa estar autenticado na conta demo da Clear para o Testador
  funcionar (os preços vêm da B3, a conta só dá a conexão).
- Otimização refeita com os mesmos parâmetros vem do cache: apagar
  `Tester/cache/` antes.
