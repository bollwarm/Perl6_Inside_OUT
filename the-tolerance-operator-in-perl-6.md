In Perl 6, there is a so-called _approximately-equal operator_ =~=. It compares two numbers approximately.

If both values are non-zero, the operator calculates their relative difference; the tolerance is defined by the $\*TOLERANCE variable, which equals to 1E-15 by default. So, for two numbers $a and $b, the result (in pseudo-code) is:

	|$a - $b| / max(|$a|, |$b|) &lt; $*TOLERANCE

(As an exercise, try implementing the absolute value operator so that it looks like the mathematical notation above.)

Let us look at the implementation of the operator. It is located in src/core/Numeric.pm.

First of all, you will notice that the ASCII variant is directly converted to the call of the Unicode version:

	sub infix:&lt;=~=&gt;(|c) { infix:&lt;≅&gt;(|c) }

The actual code is placed just above that line.

	proto sub infix:&lt;≅&gt;(Mu $?, Mu $?, *%) {*} # note, can't be pure due to dynvar
	multi sub infix:&lt;≅&gt;($?) { Bool::True }
	multi sub infix:&lt;≅&gt;(\a, \b, :$tolerance = $*TOLERANCE) {
	    # If operands are non-0, scale the tolerance to the larger of the abs values.
	    # We test b first since $value ≅ 0 is the usual idiom and falsifies faster.
	    if b &amp;&amp; a &amp;&amp; $tolerance {
	        abs(a - b) &lt; (a.abs max b.abs) * $tolerance;
	    }
	    else { # interpret tolerance as absolute
	        abs(a.Num - b.Num) &lt; $tolerance;
	    }
	}

As you see here, the routine checks if both operands are non-zero, and in this case uses the formula. If at least one of the operands is zero, the check is simpler and basically means whether the non-zero value is small enough. (Ignore the presence of the tolerance adverb for simplicity.)

Compare the speed of the two branches by making thousands of comparisons:

	$ time ./perl6 -e'0.1 =~= 0 for ^100_000'
	$ time ./perl6 -e'0.1 =~= 0.2 for ^100_000'

On my computer, the times were approximately 2.5 and 4.3 seconds. So, indeed, the check is faster if one of the values is zero.

But now think about the algorithm. The subroutine tests its arguments and decides which of the two ways to go. Does it ring a bell for you?

This is exactly what multi-subs are meant for!

So, lets us re-write the code to have all variants in separate multi-subs:

	multi sub infix:&lt;≅&gt;(**0, 0**, :$tolerance = $*TOLERANCE) {
	    Bool::True
	}

	multi sub infix:&lt;≅&gt;(**\a, 0**, :$tolerance = $*TOLERANCE) {
	    a.abs &lt; $tolerance
	}

	multi sub infix:&lt;≅&gt;(**0, \b**, :$tolerance = $*TOLERANCE) {
	    b.abs &lt; $tolerance
	}

	multi sub infix:&lt;≅&gt;(**\a, \b**, :$tolerance = $*TOLERANCE) {
	    abs(a - b) &lt; (a.abs max b.abs) * $tolerance;
	}

Recompile and run the same time measurements. This time, it was 2.8 and 3.8 seconds. So, for non-zero arguments its became 10-15% faster, and a bit slower in the other case.

Is there more room for improvement? What I don’t really like is an additional named argument that is present everywhere. As we still can change the $\*TOLERANCE variable locally, why always passing it? Create more multi-subs:

	multi sub infix:&lt;≅&gt;(0, 0) {
	    Bool::True
	}

	multi sub infix:&lt;≅&gt;(\a, 0) {
	    a.abs &lt; $*TOLERANCE
	}

	multi sub infix:&lt;≅&gt;(0, \b) {
	    b.abs &lt; $*TOLERANCE
	}

	multi sub infix:&lt;≅&gt;(\a, \b) {
	    abs(a - b) &lt; (a.abs max b.abs) * $*TOLERANCE;
	}

	multi sub infix:&lt;≅&gt;(0, 0, :$tolerance) {
	    Bool::True
	}

	multi sub infix:&lt;≅&gt;(\a, 0, :$tolerance) {
	    a.abs &lt; $tolerance
	}

	multi sub infix:&lt;≅&gt;(0, \b, :$tolerance) {
	    b.abs &lt; $tolerance
	}

	# multi sub infix:&lt;≅&gt;(\a, \b, :$tolerance) {
	#     abs(a - b) &lt; (a.abs max b.abs) * $tolerance;
	# }

At this point, there are two sets of multi-subs: pure functions for two arguments, and functions that take the custom tolerance value.

Compile. Run. Measure.

Perl 6 shows its fantastic ability of multiple dispatching. This time, the average time for both cases (0.1 =~= 0 and 0.1 =~= 0.2) was approximately the same: 2.5 seconds. Which speeds up the original operator for about 70%!

(The last sub is commented out as it leads to an infinite error message that one of the variables is undefined ¯\\\_(ツ)\_/¯. I tried to fix it by adding Mu:D before the adverb but it decreased the speed back to 3.8 seconds, which is still better then the original result, though.)

### Share this:

* [Twitter][1]
* [Facebook][2]
* [Google][3]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2018/01/10/the-tolerance-operator-in-perl-6/?share=twitter "Click to share on Twitter"
  [2]: https://perl6.online/2018/01/10/the-tolerance-operator-in-perl-6/?share=facebook "Click to share on Facebook"
  [3]: https://perl6.online/2018/01/10/the-tolerance-operator-in-perl-6/?share=google-plus-1 "Click to share on Google+"