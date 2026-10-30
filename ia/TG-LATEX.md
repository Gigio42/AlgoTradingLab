# Como o TG em LaTeX está montado

> Nota interna. Até 05/10/2026 este arquivo era o `tg/README.md`; saiu de lá
> porque a pasta `tg/` só guarda o que vai ser entregue.

## Compilar

```bash
cd tg
make          # gera codigo/ARIMA_GARCH_EA.mq5 e roda pdflatex + bibtex + 2x pdflatex
make clean    # remove os auxiliares
```

O Makefile refaz o `tg/codigo/ARIMA_GARCH_EA.mq5` sempre que o EA muda: é o EA
sem comentários e sem os trechos marcados com `//@omitir` (log, diagnóstico,
traço, avaliação), gerado por `ferramentas/scripts/codigo_apendice.sh`. É o que
o Apêndice A lista. Nunca editar esse arquivo à mão. Em 05/10/2026 a listagem
reduzida compilou sozinha no MetaEditor (prefixo `~/.wine-mt5`) com 0 erros e
0 avisos.

Os gráficos de `tg/graficos/rodada3/` são compilados à parte (comando no
cabeçalho de `curvas.tex` e `anual.tex`) e leem os dados direto de
`dados/resultados/rodada3_b3_oficial/testes/`.

## Estrutura

```
tg/
  main.tex            preâmbulo (normas da FATEC-ID) e ordem das partes
  referencias.bib     só entra na lista o que é citado
  Makefile
  codigo/             gerado pelo Makefile (Apêndice A)
  figuras/            fig01, fig02, fig04, fig05, fig06
  graficos/rodada3/   Gráficos 1 e 2 (e os de T2 e T3, não usados no texto)
  conteudo/
    capa, folharosto, resumo, abstract, siglas
    cap0-introducao      INTRODUÇÃO (sem número, texto corrido)
    cap1-fundamentacao   CAPÍTULO I
    cap2-metodologia     CAPÍTULO II (numeração 2.1 a 2.3.2 da FATEC)
    cap3-resultados      CAPÍTULO III
    cap4-consideracoes   CONSIDERAÇÕES FINAIS (sem número)
    apendice-a           código do EA
```

Figuras e textos que saíram do TG estão em `ia/rascunhos/` (versões
anteriores dos capítulos, as figuras do PTG de LSTM e indicadores) e em
`dados/resultados/rodada2_yahoo_2026-09-21/graficos_tg/` (gráficos da rodada 2).

## Formatação

Ver `ia/NORMAS-FATEC.md`, seção 7, para o que foi aplicado e por quê.
