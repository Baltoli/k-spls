requires "spls.k"

module SPLS-SPEC
  imports SPLS

  claim
  <k>
    fn transfer ( from : int , to : int , amount : int , .Params ) { #send ( from , - amount ) ; #send ( to , amount ) ; .Exprs }  fn main ( .Params ) { if ( #balance ( 1 ) >= 100 ) { if ( #balance ( 2 ) >= 0 ) { transfer ( 1 , 2 , 100 , .Args ) ; .Exprs } else { ( ) ; .Exprs } ; .Exprs } else { ( ) ; .Exprs } ; #balance ( 1 ) + #balance ( 2 ) ; .Exprs }  .Decls
    ~> main ( .Args ) ~> exit ( )
    => .
  </k>
  <exit-code>
    _ => B1 +Int B2
  </exit-code>
  <fstack>
    .List
  </fstack>
  <stack>
    .List
  </stack>
  <env>
    .Map
  </env>
  <args>
    _ => ?_
  </args>
  <globals>
    .Map
  </globals>
  <functions>
    _ => ?_
  </functions>
  <balances>
    1 |-> (B1 => ?_)
    2 |-> (B2 => ?_)
  </balances>
  /* requires 1 =/=Int 2 andBool B1 >=Int 100 andBool B2 >=Int 0 */
    /* andBool 1 =/=Int 0 andBool 2 =/=Int 0 */

endmodule
