requires "spls.k"

module SPLS-SPEC
  imports SPLS

  claim
  <k>
    fn transfer(from, to, amount) {
      if(#balance(from) >= amount) {
        #send(from, -amount);
        #send(to, amount)
      } else {
        #halt
      }
    }

    fn main(.Params) {
      if(#balance(1) >= 100) {
        transfer(1, 2, 100)
      } else { () };
      #balance(1) + #balance(2)
    }

    ~> main ( .Args ) ~> exit ( )
    => .
  </k>

  <exit-code>
    _ => B1 +Int B2
  </exit-code>

  <balances>
    1 |-> (B1 => ?_)
    2 |-> (B2 => ?_)
  </balances>

  <fstack>    .List   </fstack>
  <stack>     .List   </stack>
  <env>       .Map    </env>
  <args>      .Map    </args>
  <globals>   .Map    </globals>
  <functions> _ => ?_ </functions>

  requires B1 >=Int 0
    andBool B2 >=Int 0

endmodule
