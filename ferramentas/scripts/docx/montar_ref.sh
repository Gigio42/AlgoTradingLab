#!/bin/bash
# Monta o modelo .docx (reference.docx) do TG a partir do modelo padrão do pandoc:
# estilos de estilos.xml, Times New Roman 12 em português, página A4 com margens
# 3/2/3/2 cm, número da página no alto à direita (Manual FATEC-ID 1.5), e o Word
# atualizando sumário e listas ao abrir.
# Uso: montar_ref.sh <pandoc> <saida.docx>   (chamado pelo converter.sh)
set -euo pipefail
C=$(cd "$(dirname "$0")" && pwd); P=$1; OUT=$2
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cd "$T"
"$P" -o ref.docx --print-default-data-file reference.docx
mkdir x && cd x && bsdtar -xf ../ref.docx
perl -0pi -e 's{<w:rFonts w:asciiTheme[^>]*/>}{<w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman" w:eastAsia="Times New Roman" w:cs="Times New Roman"/>}; s{<w:lang w:val="en-US"}{<w:lang w:val="pt-BR"}; s{<w:spacing w:after="200" />}{<w:spacing w:after="0"/>}' word/styles.xml
# troca os estilos que existem e acrescenta os novos
ESTILOS="$C/estilos.xml" perl -0pi -e '
  open my $f, "<", $ENV{ESTILOS} or die; local $/; my $novos = <$f>; close $f;
  $novos =~ s/<!--.*?-->\s*//gs;
  for my $id ($novos =~ /w:styleId="([^"]+)"/g) { s{<w:style\b[^>]*w:styleId="$id"[^>]*>.*?</w:style>\s*}{}s; }
  s{</w:styles>}{$novos</w:styles>};
' word/styles.xml
# cabeçalhos: rIdCab1 = número da página à direita; rIdCab2 = vazio (abertura de capítulo)
for n in 1 2; do
  if [ $n = 1 ]; then conteudo='<w:pPr><w:jc w:val="right"/></w:pPr><w:r><w:fldChar w:fldCharType="begin"/></w:r><w:r><w:instrText xml:space="preserve"> PAGE </w:instrText></w:r><w:r><w:fldChar w:fldCharType="separate"/></w:r><w:r><w:t>1</w:t></w:r><w:r><w:fldChar w:fldCharType="end"/></w:r>'; else conteudo=''; fi
  printf '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<w:hdr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:p>%s</w:p></w:hdr>\n' "$conteudo" > word/header$n.xml
  perl -0pi -e "s{</Relationships>}{<Relationship Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/header\" Id=\"rIdCab$n\" Target=\"header$n.xml\"/></Relationships>}" word/_rels/document.xml.rels
  perl -0pi -e "s{</Types>}{<Override PartName=\"/word/header$n.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.wordprocessingml.header+xml\"/></Types>}" '[Content_Types].xml'
done
# o Word pergunta, ao abrir, se atualiza os campos (sumário e listas)
perl -0pi -e 's{<w:footnotePr}{<w:updateFields w:val="true"/><w:footnotePr}' word/settings.xml
# seção final (a do corpo): A4, margens 3/2/3/2 cm, número no alto à direita
perl -0pi -e 's{</w:body>}{<w:sectPr><w:headerReference w:type="default" r:id="rIdCab1"/><w:headerReference w:type="first" r:id="rIdCab2"/><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="1701" w:right="1134" w:bottom="1134" w:left="1701" w:header="709" w:footer="709" w:gutter="0"/></w:sectPr></w:body>}' word/document.xml
grep -q 'xmlns:r=' word/document.xml || perl -pi -e 's{<w:document }{<w:document xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" }' word/document.xml
for f in word/styles.xml word/settings.xml word/document.xml; do xmllint --noout "$f"; done
rm -f "$OUT"; bsdtar --format zip -cf "$OUT" '[Content_Types].xml' _rels docProps word
