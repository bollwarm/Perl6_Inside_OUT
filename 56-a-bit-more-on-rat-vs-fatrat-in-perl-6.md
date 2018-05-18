[Yesterday][1], we were digging into Rakudo Perl 6 to understand when a Rat value becomes a Num value. It turned out that if the value becomes too small, which means its denominator gets bigger and bigger, Rakudo starts using a Num value instead of Rat.

We found the place where it happened. Today, let us make an exercise and see if it is possible that Perl 6 behaves differently, namely, it [expands the data type][2] instead of switching it to a floating point and losing accuracy.

The change is simple. All you need is to update the ifs inside the DIVIDE\_N routine:

	--- a/src/core/Rat.pm
	+++ b/src/core/Rat.pm
	@@ -48,16 +48,14 @@ sub DIVIDE_NUMBERS(Int:D \nu, Int:D \de, \t1, \t2) {
	           ($numerator   := -$numerator),
	           ($denominator := -$denominator))),
	       nqp::if(
	-        nqp::istype(t1, FatRat) || nqp::istype(t2, FatRat),
	**+        nqp::istype(t1, FatRat) || nqp::istype(t2, FatRat) || $denominator &gt;= UINT64_UPPER,
	**         nqp::p6bindattrinvres(
	           nqp::p6bindattrinvres(nqp::create(FatRat),FatRat,'$!numerator',$numerator),
	           FatRat,'$!denominator',$denominator),
	-        nqp::if(
	-          $denominator &lt; UINT64_UPPER,
	           nqp::p6bindattrinvres(
	             nqp::p6bindattrinvres(nqp::create(Rat),Rat,'$!numerator',$numerator),
	-            Rat,'$!denominator',$denominator),
	-          nqp::p6box_n(nqp::div_In($numerator, $denominator)))))
	**+            Rat,'$!denominator',$denominator)
	+        ))
	** }

Now, there are two outcomes: either the routine generates a Rat value or a FatRat. The latter happens when the sub arguments were already FatRats or when the current Rat gets too close to zero.

Compile and test our modified perl6 executable with Newton’s algorithm from yesterday’s post:

	my $N = 25;
	my @x =
	    Rat.new(1, 1),
	    -&gt; $x {
	        $x - ($x ** 2 - $N) / (2 * $x)
	    } ... *;

	.WHAT.say for @x[0..10];
	.say for @x[1..10];

As expected, the first elements of the sequence are Rats, while the tail is made of FatRats:

	(Rat)
	(Rat)
	(Rat)
	(Rat)
	(Rat)
	(Rat)
	(FatRat)
	(FatRat)
	(FatRat)
	(FatRat)
	(FatRat)

Also, you can easily see it if you print the values:

	13
	7.461538
	5.406027
	5.01524760
	5.0000231782539490
	5.0000000000537228965718724535111
	5.00000000000000000000028861496160410945540567902983713732806515
	5.000000000000000000000000000000000000000000008329859606174157518822601061625174583303232554885171687075417887439374231515823
	5.00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000693865610585718905982734693675309615913812411108046914931948226816763601320201386971350204028084660605790650314446568089428143916887535905115787146371799888
	5.000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004814494855534925123195523522159753005055993378092336823010386671077751892080269126953923957066141452855241262256569975702944214065988292758274535222239622977104185030432093986146346015004230914044314506580063758070896734658461687838556535528402765772220596451598003813021305355635793333485373058987453787504731

## \* \* \*

I don’t know what is better — to have two different types for a rational number (not counting the Rational role) or one type that can hold both ‘narrow’ and ‘wide’ values, or a mechanism that switches to a wider data type when there is not enough capacity. I feel the best is the last option (in the case that FatRat and Rat are using different types for storing numerators and denominators, of course).

As far as I understand, that was exactly the [original thought][3]:

_For values that do not already do the `Numeric` role, the narrowest appropriate type of `Int`, `Rat`, `Num`, or `Complex` will be returned; however, string containing two integers separated by a `/`will be returned as a `Rat` (or a `FatRat` if the denominator overflows an `int64`)._

Also it feels more natural to silently add more space for more digits instead of breaking the idea of having the Rat type. Anyway, there are different opinions on this, but that should not stop Perl 6 from being widespread.

### Share this:

* [Twitter][4]
* [Facebook][5]
* [Google][6]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2018/02/13/55-fatrat-vs-rat-in-perl-6/
  [2]: https://twitter.com/LearningPerl6/status/963929480430571520
  [3]: http://design.perl6.org/S03.html#Symbolic_unary_precedence
  [4]: https://perl6.online/2018/02/14/56-a-bit-more-on-rat-vs-fatrat-in-perl-6/?share=twitter "Click to share on Twitter"
  [5]: https://perl6.online/2018/02/14/56-a-bit-more-on-rat-vs-fatrat-in-perl-6/?share=facebook "Click to share on Facebook"
  [6]: https://perl6.online/2018/02/14/56-a-bit-more-on-rat-vs-fatrat-in-perl-6/?share=google-plus-1 "Click to share on Google+"