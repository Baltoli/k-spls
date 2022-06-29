This file is a literate K definition for a simple imperative programming
language. This language is strongly and dynamically typed, and does not have a
distinction between statements and expressions.

Several elements of its design are made for simplicity of code, rather than to
produce a language that is maximally ergonomic to write.

# Syntax

We follow the K convention of defining an external _syntax_ module that
specifies how user programs should be parsed. Note that this syntax will be
extended in the main module when defining the rewrite system for the language;
these syntax extensions are not accessible by users of the language.
```k
module SPLS-SYNTAX
  imports ID-SYNTAX
  imports UNSIGNED-INT-SYNTAX
  imports BOOL
```

The only values in the language are unit (`()`), arbitrarily-sized integers, and
booleans:
```k
  syntax Value    ::= "(" ")"
                    | Int
                    | Bool
```

This language treats all syntax equivalently as expressions (i.e. everything
will evaluate to a value eventually; there is no statement-expression
distinction).

Expressions can be a value, a variable identifier, or a function call. The
`Args` sort is defined later in terms of the `Expr` sort:
```k
  syntax Expr     ::= Value
                    | Id
                    | Id "(" Args ")"
```

We support the basic set of arithmetic operations over expressions (note that
the language is dynamically typed; there is no static type checking that would
prevent `true * 2`, for example).

K's _attribute_ system is used on these productions to mark each one as being
strict in its arguments (i.e. the child `Expr`s must be evaluated to a `Value`
before this production appears at the top of the K cell), and to set the parsing
associativity of each one. A unique label is given to each one, which we will
use later to specify parsing priorities:
```k
  syntax Expr     ::= "-" Expr      [neg, strict, non-assoc]
                    | Expr "*" Expr [mul, strict, left]
                    | Expr "/" Expr [div, strict, left]
                    | Expr "+" Expr [add, strict, left]
                    | Expr "-" Expr [dub, strict, left]
```

Boolean expressions are treated similarly:
```k
  syntax Expr     ::= Expr "==" Expr [eq,   strict, non-assoc]
                    | Expr "!=" Expr [neq,  strict, non-assoc]
                    | Expr ">=" Expr [gteq, strict, non-assoc]
                    | Expr ">"  Expr [gt,   strict, non-assoc]
                    | Expr "<=" Expr [lteq, strict, non-assoc]
                    | Expr "<"  Expr [lt,   strict, non-assoc]
```

Later, we want to allow global variable declarations that are separate from the
expression grammar. The `prefer` attribute here allows for parsing ambiguities
to be resolved. We parse `let x = 2 + 2` as `let x = (2 + 2)` rather than `(let
x = 2) + 2` by preferring the top-level `let` production:
```k
  syntax VarDecl  ::= "let" Id "=" Expr [let,    strict(2), prefer]
  syntax Expr     ::= VarDecl           [decl]
                    | Id "=" Expr       [assign, strict(2)]
```

We support three basic control flow elements: if-else, while loops, and early
returns:
```k
  syntax Expr     ::= "if" "(" Expr ")" Expr "else" Expr [if,     strict(1)]
                    | "while" "(" Expr ")" Expr          [while]
                    | "return" Expr                      [return, strict]
```

