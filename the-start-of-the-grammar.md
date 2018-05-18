Yesterday, we talked about the stages of the compiling process of a Perl 6 program and saw the parse tree of a simple ‘Hello, World!’ program. Today, our journey begins at the starting point of the Grammar.

So, here is the program:

	say 'Hello, World!'

The grammar of Perl 6 is written in Not Quite Perl 6 and is located in Grammar.nqp 🙂 And that is amazing, as if you know how to work with grammars, you will be able to read the heart of the language.

The Perl 6 Grammar is defined as following:

	grammar Perl6::Grammar is HLL::Grammar does STD {
	    . . .
	}

It is a class derived from HLL::Grammar (HLL stands for _High-Level Language_) and implements the STD (_Standard_) role. Let’s not focus on the hierarchy for now, though.

The Grammar has the TOP method. Notice that this is a _method_, not a rule or a token. The main feature of the method is that it is assumed that it contains some Perl 6 _code_, not regexes.

As we did earlier, let’s use our beloved method of reverse engineering by adding our own printing instructions to different places of Rakudo sources, recompiling it and watching how it works. The first target is the TOP method:

	grammar Perl6::Grammar is HLL::Grammar does STD {
	    my $sc_id := 0;
	    method TOP() {
	        **nqp::say('At the TOP');**
	        . . .

As this is NQP, you need to call functions in the nqp:: namespace (although say is available without the namespace prefix, too). One of the notable differences between Perl 6 and NQP is the need to always have parentheses in function calls: if you omit them, the code won’t compile.

## Perl inside regexes inside Perl

For training purposes, let’s try adding similar instruction to the comp\_unit token (computational unit). This token is a part of the Grammar and is also called as one of the first methods during parsing Perl 6.

The body of the above shown TOP method is written in NQP. The body of a token is another language, and you should use regexes instead. Thus, to embed an instruction in Perl (or NQP), you need to switch the language.

There are two options: use a code block in curly braces or the colon-prefixed syntax that is very widely used in Rakudo sources to declare variables.

	token comp_unit {
	    **{
	        nqp::say('comp_unit');
	    }
	    :my $x := nqp::say('Var in grammar');**
	    . . .

Notice that it NQP, the binding := operator have to be used in place of the assignment =.

## Statement list

So, back to the grammar. In the output that the --target=parse command-line option produces, we can see a statementlist node at the top of the parse tree. Let us look at its implementation in the Grammar. With some simplifications, it looks very lightweight:

	rule statementlist($*statement_level = 0) {
	    . . .
	    &lt;.ws&gt;
	    [
	    | $
	    | &lt;?before &lt;.[\)\]\}]&gt;&gt;
	    | [ &lt;statement&gt; &lt;.eat_terminator&gt; ]*
	    ]
	    . . .
	}

Basically, it says that a statement list is a list of zero or more statements. Square brackets in Perl 6 grammars create a non-capturing group, and we see three alternatives inside. One of the alternatives is just the end of data, another one is the end of the block (e. g., ending with a closing curly brace). For the sake of art, an additional vertical bar is added before the first alternative too.

The top-level rule is simple but the rest is becoming more and more complex. For example, let’s have a quick look at the eat terminator:

	token eat_terminator {
	    || ';'
	    || &lt;?MARKED('endstmt')&gt; &lt;.ws&gt;
	    || &lt;?before ')' | ']' | '}' &gt;
	    || $
	    || &lt;?stopper&gt;
	    || &lt;?before [if|while|for|loop|repeat|given|when] » &gt; {
	       $/.'!clear_highwater'(); self.typed_panic(
	          'X::Syntax::Confused', reason =&gt; "Missing semicolon" ) }
	    || { $/.typed_panic( 'X::Syntax::Confused', reason =&gt; "Confused" ) }
	}

And this is just a small separator between the statements 🙂

The grammar file is more than 5500 lines of code; it is not possible to discuss and understand it all in a single blog post. Let us stop here for today and continue with easier stuff tomorrow.

### Share this:

* [Twitter][1]
* [Facebook][2]
* [Google][3]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2018/01/01/the-start-of-the-grammar/?share=twitter "Click to share on Twitter"
  [2]: https://perl6.online/2018/01/01/the-start-of-the-grammar/?share=facebook "Click to share on Facebook"
  [3]: https://perl6.online/2018/01/01/the-start-of-the-grammar/?share=google-plus-1 "Click to share on Google+"