requires "spls.k"

module SPLS-SPEC
  imports SPLS

  claim
  <k>
    fn sum ( n : int , nc : int , .Params ) { return n + nc ; .Exprs }  fn main ( .Params ) { sum ( N:Int, A:Int , .Args ) ; .Exprs }  .Decls ~> main(.Args) ~> exit() => .K
  </k>
  <exit-code>
    _ => N
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
  <globals>
    .Map
  </globals>
  <functions>
    _ => ?_
  </functions>
  requires A ==Int 0

endmodule
