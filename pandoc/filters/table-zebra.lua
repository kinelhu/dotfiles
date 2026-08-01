-- table-zebra.lua
-- Renders pandoc tables through tabularray's `longtabs` environment instead
-- of the default longtable, so zebra row-banding sits flush with the
-- booktabs rules at every table width.
--
-- Why not colortbl/\rowcolors (tried before, in house-style.tex history):
-- pandoc wraps longtable column specs in @{}...@{} so the table is exactly
-- \linewidth wide and the rules land flush with the margins. colortbl's row
-- shading doesn't know about that @{} trim -- it always pads shading by
-- \tabcolsep on the outer edges, so the bands overhang past the rules/margins
-- by \tabcolsep on both sides. tabularray computes its own box model (no
-- @{} involved) so `row{n} = {bg=...}` lands exactly flush by construction.
--
-- Scope: only rewrites the common case -- single table body, no
-- intermediate head/foot rows, no row/col spans, single-block cells.
-- Anything fancier (rowspans, multi-body tables) is left to pandoc's default
-- writer (plain booktabs, no zebra) rather than risk mis-rendering it.
--
-- Run AFTER table-header-font.lua in the filters: list -- that filter injects
-- \HeaderFont RawInlines into header cells; this filter just serializes
-- whatever inline content it finds (including those raw chunks) into the
-- \begin{longtabs} body.
--
-- Requires house-style.tex (\usepackage{tabularray}, \UseTblrLibrary{booktabs},
-- AccentPrimary/AccentLight colors). No-op for non-LaTeX output formats.

local function is_latex()
  return FORMAT:match("latex") or FORMAT:match("beamer")
end

local function blocks_to_latex(blocks)
  local latex = pandoc.write(pandoc.Pandoc(blocks), "latex")
  return (latex:gsub("%s+$", ""))
end

local function align_letter(align)
  if align == pandoc.AlignRight then
    return "r"
  elseif align == pandoc.AlignCenter then
    return "c"
  else
    return "l"
  end
end

local function has_span_or_multiblock(rows)
  for _, row in ipairs(rows) do
    for _, cell in ipairs(row.cells) do
      if cell.row_span > 1 or cell.col_span > 1 or #cell.contents > 1 then
        return true
      end
    end
  end
  return false
end

local function row_cells_latex(row)
  local cells = {}
  for _, cell in ipairs(row.cells) do
    table.insert(cells, blocks_to_latex(cell.contents))
  end
  return table.concat(cells, " & ")
end

function Table(tbl)
  if not is_latex() then
    return nil
  end

  -- Bail out on anything beyond the simple single-body case; pandoc's
  -- default longtable writer still handles these fine, just without zebra.
  if #tbl.bodies ~= 1 then
    return nil
  end
  local body = tbl.bodies[1]
  if #body.head > 0 or body.row_head_columns > 0 then
    return nil
  end
  if #tbl.foot.rows > 0 then
    return nil
  end
  if has_span_or_multiblock(tbl.head.rows) or has_span_or_multiblock(body.body) then
    return nil
  end

  -- Column spec: explicit pandoc widths become weighted X[] columns
  -- (tabularray fills \linewidth on its own -- no @{} bookkeeping needed);
  -- columns with no explicit width stay plain alignment letters, matching
  -- pandoc's own natural-width behaviour for tables without column widths.
  local specs = {}
  for _, cs in ipairs(tbl.colspecs) do
    local align, width = cs[1], cs[2]
    local letter = align_letter(align)
    if width == nil then
      table.insert(specs, letter)
    else
      table.insert(specs, string.format("X[%.4g,%s]", width, letter))
    end
  end

  -- Zebra: shade every other body row, starting on the 2nd body row (first
  -- body row stays unshaded, right under the header rule).
  local header_rows = #tbl.head.rows
  local body_rows = #body.body
  local shaded = {}
  for i = 2, body_rows, 2 do
    table.insert(shaded, tostring(header_rows + i))
  end

  local inner = { "colspec = {" .. table.concat(specs) .. "}" }
  if #shaded > 0 then
    table.insert(inner, "row{" .. table.concat(shaded, ",") .. "} = {bg=AccentLight}")
  end
  if header_rows > 0 then
    -- Repeat the header row(s) on every page, matching pandoc's default
    -- longtable \endhead behaviour (otherwise longtabs only shows "(Continued)").
    table.insert(inner, "rowhead = " .. header_rows)
  end

  -- tabularray's longtabs always renders a "Table N:" tag unless told
  -- otherwise -- unlike plain longtable, which stays silent when pandoc
  -- never emits a \caption. label=none is what turns that tag off (it also
  -- stops the table counter from stepping), so uncaptioned tables render
  -- with no caption row at all, matching pandoc's default behaviour.
  local outer = {}
  local has_caption = #tbl.caption.long > 0
  local has_id = tbl.attr.identifier ~= ""
  if has_caption then
    table.insert(outer, "caption={" .. blocks_to_latex(tbl.caption.long) .. "}")
    if has_id then
      table.insert(outer, "label={" .. tbl.attr.identifier .. "}")
    else
      table.insert(outer, "entry=none")
    end
  elseif has_id then
    table.insert(outer, "label={" .. tbl.attr.identifier .. "}")
  else
    table.insert(outer, "label=none")
  end

  local out = {}
  table.insert(out, "\\begin{longtabs}")
  if #outer > 0 then
    table.insert(out, "[" .. table.concat(outer, ", ") .. "]")
  end
  table.insert(out, "{" .. table.concat(inner, ", ") .. "}\n")

  table.insert(out, "\\toprule[AccentPrimary]\n")
  for _, row in ipairs(tbl.head.rows) do
    table.insert(out, row_cells_latex(row) .. " \\\\\n")
  end
  if header_rows > 0 then
    table.insert(out, "\\midrule[AccentPrimary]\n")
  end
  for _, row in ipairs(body.body) do
    table.insert(out, row_cells_latex(row) .. " \\\\\n")
  end
  table.insert(out, "\\bottomrule[AccentPrimary]\n")
  table.insert(out, "\\end{longtabs}")

  return pandoc.RawBlock("latex", table.concat(out))
end