```k
  syntax Param    ::= Id
  syntax Params   ::= List{Param, ","}

  syntax Args     ::= List{Expr, ","}

                    > Block
                    > "(" Expr ")" [bracket]

  syntax Expr     ::= #balance(Expr) [strict]
                    | #send(Expr, Expr) [strict]
                    | #halt()

  syntax Exprs    ::= NeList{Expr, ";"}

  syntax Block    ::= "{" Exprs "}"

  syntax FunDecl  ::= "fn" Id "(" Params ")" Block

  syntax Decl     ::= FunDecl
                    | VarDecl ";"

  syntax Decls    ::= NeList{Decl, ""} [prefer]

  syntax Pgm      ::= Decls
endmodule

module SPLS-CONFIGURATION
  imports SPLS-SYNTAX
  imports LIST
  imports MAP

  syntax Id       ::= "dummy" [token]
                    | "main"  [token]

  syntax KItem ::= exit()
  
  configuration
    <k> $PGM:Pgm ~> main(.Args) ~> exit() </k>
    <exit-code> 0 </exit-code>
    <fstack> .List </fstack>
    <stack> .List </stack>
    <env> .Map </env>
    <args> .Map </args>
    <globals> .Map </globals>
    <balances> .Map </balances>
    <functions>
      <function multiplicity="*" type="Map">
        <function-id> dummy </function-id>
        <function-params> .List </function-params>
        <function-body> .K </function-body>
      </function>
    </functions>
endmodule

module SPLS
  imports SPLS-CONFIGURATION
  imports INT
  imports BOOL
  imports MAP

  syntax KItem ::= frame(K)

  rule D:Decl DS => D ~> DS
  rule .Decls => .K

  rule - X => 0 -Int X
  rule X + Y => X +Int Y
  rule X - Y => X -Int Y
  rule X * Y => X *Int Y
  rule X / Y => X /Int Y

  rule B1 == B2 => B1 ==Bool B2
  rule I1 == I2 => I1 ==Int I2

  rule B1 != B2 => B1 =/=Bool B2
  rule I1 != I2 => I1 =/=Int I2

  rule I1 >= I2 => I1 >=Int I2
  rule I1 > I2 => I1 >Int I2
  rule I1 <= I2 => I1 <=Int I2
  rule I1 < I2 => I1 <Int I2

  rule if ( true ) E1 else _ => E1
  rule if ( false ) _ else E2 => E2

  rule while ( C ) E => if ( C ) { E ; while ( C ) E } else ()

  syntax List ::= paramNames(Params) [function]

  rule paramNames(.Params) => .List
  rule paramNames(X , PS) => ListItem(X) paramNames(PS)

  rule
    <k> #balance(Addr) => BM [ Addr ] ...</k>
    <balances> BM </balances>
    requires Addr in_keys(BM)
  rule #balance(_) => 0 [owise]

  syntax KItem ::= #setBalance(addr: Int, balance: Int)
  rule
    <k> #setBalance(Addr, Balance) => Balance ...</k>
    <balances> BM => BM [ Addr <- Balance ] </balances>

  rule #send(0, _) => 0

  rule
    <k>
      #send(Addr:Int, Amount) => #setBalance(Addr, maxInt(B +Int Amount, 0))
      ...
    </k>
    <balances> Addr |-> B ...</balances>
    requires Addr =/=Int 0

  rule #send(Addr:Int, Amount) => #setBalance(Addr, maxInt(Amount, 0))
    [owise]
    

  rule
    <k> fn X (PS) Body => . ...</k>
    <functions>
      (.Bag =>
        <function>
          <function-id> X </function-id>
          <function-params> paramNames(PS) </function-params>
          <function-body> Body </function-body>
        </function>
      )
      ...
    </functions>

  rule
    <k> let X = V ; => . ...</k>
    <globals> GS => GS [ X <- V ] </globals>
    requires notBool inScope(X)

  syntax KItem ::= bind(args: Args, names: List)
                 | bindArg(arg: Expr, name: Id) [strict(1)]

  rule
    <k> bind(.Args, .List) => . ...</k>
    <args> AS => .Map </args>
    <env> _ => AS </env>

  rule bind(E , AS:Args, ListItem(X) XS) => bindArg(E, X) ~> bind(AS, XS)

  rule
    <k> bindArg(V:Value, X) => . ...</k>
    <args> E => E [ X <- V ] </args>

  rule
    <k> (X (AS) ~> Rest) => bind(AS, PS) ~> Body </k>
    <fstack> .List => ListItem(frame(Rest)) ...</fstack>
    <stack> .List => ListItem(E) ...</stack>
    <env> E </env>
    <function-id> X </function-id>
    <function-params> PS </function-params>
    <function-body> Body </function-body>

  syntax Bool ::= inScope(Id) [function]
  rule [[ inScope(X) => true ]]
    <env> E </env>
    <globals> GS </globals>
    requires X in_keys(E)
      orBool X in_keys(GS)
  rule inScope(_) => false [owise]

  rule
    <k> let X = V:Value => V ...</k>
    <env> E => E [ X <- V ] </env>
    requires notBool inScope(X)

  rule
    <k> X = V:Value => V ...</k>
    <env> E => E [ X <- V ] </env>
    requires X in_keys(E)

  rule
    <k> X = V:Value => V ...</k>
    <globals> G => G [ X <- V ] </globals>
    requires X in_keys(G)

  syntax K ::= expand(Exprs) [function]
  rule expand(.Exprs) => .K
  rule expand(E ; ES) => E ~> expand(ES)

  rule { ES } => expand(ES)

  rule
    <k> V:Value => V ~> F </k>
    <fstack> ListItem(frame(F)) => .List ...</fstack>
    <stack> ListItem(E) => .List ...</stack>
    <env> _ => E </env>

  rule
    <k> (return V:Value ~> _) => V ~> F </k>
    <fstack> ListItem(frame(F)) => .List ...</fstack>
    <stack> ListItem(E) => .List ...</stack>
    <env> _ => E </env>

  rule
    <k> _:Value => .K ...</k>
    [owise]

  rule
    <k> X:Id => V ...</k>
    <env> X |-> V ...</env>

  rule
    <k> X:Id => V ...</k>
    <globals> X |-> V ...</globals>

  rule
    <k> (I:Int ~> exit()) => . </k>
    <exit-code> _ => I </exit-code>

  syntax Bool ::= isKResult(Expr) [symbol, function]
  rule isKResult(_::Value) => true
  rule isKResult(_::Expr) => false [owise]
endmodule
```
