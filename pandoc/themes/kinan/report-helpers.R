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

# gt_house(): house-style gt tables. Resolved RELATIVE to this file rather than by
# absolute path, so a project that vendors these two files into its own assets/
# directory works unchanged. The absolute form made the vendored copy unusable and
# every project that copied it had to patch this line.
local({
  here <- tryCatch(dirname(normalizePath(sys.frame(1)$ofile, mustWork = TRUE)),
                   error = function(e) NULL)
  cand <- c(if (!is.null(here)) file.path(here, "gt-house.R"),
            "~/.dotfiles/pandoc/themes/kinan/gt-house.R")
  hit  <- Find(file.exists, path.expand(cand))
  if (is.null(hit)) stop("gt-house.R not found beside report-helpers.R", call. = FALSE)
  source(hit)
})

# ---- exhibit registry: dynamic numbering via a bottom INDEX (no inline numbers) --------------------
# Exhibits are NOT numbered inline; each caption call silently registers (id, tier, kind, caption) in order of
# appearance, and exhibit_index() prints the numbered catalogue at the end. Numbers are assigned there, per
# (tier x kind) sequence, in registration order — so reordering the document reorders the numbers for free, and
# nothing inline can drift. tier = "main" | "suppl"; kind = "figure" | "table" (kind is set by the caller).
# The registry lives in the .Rmd session and is fresh each knit (this file is sourced once, in the setup chunk).
# rlang/base provide this in recent versions; defined here so the file is
# self-contained when vendored into a project that does not attach rlang.
if (!exists("%||%")) `%||%` <- function(a, b) if (is.null(a)) b else a

