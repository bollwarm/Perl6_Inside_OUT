The ternary operator ?? !! takes three operands, obviously. Although, it is said in the documentation that the operator [is an infix][1]. Let us figure out why.

Here is the fragment from the Grammar that handles the ternary operator:

	token infix:sym&lt;?? !!&gt; {
	    :my $*GOAL := '!!';
	    $&lt;sym&gt;='??'
	    &lt;.ws&gt;
	    &lt;EXPR('i=')&gt;
	    [ '!!'
	    || &lt;?before '::' &lt;.-[=]&gt;&gt; { self.typed_panic: "X::Syntax::ConditionalOperator::SecondPartInvalid", second-part =&gt; "::" }
	    || &lt;?before ':' &lt;.-[=\w]&gt;&gt; { self.typed_panic: "X::Syntax::ConditionalOperator::SecondPartInvalid", second-part =&gt; ":" }
	    || &lt;infixish&gt; { self.typed_panic: "X::Syntax::ConditionalOperator::PrecedenceTooLoose", operator =&gt; ~$&lt;infixish&gt; }
	    || &lt;?{ ~$&lt;EXPR&gt; ~~ / '!!' / }&gt; { self.typed_panic: "X::Syntax::ConditionalOperator::SecondPartGobbled" }
	    || &lt;?before \N*? [\n\N*?]? '!!'&gt; { self.typed_panic: "X::Syntax::Confused", reason =&gt; "Confused: Bogus code found before the !! of conditional operator" }
	    || { self.typed_panic: "X::Syntax::Confused", reason =&gt; "Confused: Found ?? but no !!" }
	    ]
	    &lt;O(|%conditional, :reducecheck&lt;ternary&gt;, :pasttype&lt;if&gt;)&gt;
	}

The most of the body is filled with different error reporting additions that pop up when something is wrong with the second part of the operator. Let us reduce the noise and implement the simplest form of our own artificial operator ¿¿ ¡¡ that does no such error checking:

	token infix:sym&lt;¿¿ ¡¡&gt; {
	    '¿¿'
	    &lt;.ws&gt;
	    &lt;EXPR('i=')&gt;
	    '¡¡'
	    &lt;O(|%conditional, :reducecheck&lt;ternary&gt;, :pasttype&lt;if&gt;)&gt;
	}

Now you can clearly see the structure of the token. It matches the following components: a literal string '¿¿', an expression, and another string '¡¡'. We’ve already seen [the use of the O token][2] when we were talking about precedence.

If you consider ¿¿ ¡¡ as an infix operator  ($left ¿¿ $mid ¡¡ $right), then the first and the third operands of the ternary operator are, respectively, the left and the right operands of the combined operator. The code between ¿¿ and ¡¡ is caught by the &lt;EXPR&gt; rule.

Before wrapping up for today, let us print what the Grammar finds at that position:

	token infix:sym&lt;¿¿ ¡¡&gt; {
	    '¿¿'
	    &lt;.ws&gt;
	    &lt;EXPR('i=')&gt; **{**
	**        nqp::say('Inside we see: ' ~ $&lt;EXPR&gt;)**
	**    }**
	    '¡¡'
	    &lt;O(|%conditional, :reducecheck&lt;ternary&gt;, :pasttype&lt;if&gt;)&gt;
	}

Compile and run:

	$ ./perl6 -e'say 3 ¿¿ 4 ¡¡ 5'
	Inside we see: 4
	4

It is quite difficult, though, to find the place where the actual logic of the ternary operator is defined. I would not even recommend doing that as homework 🙂 Nevertheless, come back tomorrow to see more details of the internals of the ternary operators.

### Share this:

* [Twitter][3]
* [Facebook][4]
* [Google][5]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://docs.perl6.org/language/operators#index-entry-Ternary_operator
  [2]: https://perl6.online/2017/12/28/digging-operator-precedence-part-2/
  [3]: https://perl6.online/2018/01/11/infix-nature-of-ternary-operator-in-perl-6/?share=twitter "Click to share on Twitter"
  [4]: https://perl6.online/2018/01/11/infix-nature-of-ternary-operator-in-perl-6/?share=facebook "Click to share on Facebook"
  [5]: https://perl6.online/2018/01/11/infix-nature-of-ternary-operator-in-perl-6/?share=google-plus-1 "Click to share on Google+"