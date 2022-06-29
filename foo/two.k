require "one.k"

module TWO
  imports ONE
  imports INT

  syntax Term ::= inc(Term)

  configuration
    <k> $PGM:Term </k>
    <state> 0 </state>

  rule
    <k> inc(T) => T </k>
    <state> I => I +Int 1 </state>
endmodule