.exhibit_reg <- new.env(parent = emptyenv()); .exhibit_reg$items <- list()
# tier: "main" (Figure N / Table N) | "suppl" (Supplementary Figure/Table SN) | "ref" (rendered for reference,
# UNNUMBERED — it does not consume a main/suppl number and is listed apart in the index).
register_exhibit <- function(id, tier = c("suppl", "main", "ref"), kind = c("figure", "table"), caption = "") {
  tier <- match.arg(tier); kind <- match.arg(kind)
  ids <- vapply(.exhibit_reg$items, function(e) e$id, character(1))
  if (id %in% ids) {                                         # idempotent on POSITION: first registration fixes
    i <- which(ids == id)[1]                                 # the number, so re-registering never renumbers.
    if (nzchar(caption)) .exhibit_reg$items[[i]]$caption <- caption   # but a later real call fills the caption in,
    if (nzchar(caption)) .exhibit_reg$items[[i]]$rendered <- TRUE     # and latches it as actually rendered,
    return(invisible())                                      # which is what makes declare_exhibits() below usable
  }                                                          # without blanking the index.
  .exhibit_reg$items[[length(.exhibit_reg$items) + 1L]] <-
    list(id = id, tier = tier, kind = kind, caption = caption, rendered = TRUE)
  invisible()
}
# Fix the numbering of a document's exhibits UP FRONT, in the order they will appear. Rendering is single
# pass, so exhibit_label() can otherwise only resolve a reference to an exhibit already shown; declaring the
# order lets prose cite an exhibit that appears later. Caption text still comes from the show_table()/
# fig_legend() call itself, so nothing is typed twice.
declare_exhibits <- function(..., tier = "suppl") {
  for (spec in list(...)) {
    register_exhibit(spec[[1]], tier, spec[[2]], "")
    # Declaring is not rendering. Without this flag every declared exhibit is also
    # in the registry as "shown", so setdiff(declared, shown) is always empty and
    # the "declared but never rendered" arm of check_exhibits_declared() can never
    # fire. Verified by declaring an exhibit and never rendering it: the guard
    # passed silently. A real display call latches it back to TRUE.
    i <- length(.exhibit_reg$items)
    if (identical(.exhibit_reg$items[[i]]$id, spec[[1]])) .exhibit_reg$items[[i]]$rendered <- FALSE
  }
  invisible()
}
# Every exhibit rendered must have been declared, and every declared one must be rendered. Without this the
# two lists drift silently and a forward reference points at the wrong number — the exact failure the
# declaration is meant to remove. Call after the last exhibit.
check_exhibits_declared <- function(declared) {
  shown <- vapply(Filter(function(e) isTRUE(e$rendered %||% TRUE), .exhibit_reg$items),
                  function(e) e$id, character(1))
  extra <- setdiff(shown, declared); missing <- setdiff(declared, shown)
  fmt <- function(x) if (length(x)) paste(x, collapse = ", ") else "none"   # paste() on empty gives "", not NULL
  if (length(extra) || length(missing))
    stop(sprintf("exhibit declaration out of sync — rendered but undeclared: %s | declared but never rendered: %s",
                 fmt(extra), fmt(missing)), call. = FALSE)
  invisible(TRUE)
}
exhibit_label <- function(id) {                              # resolved "Figure N" / "Supplementary Table SN" (for a rare xref)
  items <- .exhibit_reg$items
  hit <- Filter(function(x) x$id == id, items); if (!length(hit)) return(id); e <- hit[[1]]
  if (e$tier == "ref") return("")                            # reference exhibits are unnumbered
  grp <- Filter(function(x) x$tier == e$tier && x$kind == e$kind, items)
  n   <- which(vapply(grp, function(x) x$id, character(1)) == id)
  pfx <- c(main.figure = "Figure ", suppl.figure = "Supplementary Figure S",
           main.table = "Table ", suppl.table = "Supplementary Table S")[[paste(e$tier, e$kind, sep = ".")]]
  paste0(pfx, n)
}
exhibit_type <- function(tier, kind) {                       # UNNUMBERED inline type label from the declared tier
  base <- c(figure = "Figure", table = "Table")[[kind]]      # e.g. "Supplementary Figure" / "Table"
  if (tier == "suppl") paste0("Supplementary ", base) else base
}
exhibit_index <- function() {                                # the numbered catalogue — call once at the end of the report
  items <- .exhibit_reg$items
  grp <- function(tier, kind, header) {
    g <- Filter(function(x) x$tier == tier && x$kind == kind, items); if (!length(g)) return("")
    rows <- vapply(g, function(e) sprintf("| %s | %s |", exhibit_label(e$id), e$caption), character(1))
    # Pandoc takes a pipe table's relative column widths from the DASH COUNTS in the delimiter row. Left
    # at "|---|", the label column was narrow enough to break "Supplementary Figure S1" over two lines.
    # A caption may wrap (they run long); a label must not.
    paste0("\n**", header, "**\n\n| # | Exhibit |\n|", strrep("-", 26), "|", strrep("-", 62), "|\n",
           paste(rows, collapse = "\n"), "\n")
  }
  ref <- Filter(function(x) x$tier == "ref", items)          # unnumbered reference exhibits, listed apart
  ref_out <- if (length(ref)) paste0("\n**Reference (unnumbered)**\n\n| Kind | Exhibit |\n|",
    strrep("-", 26), "|", strrep("-", 62), "|\n",
    paste(vapply(ref, function(e) sprintf("| %s | %s |", tools::toTitleCase(e$kind), e$caption), character(1)),
          collapse = "\n"), "\n") else ""
  knitr::asis_output(paste0(
    grp("main", "figure", "Figures"), grp("main", "table", "Tables"),
    grp("suppl", "figure", "Supplementary figures"), grp("suppl", "table", "Supplementary tables"), ref_out))
}

# House tables. HTML: gt + gt_house() (matches the Bootstrap `.table` style).
# PDF: emit a pandoc PIPE table instead of gt's raw LaTeX, so it flows through the
# house Lua filters (table-header-font.lua → Monaspace Neon headers; table-zebra.lua
# → teal rules + zebra) exactly like the markdown tables. gt/gtsummary LaTeX bypasses
# those filters, which is why the gts looked unstyled in the PDF.
# What counts as an unbreakable numeric cell. Kept as one constant because three places must agree:
# right-alignment, \mbox protection, and width derivation. Brackets admit "2.0 [1.0-3.0]"; <> admit
# "<1%" and ">99%", which were previously read as text and mis-aligned.
NUMRE <- "^[-0-9.,%()\\[\\]<>=\u2265\u2264 /+\u2013]+$"
# perl = TRUE is REQUIRED: in a POSIX bracket expression a backslash is literal, so "\\[" and "\\]" do not
# escape — the "]" closed the class early and the pattern matched nothing at all, silently disabling both
# right-alignment and the \mbox protection.
.num_cols <- function(df) vapply(df, function(c) {
  v <- as.character(c); v <- v[!is.na(v) & nzchar(v)]
  length(v) > 0 && all(grepl(NUMRE, v, perl = TRUE)) }, logical(1))

