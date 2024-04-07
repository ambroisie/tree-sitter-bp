function commaSeparated(elem) {
  return seq(elem, repeat(seq(",", elem)), optional(","))
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
      $.integer_literal,
      $._string_literal,
      // Composites
      $.list_expression,
    ),

    // The Blueprint scanner makes use of Go's lexer, so copy their rule
    identifier: (_) => /[_\p{XID_Start}][_\p{XID_Continue}]*/,

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

    list_expression: ($) => seq(
      "[",
      optional(commaSeparated($._expr)),
      "]",
    ),

    // }}}
  }
});

// vim: foldmethod=marker sw=2
