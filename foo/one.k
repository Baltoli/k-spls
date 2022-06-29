module ONE
  
  syntax Term ::= foo()
                | bar()

  rule foo() => bar()

endmodule
