Today, I started looking into the internals of the Int class (src/core/Int.pm) and faced a strangely looking method, Range.

The Range method returns an object of the Range type showing the minimum and the maximum values that the object can hold. For example, this is how the method is defined for the Num class:

	method Range(Num:U:) { Range.new(-Inf,Inf) }

Or, for the Rational type:

	method Range(::?CLASS:U:) { Range.new(-Inf, Inf) }

It is possible to call a method directly on the typename or on a variable of that type. For example, let’s display the range of Int:

	say Int.Range; _# -Inf^..^Inf_

	my Int $x;
	say $x.Range;  _# -Inf^..^Inf_

Finally, let us look at the body of the method in src/core/Int.pm:

	method Range(Int:U:) {
	    given self {
	        when int  { $?BITS == 64 ??  int64.Range !!  int32.Range }
	        when uint { $?BITS == 64 ?? uint64.Range !! uint32.Range }

	        when int64  { Range.new(-9223372036854775808, 9223372036854775807) }
	        when int32  { Range.new(         -2147483648, 2147483647         ) }
	        when int16  { Range.new(              -32768, 32767              ) }
	        when int8   { Range.new(                -128, 127                ) }
	        # Bring back in a future Perl 6 version, or just put on the type object
	        #when int4   { Range.new(                  -8, 7                  ) }
	        #when int2   { Range.new(                  -2, 1                  ) }
	        #when int1   { Range.new(                  -1, 0                  ) }

	        when uint64 { Range.new( 0, 18446744073709551615 ) }
	        when uint32 { Range.new( 0, 4294967295           ) }
	        when uint16 { Range.new( 0, 65535                ) }
	        when uint8  { Range.new( 0, 255                  ) }
	        when byte   { Range.new( 0, 255                  ) }
	        # Bring back in a future Perl 6 version, or just put on the type object
	        #when uint4  { Range.new( 0, 15                   ) }
	        #when uint2  { Range.new( 0, 3                    ) }
	        #when uint1  { Range.new( 0, 1                    ) }

	        default {  # some other kind of Int
	            .^name eq 'UInt'
	                ?? Range.new(    0, Inf, :excludes-max )
	                !! Range.new( -Inf, Inf, :excludes-min, :excludes-max )
	        }
	    }
	}

Indeed, a bit more than expected. Some of the checks are commented out but still, for a bare Int variable, you should pass all the checks for different native times first.

I assume that most Perl users either never or very seldom use native data types (such as int64 or uint32), so for my local instance of Rakudo I removed all the when clauses to see how it affects the speed of this particular method:

	method Range(Int:U:) {
	    Range.new( -Inf, Inf, :excludes-min, :excludes-max );
	}

Compare the speed by calling a method many times. With original code:

	$ time ./perl6 -e'Int.Range for ^100_000'
	real 0m3.262s
	**user 0m3.264s**
	sys 0m0.043s

With a reduced Range method:

	$ time ./perl6 -e'Int.Range for ^100_000'
	real 0m0.268s
	**user 0m0.271s**
	sys 0m0.034s

### Share this:

* [Twitter][1]
* [Facebook][2]
* [Google][3]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2018/01/14/24-the-range-method/?share=twitter "Click to share on Twitter"
  [2]: https://perl6.online/2018/01/14/24-the-range-method/?share=facebook "Click to share on Facebook"
  [3]: https://perl6.online/2018/01/14/24-the-range-method/?share=google-plus-1 "Click to share on Google+"