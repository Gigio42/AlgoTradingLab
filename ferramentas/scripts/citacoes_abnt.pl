#!/usr/bin/perl -i
# Ajusta as formas de citação que o abntex2cite grava no .bbl
# (\abntrefinfo{explícita}{implícita}{ano}) às regras do Manual FATEC-ID
# 2026-2027, itens 2.3.1 e 2.3.5:
#  - caixa mista também dentro do parêntese (NBR 6023:2025): a forma implícita
#    deixa de ser a CAIXA ALTA e passa a ser derivada da explícita;
#  - dentro do parêntese, autores separados por "; " (fora, por " e ");
#  - "et al." em itálico nas duas formas;
#  - em trabalho acadêmico, o traço antes da instituição é meia-risca ("–"),
#    não o travessão longo ("—") que o estilo grava.
# Lê o arquivo inteiro: com nome longo, o BibTeX quebra o \abntrefinfo em duas
# linhas (foi o que deixou a FATEC-ID em caixa alta em 18/10/2026).
#   uso: perl -i citacoes_abnt.pl main.bbl
use strict; use warnings;
local $/;
my $t = <>;
$t =~ s{^\\abntrefinfo(\{(?:[^{}]++|(?1))*\})\s*(\{(?:[^{}]++|(?2))*\})\s*(\{(?:[^{}]++|(?3))*\})[ \t]*$}{
  my ($e, $a) = (substr($1,1,-1), substr($3,1,-1));
  $e =~ s/\s+/ /g;
  $e =~ s/\bet al\./\\textit{et al.}/g;
  (my $i = $e) =~ s/, /; /g;
  $i =~ s/ e /; /g;
  "\\abntrefinfo{$e}{$i}{$a}"
}gme;
$t =~ s/\) ---[ \t]*$/) --/gm; $t =~ s/\) --- /) -- /g;
print $t;
