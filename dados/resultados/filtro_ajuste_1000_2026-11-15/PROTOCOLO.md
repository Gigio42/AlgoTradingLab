# Protocolo: GARCH 1000 só com filtro e ajuste, mantendo ou encerrando no veto (15/11/2026)

Escrito antes de rodar. Estudo à parte, **não entra no TG** sem pedido.

Pedido do autor em 15/11/2026: terminar a bateria com o GARCH em 500
(`../filtro_ajuste_500_2026-11-13/`) e "aproveitar para fazer o mesmo com 1000".
Este protocolo é o daquela pasta (`../filtro_ajuste_500_2026-11-13/PROTOCOLO.md`),
com uma só mudança, `Janela_GARCH=1000`. As versões são as mesmas: **M** mantém a
posição no veto e **E** encerra. Ficam iguais a grade de 52 passagens, os
períodos, o aquecimento de quatro anos, o critério de escolha, os testes e as
comparações. O relatório põe lado a lado o TG, o 500 (M e E) e o 1000 (M e E).

## O que muda por causa da janela de 1000

- **PETR4:** as oito janelas, como no estudo de 1000 de 02/11 e no das janelas de
  13/11. C1 e T1 usam o `PETR4_DESDE1999`.
- **VALE3, USIM5 e POMO4: sem o par C1 → T1 (2004–2006 → 2007–2011).**
  - A série oficial delas começa em 02/01/2003, e 1000 pregões só se juntam no
    começo de 2007.
  - O GARCH não teria dados em toda a otimização de 2004–2006.
  - Também não teria dados nas primeiras semanas de 2007.
  - Estender a série antes de 2003 seria dado novo (regra nº 2) e não foi pedido.
  - Ficam 6 janelas por ação: C2/T2, C3/T3, C4/T4.
- Total: (8 + 3 × 6) janelas × 2 versões = 52 otimizações de 52 passagens.

## Conferências previstas

- **Passagens:** 52 em cada uma das 52 otimizações.
- **Sem GARCH:** a sub-grade sem GARCH é igual entre M e E. Ela também é igual
  à da bateria de 500, porque o ARIMA não depende da janela do GARCH.
- **Estudo das janelas:** na PETR4, as passagens são iguais ao subconjunto
  correspondente de `../janelas_garch_2026-11-13/calibracao/1000/`.
- **Testes individuais:** iguais à passagem da grade (GS e GC da PETR4).

Script: `ferramentas/scripts/filtro_ajuste_500.sh` com `JG=1000`.
