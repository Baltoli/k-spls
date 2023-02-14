# PCL

This file is a literate K implementation of PCL, a language based on the
pi calculus. PCL supports basic arithmetic and IO on top of the thread
coordination of the underlying calculus.

## Syntax

```k
module PCL-SYNTAX
  imports BOOL-SYNTAX
  imports INT-SYNTAX

  syntax Variable ::= r"[A-Z][a-zA-Z]*" [token]
  syntax Channel  ::= r"@?[a-z]+"       [token]

  syntax Id ::= Variable | Channel

  syntax Bool ::= isKResult(Exp) [symbol, function]

  syntax Exp ::= Id | Int
               | "(" Exp ")" [bracket]
               > "-" Exp     [non-assoc, strict]
               > Exp "*" Exp [left, strict]
               | Exp "/" Exp [left, strict]
               > Exp "+" Exp [left, strict]
               | Exp "-" Exp [left, strict]

  syntax External ::= "external" Channel ";"
  syntax Externals ::= NeList{External, ""}

  syntax Process ::= "in"  Id "(" Variable ")" [strict(1)]
                   | "out" Id "(" Exp ")"      [strict]
                   | "(" Process "|" Process ")"
                   | "fresh" Variable "{" Process "}"
                   | "!" "(" Process ")"
                   | "end"
                   | "stop"
                   | "let" Variable "=" Exp "{" Process "}" [strict(2)]
                   | "[" Exp "=" Exp "]" "{" Process "}" [strict(1, 2)]
                   | Process "." Process [left]

  syntax Program ::= Externals Process
endmodule
```

## Configuration

```k
module PCL-CONFIGURATION
  imports INT
  imports SET
  imports LIST

  configuration
    <startup> $PGM </startup>
    <externals> .Set </externals>
    <threads>
      <thread multiplicity="*" type="Map">
        <id> 0 </id>
        <k> . </k>
        <env> .Map </env>
      </thread>
    </threads>
    <input stream="stdin"> .List </input>
    <output stream="stdout"> .List </output>
endmodule
```

## IO Hooks

```k
module PCL-HOOKS
  imports PCL-CONFIGURATION
  imports PCL-SYNTAX
  imports STRING

  syntax Process ::= #send(Channel, Exp) [strict(2)]
                   | #recv(Channel, Variable)

  rule
    <k> in C ( X ) => #recv(C, X) ...</k>
    <externals> E </externals>
    requires C in E
    [priority(40)]

  rule
    <k> out C ( V ) => #send(C, V) ...</k>
    <externals> E </externals>
    requires C in E
    [priority(40)]

  syntax Process ::= #read(Variable)

  rule
    <k> #recv(@stdio, X) => #read(X) ...</k>
    <output>... .List => ListItem("> ") </output>

  rule
    <k> #read(X) => . ...</k>
    <input> ListItem(V:Int) => .List ...</input>
    <env> E => E [ X <- V ] </env>

  rule
    <k> #send(@stdio, V:Int) => . ...</k>
    <output>... .List => ListItem(Int2String(V) +String "\n") </output>
endmodule
```

## Semantics

```k
module PCL
  imports PCL-CONFIGURATION
  imports PCL-SYNTAX
  imports PCL-HOOKS
  imports K-EQUAL
  imports BOOL
  imports INT
  imports SET
  imports STRING

  syntax Channel ::= StringToChannel(String) [function, total, hook(STRING.string2token)]
                   | #freshChannel(Int)      [function, total, freshGenerator]
  rule #freshChannel(I) => StringToChannel("#c_" +String Int2String(I))

  rule isKResult(_:Channel) => true
  rule isKResult(_:Int) => true
  rule isKResult(_) => false [owise]

  rule
    <startup> P:Process => .K ...</startup>
    <threads>
      _ =>
        <thread>
          <id> !_:Int </id>
          <k> P </k>
          <env> .Map </env>
        </thread>
    </threads>

  rule <startup> E ES:Externals P:Process => E ~> ES ~> P ...</startup>
  rule <startup> .Externals => . ...</startup>
  rule
    <startup> external C ; => . ...</startup>
    <externals> S => S SetItem(C) </externals>

  rule
    <k> P . Q => P ~> Q ...</k>

  rule
    <k> X:Variable => C ...</k>
    <env>... X |-> C ...</env>

  rule
    <k> let X = C { P } => P ...</k>
    <env> E => E [ X <- C ] </env>

  rule
    <k> fresh X { P } => P ...</k>
    <env> E => E [ X <- !_:Channel ] </env>

  rule
    <threads>
      ...
      <thread>
        <k> in C ( X ) => . ...</k>
        <env> E => E [ X <- V ] </env>
        ...
      </thread>
      <thread>
        <k> out C ( V ) => . ...</k>
        ...
      </thread>
      ...
    </threads>
    requires isKResult(V)

  rule
    <threads>
      <thread>
        ...
        <k> (P | Q) => P ...</k>
        <env> E </env>
      </thread>
      (.Bag =>
        <thread>
          <id> !_:Int </id>
          <k> Q </k>
          <env> E </env>
        </thread>)
      ...
    </threads>

  rule
    <k> ! ( P ) => (P | !( P )) ...</k>
    [priority(110)]

  rule
    <threads>
      (<thread>... <k> . </k> ...</thread> => .Bag)
      ...
    </threads>

  rule
    <k> [ E1 = E2 ] { P } => P ...</k>
    requires E1 ==K E2

  rule
    <k> [ _ = _ ] { _ } => . ...</k>
    [owise]

  rule
    <k> end ~> _ => . </k>

  rule
    <k> stop ~> _ => . </k>
    <startup> _ => stop </startup>

  rule
    <startup> stop => . ...</startup>
    <threads> _ => .Bag </threads>
    [priority(20)]

  rule - I:Int        => 0 -Int I
  rule X:Int * Y:Int  => X *Int Y
  rule X:Int / Y:Int  => X /Int Y
  rule X:Int + Y:Int  => X +Int Y
  rule X:Int - Y:Int  => X -Int Y

endmodule
```
