We have seen the mysterious DIVIDE\_NUMBERS function a couple of times already. Let us keep our focus on it today.

The function is a part of the Rat data type. It lives in src/core/Rat.pm together with its sister, DON'T\_DIVIDE\_NUMBERS. (An apostrophe is a valid character for identifiers in Perl 6; it is not a namespace separator as in Perl 4 or Perl 5.)

First, let us read the functions, starting with the simpler one.

	sub **DON'T_DIVIDE_NUMBERS**(Int:D \nu, Int:D \de, $t1, $t2) {
	    nqp::istype($t1, FatRat) || nqp::istype($t2, FatRat)
	        ?? nqp::p6bindattrinvres(
	              nqp::p6bindattrinvres(
	                  nqp::create(FatRat),
	                  FatRat, '$!numerator', nqp::decont(nu)),
	              FatRat, '$!denominator', nqp::decont(de))
	        !! nqp::p6bindattrinvres(
	              nqp::p6bindattrinvres(
	                  nqp::create(Rat),
	                  Rat, '$!numerator', nqp::decont(nu)),
	              Rat, '$!denominator', nqp::decont(de))
	}

The first two arguments, nu and de, are the numerator and the denominator of the future Rat number. The other two arguments carry their types (we’ll see how they are used in a bit).

So, what does the function do? If creates either a FatRat or a Rat number. You get a FatRat value if at least one of the arguments is a FatRat number. In the opposite case, a Rat value is created. In the rest, both branches are identical:

	nqp::p6bindattrinvres(
	    nqp::p6bindattrinvres(
	       nqp::create(Rat),
	       Rat, '$!numerator', nqp::decont(nu)),
	    Rat, '$!denominator', nqp::decont(de))

The nqp::create function creates an object, whose attributes, $!numerator and $!denominator, are later filled up with the corresponding values. Refer to [one of the recent posts][1] to see how nqp::p6bindattrinvres was used to speed up the creation of a Rat value.

Now, to the bigger function.

	sub **DIVIDE_NUMBERS**(Int:D \nu, Int:D \de, \t1, \t2) {
	    nqp::stmts(
	      (my Int $gcd         := de == 0 ?? 1 !! nu gcd de),
	      (my Int $numerator   := nu div $gcd),
	      (my Int $denominator := de div $gcd),
	      nqp::if(
	        $denominator &lt; 0,
	        nqp::stmts(
	          ($numerator   := -$numerator),
	          ($denominator := -$denominator))),
	      nqp::if(
	        nqp::istype(t1, FatRat) || nqp::istype(t2, FatRat),
	        nqp::p6bindattrinvres(
	          nqp::p6bindattrinvres(nqp::create(FatRat),FatRat,'$!numerator',$numerator),
	          FatRat,'$!denominator',$denominator),
	        nqp::if(
	          $denominator &lt; UINT64_UPPER,
	          nqp::p6bindattrinvres(
	            nqp::p6bindattrinvres(nqp::create(Rat),Rat,'$!numerator',$numerator),
	            Rat,'$!denominator',$denominator),
	          nqp::p6box_n(nqp::div_In($numerator, $denominator)))))
	}

The second part of it is very similar to what we already discussed, but there are some data check and conversions in the beginning.

	(my Int $gcd := de == 0 ?? 1 !! nu gcd de),
	(my Int $numerator := nu div $gcd),
	(my Int $denominator := de div $gcd),

You can see here that both the numerator and the denominator are divided by their greatest common divisor. In other words, a fraction like 10/20 is converted to 1/2, and that explains the name of the function.

It also creates some kind of canonical form, making the denominator non-negative:

	nqp::if(
	  $denominator &lt; 0,
	  nqp::stmts(
	     ($numerator := -$numerator),
	     ($denominator := -$denominator))),

Great, we have two functions that either immediately create a Rat (or FatRat) value or reduce the fraction before creating a Rat (or FatRat) value.

The Rat class does the Rational role, and you can find another method that reduces the fraction there:

	method **REDUCE-ME**(--&gt; Nil) {
	    if $!denominator &gt; 1 {
	        my $gcd = $!denominator gcd $!numerator;
	        if $gcd &gt; 1 {
	            nqp::bindattr(self, self.WHAT,
	                          '$!numerator', $!numerator div $gcd);
	            nqp::bindattr(self, self.WHAT,
	                          '$!denominator', $!denominator div $gcd);
	        }
	    }
	}

Our next step is to see where the functions are used. All of them are in the src/core/Rat.pm file.

The simplest is the function for the / infix with two integer operands:

	multi sub infix:&lt;/&gt;(Int:D \a, Int:D \b) {
	   DIVIDE_NUMBERS a, b, a, b
	}

Notice that the arguments are just repeated twice, while they are used differently as soon as they reach the DIVIDE\_NUMBERS function.

With other combinations of the types of the arguments, data flow is a bit more sophisticated:

	multi sub infix:&lt;/&gt;(Int:D \a, Rational:D \b) {
	     b.REDUCE-ME; # RT #126391: [BUG] Bad "divide by 0" error message
	     DIVIDE_NUMBERS
	         b.denominator * a,
	         b.numerator,
	         a,
	         b;
	}

Please explore the src/core/Rat.pm file yourself if you want to see more examples. They all follow the idea that we already illustrated. Maybe with one exception: the code that may generate exceptions from the \*\* operator.

	multi sub infix:&lt;**&gt;(Rational:D \a, Int:D \b) {
	    b &gt;= 0
	      ?? DIVIDE_NUMBERS
	         (a.numerator ** b //
	             **fail** (a.numerator.abs &gt; a.denominator
	                   ?? X::Numeric::Overflow
	                   !! X::Numeric::Underflow).new),
	         a.denominator ** b, # we presume it likely already blew up on the numerator
	         a,
	         b
	      !! DIVIDE_NUMBERS
	         (a.denominator ** -b //
	              **fail** (a.numerator.abs &lt; a.denominator
	                    ?? X::Numeric::Overflow
	                    !! X::Numeric::Underflow).new),
	         a.numerator ** -b,
	         a,
	         b
	}

And that’s it for today. Stay tuned!

### Share this:

* [Twitter][2]
* [Facebook][3]
* [Google][4]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2018/01/25/36-rakudo-2018-01/
  [2]: https://perl6.online/2018/01/27/38-to-divide-or-not-to-divide/?share=twitter "Click to share on Twitter"
  [3]: https://perl6.online/2018/01/27/38-to-divide-or-not-to-divide/?share=facebook "Click to share on Facebook"
  [4]: https://perl6.online/2018/01/27/38-to-divide-or-not-to-divide/?share=google-plus-1 "Click to share on Google+"