function commaSeparated(elem) {
  return seq(elem, repeat(seq(",", elem)), optional(","))
}

function trailingCommaSeparated(elem) {
  return repeat(seq(elem, ","))
}

module.exports = grammar({
  name: "blueprint",

  extras: ($) => [
    /\s+/,
    $.comment,
  ],

  rules: {
    source_file: ($) => repeat($._definition),

    _definition: ($) => choice(
      $.assignment,
    ),

    comment: (_) => seq("#", /.*/),

    // Definitions {{{

    assignment: ($) => seq(
      field("left", $.identifier),
      field("operator", choice("=", "+=")),
      field("right", $._expr),
    ),

    // }}}

    // Expressions {{{

    _expr: ($) => choice(
      // Literals
      $.identifier,
      $.boolean_literal,
      $.integer_literal,
      $._string_literal,
      // Conditionals
      $.select_expression,
      // Composites
      $.list_expression,
      $.map_expression,
    ),

    // The Blueprint scanner makes use of Go's lexer, so copy their rule
    identifier: (_) => /[_\p{XID_Start}][_\p{XID_Continue}]*/,

    boolean_literal: (_) => choice("true", "false"),

    integer_literal: (_) => seq(optional("-"), /[0-9]+/),

    // The Blueprint scanner makes use of Go's lexer, so copy their rule
    _string_literal: ($) => choice(
      $.raw_string_literal,
      $.interpreted_string_literal,
    ),

    raw_string_literal: (_) => token(seq(
      "`",
      /[^`]+/,
      "`",
    )),

    interpreted_string_literal: $ => seq(
      '"',
      repeat(choice(
        // Allow all characters without special meaning, disallow newlines
        /[^"\n\\]+/,
        $.escape_sequence,
      )),
      token.immediate('"'),
    ),

    escape_sequence: (_) => token.immediate(seq(
      '\\',
      choice(
        /[^xuU]/,
        /\d{2,3}/,
        /x[0-9a-fA-F]{2,}/,
        /u[0-9a-fA-F]{4}/,
        /U[0-9a-fA-F]{8}/,
      ),
    )),

    select_expression: ($) => seq(
      "select",
      "(",
      $.select_value,
      ",",
      $.select_cases,
      ")",
    ),

    select_value: ($) => seq(
      field("type", alias(
        choice("product_variable", "release_variable", "variant"),
        $.selection_type,
      )),
      "(",
      field("condition", $._string_literal),
      ")",
    ),

    select_cases: ($) => seq(
      "{",
      optional(trailingCommaSeparated($.select_case)),
      // default *must* be the last one, enforced at parse-time...
      optional(seq($.default_case, ",")),
      "}",
    ),

    select_case: ($) => seq(
      field("pattern", $._string_literal),
      ":",
      field("value", $._case_value)
    ),

    default_case: ($) => seq(
      field("pattern", "default"),
      ":",
      field("value", $._case_value),
    ),

    _case_value: ($) => choice(
      alias("unset", $.unset),
      $._expr,
    ),

    list_expression: ($) => seq(
      "[",
      optional(commaSeparated($._expr)),
      "]",
    ),

    map_expression: ($) => seq(
      "{",
      optional(commaSeparated($._colon_property)),
      "}",
    ),

    // }}}

    // Properties {{{

    _colon_property: ($) => seq(
      field("field", $.identifier),
      ":",
      field("value", $._expr),
    ),

    // }}}
  }
});

// vim: foldmethod=marker sw=2
