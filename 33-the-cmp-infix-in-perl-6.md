In Perl 6, there is an infix operator called cmp. Despite its simple name and some connotations with its counter partner in Perl 5, its semantic is not trivial.

From the documentation, we read:

_Generic, “smart” three-way comparator._

_Compares strings with string semantics, numbers with number semantics, Pair objects first by key and then by value etc._

As we have access to the source codes, let us directly look inside and allow us to begin with strings, so go to src/core/Str.pm.

	multi sub infix:&lt;cmp&gt;(Str:D \a, Str:D \b --&gt; Order:D) {
	    ORDER(nqp::cmp_s(nqp::unbox_s(a), nqp::unbox_s(b)))
	}
	multi sub infix:&lt;cmp&gt;(str $a, str $b --&gt; Order:D) {
	    ORDER(nqp::cmp_s($a, $b))
	}

There is a method operating two objects of the Str type and another method for the lower-cased type str, which is a native type, which we skip for now; just look at its definition in src/core/natives.pm:

	my native str is repr('P6str') is Str { }

For the Perl 6 type, the objects are first converted to native strings via nqp::unbox\_s.

Then both methods delegate the comparison to the nqp::cmp\_s function. It returns 1, 0, or -1, which is fine in NQP but not enough for Perl 6, where the result should be of the Order type—you can see the expected return type Order:D in the signature of the methods.

Go to src/core/Order.pm to see that the Order type is an enumeration with the above three values:

	my enum Order (:Less(-1), :Same(0), :More(1));

In the same file, there is a function that acts as a constructor coercing an integer to Order:

	sub ORDER(int $i) {
	    nqp::iseq_i($i,0) ?? **Same** !! nqp::islt_i($i,0) ?? **Less** !! **More**
	}

So, the result of cmp is either Same, or Less, or More.

We covered the hardest part already. The rest of the smartness of the cmp operator is due to multiple dispatching.

For example, for the two given integers, the following functions are triggered (also defined in src/core/Order.pm):

	multi sub infix:&lt;cmp&gt;(Int:D \a, Int:D \b) {
	    ORDER(nqp::cmp_I(nqp::decont(a), nqp::decont(b)))
	}
	multi sub infix:&lt;cmp&gt;(int $a, int $b) {
	    ORDER(nqp::cmp_i($a, $b))
	}

Here, there is not much difference from the string implementation. You may notice the different suffixes in the NQP methods.

Then, step by step, variety rises. For example, integers and rationals:

	multi sub infix:&lt;cmp&gt;(Int:D \a, **Rational:D** \b) {
	    a.isNaN || b.isNaN ?? a.Num cmp b.Num !! a &lt;=&gt; b
	}
	multi sub infix:&lt;cmp&gt;(**Rational:D** \a, Int:D \b) {
	    a.isNaN || b.isNaN ?? a.Num cmp b.Num !! a &lt;=&gt; b
	}

Again, the implementation is simple but of course it is different from what was needed for two integers or two strings.

It gets more complicated for Real numbers:

	multi sub infix:&lt;cmp&gt;(Real:D \a, Real:D \b) {
	       (nqp::istype(a, Rational) &amp;&amp; nqp::isfalse(a.denominator))
	    || (nqp::istype(b, Rational) &amp;&amp; nqp::isfalse(b.denominator))
	    ?? a.Bridge cmp b.Bridge
	    !! a === -Inf || b === Inf
	        ?? Less
	        !! a === Inf || b === -Inf
	            ?? More
	            !! a.Bridge cmp b.Bridge
	}

I leave parsing the algorithms to the reader as an exercise but would like to pay attention to the use of the Bridge method, which is a polymorphic method that we already saw as [part of the Int type.][1]

There are separate methods for comparing complex numbers, dates, lists, ranges, and even version numbers (which looks quite complicated, by the way, see it in src/core/Version.pm).

At the bottom (or at the top, as you define what is more and less important—base or children classes), there are a few methods that deal with Mu:

	proto sub infix:&lt;cmp&gt;(Mu $, Mu $) is pure {*}
	multi sub infix:&lt;cmp&gt;(\a, \b) {
	    nqp::eqaddr(a,b)
	      ?? Same
	      !! a.Stringy cmp b.Stringy
	}
	multi sub infix:&lt;cmp&gt;(Real:D \a, \b) {
	    a === -Inf
	      ?? Less
	      !! a === Inf
	        ?? More
	        !! a.Stringy cmp b.Stringy
	}
	multi sub infix:&lt;cmp&gt;(\a, Real:D \b) {
	    b === Inf
	      ?? Less
	      !! b === -Inf
	        ?? More
	        !! a.Stringy cmp b.Stringy
	}

That’s all for today, see you tomorrow!

### Share this:

* [Twitter][2]
* [Facebook][3]
* [Google][4]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2018/01/17/28-exploring-the-int-type-in-perl-6-part-1/
  [2]: https://perl6.online/2018/01/22/33-the-cmp-infix-in-perl-6/?share=twitter "Click to share on Twitter"
  [3]: https://perl6.online/2018/01/22/33-the-cmp-infix-in-perl-6/?share=facebook "Click to share on Facebook"
  [4]: https://perl6.online/2018/01/22/33-the-cmp-infix-in-perl-6/?share=google-plus-1 "Click to share on Google+"