As soon as we touched some native integers [yesterday][1], let us look a bit closer at them. The topic is deep, so we limit ourselves with a brief understanding of interconnections between the different integer data types in Perl 6.

## UInt and UInt64

The simplest is UInt. This data type is defined in src/core/Int.pm and is literary a one-liner:

	my subset UInt of Int where {not .defined or $_ &gt;= 0};

The where clause restricts the values to be non-negative. Thus, the range of a UInt variable is 0\..^Inf:

	say UInt.Range; _# 0..^Inf_

There’s another type, UInt64. It is defined similarly but puts additional restriction to the value: it should not exceed 2⁶⁴.

	my Int $UINT64_UPPER = nqp::pow_I(2, 64, Num, Int);
	subset UInt64 of Int where { 0 &lt;= $_ &lt; $UINT64_UPPER }

By the way, don’t forget that you can use superscripts in Perl 6 directly:

	say 2⁶⁴; _# 18446744073709551616_

OK, let us confirm the borders of the UInt64 class by calling its Range method:

	$ perl6 -e'say UInt64.Range'
	-Inf^..^Inf

This result is wrong (U stands for unsigned), but I am sure that if you follow my blog you know where to fix it. Of course, the problem sits in the [Range method][2] that we were examining yesterday. Here is the fragment in src/core/Int.pm we need:

	default { # some other kind of Int
	    .^name eq 'UInt'
	        ?? Range.new( 0, Inf, :excludes-max )
	        !! Range.new( -Inf, Inf, :excludes-min, :excludes-max )
	}

Both UInt and UInt64 are the children of Int but only of the them is handled properly. Let us add the missing check like this, for example:

	when .^name eq 'UInt'   { Range.new(0, Inf, :excludes-max) }
	when .^name eq 'UInt64' { Range.new(0, 2⁶⁴ - 1) }
	default                 { Range.new( -Inf, Inf, :excludes-min, :excludes-max) }

Compile and enjoy the result:

	say Int.Range;    _# -Inf^..^Inf_
	say UInt.Range;   _# 0..^Inf_
	say UInt64.Range; _# 0..18446744073709551615_

This is fine but I am still not satisfied with a big chain of when tests. Would UInt and UInt64 be classes, not subsets, you could add individual Range methods to each of them.

## Native ints

Another big cluster of integer type definitions can be found in src/core/natives.pm. Let me quote the big part of that file here:

	my native   int is repr('P6int') is Int { }
	my native  int8 is repr('P6int') is Int is nativesize( 8) { }
	my native int16 is repr('P6int') is Int is nativesize(16) { }
	my native int32 is repr('P6int') is Int is nativesize(32) { }
	my native int64 is repr('P6int') is Int is nativesize(64) { }

	my native   uint is repr('P6int') is Int is unsigned { }
	my native  uint8 is repr('P6int') is Int is nativesize( 8) is unsigned { }
	my native   byte is repr('P6int') is Int is nativesize( 8) is unsigned { }
	my native uint16 is repr('P6int') is Int is nativesize(16) is unsigned { }
	my native uint32 is repr('P6int') is Int is nativesize(32) is unsigned { }
	my native uint64 is repr('P6int') is Int is nativesize(64) is unsigned { }

These native types are all Ints and are represented by P6int data type. If you dig into MoarVM, you will find a directory nqp/MoarVM/src/6model/reprs that contains many C and C header files, including P6int.c and P6int.h. A brief look tells us that this type is universally used for all the native types listed above:

	/* Representation used by P6 native ints. */
	struct MVMP6intBody {
	    /* Integer storage slot. */
	    **union** **{**
	        MVMint64 i64;
	        MVMint32 i32;
	        MVMint16 i16;
	        MVMint8 i8;
	        MVMuint64 u64;
	        MVMuint32 u32;
	        MVMuint16 u16;
	        MVMuint8 u8;
	    **}** value;
	};

The is nativesize and is unsigned are the traits (src/core/traits.pm) that set some attributes of the NativeHOW object:

	multi sub trait_mod:&lt;is&gt;(Mu:U $type, :$**nativesize**!) {
	    $type.^set_nativesize($nativesize);
	}
	multi sub trait_mod:&lt;is&gt;(Mu:U $type, :$**unsigned**!) {
	    $type.^set_unsigned($unsigned);
	}

And let’s make a break for today.

### Share this:

* [Twitter][3]
* [Facebook][4]
* [Google][5]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2018/01/14/24-the-range-method/
  [2]: https://perl6.online/2018/01/14/24-the-range-method/
  [3]: https://perl6.online/2018/01/15/26-native-integers-and-uint-in-perl-6/?share=twitter "Click to share on Twitter"
  [4]: https://perl6.online/2018/01/15/26-native-integers-and-uint-in-perl-6/?share=facebook "Click to share on Facebook"
  [5]: https://perl6.online/2018/01/15/26-native-integers-and-uint-in-perl-6/?share=google-plus-1 "Click to share on Google+"