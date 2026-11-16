-- Filtro do pandoc para o TG: transforma os marcadores @@...@@ do prep.pl em
-- estilos, campos e seções do Word, e numera títulos, equações e legendas como
-- no PDF. Os estilos citados aqui estão em estilos.xml.

local function raw(x) return pandoc.RawBlock('openxml', x) end
local function esc(s) return (s:gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;')) end
local function par(estilo, texto, extra)
  return raw('<w:p><w:pPr><w:pStyle w:val="' .. estilo .. '"/>' .. (extra or '') ..
    '</w:pPr><w:r><w:t xml:space="preserve">' .. esc(texto) .. '</w:t></w:r></w:p>')
end
local function marca(nome) return raw('<w:p><w:pPr><w:pStyle w:val="' .. nome .. '"/></w:pPr></w:p>') end

-- Capa e folha de rosto: \vspace e \vfill do LaTeX viram parágrafos vazios de
-- altura exata. A altura de cada bloco é estimada (Times, linha simples = 1,15 do
-- corpo da letra) e a sobra da página é dividida entre os \vfill, com folga para
-- a última linha nunca pular para a página seguinte.
local ALTURA_TEXTO_PT, FOLGA_PT = 700, 40
local function espacador(pt)
  if pt < 1 then return nil end
  return pandoc.RawBlock("openxml", string.format(
    "<w:p><w:pPr><w:spacing w:before=\"0\" w:after=\"0\" w:line=\"%d\" w:lineRule=\"exact\"/><w:rPr><w:sz w:val=\"2\"/></w:rPr></w:pPr></w:p>",
    math.floor(math.min(pt, 1584) * 20)))
end
local function altura(item)
  if item.t ~= "Div" then return 0 end
  local estilo, total = item.attributes["custom-style"], 0
  for _, b in ipairs(item.content) do
    if estilo == "Natureza" then         -- 9 cm de largura, ~47 caracteres por linha, linha simples
      total = total + math.ceil((utf8.len(pandoc.utils.stringify(b)) or 0) / 47) * 12 * 1.15
    else                                 -- linhas separadas por \\ , espaçamento 1,5
      local linhas = 1
      if b.content then for _, x in ipairs(b.content) do if x.t == "LineBreak" then linhas = linhas + 1 end end end
      total = total + linhas * (estilo == "TituloCapa" and 16 or 14) * 1.15 * 1.5
    end
  end
  return total
end
function montar_capa(itens)
  local usado, nvfill = 0, 0
  for _, it in ipairs(itens) do
    if it.vfill then nvfill = nvfill + 1
    elseif it.espaco then usado = usado + (it.espaco == "linha" and 18 or tonumber(it.espaco) * ALTURA_TEXTO_PT)
    else usado = usado + altura(it) end
  end
  local vfill = nvfill > 0 and math.max(0, (ALTURA_TEXTO_PT - FOLGA_PT - usado) / nvfill) or 0
  local res = {}
  for _, it in ipairs(itens) do
    local e = it.vfill and espacador(vfill) or (it.espaco and espacador(it.espaco == "linha" and 18 or tonumber(it.espaco) * ALTURA_TEXTO_PT))
    if e then table.insert(res, e) elseif not it.vfill and not it.espaco then table.insert(res, it) end
  end
  return res
end

local QUEBRA = '<w:p><w:r><w:br w:type="page"/></w:r></w:p>'

-- Quebra de seção. Página A4, margens 3/2/3/2 cm (Manual FATEC 1.1). Seção sem
-- cabeçalho = página contada mas sem número (pré-textuais). titlePg = primeira
-- página da seção sem número (abertura de CAPÍTULO I, II e III, Manual 1.5).
local PAGINA = '<w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="1701" w:right="1134" ' ..
  'w:bottom="1134" w:left="1701" w:header="709" w:footer="709" w:gutter="0"/>'
local function secao(o)
  local h = ''
  if o.cabecalho then
    h = '<w:headerReference w:type="default" r:id="rIdCab1"/>'
    if o.titlePg then h = h .. '<w:headerReference w:type="first" r:id="rIdCab2"/>' end
  end
  return raw('<w:p><w:pPr><w:sectPr>' .. h .. PAGINA ..
    (o.vAlign and '<w:vAlign w:val="both"/>' or '') ..
    (o.titlePg and '<w:titlePg/>' or '') .. '</w:sectPr></w:pPr></w:p>')
end
local function eh_secao(b) return b.t == 'RawBlock' and b.text:find('<w:sectPr>', 1, true) ~= nil end
local function eh_quebra(b) return b.t == 'RawBlock' and b.text == QUEBRA end

-- Sumário e listas como campos do Word (o Word pergunta se atualiza ao abrir).
local function campo(instr, titulo)
  return raw('<w:p><w:pPr><w:pStyle w:val="TituloPretextual"/></w:pPr><w:r><w:t>' .. titulo .. '</w:t></w:r></w:p>' ..
    '<w:p><w:r><w:fldChar w:fldCharType="begin" w:dirty="true"/></w:r>' ..
    '<w:r><w:instrText xml:space="preserve"> ' .. instr .. ' </w:instrText></w:r>' ..
    '<w:r><w:fldChar w:fldCharType="separate"/></w:r>' ..
    '<w:r><w:t>Clique aqui com o botão direito e escolha Atualizar campo.</w:t></w:r>' ..
    '<w:r><w:fldChar w:fldCharType="end"/></w:r></w:p>')
end
local LISTAS = {
  TOC = campo('TOC \\o "1-3" \\h \\z \\u', 'SUMÁRIO'),
  -- Lista única de ilustrações desde 05/11/2026 (Manual 4.1.1.10: os quadros
  -- caíram para 4): a LOF lê os três estilos de legenda. LOQ e LGR ficam para o
  -- caso de o main.tex voltar às listas separadas.
  LOF = campo('TOC \\h \\z \\t "Image Caption,1,Legenda Quadro,1,Legenda Grafico,1"', 'LISTA DE ILUSTRAÇÕES'),
  LOQ = campo('TOC \\h \\z \\t "Legenda Quadro,1"', 'LISTA DE QUADROS'),
  LGR = campo('TOC \\h \\z \\t "Legenda Grafico,1"', 'LISTA DE GRÁFICOS'),
  LOT = campo('TOC \\h \\z \\t "Table Caption,1"', 'LISTA DE TABELAS'),
}

local function comeca(b, prefixos)
  if b.t ~= 'Para' and b.t ~= 'Plain' then return false end
  local s = pandoc.utils.stringify(b)
  for _, p in ipairs(prefixos) do if s:sub(1, #p) == p then return true end end
  return false
end
local function fonte_ou_nota(b) return comeca(b, {'Fonte:', 'Nota:'}) end

-- Largura das colunas de tabelas sem largura definida no LaTeX (colunas l, c, r):
-- proporcional ao texto mais longo, como o LaTeX faz, em vez de colunas iguais
-- ocupando a página toda.
local LARGURA_TEXTO_CM, CM_POR_CARACTERE, FOLGA_CM = 16.0, 0.19, 0.45
local function larguras_naturais(t, forcar)
  if not forcar then
    for _, cs in ipairs(t.colspecs) do
      if cs[2] ~= nil and cs[2] ~= pandoc.ColWidthDefault and type(cs[2]) == 'number' then return end
    end
  end
  local n, maior = #t.colspecs, {}
  for i = 1, n do maior[i] = 1 end
  local function linhas(rows)
    for _, r in ipairs(rows) do
      local c = 1
      for _, cel in ipairs(r.cells) do
        if cel.col_span == 1 and c <= n then
          local len = utf8.len(pandoc.utils.stringify(cel.contents)) or 1
          if len > maior[c] then maior[c] = len end
        end
        c = c + cel.col_span
      end
    end
  end
  linhas(t.head.rows)
  for _, corpo in ipairs(t.bodies) do linhas(corpo.head); linhas(corpo.body) end
  linhas(t.foot.rows)
  local soma, cm = 0, {}
  for i = 1, n do cm[i] = maior[i] * CM_POR_CARACTERE + FOLGA_CM; soma = soma + cm[i] end
  if soma > LARGURA_TEXTO_CM then
    -- não cabe: as colunas curtas (até a cota de cada uma) ficam como estão e só
    -- as longas encolhem, como o LaTeX faria quebrando o texto delas
    local cota, fixas, longas = LARGURA_TEXTO_CM / n, 0, 0
    for i = 1, n do if cm[i] <= cota then fixas = fixas + cm[i] else longas = longas + cm[i] end end
    local escala = longas > 0 and (LARGURA_TEXTO_CM - fixas) / longas or 1
    for i = 1, n do if cm[i] > cota then cm[i] = cm[i] * escala end end
  end
  for i = 1, n do t.colspecs[i] = {t.colspecs[i][1], cm[i] / LARGURA_TEXTO_CM} end
end

-- Larguras p{..} do LaTeX, que o pandoc descarta e o prep.pl esconde na legenda
-- (LARGURAS..FIM): tira a marca da legenda e devolve a lista (0 = coluna l, c
-- ou r, sem largura, que fica com a largura natural).
local function tirar_larguras(inl)
  local w, novo = nil, pandoc.Inlines{}
  for _, x in ipairs(inl) do
    local s = x.t == 'Str' and x.text:match('^LARGURAS(.-)FIM$')
    if s then
      w = {}
      for v in s:gmatch('[^_]+') do table.insert(w, tonumber(v)) end
    elseif not (w and #novo == 0 and x.t == 'Space') then
      novo:insert(x)
    end
  end
  return w, novo
end
local function aplicar_larguras(t, w)
  larguras_naturais(t, true)
  if not w then return end
  -- colunas com largura no LaTeX ficam com ela; as outras (l, c, r) dividem o
  -- que sobra da linha, se a largura natural delas couber nisso
  local dadas, naturais = 0, 0
  for i, cs in ipairs(t.colspecs) do
    if (w[i] or 0) > 0 then dadas = dadas + w[i] else naturais = naturais + cs[2] end
  end
  local resto = 1 - dadas
  local escala = (naturais > 0 and resto > naturais) and resto / naturais or 1
  for i, cs in ipairs(t.colspecs) do
    t.colspecs[i] = {cs[1], (w[i] or 0) > 0 and w[i] or cs[2] * escala}
  end
end
local function ler_larguras(s)
  local w = {}
  for v in s:gmatch('[^_]+') do table.insert(w, tonumber(v)) end
  return w
end

-- Legenda em cima (estilo Image Caption, que alimenta a lista de ilustrações),
-- conteúdo centralizado e Fonte/Nota embaixo, um bloco depois do outro. (O
-- pandoc poria cada bloco da figura numa célula de tabela, lado a lado.)
local function estilo_legenda(cap)
  local s = pandoc.utils.stringify(cap)
  if s:match('^Quadro') then return 'Legenda Quadro' end
  if s:match('^Gráfico') then return 'Legenda Grafico' end
  return 'Image Caption'
end
function Figure(f)
  local w, cap = tirar_larguras(pandoc.utils.blocks_to_inlines(f.caption.long))
  local out = { pandoc.Div({pandoc.Para(cap)}, {['custom-style'] = estilo_legenda(cap)}) }
  for _, b in ipairs(f.content) do
    if fonte_ou_nota(b) then
      table.insert(out, pandoc.Div({pandoc.Para(b.content)}, {['custom-style'] = 'FonteIlustracao'}))
    elseif b.t == 'Table' then
      aplicar_larguras(b, w)
      table.insert(out, marca('MarcaQuadro'))   -- figura com tabela = quadro (grade fechada)
      table.insert(out, b)
    elseif b.t == 'Para' or b.t == 'Plain' then
      table.insert(out, pandoc.Div({pandoc.Para(b.content)}, {['custom-style'] = 'Figure'}))
    else
      table.insert(out, b)
    end
  end
  return out
end

-- Quadro solto (só a tabela no ambiente): o pandoc o transforma em tabela com
-- legenda. A legenda sai do objeto e vira parágrafo Image Caption.
function Table(t)
  local w, cap = tirar_larguras(pandoc.utils.blocks_to_inlines(t.caption.long))
  if w then
    aplicar_larguras(t, w)
    t.caption = pandoc.Caption({pandoc.Plain(cap)})
  else
    larguras_naturais(t)
  end
  if pandoc.utils.stringify(cap):match('^Quadro') then
    t.caption = pandoc.Caption()
    return { pandoc.Div({pandoc.Para(cap)}, {['custom-style'] = 'Legenda Quadro'}), marca('MarcaQuadro'), t }
  end
  return t
end

-- Código dos apêndices com as cores do PDF (codigo.theme); a numeração das
-- linhas é posta depois, no posprocessar.pl.
function CodeBlock(c)
  c.classes = {'cpp'}
  c.attributes = {}
  return c
end

-- Equação numerada à direita, (capítulo.n) como no PDF: centralizada por
-- tabulação, com o número encostado na margem.
local function equacao(b)
  if b.t ~= 'Para' or #b.content < 2 then return nil end
  local s = b.content[1]
  if s.t ~= 'Str' then return nil end
  local n = s.text:match('^EQNUM(.-)EQNUM$')
  if not n then return nil end
  local corpo = {pandoc.RawInline('openxml', '<w:r><w:tab/></w:r>')}
  for i = 2, #b.content do
    local x = b.content[i]
    if x.t == 'Math' then table.insert(corpo, pandoc.Math('InlineMath', '\\displaystyle ' .. x.text))
    elseif x.t ~= 'Space' and x.t ~= 'SoftBreak' then table.insert(corpo, x) end
  end
  table.insert(corpo, pandoc.RawInline('openxml', '<w:r><w:tab/></w:r>'))
  table.insert(corpo, pandoc.Str('(' .. n .. ')'))
  return pandoc.Div({pandoc.Para(corpo)}, {['custom-style'] = 'Equacao'})
end

function Pandoc(doc)
  local out = {}
  local estilo = nil           -- estilo aplicado a tudo dentro de capa, resumo e referências
  local depois_div = false     -- o título que vem logo depois de "CAPÍTULO N" não quebra página
  local secao_com_div = false  -- a seção atual começou com "CAPÍTULO N"
  local proxima_tabela = nil   -- marca da próxima tabela (lista de siglas)
  local proxima_largura = nil  -- larguras da próxima tabela solta (LARGURAS..FIM)
  local cap, sec, sub, apendice = 0, 0, 0, nil
  local capa = nil             -- blocos da capa ou folha de rosto em montagem (ver montar_capa)
  local function add(b) table.insert(capa or out, b) end

  for _, b in ipairs(doc.blocks) do
    local m = (b.t == 'Para' or b.t == 'Plain') and pandoc.utils.stringify(b):match('^@@(.-)@@$')
    if m then
      local cmd, arg = m:match('^(%S+)%s*(.*)$')
      if cmd == "CAPA" then estilo = "Centralizado"; capa = {}
      elseif cmd == "FIMCAPA" then
        estilo = nil
        for _, x in ipairs(montar_capa(capa)) do table.insert(out, x) end
        capa = nil
        add(secao{})
      elseif cmd == "ESPACO" then if capa then table.insert(capa, {espaco = arg}) end
      elseif cmd == "VFILL" then if capa then table.insert(capa, {vfill = true}) end
      elseif cmd == 'NATUREZA' then estilo = 'Natureza'
      elseif cmd == 'FIMNATUREZA' then estilo = 'Centralizado'
      elseif cmd == 'QUEBRA' then if estilo == 'Resumo' or estilo == 'ResumoIngles' then estilo = nil end; add(raw(QUEBRA))
      elseif cmd == 'SECAO' then add(secao{})
      elseif cmd == 'LISTA' then add(LISTAS[arg]); add(raw(QUEBRA))
      elseif cmd == 'PRETIT' then
        add(par('TituloPretextual', arg))
        if arg == 'RESUMO' then estilo = 'Resumo'
        elseif arg == 'ABSTRACT' then estilo = 'ResumoIngles'
        elseif arg == 'LISTA DE SIGLAS' then proxima_tabela = 'MarcaSemBorda' end
      elseif cmd == 'DIV' then
        add(secao{cabecalho = true, titlePg = secao_com_div})
        add(par('RotuloDivisao', arg))
        depois_div, secao_com_div = true, true
      elseif cmd == 'REFS' then
        add(raw(QUEBRA))
        add(par('Heading1', 'REFERÊNCIAS', '<w:jc w:val="center"/>'))
        estilo = 'Bibliography'
      elseif cmd == 'FIMREFS' then estilo = nil
      elseif cmd:match('^LARGURAS') then proxima_largura = ler_larguras(cmd:match('^LARGURAS(.-)FIM$'))
      end

    elseif b.t == 'Header' then
      local unnumbered = b.classes:includes('unnumbered')
      local txt = pandoc.utils.stringify(b.content)
      if b.level == 1 then
        if not depois_div then add(raw(QUEBRA)) end
        depois_div = false
        sec, sub = 0, 0
        if txt:match('^APÊNDICE') then
          apendice = txt:match('^APÊNDICE (%u)')
          add(b)  -- título do apêndice como veio (mantém o itálico)
        elseif unnumbered then
          add(par('Heading1', pandoc.text.upper(txt), '<w:jc w:val="center"/>'))
        else
          cap = cap + 1
          table.insert(b.content, 1, pandoc.Space()); table.insert(b.content, 1, pandoc.Str(tostring(cap)))
          add(b)
        end
      else
        if not unnumbered then
          local base = apendice or tostring(cap)
          if b.level == 2 then sec, sub = sec + 1, 0; base = base .. '.' .. sec
          else sub = sub + 1; base = base .. '.' .. sec .. '.' .. sub end
          table.insert(b.content, 1, pandoc.Space()); table.insert(b.content, 1, pandoc.Str(base))
        end
        if apendice then
          -- Seções do apêndice (B.1...) com a aparência de seção, mas fora do
          -- sumário: no sumário só entra o título principal do apêndice (Manual,
          -- observação do item dos apêndices). O estilo não tem nível de tópico.
          add(pandoc.Div({pandoc.Para(b.content)}, {['custom-style'] = 'SecaoApendice'}))
        else
          add(b)
        end
      end

    elseif b.t == 'Table' and (proxima_tabela or proxima_largura) then
      if proxima_largura then aplicar_larguras(b, proxima_largura) end
      if proxima_tabela then add(marca(proxima_tabela)) end
      add(b); proxima_tabela, proxima_largura = nil, nil

    elseif equacao(b) then add(equacao(b))

    elseif fonte_ou_nota(b) then
      add(pandoc.Div({b}, {['custom-style'] = 'FonteIlustracao'}))

    elseif estilo then
      -- cada parágrafo com o seu estilo (blocos aninhados, como o abstract dentro
      -- do ambiente de idioma, são abertos; marcadores soltos lá dentro somem)
      for _, c in ipairs(b.t == 'Div' and b.content or {b}) do
        local e = estilo
        if (c.t == 'Para' or c.t == 'Plain') and pandoc.utils.stringify(c):match('^@@.-@@$') then
          e = nil
        elseif (estilo == 'Resumo' or estilo == 'ResumoIngles') and comeca(c, {'Palavras-chave:', 'Keywords:'}) then
          e = estilo == 'Resumo' and 'PalavrasChave' or 'PalavrasChaveIngles'
        elseif estilo == 'Centralizado' and c.t == 'Para' and #c.content == 1 and c.content[1].t == 'Strong' then
          e = 'TituloCapa'
        end
        if e then add(pandoc.Div({c}, {['custom-style'] = e})) end
      end
    else
      add(b)
    end
  end
  if secao_com_div then add(marca('MarcaTitlePg')) end  -- a última seção também abre com "CAPÍTULO N"

  -- nunca duas quebras seguidas, nem quebra de página junto de quebra de seção
  local limpo = {}
  for i, b in ipairs(out) do
    local prox, ant = out[i + 1], limpo[#limpo]
    if eh_quebra(b) and ((ant and (eh_quebra(ant) or eh_secao(ant))) or (prox and eh_secao(prox)) or not ant) then
      -- descarta
    else
      table.insert(limpo, b)
    end
  end
  doc.blocks = limpo
  return doc
end
