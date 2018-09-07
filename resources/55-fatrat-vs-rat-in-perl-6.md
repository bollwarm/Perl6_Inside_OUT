Yesterday, Solomon Foster [posted an example][1] in the Perl 6 group on Facebook:

	my @x =
	    FatRat.new(1, 1),
	    -&gt; $x { $x - ($x ** 2 - $N) / (2 * $x) } ... *

This code implements Newton’s method of finding an approximate value of a square root of $N. The important thing is that it is using a FatRat value for higher accuracy.

Let us run it for the value of 9:

	my $N = 9;

	my @x =
	    Rat.new(1, 1),
	    -&gt; $x { $x - ($x ** 2 - $N) / (2 * $x) } ... *;

	.say for @x[0..7];

Very soon, it converges to the correct value:

	1
	5
	3.4
	3.023529
	3.000092
	3.00000000140
	3.00000000000000000033
	3.0000000000000000000000000000000000000176

If you narrow the data type down to Rat, then, after a certain point, it will not be wide enough to keep all the decimal digits:

	1
	5
	3.4
	3.023529
	3.000092
	3.00000000140
	3.00000000000000000033
	3

Of course, the absolutely correct result is achieved faster but we understand that that is due to the lack of Rat’s capacity in comparison to FatRat, and it won’t work for non-integer results, probably. Let us try it with $N = 5 and with ten iterations:

With Rat:

	1
	3
	2.333333
	2.238095
	2.236069
	2.23606798
	2.236067977499790
	2.23606797749979
	2.23606797749979
	2.23606797749979
	2.23606797749979

With FatRat:

	1
	3
	2.333333
	2.238095
	2.236069
	2.23606798
	2.236067977499790
	2.2360679774997896964091736687
	2.2360679774997896964091736687312762354406183596115257243
	2.236067977499789696409173668731276235440618359611525724270897245410520925637804899414414408378782274969508176
	2.23606797749978969640917366873127623544061835961152572427089724541052092563780489941441440837878227496950817615077378350425326772444707386358636012153345270886677817319187916581127664532263985658053576135041753378500

(I hope your browser just scrolls the code block instead of wrapping the text to the new lines.)

OK, we see that FatRat gives more digits. Now look at the definition of the classes in src/core/Rat.pm:

	# XXX: should be Rational[Int, uint]
	my class Rat is Cool does Rational[Int, Int] { . . . }

	my class FatRat is Cool does Rational[Int, Int] { . . . }

Both classes implement a [parameterised][2] Rational role. In both cases, the parameters are the same — both the numerator and the denominator are supposed to be Int values. So, why do the results of the Newton’s approximation were so different if we use the same data type to represent the fraction? Let us try figuring that out.

