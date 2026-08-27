/**
 * @file Tree-sitter grammar for the Slydes presentation language
 * @license MIT
 */

/// <reference types="tree-sitter-cli/dsl" />
// @ts-check

module.exports = grammar({
  name: "sly",

  extras: _ => [/[^\S\r\n]+/],

  rules: {
    source_file: $ => repeat(choice(
      $.metadata,
      $.section_underline,
      $.slide_end,
      $.container,
      $.fenced_code_block,
      $.display_formula,
      $.heading,
      $.image,
      $.list_item,
      $.paragraph,
      $.blank_line,
    )),

    metadata: $ => prec(10, seq(
      field("open", alias(token("+++"), $.metadata_delimiter)),
      $._newline,
      repeat(choice($.metadata_entry, $.blank_line)),
      field("close", alias(token("+++"), $.metadata_delimiter)),
      $._newline,
    )),

    metadata_entry: $ => seq(
      field("key", $.identifier),
      "=",
      field("value", choice($.string, $.boolean, $.number, $.bare_value)),
      $._newline,
    ),

    section_underline: $ => prec.right(10, seq(
      field("marker", alias(token(seq("===", repeat("="))), $.section_marker)),
      optional($.attributes),
      $._newline,
    )),

    slide_end: $ => prec.right(10, seq(
      alias(token("---"), $.slide_delimiter),
      optional($.attributes),
      $._newline,
    )),

    container: $ => prec.right(10, seq(
      alias(":::", $.container_marker),
      field("kind", $.identifier),
      optional($.argument_list),
      optional($.attributes),
      $._newline,
    )),

    argument_list: $ => seq(
      "(",
      optional(seq($.argument, repeat(seq(",", $.argument)))),
      ")",
    ),
    argument: _ => token(/[^,()\s]+/),

    attributes: $ => seq(
      "{",
      repeat1(choice($.class, $.id, $.key_value_attribute)),
      "}",
    ),
    class: _ => token(/\.[A-Za-z_][A-Za-z0-9_-]*/),
    id: _ => token(/#[A-Za-z_][A-Za-z0-9_-]*/),
    key_value_attribute: $ => seq(
      field("key", $.attribute_name),
      "=",
      field("value", choice($.string, $.attribute_value)),
    ),
    attribute_name: _ => token(/[A-Za-z_][A-Za-z0-9_-]*/),
    attribute_value: _ => token(/[^}\s,]+/),

    heading: $ => prec.right(seq(
      field("marker", alias(token(/#{1,6}/), $.heading_marker)),
      field("content", repeat1($._inline)),
      $._newline,
    )),

    list_item: $ => prec.right(seq(
      field("marker", choice(
        alias(token(choice("-", "+", "*")), $.bullet_marker),
        alias(token(/[0-9]+\./), $.ordered_marker),
      )),
      field("content", repeat1($._inline)),
      $._newline,
    )),

    fenced_code_block: $ => prec(10, seq(
      field("open", alias(token("```"), $.code_fence)),
      optional(field("language", $.info_string)),
      $._newline,
      repeat(choice($.code_line, $.blank_line)),
      field("close", alias(token(prec(10, "```")), $.code_fence)),
      $._newline,
    )),
    info_string: _ => token(/[A-Za-z0-9_+-]+/),
    code_line: $ => seq(token(prec(-1, /[^\r\n]+/)), $._newline),

    display_formula: $ => prec(10, choice(
      seq(
        field("open", alias("\\[", $.math_delimiter)),
        $._newline,
        optional(field("content", $.formula_block_content)),
        field("close", alias("\\]", $.math_delimiter)),
        $._newline,
      ),
      seq(
        field("open", alias("$$", $.math_delimiter)),
        $._newline,
        optional(field("content", $.dollar_formula_block_content)),
        field("close", alias("$$", $.math_delimiter)),
        $._newline,
      ),
    )),
    formula_block_content: $ => repeat1(choice($.formula_line, $.blank_line)),
    dollar_formula_block_content: $ => repeat1(choice($.dollar_formula_line, $.blank_line)),
    formula_line: $ => seq(token(prec(-1, /[^\r\n]+/)), $._newline),
    dollar_formula_line: $ => seq(token(prec(-1, /[^\r\n]+/)), $._newline),

    image: $ => prec.right(10, seq(
      "!",
      "[",
      field("description", optional($.link_text)),
      "]",
      "(",
      field("destination", $.link_destination),
      ")",
      optional($.attributes),
      $._newline,
    )),

    paragraph: $ => prec.right(seq(repeat1($._inline), $._newline)),

    _inline: $ => choice(
      $.strong_emphasis,
      $.emphasis,
      $.strikethrough,
      $.code_span,
      $.inline_formula,
      $.link,
      $.text,
    ),

    strong_emphasis: $ => choice(
      seq(alias("**", $.strong_marker), field("content", repeat1($._inline_no_strong)), alias("**", $.strong_marker)),
      seq(alias("__", $.strong_marker), field("content", repeat1($._inline_no_underscore)), alias("__", $.strong_marker)),
    ),
    _inline_no_strong: $ => choice($.emphasis, $.strikethrough, $.code_span, $.inline_formula, $.link, $.strong_text),
    _inline_no_underscore: $ => choice($.strikethrough, $.code_span, $.inline_formula, $.link, $.underscore_text),
    strong_text: _ => token(prec(-1, choice(/[^*~`$\[\]\n]+/, "*"))),
    underscore_text: _ => token(prec(-1, choice(/[^_~`$\[\]\n]+/, "_"))),

    emphasis: $ => choice(
      seq(alias("*", $.emphasis_marker), field("content", repeat1($._inline_no_emphasis)), alias("*", $.emphasis_marker)),
      seq(alias("_", $.emphasis_marker), field("content", repeat1($._inline_no_underscore_emphasis)), alias("_", $.emphasis_marker)),
    ),
    _inline_no_emphasis: $ => choice($.strikethrough, $.code_span, $.inline_formula, $.link, $.emphasis_text),
    _inline_no_underscore_emphasis: $ => choice($.strikethrough, $.code_span, $.inline_formula, $.link, $.underscore_emphasis_text),
    emphasis_text: _ => token(prec(-1, /[^*~`$\[\]\n]+/)),
    underscore_emphasis_text: _ => token(prec(-1, /[^_~`$\[\]\n]+/)),

    strikethrough: $ => seq(
      alias("~~", $.strikethrough_marker),
      field("content", $.strikethrough_text),
      alias("~~", $.strikethrough_marker),
    ),
    strikethrough_text: _ => token(/[^~\n]+/),

    code_span: $ => seq(
      alias("`", $.code_span_marker),
      field("content", $.code_span_content),
      alias("`", $.code_span_marker),
    ),
    code_span_content: _ => token(/[^`\n]+/),

    inline_formula: $ => seq(
      alias("$", $.math_delimiter),
      field("content", $.formula_content),
      alias("$", $.math_delimiter),
    ),
    formula_content: _ => token(/[^$\n]+/),

    link: $ => seq(
      "[",
      field("text", $.link_text),
      "]",
      "(",
      field("destination", $.link_destination),
      ")",
    ),
    link_text: _ => token(/[^\]\n]+/),
    link_destination: _ => token(/[^)\s]+/),

    text: _ => token(prec(-2, /[^\r\n*_$`~\[\]]+|[*_~\[\]]/)),
    identifier: _ => token(/[A-Za-z_][A-Za-z0-9_-]*/),
    string: _ => token(choice(/"([^"\\]|\\.)*"/, /'([^'\\]|\\.)*'/)),
    boolean: _ => choice("true", "false"),
    number: _ => token(/[+-]?[0-9]+(\.[0-9]+)?/),
    bare_value: _ => token(/[^\r\n]+/),
    blank_line: $ => $._newline,
    _newline: _ => token(/\r?\n/),
  },
});
