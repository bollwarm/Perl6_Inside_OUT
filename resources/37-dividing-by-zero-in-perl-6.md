You might already know that it is possible to divide by zero in Perl 6 🙂

Well, seriously speaking, you can only do that until you don’t want to announce it to the others. So, the division itself is not a problem:

	$ ./perl6 -e'my $x = 1; my $y = **$x / 0**; say "Done"'
	Done

It becomes a problem when the result of the division is used somewhere, for example, when you print it:

	$ ./perl6 -e'my $x = 1; my $y = $x / 0; **say $y**'
	Attempt to divide 1 by zero using div
	  in block  at -e line 1

This type of failure is called _soft failure_. Today, we will look at the places in Rakudo, where a divide-by-zero error can be triggered.

Did you notice that the error message above says _divide by zero using div_. Does it mean that other methods of division by zero exist too? Let’s figure it out.

The error message is generated within an exception (src/core/Exception.pm) of the X::Numeric::DivideByZero type:

	my class X::Numeric::DivideByZero is Exception {
	    has $.using;
	    has $.details;
	    has $.numerator;
	    method message() {
	        **"Attempt to divide{$.numerator ?? " $.numerator" !! ''} by zero"
	          ~ ( $.using ?? " using $.using" !! '' )
	          ~ ( " $_" with $.details );**
	    }
	}

As you see, the final message may vary.

The most obvious case when the exception can happen is division. For example, integer division (src/core/Int.pm):

	multi sub infix:&lt;div&gt;(Int:D \a, Int:D \b) {
	    b
	      ?? nqp::div_I(nqp::decont(a), nqp::decont(b), Int)
	      !! Failure.new(**X::Numeric::DivideByZero.new**(
	            :using&lt;div&gt;, :numerator(a))
	         )
	}

You see, the :using attribute is set to div, which indicates that the error happened inside the div routine.

Just out of curiosity, what if you skip the check if b is zero and pass the operands to NQP?

	multi sub infix:&lt;div&gt;(Int:D \a, Int:D \b) {
	    **nqp::div_I(nqp::decont(a), nqp::decont(b), Int)
	**
	#    b
	#      ?? nqp::div_I(nqp::decont(a), nqp::decont(b), Int)
	#      !! Failure.new(X::Numeric::DivideByZero.new(
	#            :using&lt;div&gt;, :numerator(a))
	#         )
	}

You’ll get a lower-level exception:

	$ ./perl6 -e'my $x = 1; my $y = $x / 0; say $y'
	Floating point exception: 8

OK, going back to original sources. Another example is the modulo operator, where the error message is a bit different:

	$ ./perl6 -e'my $x = 1; my $y = $x % 0; say $y'
	Attempt to divide 1 by zero **using %**
	  in block &lt;unit&gt; at -e line 1

This time, the division was using %, which is easily seen in the code:

	multi sub infix:&lt;%&gt;(Int:D \a, Int:D \b --&gt; Int:D) {
	    . . .
	    Failure.new(
	        X::Numeric::DivideByZero.new(**:using&lt;%&gt;**, :numerator(a))
	    )
	    . . .

There are a few other places in the code that generate the X::Numeric::DivideByZero exception; those (for example, the divisibility operator %%) are similar to what we already covered.

## Addendum

What should worry you is why did the error message mention div if we were dividing numbers using /. Maybe it was a different place, and the error message was generated not inside infix::&lt;div&gt;? No, that’s correct (it is easy to prove by changing the error message in the source code).

Use of the / character does not necessarily mean a division. A Rat number can be created; for example:

	$ ./perl6 -e'my $x = 1/0; say $x.WHAT'
	(Rat)

The real call tree for our example is the following:

* Rat::infix:&lt;/&gt;(Int, Int)
  * DIVIDE\_NUMBERS(Int, Int)
    * Int::infix&lt;div&gt;(Int, Int)

So, it starts with an attempt to create a Rat value and goes deeper to the div infix. The DIVIDE\_NUMBERS function is a part of the Rat constructor, which we already mentioned yesterday, so it is another stimulus to look at it in detail.

### Share this:

* [Twitter][1]
* [Facebook][2]
* [Google][3]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2018/01/26/37-dividing-by-zero-in-perl-6/?share=twitter "Click to share on Twitter"
  [2]: https://perl6.online/2018/01/26/37-dividing-by-zero-in-perl-6/?share=facebook "Click to share on Facebook"
  [3]: https://perl6.online/2018/01/26/37-dividing-by-zero-in-perl-6/?share=google-plus-1 "Click to share on Google+"