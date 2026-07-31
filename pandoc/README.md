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

## RevealJS theme (`theme-kinan.scss`)

For **interactive data presentations** with R (plotly, DT, reactable).

### Setup (per project)

```bash
cp ~/.local/share/pandoc/themes/revealjs/theme-kinan.scss .
```

**YAML template:**
```yaml
format:
  revealjs:
    theme: [simple, theme-kinan.scss]
    slide-number: c/t
    transition: none
    fig-align: center
    scrollable: true
    embed-resources: true
    auto-stretch: false
    progress: true
    width: 1600
    height: 900
    navigation-mode: linear
filters:
  - /Users/kinelhu/.local/share/pandoc/filters/revealjs-wrap-body.lua
mermaid-format: svg
execute:
  echo: false
```

> `auto-stretch: false` — prevent Quarto from auto-resizing R figures.
> `scrollable: true` — slide scrolls if content overflows.

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

## Lua filters

### `beamer-blocks.lua`

Used by `mdslides`. Converts `::: {.alertblock}` / `::: {.exampleblock}` to `\begin{alertblock}` / `\begin{exampleblock}` (pandoc 3.x only generates `\begin{block}` by default). Also generates `\insertshortauthor` from the YAML `author` list.

### `revealjs-wrap-body.lua`

Used by the RevealJS theme. Does two things:

1. Converts `::: {.block}` / `{.alertblock}` / `{.exampleblock}` to raw `<div>` HTML — prevents pandoc from creating nested `<section>` elements that break RevealJS navigation.
2. Wraps per-slide content (everything after `## Title`) in a `.slide-body` div for CSS vertical centering.

Only active when `FORMAT == "revealjs"`, no-op otherwise.
