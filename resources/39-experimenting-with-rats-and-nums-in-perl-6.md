Today, it will be a post with some small things about the two data types, Rat and Num.

First of all, Zoffix Znet added some insights on Twitter regarding my previous posts. Let me just quote them here.

Some useful information about [DIVIDE\_NUMBERS and DON'T\_DIVIDE\_NUMBERS][1]:

_[FWIW][2], these will be gone some time these year, together with .REDUCE-ME method. Rats are meant to be immutable, so once we get native uint64s straightened out, to counteract perf loss from removal of DON’T\_DIVIDE optimization, all of these ops will just be making new Rationals._

And about [dividing by zero][3]:

_[You can][4] divide by zero \*and\* announce it to others, as long as you use the Num view of Rationals, which uses IEEE 754-2008 semantics with regards to division by zero<br />
 &lt;Zoffix&gt; m: .Num.say for 1/0, -1/0, 0/0<br />
 &lt;camelia&gt; rakudo-moar a9a9e1c97: OUTPUT: «Inf␤-Inf␤NaN␤»_

Let us play with dividing by 0 a bit more.

So, indeed, you can get Inf if you cast a Rat value to Num:

	$ perl6 -e'say (1/0).Num'
	Inf

By the way, don’t forget that some spaces are meaningful in Perl 6. The following two lines of code are different:

	say (1/0).Num;
	say(1/0).Num;

The first line prints Inf, while the second throws an exception. This is because the first line is equivalent to:

	say((1/0).Num);

While the second line tries to convert the result of calling say to Num.

Let us trace the data types in the following program:

	my $x = 1/0;
	say $x.WHAT; **_# (Rat)_**

	# say $x; # Error

	my $y = $x.Num;
	say $y.WHAT; **_# (Num)_**

	say $y;     _ # Inf_

Is it possible that Rats also return Inf after division by zero?

First of all, here is the method of the Rational role that is used to convert a Rat number to a Num value:

	method Num() {
	    nqp::p6box_n(nqp::div_In(
	       nqp::decont($!numerator),
	       nqp::decont($!denominator)))
	}

The rest of the work is thus done by some NQP code, which in the end gives us Inf.

Let us start with a simple thing first and print Inf when the value is stringified. Replace the Str method of the Rational role with the following:

	multi method Str(::?CLASS:D:) {
	    unless $!denominator {
	        return 'NaN' unless $!numerator;
	        return 'Inf' if $!numerator &gt;= 0;
	        return '-Inf';
	    }
	}

This should only solve the problem in the cases when a ‘broken’ number is used as a string, for example:

	my $x = 1/0;
	say $x; _# Inf_

	my $y = -1/0;
	say $y; _# -Inf_

	my $z = 0/0;
	say $z; _# NaN_

Surprisingly, it gave us even more, and we can use such numbers in calculations:

	$ ./perl6 -e'my $x = 1/0; my $y = 1 + $x; say $y'
	Inf

Now, look at the original Str method:

	multi method Str(::?CLASS:D:) {
	**    my $whole = self.abs.floor;**
	**    my $fract = self.abs - $whole;**

	    # fight floating point noise issues RT#126016
	    if $fract.Num == 1e0 { ++$whole; $fract = 0 }

	    my $result = nqp::if(
	        nqp::islt_I($!numerator, 0), '-', ''
	    ) ~ $whole;

	    if $fract {
	        my $precision = $!denominator &lt; 100_000
	        ?? 6 !! $!denominator.Str.chars + 1;

	        my $fract-result = '';
	        while $fract and $fract-result.chars &lt; $precision {
	            $fract *= 10;
	            given $fract.floor {
	                $fract-result ~= $_;
	                $fract -= $_;
	            }
	        }
	        ++$fract-result if 2*$fract &gt;= 1; # round off fractional result

	        $result ~= '.' ~ $fract-result;
	    }
	    $result
	}

If you debug the code, you will soon discover that the exception happens in the first lines, when the abs method is called on a number.

This method is defined in the Real role:

	method abs() { self &lt; 0 ?? -self !! self }

Let us redefine it for Rationals (ignore negative values for now):

	method abs() {
	    if $!denominator == 0 {
	        Inf
	    }
	    else {
	        $!numerator / $!denominator
	    }
	}

Now, the check happens in this method. Let’s try it:

	$ ./perl6 -e'my $x = 1/2; say $x;'
	0.5

	$ ./perl6 -e'my $x = 1/0; say $x;'
	**Inf.NaNNaN**

Almost what is needed. You may fix the output as an exercise or just run git checkout src 🙂

### Share this:

* [Twitter][5]
* [Facebook][6]
* [Google][7]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2018/01/27/38-to-divide-or-not-to-divide/
  [2]: https://twitter.com/zoffix/status/957413166631317505
  [3]: https://perl6.online/2018/01/26/37-dividing-by-zero-in-perl-6/
  [4]: https://twitter.com/zoffix/status/957413711018328064
  [5]: https://perl6.online/2018/01/28/39-experimenting-with-rats-and-nums-in-perl-6/?share=twitter "Click to share on Twitter"
  [6]: https://perl6.online/2018/01/28/39-experimenting-with-rats-and-nums-in-perl-6/?share=facebook "Click to share on Facebook"
  [7]: https://perl6.online/2018/01/28/39-experimenting-with-rats-and-nums-in-perl-6/?share=google-plus-1 "Click to share on Google+"