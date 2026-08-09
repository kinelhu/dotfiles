# report-helpers.R — house-style exhibit helpers for a stats-report .Rmd (HTML + PDF).
# -----------------------------------------------------------------------------
# One source() line pulls in everything needed to render house-styled tables and
# figure legends identically in both formats. Sources gt-house.R itself, so the
# .Rmd setup chunk only needs:  source(".../report-helpers.R")
#
# Assumes (define these in the .Rmd setup chunk before the exhibit chunks run):
#   - packages: tidyverse (readr), gt, gtsummary, htmltools, knitr
#   - globals:  tab_dir  (dir holding the table CSV/RDS files)
#               fig_dir  (dir holding the figure PNGs and <name>_legend.md files)
# The helpers read tab_dir/fig_dir at CALL time, so sourcing order is flexible.
#
# See docs/report-authoring.md (in the project) for the usage API and the
# brittleness notes; the palette/CSS/LaTeX plumbing is documented in the pandoc
# README. Keep this file and the .Rmd's own stats helpers separate — only the
# EXHIBIT machinery lives here.
# -----------------------------------------------------------------------------

source("/Users/kinelhu/.dotfiles/pandoc/themes/kinan/gt-house.R")   # gt_house(): house-style gt tables

# House tables. HTML: gt + gt_house() (matches the Bootstrap `.table` style).
# PDF: emit a pandoc PIPE table instead of gt's raw LaTeX, so it flows through the
# house Lua filters (table-header-font.lua → Monaspace Neon headers; table-zebra.lua
# → teal rules + zebra) exactly like the markdown tables. gt/gtsummary LaTeX bypasses
# those filters, which is why the gts looked unstyled in the PDF.
latex_escape <- function(x) {                              # minimal escape for title text
  x <- gsub("\\\\", "\\\\textbackslash{}", x)
  x <- gsub("([&%$#_{}])", "\\\\\\1", x)
  x <- gsub("~", "\\\\textasciitilde{}", x)
  gsub("\\^", "\\\\textasciicircum{}", x)
}
tex_exhibit_title <- function(title)                       # bold teal Neon line, above the exhibit (PDF)
  paste0("```{=latex}\n\\par\\vspace{0.6em}\\noindent{\\HeaderFont\\color{AccentPrimary}",
         latex_escape(title), "}\\par\\vspace{0.15em}\n```\n\n")
