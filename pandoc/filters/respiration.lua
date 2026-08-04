-- Respiration typographique : en sortie LaTeX, la règle horizontale markdown
-- (***) devient \respiration — un blanc vertical défini par le template livre
-- (book-template.tex) — au lieu du filet centré que pandoc trace par défaut.
-- Les autres formats de sortie gardent le comportement standard de pandoc.
if FORMAT:match('latex') then
  function HorizontalRule()
    return pandoc.RawBlock('latex', '\\respiration{}')
  end
end
