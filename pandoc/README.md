# Pandoc pipeline

Wrappers, filters, templates and themes for academic writing and presentations.

All directories are symlinked from `~/.local/share/pandoc/` by `install.sh`.

---

## CLI wrappers (defined in `.zshrc`)

### `mdslides <file.md> [flags]`

Compiles a Markdown file to a **Beamer PDF** using `slides-kinan.yaml` defaults.

```bash
mdslides talk.md               # → talk-slides.pdf + talk-slides.tex
mdslides talk.md --handout     # → also talk-handout.pdf (\pause collapsed)
mdslides talk.md --draft       # → talk-draft.pdf (images as grey boxes, fast)
```

**YAML front matter fields:**

| Field | Effect |
|---|---|
| `notes: show` | Notes printed below each slide |
| `notes: only` | Notes-only PDF (speaker script) |
| `notes: right` | Dual-screen PDF — open with pympress or pdfpc |
| *(absent)* | Notes hidden, normal slides |

### `mdpdf <file.md>`

Compiles a Markdown file to a **PDF article** using `article-kinan.yaml`.

### `mddocx <file.md>`

Compiles a Markdown file to a **Word document** using `docx-kinan.yaml`.

---

## Book / essai (`book-kinan`)

For long-form literary work (essays, books) — distinct from `article-kinan`,
which is tuned for the branded academic/stats-report house style.

```bash
pandoc file.md --defaults book-kinan -o book.pdf
```

**Requires `lualatex`** (not xelatex) — `luaotfload` finds EB Garamond
directly in the TeX Live tree, so nothing needs to be installed into Font
Book.

Design:
- `book` class, `\frontmatter`/`\mainmatter`, 6×9in trim by default
  (override with a `geometry:` metadata field).
- Centered chapter titles with **no LaTeX auto-numbering** — chapter
  headings must carry whatever numbering you want in the text itself (e.g.
  `## II. Le socle`), since the template only ever prints the heading text.
  This also means all chapter headings must sit at the same Markdown level;
  the default (`shift-heading-level-by: -1`) assumes chapters are `##`.
- Running heads: chapter title on verso pages, book title on recto.
- Markdown footnotes (`[^1]`) render as **endnotes, flushed and renumbered
  after each chapter** (via the `endnotes` package + an `etoolbox` hook on
  `\chapter`), not end-of-book or bottom-of-page.
- Optional, not auto-applied: `\dropcap{X}{rest of word}` (drop cap, via
  `lettrine`) and `\epigraph{quote}{attribution}` — insert as raw LaTeX in
  the Markdown source where wanted.

Multi-chapter books assembled from several files (rather than one big `.md`)
need their own small build script to concatenate chapters in the *correct*
order before piping into pandoc — do not glob-sort filenames if they use
Roman numerals (`IX-` sorts before `V-` as a plain string). See
`~/Dev/backrooms/build-pdf.sh` for a worked example.

---

## Beamer slides (`mdslides`)

### Syntax reference

**Sections and slides:**
```markdown
# Section title          ← section divider slide (tcolorbox badge style)
## Slide title           ← frame title with AccentPrimary underline
```

**Blocks (same syntax as in RevealJS):**
```markdown
::: {.block}
### Title
Content
:::

::: {.alertblock}
### Warning
Content
:::

::: {.exampleblock}
### Positive note
Content
:::
```

**Columns:**
```markdown
::: columns
:::: column
Left content
::::
:::: column
Right content
::::
:::
```

**Progressive reveal:**
```markdown
Text before.
\pause
Text after.
```

**Font size reduction (useful for dense slides):**
```markdown
::: {.smtext}   ← 9pt
::: {.fntext}   ← 8pt
::: {.sstext}   ← 7pt
```

**Images:**
```markdown
![Caption](images/fig.png){height=82%}   ← fills to bottom
![](images/fig.png)                       ← auto-fit (pandocbounded)
```

```latex
\begin{center}
\includegraphics[trim=0 1000 0 0, clip, height=0.82\textheight]{images/fig.png}
\end{center}
```

**Speaker logo (top-right of frame title):**
```latex
\slidelogo{images/logo.png}
\slidelogo[2cm]{images/logo.png}
```

---

## Quarto house style (`pandoc/themes/kinan/`)