# Direct tabularray longtabs with CUSTOM column X-weights + the house style (teal rules, zebra, HeaderFont).
# Used when col_widths is given, because pandoc's own width inference from a generated table is unreliable.
# Cells are LaTeX-escaped, so markdown in cells is NOT rendered — use for plain CSV tables, not gtsummary.
tex_tblr <- function(df, widths) {
  if (length(widths) != ncol(df)) widths <- rep(1, ncol(df))
  num  <- vapply(df, function(c) { v <- c[nzchar(c)]; length(v) > 0 && all(grepl("^[-0-9.,%() /+–]+$", v)) }, logical(1))
  colspec <- paste0(sprintf("X[%s,%s]", format(widths, trim = TRUE), ifelse(num, "r", "l")), collapse = "")
  hdr  <- paste0("{\\HeaderFont ", latex_escape(names(df)), "}", collapse = " & ")
  rows <- vapply(seq_len(nrow(df)), function(i) paste0(latex_escape(as.character(df[i, ])), collapse = " & "), character(1))
  zebra <- if (nrow(df) >= 2) 1 + seq(2, nrow(df), by = 2) else integer(0)   # header = row 1; shade alt body rows
  zspec <- if (length(zebra)) sprintf(", row{%s} = {bg=AccentLight}", paste(zebra, collapse = ",")) else ""
  paste0("```{=latex}\n",
    sprintf("\\begin{longtabs}[label=none]{colspec = {%s}, rowhead = 1%s}\n", colspec, zspec),
    "\\toprule[AccentPrimary]\n", hdr, " \\\\\n\\midrule[AccentPrimary]\n",
    paste0(rows, " \\\\", collapse = "\n"), "\n\\bottomrule[AccentPrimary]\n\\end{longtabs}\n```")
}
# landscape = TRUE rotates the page for a wide table (pdflscape, loaded by the template).
# col_widths = numeric weights (one per column) → tex_tblr for exact control instead of auto widths.
house_df <- function(df, title = NULL, note = NULL, label = NULL, landscape = FALSE, col_widths = NULL) {
  title <- paste(c(label, title), collapse = " "); if (!nzchar(title)) title <- NULL  # fold "Table Sx." in
  if (knitr::is_latex_output()) {
    df <- as.data.frame(df, check.names = FALSE)
    names(df) <- gsub("[\r\n]+", " ", names(df))          # newlines in headers break pipe tables (gtsummary)
    df[] <- lapply(df, function(col) { col <- as.character(col); col[is.na(col)] <- ""; col })  # blank NA cells
    body <- if (!is.null(col_widths)) tex_tblr(df, col_widths)               # custom widths (direct tabularray)
            else paste(knitr::kable(df, format = "pipe"), collapse = "\n")   # auto widths via kable + Lua filters
    out <- if (!is.null(title)) paste0(tex_exhibit_title(title), body) else body
    # note as a footnote: \footnotesize + heavier grey, a step below the figure-legend \small (a table
    # footnote is subordinate to a legend). Markdown between the raw-latex spans is still processed by pandoc.
    if (!is.null(note)) out <- paste0(out, "\n\n`{\\footnotesize\\color{black!70}`{=latex}", note, "`\\par}`{=latex}")
    if (landscape)
      out <- paste0("```{=latex}\n\\begin{landscape}\n```\n\n", out, "\n\n```{=latex}\n\\end{landscape}\n```\n")
    return(knitr::asis_output(out))
  }
  g <- gt::gt(df)
  if (!is.null(note)) g <- g |> gt::tab_source_note(gt::md(note))
  g <- gt_house(g)
  if (is.null(title)) return(g)
  # Title OUTSIDE the table (left-aligned teal Neon .exhibit-title), matching the PDF — not gt's centred caption.
  htmltools::tagList(htmltools::tags$div(title, class = "exhibit-title"),
                     htmltools::HTML(gt::as_raw_html(g)))
}
# Figure legend: split the bold lead from the body and render them INLINE as one paragraph — a teal Neon
# run-in lead (.exhibit-lead) then an italic, slightly-smaller body (.figure-legend). Format-aware (CSS for
# HTML, inline raw LaTeX for PDF). The leading blank line is REQUIRED: without it pandoc folds the fence /
# raw block into the preceding figure's paragraph (the two chunks render with no blank line between them),
# which is why the div markup showed up literally. Use in an asis chunk: `fig_legend("F_x")`.
fig_legend <- function(name, label = NULL) {
  txt  <- fig_cap(name)
  m    <- regmatches(txt, regexec("^\\s*\\*\\*(.+?)\\*\\*\\s*(.*)$", txt))[[1]]
  has  <- length(m) == 3
  lead <- if (has) trimws(m[2]) else ""
  body <- if (has) trimws(m[3]) else txt
  lead <- trimws(paste(c(label, lead), collapse = " "))   # fold "Figure Sx." into the teal Neon lead
  if (knitr::is_latex_output()) {
    ld <- if (nzchar(lead))   # \HeaderFont{} — the {} keeps the control word from eating the lead's first word
      paste0("`\\textcolor{AccentPrimary}{\\HeaderFont{}`{=latex}", lead, "`}`{=latex} ") else ""
    return(knitr::asis_output(paste0(               # body: near-parity \small, upright, heavier grey
      "\n\n", ld,
      "`{\\small\\color{black!70}`{=latex}", body, "`\\par}`{=latex}\n")))
  }
  knitr::asis_output(paste0(
    "\n\n::: {.figure-legend}\n",
    if (nzchar(lead)) paste0("[", lead, "]{.exhibit-lead} ") else "",
    body, "\n:::\n"))
}
# note defaults to the table's `<name>_footer.md` sidecar (written by save_df_tbl/save_tbl) — the single source of
# the footnote, authored at the table in the analysis script. Pass note= explicitly only to override for a one-off.
read_footer <- function(name) {
  p <- file.path(tab_dir, paste0(name, "_footer.md"))
  if (file.exists(p)) paste(readLines(p, warn = FALSE), collapse = " ") else NULL
}
show_csv <- function(csv, title = NULL, note = NULL, label = NULL, landscape = FALSE, col_widths = NULL) {
  if (is.null(note)) note <- read_footer(sub("\\.csv$", "", csv))
  house_df(readr::read_csv(file.path(tab_dir, csv), show_col_types = FALSE), title, note, label, landscape, col_widths)
}
# gtsummary tables (T1): HTML renders the native object (keeps bold labels, indented
# levels, BLANK not "NA" category cells); PDF flattens to a tibble so the pipe-table
# route can house-style it.
show_gts <- function(rds, title = NULL, note = NULL, label = NULL, landscape = FALSE, col_widths = NULL) {
  if (is.null(note)) note <- read_footer(sub("\\.rds$", "", rds))
  x <- readRDS(file.path(tab_dir, rds))
  if (knitr::is_latex_output()) return(house_df(gtsummary::as_tibble(x), title, note, label, landscape, col_widths))
  title <- paste(c(label, title), collapse = " "); if (!nzchar(title)) title <- NULL
  g <- gtsummary::as_gt(x)
  if (!is.null(note)) g <- g |> gt::tab_source_note(gt::md(note))
  g <- gt_house(g)
  if (is.null(title)) return(g)
  htmltools::tagList(htmltools::tags$div(title, class = "exhibit-title"),
                     htmltools::HTML(gt::as_raw_html(g))) }
# Prefer the vector PDF in a LaTeX/PDF build (sharp at any scale, journal-preferred; save_fig writes it via
# cairo_pdf, so fonts embed and alpha is honoured), fall back to the 300-dpi PNG for HTML (browsers can't inline
# a PDF as <img>) or if no PDF exists. One code path for every figure — including the Graphviz pipeline diagram.
fig <- function(name) {
  pdf <- file.path(fig_dir, paste0(name, ".pdf"))
  knitr::include_graphics(
    if (knitr::is_latex_output() && file.exists(pdf)) pdf
    else file.path(fig_dir, paste0(name, ".png")))
}
fig_cap <- function(name) {                                 # descriptive caption from the figure's legend .md (no number)
  p <- file.path(fig_dir, paste0(name, "_legend.md"))
  if (!file.exists(p)) return("")
  txt <- paste(readLines(p, warn = FALSE), collapse = " ")
  sub("^\\*\\*Figure\\.?\\s*", "**", txt)                    # drop the "Figure." placeholder, keep the bold title lead
}
