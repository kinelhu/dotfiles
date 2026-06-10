-- beamer-blocks.lua
--
-- 1. Convertit {.alertblock} / {.exampleblock} en \begin{alertblock} / \begin{exampleblock}
--    (Pandoc 3.x génère \begin{block} pour tous les types)
--
-- 2. Génère \insertshortauthor pour le footer depuis la liste d'auteurs YAML :
--    - shortauthor: "El Husseini & Roux"  → utilisé tel quel (priorité)
--    - author: [Kinan El Husseini, Antoine Roux]  → "El Husseini & Roux" auto
--    - Sinon → Beamer affiche \insertauthor par défaut
--
-- Notes Beamer : géré dans le wrapper mdslides (lecture du champ YAML `notes:`
-- et injection via -H dans le preamble), pas ici — header-includes ne fonctionne
-- pas de façon fiable depuis un filtre Lua en Pandoc 3.9.
--
-- Syntaxe blocks :
--   ::: {.alertblock}
--   ### Titre
--   Corps
--   :::

-- ---- Blocks : alertblock / exampleblock ----

local BEAMER_BLOCKS = { alertblock = true, exampleblock = true }

function Div(el)
  local env = nil
  for _, cls in ipairs(el.classes) do
    if BEAMER_BLOCKS[cls] then env = cls; break end
  end
  if not env then return nil end

  local title = ""
  local body  = el.content
  if #body > 0 and body[1].t == "Header" then
    title = pandoc.utils.stringify(body[1])
    body  = { table.unpack(body, 2) }
  end

  local open  = pandoc.RawBlock("latex", "\\begin{" .. env .. "}{" .. title .. "}")
  local close = pandoc.RawBlock("latex", "\\end{"   .. env .. "}")

  local result = { open }
  for _, blk in ipairs(body) do table.insert(result, blk) end
  table.insert(result, close)
  return result
end

-- ---- Short author pour le footline ----

local function last_name(full)
  -- Tout sauf le premier mot : "Kinan El Husseini" → "El Husseini"
  return full:match("^%S+%s+(.+)$") or full
end

function Pandoc(doc)
  local meta  = doc.meta
  local short = nil

  if meta.shortauthor then
    short = pandoc.utils.stringify(meta.shortauthor)

  elseif meta.author and type(meta.author) == "table" and #meta.author > 1 then
    local names = {}
    for _, a in ipairs(meta.author) do
      table.insert(names, pandoc.utils.stringify(a))
    end
    if #names == 2 then
      short = last_name(names[1]) .. " \\& " .. last_name(names[2])
    else
      short = last_name(names[1]) .. " et~al."
    end
  end

  if short then
    -- Injecté dans include-before : hors de tout \begin{frame}, pas de diapo vide
    local cmd  = "\\renewcommand{\\insertshortauthor}{" .. short .. "}"
    local item = pandoc.MetaBlocks({pandoc.RawBlock("latex", cmd)})
    if doc.meta['include-before'] then
      table.insert(doc.meta['include-before'], item)
    else
      doc.meta['include-before'] = pandoc.MetaList({item})
    end
  end

  return doc
end
