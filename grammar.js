module.exports = grammar({
  name: "blueprint",

  extras: ($) => [
    /\s+/,
  ],

  rules: {
    source_file: ($) => repeat($._definition),

    _definition: ($) => choice(
      $.assignment,
    ),

    // Definitions {{{

    assignment: ($) => seq(
      field("left", $.identifier),
      field("operator", "="),
      field("right", $._expr),
    ),

    // }}}

    // Expressions {{{

    _expr: ($) => choice(
      // Literals
      $.identifier,
      $.integer_literal,
    ),

    // The Blueprint scanner makes use of Go's lexer, so copy their rule
    identifier: (_) => /[_\p{XID_Start}][_\p{XID_Continue}]*/,

    integer_literal: (_) => /[0-9]+/,

    // }}}
  }
});

// vim: foldmethod=marker sw=2
