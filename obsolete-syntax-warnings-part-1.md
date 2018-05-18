Yesterday, we saw an error message about the improper syntax of the ternary operator. Let’s look at other similar things that the Rakudo designers has implemented for us to make the transition from Perl 5 smoother.

First of all, the Perl 6 grammar file (src/Perl6/Grammar.nqp) contains four different methods for reacting to obsolete syntax:

	method obs($old, $new, $when = 'in Perl 6') {
	    $*W.throw(self.MATCH(), ['X', 'Obsolete'],
	        old         =&gt; $old,
	        replacement =&gt; $new,
	        when        =&gt; $when,
	    );
	}
	method obsvar($name) {
	    $*W.throw(self.MATCH(), ['X', 'Syntax', 'Perl5Var'], :$name);
	}

	method sorryobs($old, $new, $when = 'in Perl 6') {
	    $*W.throw(self.MATCH(), ['X', 'Obsolete'],
	        old         =&gt; $old,
	        replacement =&gt; $new,
	        when        =&gt; $when,
	    );
	}

	method worryobs($old, $new, $when = 'in Perl 6') {
	    self.typed_worry('X::Obsolete',
	        old         =&gt; $old,
	        replacement =&gt; $new,
	        when        =&gt; $when,
	    );
	}

Three of these methods throw exceptions, the fourth one prints a warning. The final text of the error message is using the information from the arguments of the methods. For example, this is what we saw yesterday:

	&lt;.obs('? and : for the ternary conditional operator', '?? and !!')&gt;

This part of the token regex is transformed to the following error message (the parts from the regex are highlighted):

	Unsupported use of **? and : for the ternary conditional operator**;
	in Perl 6 please use **?? and !!**

## Obsolete syntax

Let us see what other messages we have in the current Rakudo Perl 6 compiler.

### Negative indices

The first example is very likely one of the most common mistake that a Perl 5 programmer faces when programming in Perl 6.

	$ perl6 -e'my @a; say @a[-1]'
	===SORRY!=== Error while compiling -e
	Unsupported use of a negative -1 subscript to index from the end;
	in Perl 6 please use a function such as *-1
	at -e:1
	------&gt; my @a; say @a[-1]⏏

To count from the end of the array, you should use a WhateverCode instead of negative integers. This is how the error message is encoded in the src/Perl6/Actions.nqp file (notice that this is an NQP module, not the Perl 6 one, while the syntax is very clear):

	method postcircumfix:sym&lt;[ ]&gt;($/) {
	    . . .
	    my $ix := $_ ~~ / [ ^ | '..' ] \s* **&lt;( '-' \d+ )&gt;** \s* $ /;
	    if $ix {
	        $c.obs("a negative " ~ $ix ~ " subscript to index from the end",
	               "a function such as *" ~ $ix);
	    }
	    . . .
	}

The $c variable is the current symbol in the syntax tree, and the $ix is a negative index taken from the square brackets (notice the position of the capturing parentheses inside the regex). If there is a negative index, an error message is generated for your pleasure.

The rest of the .obs calls happen in the src/Perl6/Grammar.nqp file.

### Perl 6 loop, not C-style for

The for loop in Perl 6 is designed to work with lists or arrays, so using it in the C-style, which is allowed in Perl 5, is prohibited:

	$ perl6 -e'**for (my $i = 1; $i != 10; $i++)** {}'
	===SORRY!=== Error while compiling -e
	Unsupported use of C-style "for (;;)" loop;
	in Perl 6 please use "loop (;;)"
	at -e:1
	------&gt; for ⏏(my $i = 1; $i != 10; $i++) {}

Localise that error message in the grammar:

	rule statement_control:sym&lt;for&gt; {
	    &lt;sym&gt;&lt;.kok&gt; {}
	    [ &lt;?before 'my'? '$'\w+\s+'(' &gt;
	        &lt;.typed_panic: 'X::Syntax::P5'&gt; ]?
	    [ &lt;?before '(' &lt;.EXPR&gt;? ';' &lt;.EXPR&gt;? ';' &lt;.EXPR&gt;? ')' &gt;
	        **&lt;.obs('C-style "for (;;)" loop', '"loop (;;)"')&gt;** ]?
	    &lt;xblock(1)&gt;
	}

Here, you also can see another type of error message regarding the Perl 5 syntax (see where the typed\_panic method matches):

	$ ./perl6 -e'**for my $x (@a)** {}'
	===SORRY!=== Error while compiling -e
	This appears to be Perl 5 code
	at -e:1
	------&gt; for ⏏my $x (@a) {}

Interestingly, this is the only place where the X::Syntax::P5 exception is used.

That’s all for today, stay tuned for more error messages tomorrow! 🙂

### Share this:

* [Twitter][1]
* [Facebook][2]
* [Google][3]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2017/12/29/obsolete-syntax-warnings-part-1/?share=twitter "Click to share on Twitter"
  [2]: https://perl6.online/2017/12/29/obsolete-syntax-warnings-part-1/?share=facebook "Click to share on Facebook"
  [3]: https://perl6.online/2017/12/29/obsolete-syntax-warnings-part-1/?share=google-plus-1 "Click to share on Google+"