A single Quarto extension — id **`kinan`** — contributes three formats:
`kinan-revealjs` (interactive slide decks), `kinan-html` and `kinan-pdf`
(long-form reports: `.qmd` that aren't slides). One `_extension.yml`, one
palette, no more copy-pasting the theme file into each project (that's
exactly how `theme-kinan.scss` drifted out of sync with itself in the past —
the live copy under `~/.quarto/extensions/` fell behind the one in this repo
until they were reconciled and symlinked back together).

### Setup (per project)

Quarto only resolves extensions from a **project-local** `_extensions/`
folder — there is no working global lookup, even though `~/.quarto/extensions/`
exists. Run this once per project:

```bash
~/.dotfiles/pandoc/link-quarto-house-style.sh   # symlinks _extensions/kinan
```

Then in any `.qmd`'s frontmatter:

```yaml
format:
  kinan-revealjs: default   # interactive slide deck
  kinan-html: default       # long-form report, HTML
  kinan-pdf: default        # long-form report, PDF (stats-report-template.tex + zebra tables)
```

(Quarto only renders multiple formats at once with `quarto render`, not
`quarto preview`; use whichever one(s) you need.)

### RevealJS (`kinan-revealjs`) — interactive data presentations

For presentations with R (plotly, DT, reactable).

```yaml
format:
  kinan-revealjs:
    transition: none
    fig-align: center
    scrollable: true
    embed-resources: true
    auto-stretch: false
    navigation-mode: linear
filters:
  - /Users/kinelhu/.local/share/pandoc/filters/revealjs-wrap-body.lua
mermaid-format: svg
execute:
  echo: false
```

> `auto-stretch: false` — prevent Quarto from auto-resizing R figures.
> `scrollable: true` — slide scrolls if content overflows.
> `slide-number`/`width`/`height`/`progress` are already set by the extension
> — no need to repeat them.

### Syntax reference

**Sections and slides** — identical to Beamer:
```markdown
# Section title
## Slide title
```

**Blocks** — identical syntax to Beamer:
```markdown
::: {.block}
### Title
Content
:::

::: {.alertblock}       ← blue header
::: {.exampleblock}     ← green header
```

**Columns** — identical to Beamer:
```markdown
::: {.columns}
:::: {.column}
Left
::::
:::: {.column}
Right
::::
:::
```

**Progressive reveal (`\pause` equivalent):**
```markdown
::: {.fragment}
Content revealed on next keypress.
:::

::: {.fragment .fade-in}
::: {.fragment .fade-up}
::: {.fragment .highlight-accent}   ← AccentPrimary + bold
::: {.fragment .highlight-alert}    ← AlertBlue + bold
::: {.fragment .semi-fade-out}      ← dims to 40% (de-emphasise previous)
```

**Full-screen image slide:**
```markdown
## {background-image="images/fig.png" background-size="contain"}
```

**Coloured section slide** (custom background; h1 appears as plain white text over it):
```markdown
# Section title {background-color="#4279d7"}
```

**Vertical centering utility** (useful to manually center a block of content):
```markdown
::: {.vcenter}
content
:::
```

**Mermaid diagrams** — add `mermaid-format: svg` to YAML; no extra CSS needed.

**Inline text colour:**
```markdown
[Important text]{style="color: #c0392b;"}
```

**Footnote / citation:**
```markdown
::: {.footnote}
Verleden GM et al. *JHLT.* 2019;38(5):493.
:::
```

**Font size helpers:**
```markdown
::: {.smtext}   ← 82% of base
::: {.fntext}   ← 70%
::: {.sstext}   ← 60%
```

### Interactive R outputs

**Filterable/scrollable table:**
```r
DT::datatable(df,
  options = list(pageLength = 8, scrollY = "400px"),
  rownames = FALSE)
```

**Interactive plot:**
```r
plotly::ggplotly(p)
```

Both are styled automatically by `theme-kinan.scss` (AccentPrimary header row for DT, matching font).

### Global font size

`$mainFontSize: 28px` in `/*-- scss:defaults --*/` — all `em`-based sizes scale proportionally.  
`width: 1600` / `height: 900` in YAML controls the RevealJS viewport scale.

---

## Long-form reports (`kinan-html` / `kinan-pdf`)

For `.qmd` that aren't slides — course notes, tutorials, analysis reports.
Same underlying house style as `mdpdf`/`article-kinan` (Inter body, Monaspace
Neon headers, teal rules, flush zebra tables), reached from Quarto instead of
bare Markdown.

```yaml
---
title: "…"
format:
  kinan-html: default
  kinan-pdf: default
---
```

- `kinan-pdf` renders through `stats-report-template.tex` (xelatex) with
  `table-header-font.lua` + `table-zebra.lua` already wired in — any pandoc
  table gets teal booktabs rules and flush zebra banding for free.
- `kinan-html` layers `kinan-report.scss` on Bootstrap's `cosmo` theme — same
  palette/fonts, plus matching zebra tables via `nth-child(even)`.
- Both default `toc: true`; add `number-sections`, `code-fold`, etc. per
  document same as any other Quarto format.
- Rendering both at once (`quarto render`, not `quarto preview`) gives each
  format a cross-link to the other ("Other Formats" in the HTML sidebar).

### R Markdown equivalent (`.Rmd`)

`rmarkdown::render()` can't consume Quarto extensions, so the same house
style is wired in directly per-document instead of via a named format:

```yaml
output:
  html_document:
    toc: true
    toc_depth: 3
    css: /Users/kinelhu/.dotfiles/pandoc/themes/kinan/kinan-report.css
  pdf_document:
    toc: true
    latex_engine: xelatex
    template: /Users/kinelhu/.dotfiles/pandoc/templates/stats-report-template.tex
    pandoc_args:
      - "--lua-filter=/Users/kinelhu/.dotfiles/pandoc/filters/table-header-font.lua"
      - "--lua-filter=/Users/kinelhu/.dotfiles/pandoc/filters/table-zebra.lua"
```

`kinan-report.css` is a hand-maintained plain-CSS twin of `kinan-report.scss`
(knitr has no Sass compiler for Quarto's `scss:defaults`/`scss:rules`
theme format) — same palette, targets Bootstrap 3 (rmarkdown's `html_document`
default), so keep the two in sync by hand if the look changes.

**TOC.** A plain `toc: true` block; the CSS gives `#TOC` a subtle teal-bordered
box, a bold Neon **"Contents"** header (via `::before`), and Neon links, so it
echoes the headers it points to. (A floating `toc_float` sidebar was tried and
dropped — didn't read as tasteful.)

**Header weight.** Table headers, captions, and the `.table thead` use
**Monaspace Neon ExtraBold** (matching the PDF's `\HeaderFont`) — plain "Monaspace
Neon" + `font-weight: bold` renders visibly lighter than the PDF and looks
under-weight next to the teal rules.

**Exhibit titles + figure legends.** Shared classes give tables and figures a
consistent look in both formats:

- `.exhibit-title` — teal Neon ExtraBold, left-aligned, a **block above** the
  table (not gt's centred caption).
- `.figure-legend` — the legend as one paragraph: a bold teal Neon run-in lead
  (`.exhibit-lead`, inline) then an italic, slightly-smaller Inter body; inner
  `<em>` toggles upright so `*Abbreviations:*` stands out.

HTML gets these via CSS. PDF has no div→environment mapping in pandoc (a classed
div just emits its content), so the same look is produced with **raw LaTeX**: a
`{\HeaderFont\color{AccentPrimary} …}` line above a table, and for a figure an
**inline** run of `\textcolor{AccentPrimary}{\HeaderFont{} lead}` +
`{\itshape\footnotesize\color{TextSecondary} body}` in one paragraph. A
`fig_legend()` helper splits a legend's bold lead from its body; table titles come
from `tex_exhibit_title()`. No third Lua filter needed.

Two gotchas that cost time here:
- **A figure image chunk and the following legend chunk render with no blank line
  between them**, so pandoc folds the legend's `:::`/raw block into the image's
  paragraph and it shows up literally. Prefix the legend output with `\n\n`.
- **Pandoc strips the trailing space inside an inline `` `…`{=latex} `` span**, so
  `\HeaderFont ` swallows the next word (`\HeaderFontCorpus` → undefined). End the
  control word with `{}` (`\HeaderFont{}`).

A figure/table's "Supplementary Figure Sx." label is passed as a `label` arg and
**folded into the teal Neon lead/title** (journal style) rather than sitting as a
separate bold-black line above the exhibit, which clashed.

**gt / gtsummary tables — `gt-house.R`.** The Lua filters and the `.table` CSS
only reach **pandoc tables** (markdown, `knitr::kable`). `gt` and
`gtsummary::as_gt()` emit their own scoped styling — `<table class="gt_table">`
in HTML, raw LaTeX in PDF — so they **bypass the house style in both formats**.
Two-part fix:

- *HTML*: `source(".../themes/kinan/gt-house.R")` and pipe every gt through
  `gt_house()` (apply it **last**, after `tab_header`/`tab_source_note`). It
  reproduces the `.table` look from inside gt: Inter body, bold teal Monaspace
  Neon column headers **and caption/title**, flush teal zebra, transparent
  interior rules. Palette mirrors `kinan-report.scss` — keep in sync by hand.
- *PDF*: don't feed gt LaTeX to xelatex — render the same data as a **pandoc
  pipe table** so it flows through `table-header-font.lua` + `table-zebra.lua`
  like any markdown table. A format-aware helper does both, e.g.:

  ```r
  house_df <- function(df, title = NULL, note = NULL) {
    if (knitr::is_latex_output()) {
      df <- as.data.frame(df, check.names = FALSE)
      names(df) <- gsub("[\r\n]+", " ", names(df))      # newlines in headers break pipe tables
      df[] <- lapply(df, \(c) { c <- as.character(c); c[is.na(c)] <- ""; c })  # blank NA cells
      out <- paste(knitr::kable(df, format = "pipe"), collapse = "\n")         # NO caption (see below)
      if (!is.null(title))                              # title as a bold teal Neon line instead
        out <- paste0("```{=latex}\n\\par\\noindent{\\HeaderFont\\color{AccentPrimary}",
                      title, "}\\par\\vspace{0.15em}\n```\n\n", out)
      if (!is.null(note)) out <- paste0(out, "\n\n", note)
      return(knitr::asis_output(out))                   # → lua filters style the table
    }
    g <- gt::gt(df)
    if (!is.null(title)) g <- gt::tab_header(g, title = title)
    if (!is.null(note))  g <- gt::tab_source_note(g, gt::md(note))
    gt_house(g)                                         # HTML: match .table
  }
  ```

  For a `gtsummary` object, flatten with `gtsummary::as_tibble()` in the LaTeX
  branch before `house_df()`.

  Two things learned building this:
  - **Don't pass `caption=` to `kable`.** A pandoc table caption makes
    `tabularray`'s `longtabs` auto-number it ("Table 1:", "Table 2:" …), which
    reads as noise in a report that titles its tables descriptively. Render the
    title as its own bold Neon line above the table instead (as above) — it also
    matches the HTML Neon caption from `gt_house()`. Escape LaTeX specials in the
    title if they can occur.
  - **`gtsummary::as_tibble()` column names contain `\n`** (e.g.
    `**Overall**  \nN = 485`). A newline in a pipe-table header cell breaks the
    table — pandoc dumps it as raw text. Collapse them first (the `gsub` above).

> **PDF caption gotcha (figures):** knitr inserts a chunk's static `fig.cap`
> straight into `\caption{}` **without escaping**, so a raw `_`/`%`/`&`/`$`/`#`
> (e.g. a file path like `foo_bar.R`) throws xelatex into math mode ("Missing $
> inserted"). Keep static `fig.cap` strings free of LaTeX specials, or wrap
> offending tokens in backticks. (Underscores are harmless in HTML, so this only
> bites the PDF.)

Skip all of this for package vignettes (`rmarkdown::html_vignette`) — those
should look like a standard R vignette, not carry personal branding.

---

## Lua filters

### `beamer-blocks.lua`

Used by `mdslides`. Converts `::: {.alertblock}` / `::: {.exampleblock}` to `\begin{alertblock}` / `\begin{exampleblock}` (pandoc 3.x only generates `\begin{block}` by default). Also generates `\insertshortauthor` from the YAML `author` list.

### `revealjs-wrap-body.lua`

Used by the RevealJS theme. Does two things:

1. Converts `::: {.block}` / `{.alertblock}` / `{.exampleblock}` to raw `<div>` HTML — prevents pandoc from creating nested `<section>` elements that break RevealJS navigation.
2. Wraps per-slide content (everything after `## Title`) in a `.slide-body` div for CSS vertical centering.

Only active when `FORMAT == "revealjs"`, no-op otherwise.
