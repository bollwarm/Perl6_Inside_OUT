Today, we continue our initial exploration of the Real role, that was started [a couple of days ago][1].

Together with its methods, the role contains a number of subroutines (placed outside the role) that define the infix operators with the objects of the Real type. The list is not that long, so let me copy it here:

	multi sub infix:&lt;+&gt;(Real \a, Real \b) { a.Bridge + b.Bridge }
	multi sub infix:&lt;-&gt;(Real \a, Real \b) { a.Bridge - b.Bridge }
	multi sub infix:&lt;*&gt;(Real \a, Real \b) { a.Bridge * b.Bridge }
	multi sub infix:&lt;/&gt;(Real \a, Real \b) { a.Bridge / b.Bridge }
	multi sub infix:&lt;%&gt;(Real \a, Real \b) { a.Bridge % b.Bridge }
	multi sub infix:&lt;**&gt;(Real \a, Real \b) { a.Bridge ** b.Bridge }
	multi sub infix:«&lt;=&gt;»(Real \a, Real \b) { a.Bridge &lt;=&gt; b.Bridge }
	multi sub infix:&lt;==&gt;(Real \a, Real \b) { a.Bridge == b.Bridge }
	multi sub infix:«&lt;»(Real \a, Real \b) { a.Bridge &lt; b.Bridge }
	multi sub infix:«&lt;=»(Real \a, Real \b) { a.Bridge &lt;= b.Bridge }
	multi sub infix:«≤» (Real \a, Real \b) { a.Bridge ≤ b.Bridge }
	multi sub infix:«&gt;»(Real \a, Real \b) { a.Bridge &gt; b.Bridge }
	multi sub infix:«&gt;=»(Real \a, Real \b) { a.Bridge &gt;= b.Bridge }
	multi sub infix:«≥» (Real \a, Real \b) { a.Bridge ≥ b.Bridge }

	proto sub infix:&lt;mod&gt;($, $) is pure {*}
	multi sub infix:&lt;mod&gt;(Real $a, Real $b) {
	    $a - ($a div $b) * $b;
	}

As you see, most of the operators are using [the Bridge method][2], which allows using the same code in derived classes that may redefine the bridge.

There’s also one prefix operation for negation:

	multi sub prefix:&lt;-&gt;(Real:D \a) { -a.Bridge }

The cis function works as a type converter returning a complex number:

	roto sub cis($) {*}
	multi sub cis(Real $a) { $a.cis }

Try it out:

	&gt; cis(pi)
	-1+1.22464679914735e-16i

	&gt; cis(pi).WHAT
	(Complex)

A bit outstanding, there is a function for atan2:

	proto sub atan2($, $?) {*}
	multi sub atan2(Real \a, Real \b = 1e0) { a.Bridge.atan2(b.Bridge) }
	# should really be (Cool, Cool), and then (Cool, Real) and (Real, Cool)
	# candidates, but since Int both conforms to Cool and Real, we'd get lots
	# of ambiguous dispatches. So just go with (Any, Any) for now.
	multi sub atan2( \a, \b = 1e0) { a.Numeric.atan2(b.Numeric) }

It is a bit strange as it does not follow the manner in which other trigonometric functions are implemented. The atan2 routine is also defined as a method:

	proto method atan2(|) {*}
	multi method atan2(Real $x = 1e0) { self.Bridge.atan2($x.Bridge) }
	multi method atan2(Cool $x = 1e0) { self.Bridge.atan2($x.Numeric.Bridge) }

All other trigonometric functions only exist as Real methods. The rest is defined inside the src/core/Numeric.pm file as self-standing subroutines, for example:

	proto sub cos($) is pure {*}
	multi sub cos(Numeric \x) { x.cos }
	multi sub cos(Cool \x) { x.Numeric.cos }

	. . .

	proto sub atan($) is pure {*}
	multi sub atan(Numeric \x) { x.atan }
	multi sub atan(Cool \x) { x.Numeric.atan }

There are a few more routines but let us skip them, as they are quite straightforward and clear.

In the next part, we will explore the two methods of the Real role: polymod and base. Stay tuned!

### Share this:

* [Twitter][3]
* [Facebook][4]
* [Google][5]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2018/02/15/57-examining-the-real-role-of-perl-6-part-1/
  [2]: https://perl6.online/2018/02/11/53-going-over-the-bridge-part-1/
  [3]: https://perl6.online/2018/02/18/59-examining-the-real-role-of-perl-6-part-2/?share=twitter "Click to share on Twitter"
  [4]: https://perl6.online/2018/02/18/59-examining-the-real-role-of-perl-6-part-2/?share=facebook "Click to share on Facebook"
  [5]: https://perl6.online/2018/02/18/59-examining-the-real-role-of-perl-6-part-2/?share=google-plus-1 "Click to share on Google+"