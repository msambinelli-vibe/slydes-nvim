(image
  destination: (link_destination) @image.src) @image

((inline_formula
  content: (formula_content) @image.content)
  (#set! image.lang "latex")
  (#set! image.ext "math.tex")) @image

((display_formula
  content: (formula_block_content) @image.content)
  (#set! image.lang "latex")
  (#set! image.ext "math.tex")) @image

((display_formula
  content: (dollar_formula_block_content) @image.content)
  (#set! image.lang "latex")
  (#set! image.ext "math.tex")) @image
