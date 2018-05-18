Today, we will see how Perl 6 helps to keep our programs better.

## Redeclaration of a variable

Examine the following program:

	my $x = 1;
	my $x = 2;
	say $x;

You can immediately see that this program is not entirely correct. Either we meant to assign a new value to $x or to create a new variable with a different name. In either case, compiler has no idea and complains:

	$ perl6 redecl.pl
	Potential difficulties:
	    Redeclaration of symbol '$x'
	    at /Users/ash/redecl.pl:2
	    ------&gt; my $x⏏ = 2;
	2

You see a runtime warning, while the program does not stop. Let us find out where it happens in the source code.

When you declare a variable, the grammar matches the corresponding text and calls the variable\_declarator action method. It is quite compact but nevertheless I will not quote it completely.

	class Perl6::Actions is HLL::Actions does STDActions {
	    . . .

	    method variable_declarator($/) {
	        . . .
	    }

	    . . .
	}

By the way, you can see here how Perl 6 treats a variable name:

	 my $past := $&lt;variable&gt;.ast;
	 my $sigil := $&lt;variable&gt;&lt;sigil&gt;;
	 my $twigil := $&lt;variable&gt;&lt;twigil&gt;;
	 my $desigilname := ~$&lt;variable&gt;&lt;desigilname&gt;;
	 **my $name := $sigil ~ $twigil ~ $desigilname;**

The name of a variable is a concatenation of a sigil, a twigil and an identifier (which is called desigiled name in the code).

Then, if we’ve got a proper variable name, check it against an existing lexpad:

	if $&lt;variable&gt;&lt;desigilname&gt; {
	    my $lex := $*W.cur_lexpad();
	    if $lex.symbol($name) {
	        $/.typed_worry('X::Redeclaration', symbol =&gt; $name);
	    }

If the name is known, generate a warning. If everything is fine, create a variable declaration:

	make declare_variable($/, $past, ~$sigil, ~$twigil, $desigilname,
	                      $&lt;trait&gt;, $&lt;semilist&gt;, :@post);

## Redeclaration of a routine

Now, let us try to re-create a subroutine:

	sub f() {}
	sub f() {}

This may only be OK if the subs are declared as multi-subs. With the given code, the program will not even compile:

	===SORRY!=== Error while compiling /Users/ash/redecl.pl
	Redeclaration of routine 'f' (did you mean to declare a multi-sub?)
	at /Users/ash/redecl.pl:6
	------&gt; sub f() {}⏏&lt;EOL&gt;

This time, it happens in a much more complicated method, routine\_def:

	method routine_def($/) {
	     . . .

	     my $predeclared := $outer.symbol($name);
	     if $predeclared {
	         my $Routine := $*W.find_symbol(['Routine'], :setting-only);
	         unless nqp::istype( $predeclared&lt;value&gt;, $Routine)
	                &amp;&amp; nqp::getattr_i($predeclared&lt;value&gt;, $Routine, '$!yada') {
	              $*W.throw($/, ['X', 'Redeclaration'],
	                        symbol =&gt; ~$&lt;deflongname&gt;.ast,
	                        what =&gt; 'routine',
	              );
	         }
	     }

## The exception

The code of the exception is rather simple. Here it is:

	my class X::Redeclaration does X::Comp {
	    has $.symbol;
	    has $.postfix = '';
	    has $.what = 'symbol';
	    method message() {
	        "Redeclaration of $.what '$.symbol'"
	        ~ (" $.postfix" if $.postfix)
	        ~ (" (did you mean to declare a multi-sub?)" if $.what eq 'routine');
	    }
	}

As you see, depending on the value of $.what, it prints either a short message or adds a suggestion to use the multi keyword.

### Share this:

* [Twitter][1]
* [Facebook][2]
* [Google][3]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2018/03/01/67-redeclaration-of-a-symbol/?share=twitter "Click to share on Twitter"
  [2]: https://perl6.online/2018/03/01/67-redeclaration-of-a-symbol/?share=facebook "Click to share on Facebook"
  [3]: https://perl6.online/2018/03/01/67-redeclaration-of-a-symbol/?share=google-plus-1 "Click to share on Google+"