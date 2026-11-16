#!/usr/bin/perl
# Lê o main.bbl (já passado pelo citacoes_abnt.pl) e grava:
#   citas.tsv  chave \t explícita \t implícita \t ano
#   refs.tex   um parágrafo por referência, exatamente como no PDF
use strict; use warnings; use utf8;
my ($bbl, $dir) = @ARGV;
local $/; open my $B, '<:utf8', $bbl or die; my $t = <$B>; close $B;
# "Dispon{\'\i}vel": o pandoc faria "ı" sem pingo + acento combinado, que o Word
# não reconhece como "í" (busca e corretor). Troca pela letra pronta.
$t =~ s/\{\\'\\i\}/í/g; $t =~ s/\\'\{\\i\}/í/g;
my $grupo; $grupo = qr/\{(?:[^{}]++|(??{$grupo}))*\}/;
open my $C, '>:utf8', "$dir/citas.tsv" or die; open my $R, '>:utf8', "$dir/refs.tex" or die;
while ($t =~ /\\bibitem\[[^]]*\]\{([^}]+)\}\s*\\abntrefinfo(\{(?:[^{}]++|(?2))*\})(\{(?:[^{}]++|(?3))*\})(\{(?:[^{}]++|(?4))*\})\s*(\{(?:[^{}]++|(?5))*\})/g) {
  my ($k, $e, $i, $a, $corpo) = ($1, $2, $3, $4, $5);
  s/^\{//, s/\}$// for ($e, $i, $a, $corpo);
  print $C "$k\t$e\t$i\t$a\n";
  $corpo =~ s/\n\s*/ /g;
  print $R "$corpo\n\n";
}
