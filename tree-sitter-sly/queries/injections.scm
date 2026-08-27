((fenced_code_block
  language: (info_string) @injection.language
  (code_line) @injection.content)
  (#set! injection.combined))

((inline_formula
  content: (formula_content) @injection.content)
  (#set! injection.language "latex"))

((display_formula
  content: (formula_block_content) @injection.content)
  (#set! injection.language "latex"))

((display_formula
  content: (dollar_formula_block_content) @injection.content)
  (#set! injection.language "latex"))
