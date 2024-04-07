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
    ),

    // The Blueprint scanner makes use of Go's lexer, so copy their rule
    identifier: (_) => /[_\p{XID_Start}][_\p{XID_Continue}]*/,

    integer_literal: (_) => seq(optional("-"), /[0-9]+/),

    // }}}
  }
});

// vim: foldmethod=marker sw=2
