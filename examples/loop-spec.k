module LOOP-SPEC
  imports VERIFICATION

  claim
    <k>
      while ( $n > 0 ) {
        $s = ($s + $n);
        $n = ($n - 1)
      } => #return(())
    </k>
    <env>
      $s |-> (S:Int => S +Int (N *Int (N +Int 1) /Int 2))
      $n |-> (N:Int => 0)
    </env>
    requires N >=Int 0
endmodule
