-- fullpage.lua
-- A Div with class `fullpage` is printed on its own page in the PDF, vertically
-- centred (a "plate"), and SHRUNK-TO-FIT: the whole block (image + legend, or a
-- table) is wrapped in an adjustbox capped at 0.94\textheight, so if it would overflow
-- the page it scales down uniformly until it fits; if it already fits it is left at
-- natural size. The cap is 0.94 (not 1.0) \textheight to leave headroom for the page's
-- \topskip: a box of exactly \textheight plus \topskip overflows and floats to the next
-- page, leaving a blank one behind. \clearpage before and after isolate the page;
-- \vspace*{\fill} above / \vfill below centre it. Wrap a whole exhibit's chunk(s) in the div:
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
-- Uniform scaling shrinks the legend text along with the image (that is the point —
-- everything stays proportionate and on one page). The \linewidth minipage gives the
-- legend a width to wrap at before scaling. No-op for non-LaTeX output.
-- Requires adjustbox (loaded by stats-report-template.tex).

local function is_latex()
  return FORMAT:match("latex") or FORMAT:match("beamer")
end

function Div(el)
  if not is_latex() then
    return nil
  end
  for _, cls in ipairs(el.classes) do
    if cls == "fullpage" then
      -- Top glue is \vspace*{\fill} (starred → survives the page break) rather than \null\vfill:
      -- a \null strut plus a \textheight-capped adjustbox exceeds the page for a near-full-height plate,
      -- floating the box to the next page and leaving a blank one behind. \vspace* adds no strut.
      local open = table.concat({
        "\\clearpage\\vspace*{\\fill}",
        "\\begin{adjustbox}{max width=\\linewidth,max totalheight=0.94\\textheight,center}",
        "\\begin{minipage}{\\linewidth}",
      }, "\n")
      local close = table.concat({
        "\\end{minipage}",
        "\\end{adjustbox}",
        "\\vfill\\clearpage",
      }, "\n")
      local out = { pandoc.RawBlock("latex", open) }
      for _, b in ipairs(el.content) do
        table.insert(out, b)
      end
      table.insert(out, pandoc.RawBlock("latex", close))
      return out
    end
  end
  return nil
end
