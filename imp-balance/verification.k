require "imp-balance.md"

module VERIFICATION
  imports IMP-BALANCE
  imports INT

  syntax Id ::= "from"      [token]
              | "to"        [token]
              | "amount"    [token]
              | "transfer"  [token]

  /* Lemmas for live demo, if time */
  /* rule A +Int (0 -Int B) => A -Int B [simplification] */

  /* rule maxInt(A +Int B, 0) => A +Int B */
  /*   requires A >=Int 0 andBool B >=Int 0 */
  /*   [simplification] */
endmodule