# Recommended relative column weights, derived from the table's own content, so a caller never has to
# guess-render-correct. Numeric columns cannot break, so they claim their longest cell outright; text
# wraps, so it claims a fraction of its longest cell, floored by its longest unbreakable word (a header
# wraps between words and at hyphens, so "2005-2010" demands 4 characters, not 9). The cap keeps one very
# long label from swallowing the table: past ~30 characters it is wrapping regardless.
auto_col_widths <- function(df, group_col = NULL) {
  d <- if (!is.null(group_col) && group_col %in% names(df)) df[setdiff(names(df), group_col)] else df
  isnum <- .num_cols(d)
  maxc <- vapply(d, function(c) { v <- as.character(c); v <- v[!is.na(v) & nzchar(v)]
    if (length(v)) max(nchar(v)) else 1 }, numeric(1))
  hdr  <- vapply(strsplit(names(d), "[ /\n-]+"), function(w) max(nchar(w)), numeric(1))
  w <- ifelse(isnum, pmax(maxc, hdr), pmax(pmin(maxc, 30) / 1.8, hdr))
  round(w / min(w), 1)
}

# Display metadata authored at the table (analysis side) and read here, mirroring the <name>_footer.md
# sidecar. Grouping and column weights are properties of the table, not of the document showing it: the
# same table appears in several documents, and specifying them per document is how one copy came to
# group while another did not.
read_display <- function(name) {
  p <- file.path(tab_dir, paste0(name, "_display.dcf"))
  if (!file.exists(p)) return(list())
  d <- as.list(as.data.frame(read.dcf(p), stringsAsFactors = FALSE))
  if (!is.null(d$col_widths)) d$col_widths <- as.numeric(strsplit(d$col_widths, ",")[[1]])
  if (!is.null(d$landscape)) d$landscape <- as.logical(d$landscape)
  d[!vapply(d, function(x) length(x) == 0 || all(is.na(x)), logical(1))]
}

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
  # Length must match the DISPLAYED columns, i.e. after group_col removes its own. Falling back to equal
  # widths here would silently undo the caller's layout the moment a table gains a column.
  if (length(widths) != ncol(df))
    stop(sprintf("col_widths has %d weights for %d displayed columns%s.", length(widths), ncol(df),
                 " (group_col drops its own column)"), call. = FALSE)
  num  <- .num_cols(df)
  # A numeric cell must never be split: LaTeX treats the hyphen in a range as a break point, so a narrow
  # column rendered "2.03-4.66" as "2.03" over "4.66" and doubled every row's height. \mbox forbids the
  # break; if the column really is too narrow the overflow is visible rather than silently misleading.
  nb <- function(x, is_num) {
    if (is_num) return(ifelse(nzchar(x), paste0("\\mbox{", x, "}"), x))
    # LaTeX will not break a compound like "Pseudomonas/Aspergillus": it has no space and no hyphen, so a
    # column narrower than the token overflows into the neighbour and the tail is lost under it. Permit a
    # break after the slash instead of demanding the width.
    gsub("/", "/\\\\allowbreak{}", x, fixed = FALSE)
  }
  colspec <- paste0(sprintf("X[%s,%s]", format(widths, trim = TRUE), ifelse(num, "r", "l")), collapse = "")
  # Cells arrive with markdown bold from two sources: **Group** section rows inserted by house_df, and
  # gtsummary's **header** / __label__ markup. Applied AFTER latex_escape, so `_` is already `\_`; without
  # it the markers print literally, which is what kept gtsummary tables off this path entirely.
  md_bold <- function(x) {
    x <- gsub("\\*\\*(.+?)\\*\\*", "\\\\textbf{\\1}", x)
    gsub("\\\\_\\\\_(.+?)\\\\_\\\\_", "\\\\textbf{\\1}", x)
  }
  # \newline, not \\: inside a cell "\\" would end the table row. X columns are paragraph-mode, so this
  # is a line break within the header cell.
  # Trim the whitespace AROUND the break, not just the break: gtsummary writes the markdown hard-break
  # idiom ("**Overall**  \nN = 1,073"), and in a right-aligned column those two trailing spaces are
  # typeset, leaving the first line two characters short of the edge while the second sits flush.
  # \linebreak, not \newline: \newline fills the rest of the broken line, which overrides the column's
  # alignment ("Overall" came out flush left above a right-aligned "N = 1,073"). \linebreak adds no fill,
  # so each line follows the column. \shortstack is not an option here — it does not wrap, so a long
  # header overflows into its neighbour.
  hdr  <- paste0("{\\HeaderFont ",
                 gsub("[ \t]*[\r\n]+[ \t]*", "\\\\linebreak ",
                      md_bold(latex_escape(names(df)))), "}", collapse = " & ")
  rows <- vapply(seq_len(nrow(df)), function(i)
    paste0(mapply(nb, md_bold(latex_escape(as.character(df[i, ]))), num), collapse = " & "), character(1))
  zebra <- if (nrow(df) >= 2) 1 + seq(2, nrow(df), by = 2) else integer(0)   # header = row 1; shade alt body rows
  zspec <- if (length(zebra)) sprintf(", row{%s} = {bg=AccentLight}", paste(zebra, collapse = ",")) else ""
  paste0("```{=latex}\n",
    sprintf("\\begin{longtabs}[label=none]{colspec = {%s}, rowhead = 1%s}\n", colspec, zspec),
    "\\toprule[AccentPrimary]\n", hdr, " \\\\\n\\midrule[AccentPrimary]\n",
    paste0(rows, " \\\\", collapse = "\n"), "\n\\bottomrule[AccentPrimary]\n\\end{longtabs}\n```")
}
# landscape = TRUE rotates the page for a wide table (pdflscape, loaded by the template).
# col_widths = numeric weights (one per column) → tex_tblr for exact control instead of auto widths.
# Word tables go through flextable, NOT a markdown pipe table. Pandoc derives Word column widths from the
# pipe table's delimiter row, i.e. from each column's widest cell, so one long free-text column starves the
# short ones: a 6-column codebook gave "not stated" a 0.22-inch column that wrapped to two characters per
# line and ran a 36-row table over several pages. flextable writes the OOXML directly and autofits.
docx_ft <- function(df, title = NULL, note = NULL, fontsize = 8, col_widths = NULL) {
  # gtsummary writes **bold** / __bold__ into its label cells and flextable renders no markdown, so
  # without this Word printed "__Outcome role__" literally. Find them, strip the markers, bold the cell.
  # Headers carry it too ("**Overall**  N = 1,073"), and flextable bolds the header row itself, so the
  # markers are simply removed there. Strip pairs anywhere rather than only whole-cell, since gtsummary
  # emits both wrapped labels and partially marked headers.
  unmd <- function(x) gsub("__(.*?)__", "\\1", gsub("\\*\\*(.*?)\\*\\*", "\\1", x))
  names(df) <- gsub("[ \t]*[\r\n]+[ \t]*", "\n", unmd(names(df)))   # same trim for Word
  bold_at <- list()
  for (j in seq_along(df)) {
    hit <- grep("^(\\*\\*|__)(.*)\\1$", df[[j]])
    if (length(hit)) {
      bold_at[[length(bold_at) + 1L]] <- list(i = hit, j = j)
    }
    df[[j]] <- unmd(df[[j]])          # whole-cell markers bolded above; strip any remaining pairs
  }
  ft <- flextable::flextable(df)
  for (b in bold_at) ft <- flextable::bold(ft, i = b$i, j = b$j, part = "body")
  ft <- ft |>
    flextable::bold(part = "header") |>
    flextable::fontsize(size = fontsize, part = "all") |>
    flextable::valign(valign = "top", part = "all") |>
    flextable::padding(padding.top = 1, padding.bottom = 1, part = "all")
  # Word gets the same relative weights as the PDF. Autofit sizes columns to content and so re-creates
  # the starved-column problem on wide tables; fixed widths from the weights do not. 6.5in = letter/A4
  # text width at 1in margins. Derived from content when the caller supplies none.
  if (is.null(col_widths) || length(col_widths) != ncol(df)) col_widths <- auto_col_widths(df)
  ft <- ft |>
    flextable::width(width = 6.5 * col_widths / sum(col_widths)) |>
    flextable::set_table_properties(layout = "fixed")
  if (!is.null(title)) ft <- flextable::set_caption(ft, title)
  # flextable renders no markdown, so strip the emphasis pairs the footnote is authored with.
  if (!is.null(note))
    ft <- flextable::add_footer_lines(ft, gsub("\\*(\\S[^*]*?\\S|\\S)\\*", "\\1", note)) |>
      flextable::fontsize(size = fontsize - 1, part = "footer")
  ft
}
house_df <- function(df, title = NULL, note = NULL, label = NULL, landscape = FALSE, col_widths = NULL,
                     group_col = NULL) {
  title <- paste(c(label, title), collapse = " "); if (!nzchar(title)) title <- NULL  # fold "Table Sx." in
  has_grp <- !is.null(group_col) && group_col %in% names(df)
  is_tex <- knitr::is_latex_output()
  # Word takes the PDF's flatten-to-pipe-table route, not the gt route: pandoc's docx writer DROPS raw
  # HTML, so a gt table emits nothing at all and the exhibit silently disappears from the document. A
  # pipe table becomes a real w:tbl styled by the reference doc. Title and note go as markdown, since
  # the raw-LaTeX runs the PDF branch wraps them in would be dropped for the same reason.
  is_docx <- !is_tex && isTRUE(knitr::pandoc_to("docx"))
  if (is_tex || is_docx) {
    df <- as.data.frame(df, check.names = FALSE)
    # gtsummary authors a deliberate break in stratified headers ("**RCT**\nN = 40"). Only the pipe-table
    # route cannot carry it — a newline there terminates the row — so collapse it just for that route;
    # tabularray and flextable both render it.
    if (is_tex && is.null(col_widths)) names(df) <- gsub("[\r\n]+", " ", names(df))
    df[] <- lapply(df, function(col) { col <- as.character(col); col[is.na(col)] <- ""; col })  # blank NA cells
    if (has_grp) {                                         # section headers: one bold row per group, group col dropped (pandoc renders **md** in pipe cells)
      grp <- df[[group_col]]; body_df <- df[, setdiff(names(df), group_col), drop = FALSE]
      first <- names(body_df)[1]
      parts <- lapply(unique(grp), function(g) {
        hdr <- body_df[1, , drop = FALSE]; hdr[] <- ""; hdr[[first]] <- paste0("**", g, "**")
        rbind(hdr, body_df[grp == g, , drop = FALSE])
      })
      df <- do.call(rbind, parts); rownames(df) <- NULL
    }
    body <- if (!is.null(col_widths) && is_tex) tex_tblr(df, col_widths)     # custom widths (direct tabularray; LaTeX only)
            else paste(knitr::kable(df, format = "pipe"), collapse = "\n")   # auto widths via kable + Lua filters
    if (is_docx) return(docx_ft(df, title, note, col_widths = col_widths))
    out <- if (!is.null(title)) paste0(tex_exhibit_title(title), body) else body
    # note as a footnote: \footnotesize + heavier grey, a step below the figure-legend \small (a table
    # footnote is subordinate to a legend). Markdown between the raw-latex spans is still processed by pandoc.
    if (!is.null(note)) out <- paste0(out, "\n\n`{\\footnotesize\\color{black!70}`{=latex}", note, "`\\par}`{=latex}")
    if (landscape)
      out <- paste0("```{=latex}\n\\begin{landscape}\n```\n\n", out, "\n\n```{=latex}\n\\end{landscape}\n```\n")
    return(knitr::asis_output(out))
  }
  # A cell whose entire content is **bold** renders bold in the LaTeX path (pandoc
  # processes the markdown) and is detected and bolded explicitly in the docx path.
  # gt received the raw string, so the SAME table came out bold in the PDF and with
  # literal asterisks in the HTML. fmt_markdown on the affected columns only.
  .md_cols <- names(df)[vapply(df, function(c)
    any(grepl("^(\\*\\*|__).*\\1$", as.character(c))), logical(1))]
  g <- if (has_grp) gt::gt(df, groupname_col = group_col) else gt::gt(df)   # native spanning row groups in HTML
  if (length(.md_cols)) g <- g |> gt::fmt_markdown(columns = gt::all_of(.md_cols))
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
fig_legend <- function(name, tier = "suppl", numbered = FALSE) {
  txt  <- fig_cap(name)
  m    <- regmatches(txt, regexec("^\\s*\\*\\*(.+?)\\*\\*\\s*(.*)$", txt))[[1]]
  has  <- length(m) == 3
  lead <- if (has) trimws(m[2]) else ""
  body <- if (has) trimws(m[3]) else txt
  register_exhibit(name, tier, "figure", sub("\\.$", "", lead))   # caption = the bold lead (index adds the number)
  # Mirrors show_table(): unnumbered inline type label by default ("Supplementary Figure. <title>"), with the
  # number living in the index; numbered = TRUE resolves the registry number into the legend instead
  # ("Supplementary Figure S2. <title>"), for a journal that wants it in the caption. register_exhibit()
  # above must run first — exhibit_label() reads the registry this very call has just written to.
  lab  <- if (numbered) exhibit_label(name) else exhibit_type(tier, "figure")
  lead <- trimws(paste0(lab, ". ", lead))
  if (knitr::is_latex_output()) {
    ld <- if (nzchar(lead))   # \HeaderFont{} — the {} keeps the control word from eating the lead's first word
      paste0("`\\textcolor{AccentPrimary}{\\HeaderFont{}`{=latex}", lead, "`}`{=latex} ") else ""
    return(knitr::asis_output(paste0(               # body: near-parity \small, upright, heavier grey
      "\n\n", ld,
      "`{\\small\\color{black!70}`{=latex}", body, "`\\par}`{=latex}\n")))
  }
  if (isTRUE(knitr::pandoc_to("docx")))   # the div/span below are styling hooks with no docx equivalent
    return(knitr::asis_output(paste0("\n\n", if (nzchar(lead)) paste0("**", lead, "** ") else "", body, "\n")))
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
# show_table(): ONE table entry point. `id` is the exhibit name with or without extension; it dispatches on the
# file present in tab_dir — `<id>.rds` (a gtsummary object) else `<id>.csv` (a plain data frame). Registers for the
# bottom index (kind = "table") and renders with NO inline number. gtsummary (T1): HTML renders the native object
# (bold labels, indented levels, BLANK not "NA" cells); PDF flattens to a tibble for the house pipe-table route.
# gtsummary holds indentation as STYLING METADATA (table_styling$indent), not as
# text: as_gt() applies it, as_tibble() returns the labels flush left. show_table()
# sends HTML through as_gt() and LaTeX/docx through as_tibble(), so a Table 1 came
# out with its factor levels indented under their variable in the HTML and flush
# left in the PDF, where every level read as a variable in its own right.
#
# Re-applied as NON-BREAKING spaces, because pandoc collapses runs of ordinary
# whitespace on the way to LaTeX. n_spaces is read per row rather than assumed, so
# a table with several indent levels keeps all of them.
gts_as_tibble_indented <- function(x, unit = "\u00a0") {
  df <- gtsummary::as_tibble(x)
  ind <- x$table_styling$indent
  if (is.null(ind) || !nrow(ind)) return(df)
  lab <- names(df)[1]                       # as_tibble renames label to its header
  for (k in seq_len(nrow(ind))) {
    n <- ind$n_spaces[k]
    if (is.na(n) || n <= 0) next
    hit <- tryCatch(rlang::eval_tidy(ind$rows[[k]], data = x$table_body), error = function(e) NULL)
    if (is.null(hit)) next
    hit <- rep_len(as.logical(hit), nrow(df))
    hit[is.na(hit)] <- FALSE
    df[[lab]][hit] <- paste0(strrep(unit, n), df[[lab]][hit])
  }
  df
}

show_table <- function(id, title = NULL, note = NULL, tier = "suppl", landscape = NULL, col_widths = NULL,
                       group_col = NULL, numbered = FALSE) {
  base <- sub("\\.(csv|rds)$", "", id)
  if (is.null(note)) note <- read_footer(base)
  disp <- read_display(base)                       # authored at the table; arguments here override it
  if (is.null(col_widths)) col_widths <- disp$col_widths
  if (is.null(group_col))  group_col  <- disp$group_col
  if (is.null(landscape))  landscape  <- isTRUE(disp$landscape)
  register_exhibit(base, tier, "table", if (!is.null(title) && nzchar(title)) title else base)   # index adds the number
  # Unnumbered inline type label from the tier, e.g. "Supplementary Table. <caption>" (number lives in the index).
  # numbered = TRUE resolves the registry number into the caption instead ("Table 1. <caption>"), for a journal
  # submission where each table travels as its own file and cannot rely on a document-level index.
  lab  <- if (numbered) exhibit_label(base) else exhibit_type(tier, "table")
  disp <- if (!is.null(title) && nzchar(title)) paste0(lab, ". ", title) else lab
  rds <- file.path(tab_dir, paste0(base, ".rds"))
  if (file.exists(rds)) {                                   # gtsummary object
    x <- readRDS(rds)
    # docx joins the LaTeX branch: as_gt() below yields raw HTML, which the docx writer drops (see house_df).
    if (knitr::is_latex_output() || isTRUE(knitr::pandoc_to("docx")))
      return(house_df(gts_as_tibble_indented(x), disp, note, NULL, landscape, col_widths))
    g <- gtsummary::as_gt(x)
    if (!is.null(note)) g <- g |> gt::tab_source_note(gt::md(note))
    g <- gt_house(g)
    return(htmltools::tagList(htmltools::tags$div(disp, class = "exhibit-title"),
                              htmltools::HTML(gt::as_raw_html(g))))
  }
  house_df(readr::read_csv(file.path(tab_dir, paste0(base, ".csv")), show_col_types = FALSE),
           disp, note, NULL, landscape, col_widths, group_col)   # disp = type label + caption; NULL label
}
# Back-compat shims (deprecated — prefer show_table). Kept so older call sites don't break during migration.
show_csv <- function(csv, title = NULL, note = NULL, tier = "suppl", landscape = FALSE, col_widths = NULL)
  show_table(csv, title, note, tier, landscape, col_widths)
show_gts <- function(rds, title = NULL, note = NULL, tier = "suppl", landscape = FALSE, col_widths = NULL)
  show_table(rds, title, note, tier, landscape, col_widths)
# Prefer the vector PDF in a LaTeX/PDF build (sharp at any scale, journal-preferred; save_fig writes it via
# cairo_pdf, so fonts embed and alpha is honoured), fall back to the 300-dpi PNG for HTML (browsers can't inline
# a PDF as <img>) or if no PDF exists. One code path for every figure — including the Graphviz pipeline diagram.
# force_png = TRUE keeps the raster even in the PDF build — the escape hatch for a figure whose vector PDF is
# pathological (e.g. a 100k-point scatter that would bloat the file); no current figure needs it.
fig <- function(name, force_png = FALSE) {
  pdf <- file.path(fig_dir, paste0(name, ".pdf"))
  knitr::include_graphics(
    if (!force_png && knitr::is_latex_output() && file.exists(pdf)) pdf
    else file.path(fig_dir, paste0(name, ".png")))
}
fig_cap <- function(name) {                                 # descriptive caption from the figure's legend .md (no number)
  p <- file.path(fig_dir, paste0(name, "_legend.md"))
  if (!file.exists(p)) return("")
  txt <- paste(readLines(p, warn = FALSE), collapse = " ")
  sub("^\\*\\*Figure\\.?\\s*", "**", txt)                    # drop the "Figure." placeholder, keep the bold title lead
}