Just to see how the parts of the fraction are constructed in the role, here’re their declarations:

	my role Rational[::NuT = Int, ::DeT = ::("NuT")] does Real {
	    has NuT $.numerator = 0;
	    has DeT $.denominator = 1;

So, in both cases, we have the following attributes:

	has Int $.numerator = 0;
	has Int $.denominator = 1;

Let’s check if the types are not changed somewhere inside the black box:

	my $N = 5;
	my @x = FatRat.new(1, 1), -&gt; $x { $x - ($x ** 2 - $N) / (2 * $x) } ... *;

	my $v = @x[7];
	say $v.numerator.WHAT;
	say $v.denominator.WHAT;

With the FatRat type, the program confirms Ints:

	$ perl6 sqr-fatrat.pl
	(Int)
	(Int)

Now try the Rat type:

	$ perl6 sqr-fatrat.pl
	No such method 'numerator' for invocant of type 'Num'.
	Did you mean 'iterator'?
	  in block &lt;unit&gt; at sqr-fatrat.pl line 10

What?! What do you mean? Does it mean that the values are not Rats anymore? Let’s check it and print the types of the data elements. We know that we started the sequence with a Rat value:

	**Rat.new(1, 1)**, -&gt; $x { $x - ($x ** 2 - $N) / (2 * $x) } ... *;

The pointy block is a generator of the next elements, so nothing bad here. Nevertheless, let’s call .WHAT on each element:

	.WHAT.say for @x[0..10];

Here is the output:

	(Rat)
	(Rat)
	(Rat)
	(Rat)
	(Rat)
	(Rat)
	(Rat)
	(Num)
	(Num)
	(Num)
	(Num)

The first seven items were Rats, while the rest became Nums! That explains why we saw different results, of course. But why was the data type changed?

Try it slowly. First, see the type of the value immediately after it is generated:

	my $N = 5;
	my @x =
	    Rat.new(1, 1),
	    -&gt; $x {
	        my $n = $x - ($x ** 2 - $N) / (2 * $x);
	        **say $n.WHAT;**
	        $n;
	    } ... *;

It prints the same list of types as before.

The second step is to try to force the data type everywhere we can:

	my **Rat** $N = **Rat**.new(5);
	my **Rat** @x =
	    **Rat**.new(1, 1),
	    -&gt; **Rat** $x {
	        my **Rat** $n = $x - ($x ** 2 - $N) / (2 * $x);
	        say $n.WHAT;
	        $n;
	 } ... *;

Run the program and see what it says:

	(Rat)
	(Rat)
	(Rat)
	(Rat)
	(Rat)
	(Rat)
	Type check failed in assignment to $n;
	**expected Rat but got Num** (2.23606797749979e0)
	   in block &lt;unit&gt; at sqr-fatrat.pl line 5

It became even worse 🙂 If you force FatRat, then everything stays fine. OK, now it is really time to understand when the border is crossed and the data type is changed.

Let us visualise it a bit more so that we see the numerator and the denominator of the generated number, as well as the type of the intermediate value that is used to calculate it:

	-&gt; Rat $x {
	    my $d = ($x ** 2 - $N);
	    say $d;
	    say $d.WHAT;

	    my Rat $n = $x - $d / (2 * $x);
	    say $n.WHAT;
	    say $n.nude;
	    $n;
	} ... *;

This gives us the way to confirm that it breaks:

	-4
	(Rat)
	(Rat)
	(3 1)
	4
	(Rat)
	(Rat)
	(7 3)
	0.444444
	(Rat)
	(Rat)
	(47 21)
	0.009070
	(Rat)
	(Rat)
	(2207 987)
	0.0000041
	(Rat)
	(Rat)
	(4870847 2178309)
	**0.00000000000084**
	(Rat)
	(Rat)
	**(23725150497407 10610209857723)**
	**0**
	**(Num)**
	Type check failed in assignment to $n; expected Rat but got Num (2.23606797749979e0)
	 in block &lt;unit&gt; at /Users/ash/Books/perl6.ru/sqr-fatrat.pl line 9

As you see, just before the exception, the parts of the fraction became quite big, and the type of the subexpression turned from Rat to Num. At that moment, the value of $d gets close to zero (this value is the error between the correct answer and the approximated value on the previous iteration).

Seems like we are close to the final destination. Once again, look at the changes of the $d variable:

	say $d.perl ~ ' = ' ~ $d;

During the first few iterations, it goes to exact zero:

	-4.0 = -4
	4.0 = 4
	&lt;4/9&gt; = 0.444444
	&lt;4/441&gt; = 0.009070
	&lt;4/974169&gt; = 0.0000041
	&lt;4/4745030099481&gt; = 0.00000000000084
	0e0 = 0

This is not happening when FatRat values are used:

	FatRat.new(-4, 1) = -4
	FatRat.new(4, 1) = 4
	FatRat.new(4, 9) = 0.444444
	FatRat.new(4, 441) = 0.009070
	FatRat.new(4, 974169) = 0.0000041
	FatRat.new(4, 4745030099481) = 0.00000000000084
	FatRat.new(4, 112576553224922323902744729) = 0.0000000000000000000000000355
	. . .

We now get to the \*\* operation for Rats (remember that $d = ($x \*\* 2 - $N)?):

	multi sub infix:&lt;**&gt;(Rational:D \a, Int:D \b) {
	    **b &gt;= 0
	        ?? DIVIDE_NUMBERS
	           (a.numerator ** b // fail (a.numerator.abs &gt; a.denominator ?? X::Numeric::Overflow !! X::Numeric::Underflow).new),
	           a.denominator ** b, # we presume it likely already blew up on the numerator
	           a,
	           b**
	       !! DIVIDE_NUMBERS
	           (a.denominator ** -b // fail (a.numerator.abs &lt; a.denominator ?? X::Numeric::Overflow !! X::Numeric::Underflow).new),
	           a.numerator ** -b,
	           a,
	           b
	}

In our case, b is always non-negative, and we go to [our old friend][3], DIVIDE\_NUMBERS.

	sub DIVIDE_NUMBERS(Int:D \nu, Int:D \de, \t1, \t2) {
	    . . .
	    nqp::if(
	        **$denominator &lt; UINT64_UPPER**,
	        nqp::p6bindattrinvres(
	        nqp::p6bindattrinvres(nqp::create(Rat),Rat,'$!numerator',$numerator),
	        Rat,'$!denominator',$denominator),
	        **nqp::p6box_n**(nqp::div_In($numerator, $denominator)))))
	}

Yes! Finally, you can see that if the denominator is not big enough, a Rat number is returned. Otherwise, the nqp::p6box\_n function creates a Num value. For a FatRat, there is a different branch that does not do the check:

	nqp::if(
	nqp::istype(t1, FatRat) || nqp::istype(t2, FatRat),
	nqp::p6bindattrinvres(
	    nqp::p6bindattrinvres(nqp::create(FatRat),FatRat,'$!numerator',$numerator),
	    FatRat,'$!denominator',$denominator),

The function is a Perl 6 extension to NQP, there’s a documentation line in docs/ops.markdown:

	## p6box_n
	* p6box_n(num $value)
	Box a native num into a Perl 6 Num.

Congratulations, we’ve tracked that down!

### Share this:

* [Twitter][4]
* [Facebook][5]
* [Google][6]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://www.facebook.com/groups/perl6/permalink/2044834289116253/
  [2]: https://perl6.online/2018/01/06/parameterised-roles-in-perl-6/
  [3]: https://perl6.online/2018/01/27/38-to-divide-or-not-to-divide/
  [4]: https://perl6.online/2018/02/13/55-fatrat-vs-rat-in-perl-6/?share=twitter "Click to share on Twitter"
  [5]: https://perl6.online/2018/02/13/55-fatrat-vs-rat-in-perl-6/?share=facebook "Click to share on Facebook"
  [6]: https://perl6.online/2018/02/13/55-fatrat-vs-rat-in-perl-6/?share=google-plus-1 "Click to share on Google+"