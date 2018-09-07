As promised [yesterday][1], let us take a look at the two methods of the Real role: polymod and base.

## polymod

I already devoted a post to the [Int.polymod][2] method, but the method also exists in the Real role. Let us see if it is different.

	method polymod(Real:D: +@mods) {
	    my $more = self;
	    my $lazy = @mods.is-lazy;
	    fail X::OutOfRange.new(
	        :what('invocant to polymod'), :got($more), :range&lt;0..Inf&gt;
	    ) if $more &lt; 0;
	    gather {
	        for @mods -&gt; $mod {
	            last if $lazy and not $more;
	            Failure.new(X::Numeric::DivideByZero.new:
	                using =&gt; 'polymod', numerator =&gt; $more
	            ) unless $mod;
	            take my $rem = $more % $mod;
	            $more -= $rem;
	            $more /= $mod;
	        }
	        take $more if ($lazy and $more) or not $lazy;
	    }
	}

It looks familiar. Comparing to the method of Int, the separation of lazy and non-lazy lists is incorporated in the main loop. In the rest, it is again the mod operation (in the form of %) and a division (and some additional subtraction).

Try the method on the same 120 (but as a Numeric value):

	&gt; say 120.polymod(10,10)
	(0 2 1)

	&gt; say 120e0.polymod(10,10)
	(0 2 1)

The first method is a call of Int.polymod, while the second one is Real.polymod. The results are the same.

A final note on the method. Just notice that it also works with non-integer values:

	&gt; 120.34.polymod(3.3, 4.4)
	(1.54 0.8 8)

Indeed, 1.54 + 0.8 \* 3.3 + 8 \* 3.3 \* 4.4 = 120.34.

## base

The base method converts a number to its representation in a different system, e. g., hexadecimal, octal, or in a system with 5 or 35 digits. Extrapolating hexadecimal system, you may guess that if there are 36 digits, then the digits are 0 to 9 and A to Z.

A few examples with the numbers with a floating point (actually, Rat numbers here):

	&gt; 120.34.base(10)
	120.34
	&gt; 120.34.base(36)
	3C.C8N1FU
	&gt; 120.34.base(3)
	11110.100012
	&gt; 120.34.base(5)
	440.132223

The fractional part is converted separately. The second argument of the method limits the number of digits in it. Compare:

	&gt; 120.34.base(5)
	440.132223
	&gt; 120.34.base(5, 2)
	440.14

I will skip the details of the method internals and will only show the most interesting parts.

The signature of the method in the src/core/Real.pm file is the following:

	 method base(Int:D $base, $digits? is copy)

The [documentation][3] interprets that quite differently (although correct semantically):

	method base(Real:D: Int:D $base where 2..36, $digits? --&gt; Str:D)

The possible digits are listed explicitly (not in ranges):

	my @conversion := &lt;0 1 2 3 4 5 6 7 8 9
	                   A B C D E F G H I J
	                   K L M N O P Q R S T
	                   U V W X Y Z&gt;;

Finally, the last gathering of the separate digits into a resulting string is done like that, using a call to the Int.base method:

	my Str $r = $int_part.base($base);
	$r ~= '.' ~ **@conversion**[@frac_digits].join if @frac_digits;
	# if $int_part is 0, $int_part.base doesn't see the sign of self
	$int_part == 0 &amp;&amp; self &lt; 0 ?? '-' ~ $r !! $r;

The method also does some heuristics to determine the number of digits after the floating point:

	my $prec = $digits // 1e8.log($base.Num).Int;
	. . .
	for ^$prec {
	    last unless $digits // $frac;
	    $frac = $frac * $base;
	    push @frac_digits, $frac.Int;
	    $frac = $frac - $frac.Int;
	}

Compare now the method with the same method from the Int class:

	multi method base(Int:D: Int:D $base) {
	    2 &lt;= $base &lt;= 36
	        ?? nqp::p6box_s(**nqp::base_I(self,nqp::unbox_i($base))**)
	        !! Failure.new(X::OutOfRange.new(
	            what =&gt; "base argument to base", :got($base), :range&lt;2..36&gt;))
	}

In this case, all the hard work is delegated to the base\_I function of NQP.

And that’s more or less all that I wanted to cover from the Real role internals.

### Share this:

* [Twitter][4]
* [Facebook][5]
* [Google][6]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2018/02/18/59-examining-the-real-role-of-perl-6-part-2/
  [2]: https://perl6.online/2018/02/16/58-a-word-on-polymod-in-perl-6/
  [3]: https://docs.perl6.org/routine/base
  [4]: https://perl6.online/2018/02/18/60-examining-the-real-role-of-perl-6-part-3/?share=twitter "Click to share on Twitter"
  [5]: https://perl6.online/2018/02/18/60-examining-the-real-role-of-perl-6-part-3/?share=facebook "Click to share on Facebook"
  [6]: https://perl6.online/2018/02/18/60-examining-the-real-role-of-perl-6-part-3/?share=google-plus-1 "Click to share on Google+"