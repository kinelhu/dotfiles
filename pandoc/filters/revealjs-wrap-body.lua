-- revealjs-wrap-body.lua
-- Two jobs:
--   1. Convert ::: {.block} / {.alertblock} / {.exampleblock} to raw <div> HTML
--      so RevealJS never sees nested <section> elements (which break navigation).
--   2. Wrap per-slide content (non-h2 blocks) in .slide-body for CSS centering.
-- No-op for non-RevealJS output.

if FORMAT ~= "revealjs" then return {} end

local BLOCK_CLASSES = { block = true, alertblock = true, exampleblock = true }

-- Pass 1 : convert .block / .alertblock / .exampleblock divs → raw HTML divs
function Div(el)
  local block_class = nil
  for _, cls in ipairs(el.classes) do
    if BLOCK_CLASSES[cls] then block_class = cls; break end
  end
  if not block_class then return nil end

  local title_text = ""
  local body_blocks = {}
  for _, blk in ipairs(el.content) do
    if blk.t == "Header" and title_text == "" then
      title_text = pandoc.utils.stringify(blk)
    else
      table.insert(body_blocks, blk)
    end
  end

  local body_html = pandoc.write(pandoc.Pandoc(body_blocks), "html")

  local html = '<div class="beamer-block ' .. block_class .. '">'
  if title_text ~= "" then
    html = html .. '<div class="block-title">' .. title_text .. '</div>'
  end
  html = html .. '<div class="block-body">' .. body_html .. '</div>'
  html = html .. '</div>'

  return pandoc.RawBlock("html", html)
end

-- Pass 2 : wrap post-h2 content in .slide-body for vertical centering
function Pandoc(doc)
  local new_blocks = {}
  local buffer     = {}
  local in_slide   = false

  local function flush()
    if #buffer > 0 then
      table.insert(new_blocks,
        pandoc.Div(buffer, pandoc.Attr("", { "slide-body" }, {})))
      buffer = {}
    end
  end

  for _, block in ipairs(doc.blocks) do
    if block.t == "Header" then
      if in_slide then flush() end
      table.insert(new_blocks, block)
      in_slide = (block.level == 2)
    elseif in_slide then
      table.insert(buffer, block)
    else
      table.insert(new_blocks, block)
    end
  end

  if in_slide then flush() end
  return pandoc.Pandoc(new_blocks, doc.meta)
end
