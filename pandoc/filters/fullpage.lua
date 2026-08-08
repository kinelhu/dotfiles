-- fullpage.lua
-- A Div with class `fullpage` is printed on its own page in the PDF, vertically
-- centred (a "plate"): \clearpage before it, \vfill above and below to centre the
-- content, and \clearpage after. Wrap a whole exhibit — an image chunk plus its
-- fig_legend chunk, or a show_csv/show_gts table chunk — in the div:
--
--   ::: {.fullpage}
--   ```{r}
--   fig("F_x")
--   ```
--   ```{r, results='asis', echo=FALSE}
--   fig_legend("F_x", "Figure 2.")
--   ```
--   :::
--
-- No-op for non-LaTeX output (HTML is fluid and just renders the content).

local function is_latex()
  return FORMAT:match("latex") or FORMAT:match("beamer")
end

function Div(el)
  if not is_latex() then
    return nil
  end
  for _, cls in ipairs(el.classes) do
    if cls == "fullpage" then
      local out = { pandoc.RawBlock("latex", "\\clearpage\\null\\vfill") }
      for _, b in ipairs(el.content) do
        table.insert(out, b)
      end
      table.insert(out, pandoc.RawBlock("latex", "\\vfill\\clearpage"))
      return out
    end
  end
  return nil
end
