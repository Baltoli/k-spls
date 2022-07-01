This file is a literate K definition for a simple imperative programming
language. This language is dynamically typed, and does not have a
distinction between statements and expressions.

Several elements of its design are made for simplicity of code, rather than to
produce a language that is maximally ergonomic to write.

# Syntax

We follow the K convention of defining an external _syntax_ module that
specifies how user programs should be parsed. Note that this syntax will be
extended in the main module when defining the rewrite system for the language;
these syntax extensions are not accessible by users of the language.
```k
module IMP-BALANCE-SYNTAX
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
                    | Expr "-" Expr [sub, strict, left]
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

The `prefer` attribute here allows for parsing ambiguities to be resolved. We
parse `let x = 2 + 2` as `let x = (2 + 2)` rather than `(let x = 2) + 2` by
preferring the top-level `let` production:
```k
  syntax Expr     ::= "let" Id "=" Expr [let,    strict(2), prefer]
                    | Id "=" Expr       [assign, strict(2)]
```

We support three basic control flow elements: if-else, while loops, and early
returns:
```k
  syntax Expr     ::= "if" "(" Expr ")" Expr "else" Expr [if,     strict(1)]
                    | "while" "(" Expr ")" Expr          [while]
                    | "return" Expr                      [return, strict]
```

Expressions can be sequenced with `;`, and a list of expressions makes up a
block. Note the use of K's syntactic list feature here to deal with the
boilerplate code of parsing separated lists. Blocks themselves are expressions
as well:
```k
  syntax Exprs    ::= NeList{Expr, ";"}
  syntax Block    ::= "{" Exprs "}"
  syntax Expr     ::= Block [block]
```

Expressions can be parenthesized:
```k
  syntax Expr     ::= "(" Expr ")" [bracket]
```

The unique labels we gave to each kind of expression production can be used to
assign their relative parsing priorities:
```k
  syntax priorities neg > mul div > add sub > eq neq gteq gt lteq lt
```

Function declarations and argument lists for calls make similar use of syntactic
lists:
```k
  syntax Param    ::= Id
  syntax Params   ::= List{Param, ","}
  syntax FunDecl  ::= "fn" Id "(" Params ")" Block

  syntax Args     ::= List{Expr, ","}
```

The top-level program structure in this language is a sequence of declarations:
```k
  syntax Decl     ::= FunDecl
  syntax Decls    ::= NeList{Decl, ""} [prefer]
  syntax Pgm      ::= Decls
```

Finally, we extend the `Expr` sort with some special forms that we will use
later to demonstrate proofs in K:
```k
  syntax Expr     ::= #balance(Expr)    [strict]
                    | #send(Expr, Expr) [strict]
                    | #halt()
endmodule
```

# Configuration

The configuration for this language contains the state required to represent a
running program:
* The current computation in the `<k>` cell
* Call and environment stacks
* An environment mapping names to values
* Account balances (an example of "outside world") interaction
```k
module IMP-BALANCE-CONFIGURATION
  imports IMP-BALANCE-SYNTAX
  imports LIST
  imports MAP
```

K parses in two different modes depending on whether the program is "standalone"
input (e.g. being read from a file with `krun` etc.), or is part of a K
definition. This is to avoid a parsing ambiguity between K variables and
identifiers that happen to begin with an upper-case letter; we therefore need to
pre-declare any identifier tokens that we write in the configuration:
```k
  syntax Id       ::= "dummy" [token]
                    | "main"  [token]

  syntax KItem ::= exit()
```

The `$PGM` variable is a placeholder used by the K toolchain to represent the
program passed by `krun` etc. (e.g. the contents of a file, or the `-cPGM`
command line flag). To give every program the same entry-point, we follow the
user's program with a call to the `main` function:
```k
  configuration
    <k> $PGM:Pgm ~> main(.Args) ~> exit() </k>
    <exit-code> 0     </exit-code>
    <fstack>    .List </fstack>
    <stack>     .List </stack>
    <env>       .Map  </env>
    <args>      .Map  </args>
    <balances>  .Map  </balances>
    <functions>
      <function multiplicity="*" type="Map">
        <function-id>     dummy </function-id>
        <function-params> .List </function-params>
        <function-body>   .K    </function-body>
      </function>
    </functions>
endmodule
```

# Semantics

This module defines the run-time semantics of programs in our language by
providing rewrite rules over the many-sorted grammar described above.
```k
module IMP-BALANCE
  imports IMP-BALANCE-CONFIGURATION
  imports INT
  imports BOOL
  imports MAP
```

## Arithmetic and Boolean

Arithmetic and boolean rules are simple to write because K's strictness
annotations ensure that we only ever have to rewrite over values. The symbols
`-Int` etc. are function symbols in K, which means that they are evaluated
immediately on being constructed, and cannot be pattern-matched on.
```k
  rule   - X => 0 -Int X

  rule X + Y => X +Int Y
  rule X - Y => X -Int Y
  rule X * Y => X *Int Y
  rule X / Y => X /Int Y

  rule B1 == B2 => B1 ==Bool B2
  rule I1 == I2 => I1 ==Int I2

  rule B1 != B2 => B1 =/=Bool B2
  rule I1 != I2 => I1 =/=Int  I2

  rule I1 >= I2 => I1 >=Int I2
  rule I1 >  I2 => I1 >Int  I2
  rule I1 <= I2 => I1 <=Int I2
  rule I1 <  I2 => I1 <Int  I2
