# gt-house.R — apply the Kinan house style to a gt (or gtsummary::as_gt) table.
# -----------------------------------------------------------------------------
# gt/gtsummary emit <table class="gt_table"> with their own scoped <style> block,
# so the Bootstrap `.table` rules in kinan-report.css never reach them. This helper
# reproduces the SAME look from inside gt: Inter body, Monaspace Neon bold teal-ruled
# column headers, flush teal zebra, transparent inner rules. Palette mirrors
# kinan-report.scss / house-style.tex — keep the three in sync by hand.
#
# Usage:  source(".../gt-house.R"); some_gt |> gt_house()
# Apply it LAST in the pipe (after tab_header/tab_source_note), so header and note
# rows inherit the styling too.

gt_house <- function(g,
                     accent       = "#27A9BC",   # AccentPrimary (teal)
                     accent_light = "#EEF8FA",   # rgba(39,169,188,0.08) flattened on white
                     ink          = "#1A1A1A",
                     font_size    = 85) {         # percent, matches the report's 85%
  body_font <- c("Inter", "-apple-system", "BlinkMacSystemFont", "Segoe UI",
                 "Helvetica", "Arial", "sans-serif")
  # ExtraBold face first, to match the PDF's \HeaderFont (Monaspace Neon ExtraBold);
  # plain "Monaspace Neon" + bold renders noticeably lighter than the PDF headers.
  head_font <- c("Monaspace Neon ExtraBold", "Monaspace Neon", "Menlo", "SFMono-Regular", "monospace")

  g |>
    gt::opt_table_font(font = body_font, color = ink) |>
    gt::tab_options(
      table.font.size                = gt::pct(font_size),
      # teal top/bottom rules (the "colored bars")
      table.border.top.color         = accent,
      table.border.top.width         = gt::px(1),
      table.border.bottom.color      = accent,
      table.border.bottom.width      = gt::px(1),
      # teal rules bracketing the header row
      column_labels.border.top.color = accent,
      column_labels.border.top.width = gt::px(1),
      column_labels.border.bottom.color = accent,
      column_labels.border.bottom.width = gt::px(1),
      column_labels.font.weight      = "bold",
      heading.border.bottom.color    = accent,
      # kill the interior horizontal rules (transparent, like the CSS)
      table_body.hlines.color        = "transparent",
      table_body.border.bottom.color = accent,
      # flush teal zebra
      row.striping.include_table_body = TRUE,
      row.striping.background_color  = accent_light
    ) |>
    # Monaspace Neon column headers (opt_table_font sets the body font globally;
    # this overrides just the header cells to echo the section-header treatment).
    gt::tab_style(
      style     = gt::cell_text(font = head_font, weight = "bold"),
      locations = gt::cells_column_labels()
    ) |>
    # Caption/title in bold teal Monaspace Neon so it echoes the section headers
    # instead of clashing above them. tryCatch: no-op when the table has no title.
    (\(g) tryCatch(
      g |> gt::tab_style(
        style     = gt::cell_text(font = head_font, weight = "bold", color = accent),
        locations = gt::cells_title(groups = "title")),
      error = function(e) g))()
}
