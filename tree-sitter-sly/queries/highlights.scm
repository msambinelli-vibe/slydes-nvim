(metadata_delimiter) @punctuation.special
(metadata_entry key: (identifier) @property)
(metadata_entry value: (string) @string)
(metadata_entry value: (boolean) @boolean)
(metadata_entry value: (number) @number)

((paragraph) @markup.heading.1
  .
  (section_underline))
(section_marker) @punctuation.special

(heading) @markup.heading
(heading marker: (heading_marker) @markup.heading.1 (#eq? @markup.heading.1 "#"))
(heading marker: (heading_marker) @markup.heading.2 (#eq? @markup.heading.2 "##"))
(heading marker: (heading_marker) @markup.heading.3 (#eq? @markup.heading.3 "###"))
(heading marker: (heading_marker) @markup.heading.4 (#eq? @markup.heading.4 "####"))
(heading marker: (heading_marker) @markup.heading.5 (#eq? @markup.heading.5 "#####"))
(heading marker: (heading_marker) @markup.heading.6 (#eq? @markup.heading.6 "######"))

(slide_delimiter) @punctuation.special
(container_marker) @punctuation.special
(container kind: (identifier) @type)
(argument) @number

(attributes ["{" "}"] @punctuation.bracket)
(class) @attribute
(id) @attribute
(key_value_attribute key: (attribute_name) @property)
(key_value_attribute value: (attribute_value) @string)

(strong_emphasis) @markup.strong
(strong_marker) @conceal
(emphasis) @markup.italic
(emphasis_marker) @conceal
(strikethrough) @markup.strikethrough
(strikethrough_marker) @conceal
(code_span) @markup.raw
(code_span_marker) @conceal

(bullet_marker) @markup.list
(ordered_marker) @markup.list
(link text: (link_text) @markup.link.label)
(link destination: (link_destination) @markup.link.url)
(image description: (link_text) @markup.link.label)
(image destination: (link_destination) @markup.link.url)

(code_fence) @markup.raw.block
(info_string) @label
(code_line) @markup.raw.block

(math_delimiter) @punctuation.special
(formula_content) @markup.math
(formula_block_content) @markup.math
(dollar_formula_block_content) @markup.math

((strong_marker) @conceal (#set! conceal ""))
((emphasis_marker) @conceal (#set! conceal ""))
((strikethrough_marker) @conceal (#set! conceal ""))
((code_span_marker) @conceal (#set! conceal ""))
((heading_marker) @conceal (#set! conceal ""))
((bullet_marker) @conceal (#set! conceal "•"))
