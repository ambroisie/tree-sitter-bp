[
 (line_comment)
 (block_comment)
] @comment

; Literal {{{
(boolean_literal) @boolean

(integer_literal) @number

[
 (raw_string_literal)
 (interpreted_string_literal)
] @string

(escape_sequence) @string.escape
; }}}

; vim: sw=2 foldmethod=marker
