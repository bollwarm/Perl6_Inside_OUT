Yesterday, we took a look at how the ? and so operators are dispatched depending on the type of the variable. We did it with the intention to understand what is the difference between them.

Here is once again an excerpt from the src/core/Bool.pm file, where the bodies of the subs look alike:

	proto sub prefix:&lt;?&gt;(Mu $) is pure {*}
	multi sub prefix:&lt;?&gt;(Bool:D \a) { a }
	multi sub prefix:&lt;?&gt;(Bool:U \a) { Bool::False }
	multi sub prefix:&lt;?&gt;(Mu \a) { a.Bool }

	proto sub prefix:&lt;so&gt;(Mu $) is pure {*}
	multi sub prefix:&lt;so&gt;(Bool:D \a) { a }
	multi sub prefix:&lt;so&gt;(Bool:U \a) { Bool::False }
	multi sub prefix:&lt;so&gt;(Mu \a) { a.Bool }

Both of them coerce the arguments to a Bool value. The difference is in their operator precedence. You cannot say for sure what is the precedence if you only look at the Bool.pm file. You will find more details in the src/Perl6/Grammar.nqp file describing the Perl 6 language grammar. Here are the fragments we need:

	token prefix:sym&lt;so&gt; { &lt;sym&gt;&lt;.end_prefix&gt; &lt;O(|%loose_unary)&gt; }
	. . .
	token prefix:sym&lt;?&gt; { &lt;sym&gt; &lt;!before '??'&gt; &lt;O(|%symbolic_unary)&gt; }

These look complex but let’s first concentrate only on the last part of the token definitions: &lt;O(|%loose\_unary)&gt; and &lt;O(|%symbolic\_unary)&gt;. Obviously, these are what define the rules for precedence. You can find a list of about 30 different kind of precedences in the same file:

	## Operators

	. . .
	my **%symbolic_unary** := nqp::hash('prec', 'v=', 'assoc', 'unary', 'dba', 'symbolic unary');
	. . .
	my %list_assignment := nqp::hash('prec', 'i=', 'assoc', 'right', 'dba', 'list assignment', 'sub', 'e=', 'fiddly', 1);
	my **%loose_unary** := nqp::hash('prec', 'h=', 'assoc', 'unary', 'dba', 'loose unary');
	my %comma := nqp::hash('prec', 'g=', 'assoc', 'list', 'dba', 'comma', 'nextterm', 'nulltermish', 'fiddly', 1);
	. . .

Let’s avoid digging deeper into how it works at the moment. Looking at the list you can guess that the letters k, j, h, and g define the preference order of different kinds of preference rules. As well a right or left dictate the associativity of the operators.

So, the so operator has the _loose unary_ precedence level and the ? operator has a higher _symbolic unary_ precedence.

## The old conditional operator

Before we wrap up for today, let’s look at another interesting place where the single question mark can be caught in the Perl 6 program. I am talking about the following token in the grammar (notice that this time this is for an infix, not for a prefix):

	token infix:sym&lt;?&gt; {
	    &lt;sym&gt; {} &lt;![?]&gt; &lt;?before &lt;.-[;]&gt;*?':'&gt;
	    &lt;.obs('? and : for the ternary conditional operator', '?? and !!')&gt;
	    &lt;O(|%conditional)&gt;
	}

This code catches the usage of a single ?, which was a part of the ternary operator in Perl 5 unlike the double ?? from the ternary operator in Perl 6.

The &lt;.obs...&gt; part of the token regex prints a warning about obsolete syntax:

	$ ./perl6 -e'say 1 ? True : False'
	===SORRY!=== Error while compiling -e
	Unsupported use of ? and : for the ternary conditional operator;
	in Perl 6 please use ?? and !!
	at -e:1
	------&gt; say 1 ?⏏ True : False

So, if you use the old syntax, you’ll get not only an error message but also a hint on how to fix the issue.

### Share this:

* [Twitter][1]
* [Facebook][2]
* [Google][3]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2017/12/28/digging-operator-precedence-part-2/?share=twitter "Click to share on Twitter"
  [2]: https://perl6.online/2017/12/28/digging-operator-precedence-part-2/?share=facebook "Click to share on Facebook"
  [3]: https://perl6.online/2017/12/28/digging-operator-precedence-part-2/?share=google-plus-1 "Click to share on Google+"