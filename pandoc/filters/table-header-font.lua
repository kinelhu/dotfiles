-- table-header-font.lua
-- Sets pandoc table header-row content in \HeaderFont (Monaspace Neon
-- ExtraBold, defined in house-style.tex) to echo the section-header
-- treatment. Only touches header-cell inline content -- column widths,
-- table environment (longtable/tabular), and everything else pandoc's
-- default LaTeX table writer does are left completely untouched.
--
-- Wrapped in an explicit {...} group rather than relying on cells being
-- implicitly scoped: plain l/c/r columns (pandoc's default, no special
-- column modifiers) do not automatically group each cell's content, so an
-- unscoped font switch could bleed into the next column of the same row.
--
-- Requires \HeaderFont to already be defined (house-style.tex, pulled in
-- by stats-report-template.tex before \begin{document}). No-op for
-- non-LaTeX output formats.

local function is_latex()
  return FORMAT:match("latex") or FORMAT:match("beamer")
end

function Table(tbl)
  if not is_latex() then
    return nil
  end
  if not tbl.head then
    return nil
  end

  for _, row in ipairs(tbl.head.rows) do
    for _, cell in ipairs(row.cells) do
      for _, block in ipairs(cell.contents) do
        if block.content then
          table.insert(block.content, 1, pandoc.RawInline("latex", "{\\HeaderFont "))
          table.insert(block.content, pandoc.RawInline("latex", "}"))
        end
      end
    end
  end

  return tbl
end
