# Exploratório: a estimação do ARIMA muda o resultado? (15/10/2026)

Curiosidade do autor, depois da bateria. **Não muda a decisão do protocolo
(fica Hannan-Rissanen + AIC).** Rodado com `ferramentas/scripts/exploratorio_estimacao.sh`;
tabela em `resumo.txt` (`resumo_exploratorio.sh`). Antes, a implementação da
máxima verossimilhança foi conferida em
`dados/verificacao/verificacao_mv_arima_2026-10-15.txt` (EA `ferramentas/VerificarMV_EA.mq5`).

## Verificação da implementação

- Em 19 de 20 séries, o otimizador chegou ao mínimo da busca exaustiva
  (397 x 397 pontos), com diferença relativa da ordem de 1e-3 (ou abaixo, por
  ser contínuo). Em 1, parou num ótimo local; o global estava encostado no
  limite da região invertível (theta = 0,98). Comportamento conhecido do ARMA
  com raízes quase canceladas.
- Por que o HR "escolheu melhor": na mesma amostra, o (4,4) ganha em média +7,16
  de log-verossimilhança sobre o verdadeiro (1,0) com a MV e só +1,09 com o HR.
  O AIC aceita 7 parâmetros a mais quando o ganho passa de 7, então com a MV ele
  escolhe modelos grandes ((4,4) foi o mais escolhido). A imprecisão do HR nos
  modelos grandes age como uma penalidade extra. Com o BIC, a MV acerta a ordem
  em 103 de 150 vezes, mais que o HR com AIC (89 de 150).
- Não foi por "mais testes com o HR": cada série foi estimada pelos dois
  métodos, com as mesmas réplicas e a mesma semente.

## Resultado de mercado (mesmos robôs, 5 períodos, 4 combinações, 45 rodadas novas)

- **Nenhuma combinação domina.** Melhor retorno cru em 15 casos: HR+AIC 7,
  HR+BIC 2, MV+AIC 3, MV+BIC 3 (o HR+AIC é favorecido, porque os robôs foram
  escolhidos com ele). Menor queda: 7, 1, 3, 4. Menor volatilidade: 2, 3, 6, 4.
- **O retorno muda muito com a estimação, para a mesma configuração**: em
  2017–2024, o ARIMA isolado vai de +95,7% (HR+AIC) a −2,0% (MV+AIC); a
  configuração sem GARCH, de −50,1% a +82,3%. Sinal de que a previsão de direção
  é frágil (perto do acaso), e não de que um método seja melhor.
- **A proteção do GARCH não depende da estimação:** com GARCH x mesma
  configuração sem ele, queda menor em 20 de 20 combinações (período x
  estimação) e volatilidade menor em 20 de 20; retorno cru maior em 9 de 20.
  É a verificação de robustez mais forte que o trabalho tem para a proteção.
- Tempo real por rodada com a MV: de 27 s a 103 s (o HR, 17 s).
