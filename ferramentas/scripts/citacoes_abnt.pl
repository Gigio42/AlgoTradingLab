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
#   uso: perl -i citacoes_abnt.pl main.bbl
use strict; use warnings;
my $b = qr/(?<g>\{(?:[^{}]++|(?&g))*\})/;   # grupo de chaves balanceado
while (my $l = <>) {
  if ($l =~ /^\\abntrefinfo(\{(?:[^{}]++|(?1))*\})(\{(?:[^{}]++|(?2))*\})(\{(?:[^{}]++|(?3))*\})\s*$/) {
    my ($e, $a) = (substr($1,1,-1), substr($3,1,-1));
    $e =~ s/\bet al\./\\textit{et al.}/g;
    (my $i = $e) =~ s/, /; /g;
    $i =~ s/ e /; /g;
    $l = "\\abntrefinfo{$e}{$i}{$a}\n";
  }
  $l =~ s/\) ---\s*$/) --\n/; $l =~ s/\) --- /) -- /g;
  print $l;
}
