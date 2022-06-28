module SPLS-SYNTAX
  imports ID-SYNTAX
  imports UNSIGNED-INT-SYNTAX
  imports BOOL

  syntax Value    ::= "(" ")"
                    | Int
                    | Bool

  syntax Type     ::= "int"
                    | "bool"
                    | "unit"

  syntax Param    ::= Id ":" Type
  syntax Params   ::= List{Param, ","}

  syntax Args     ::= List{Expr, ","}

  syntax Expr     ::= Value
                    | Id
                    | Id "(" Args ")"
                    | "-" Expr [non-assoc]
                    > Expr "*" Expr [left, strict]
                    | Expr "/" Expr [left, strict]
                    > Expr "+" Expr [left, strict]
                    | Expr "-" Expr [left, strict]
                    > Expr "==" Expr [non-assoc, strict]
                    | Expr "!=" Expr [non-assoc, strict]
                    | Expr ">=" Expr [non-assoc, strict]
                    | Expr ">" Expr [non-assoc, strict]
                    | Expr "<=" Expr [non-assoc, strict]
                    | Expr "<" Expr [non-assoc, strict]
                    > VarDecl
                    | "if" "(" Expr ")" Expr "else" Expr [strict(1)]
                    | "while" "(" Expr ")" Expr
                    | Id "=" Expr [strict(2)]
                    | "return" Expr [strict]
                    > Block
                    > "(" Expr ")" [bracket]

  syntax Exprs    ::= NeList{Expr, ";"}

  syntax Block    ::= "{" Exprs "}"

  syntax FunDecl  ::= "fn" Id "(" Params ")" Block
  syntax VarDecl  ::= "let" Id "=" Expr [strict(2)]

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
                    | "sum"  [token]
                    | "n"  [token]
                    | "nc"  [token]

  syntax KItem ::= exit()

  configuration
    <k> $PGM:Pgm ~> main(.Args) ~> exit() </k>
    <exit-code> 0 </exit-code>
    <fstack> .List </fstack>
    <stack> .List </stack>
    <env> .Map </env>
    <globals> .Map </globals>
    <functions>
      <function multiplicity="*" type="Map">
        <function-id> dummy </function-id>
        <function-params> .List </function-params>
        <function-param-types> .List </function-param-types>
        <function-body> .K </function-body>
      </function>
    </functions>
endmodule

module SPLS
  imports SPLS-CONFIGURATION
  imports INT
  imports BOOL

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
                | paramTypes(Params) [function]

  rule paramNames(.Params) => .List
  rule paramNames(X : _ , PS) => ListItem(X) paramNames(PS)

  rule paramTypes(.Params) => .List
  rule paramTypes(_ : T , PS) => ListItem(T) paramTypes(PS)

  rule
    <k> fn X (PS) Body => . ...</k>
    <functions>
      (.Bag =>
        <function>
          <function-id> X </function-id>
          <function-params> paramNames(PS) </function-params>
          <function-param-types> paramTypes(PS) </function-param-types>
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

  rule bind(.Args, .List) => .K
  rule bind(E , AS:Args, ListItem(X) XS) => bindArg(E, X) ~> bind(AS, XS)

  rule
    <k> bindArg(V:Value, X) => . ...</k>
    <env> E => E [ X <- V ] </env>

  rule
    <k> (X (AS) ~> Rest) => bind(AS, PS) ~> Body </k>
    <fstack> .List => ListItem(frame(Rest)) ...</fstack>
    <stack> .List => ListItem(E) ...</stack>
    <env> E => .Map </env>
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