```

## Declarations and Environment

Local variable declarations do not allow us to redeclare variables:
```k
  rule
    <k> let X = V:Value => V ...</k>
    <env> E => E [ X <- V ] </env>
    requires notBool X in_keys(E)
```

Writes to the environment and variable lookups are similar:
```k
  rule
    <k> X = V:Value => V ...</k>
    <env> E => E [ X <- V ] </env>
    requires X in_keys(E)

  rule
    <k> X:Id => V ...</k>
    <env> X |-> V ...</env>
```

Function declarations use a helper function to unpack a syntactic list of
parameter names into a hooked (native) K list of identifiers. When we see a
function declaration, we add a new child cell to the `<functions>` cell with the
`.Bag => ...` rewrite. K's ability to stash the whole function body in the
configuration makes it easy to later implement call and return:
```k
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

  syntax List ::= paramNames(Params) [function]
  rule paramNames(.Params) => .List
  rule paramNames(X , PS) => ListItem(X) paramNames(PS)
```

Additionally, we need to unpack the syntactic list of declarations that makes up
a program:
```k
  rule D:Decl DS => D ~> DS
  rule .Decls => .K
```

## Control Flow

### Conditionals and Loops

Conditional expressions rewrite to either of their branches, intuitively:
```k
  rule if ( true  ) E1 else _  => E1
  rule if ( false ) _  else E2 => E2
```

Loops take advantage of non-strict evaluation to repeat their condition checks
in the desugared right-hand side: `C` is an expression, rather than a value, so
we can reuse it when the next iteration is checked:
```k
  rule
    while ( C ) E
    => if ( C ) { 
        E ; 
        while ( C ) E 
       } else ()
```

We expand out the syntactic list that makes up a block:
```k
  syntax K ::= expand(Exprs) [function]
  rule expand(.Exprs) => .K
  rule expand(E ; ES) => E ~> expand(ES)

  rule { ES } => expand(ES)
```

### Call and Return

To call a function, we need to make sure the call has the correct number of
arguments, then bind those arguments to the parameters from the function's
declaration in a new environment. Then, we set the function's body as the next
computation, and save the current environment and computation in a stack frame.

To make sure that arguments are evaluated in the _current_ environment before we
stash it on the stack, we store the argument bindings in the `<args>` cell, then
overwrite the environment when we're done binding arguments.
```k
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
```

Note the use of K's "configuration completion" here: the compiler can infer that
the three `<function-*>` cells belong to a parent `<function>` cell, and so we
don't need to mention the parent.
```k
  syntax KItem ::= frame(K)

  rule
    <k> (X (AS) ~> Rest) => bind(AS, PS) ~> Body </k>
    <fstack> .List => ListItem(frame(Rest)) ...</fstack>
    <stack>  .List => ListItem(E)           ...</stack>
    <env> E </env>
    <function-id>     X    </function-id>
    <function-params> PS   </function-params>
    <function-body>   Body </function-body>
```

We can return from a function in two ways: early, with the `return` keyword, or
by having a function's body evaluate down to a single value in the `<k>` cell.
These cases are treated identically once we have the value to be returned:
```k
  syntax KItem ::= #return(Value)

  rule <k> V               => #return(V) </k>
  rule <k> (return V ~> _) => #return(V) </k>

  rule
    <k> #return(V) => V ~> F </k>
    <fstack> ListItem(frame(F)) => .List ...</fstack>
    <stack> ListItem(E) => .List ...</stack>
    <env> _ => E </env>
```

## Program

If we have a value left at the top of the `<k>` cell, but computations left to
do, we just discard it:
```k
  rule _:Value => . [owise]
```

If there's an integer left at program exit, set the return code appropriately:
```k
  rule
    <k> (I:Int ~> exit()) => . </k>
    <exit-code> _ => I </exit-code>
```

## Account Operations

The internal `#setBalance` operation doesn't check its argument; it just updates
the balance table:
```k
  syntax KItem ::= #setBalance(addr: Int, balance: Int)
  rule
    <k> #setBalance(Addr, Balance) => Balance ...</k>
    <balances> BM => BM [ Addr <- Balance ] </balances>
```

Accounts not in the balance table have `0` balance by default:
```k
  rule
    <k> #balance(Addr) => BM [ Addr ] ...</k>
    <balances> BM </balances>
    requires Addr in_keys(BM)
  rule #balance(_) => 0 [owise]
```

The `#send` operation is exposed to user programs, and so is checked. The zero
address is a sink, and so will accept any argument without checking:
```k
  rule #send(0, _) => 0
```

If an account has an existing balance, we set their balance to the adjusted
balance, ensuring it never goes below 0:
```k
  rule
    <k>
      #send(Addr:Int, Amount) => #setBalance(Addr, maxInt(B +Int Amount, 0))
      ...
    </k>
    <balances> Addr |-> B ...</balances>
    requires Addr =/=Int 0
```

If not, we behave similarly:
```k
  rule #send(Addr:Int, Amount) => #setBalance(Addr, maxInt(Amount, 0))
  [owise]
```


## Boilerplate

This function is a hook that guides the compiler's generation of heating and
cooling rules for expressions.
```k
  syntax Bool ::= isKResult(Expr) [symbol, function]
  rule isKResult(_:Value) => true
  rule isKResult(_) => false [owise]
```

```k
endmodule
```
