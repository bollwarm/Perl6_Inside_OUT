Today, we are looking precisely at the proto keyword. It gives a hint for the compiler about your intention to create multi-subs.

## Example 1

Consider an example of the function that either flips a string or negates an integer.

	multi sub f(Int $x) {
	    return -$x;
	}

	multi sub f(Str $x) {
	    return $x.flip;
	}

	say f(42);      _# -42_
	say f('Hello'); _# olleH_

What if we create another variant of the function that takes two arguments.

	multi sub f($a, $b) {
	    return $a + $b;
	}

	say f(1, 2); _# 3
	_

This code perfectly works, but it looks like its harmony is broken. Even if the name of the function says nothing about what it does, we intended to have a function that somehow returns a ‘reflected’ version of its argument. The function that adds up two numbers does not fit this idea.

So, it is time to clearly announce the intention with the help of the proto keyword.

	proto sub f($x) {*}

Now, an attempt of calling the two-argument function won’t compile:

	===SORRY!=== Error while compiling proto.pl
	Calling f(Int, Int) will never work with proto signature ($x)
	at proto.pl:15
	------&gt; say ⏏f(1,2)

The calls of the one-argument variants work perfectly. The proto-definition creates a pattern for the function f: its name is _f_, and it takes one scalar argument. Multi-functions specify the behaviour and narrow their expertise to either integers or strings.

## Example 2

Another example involves a proto-definition with two typed arguments in the function signature.

	proto sub g(Int $x, Int $y) {*}

In this example, the function returns a sum of the two integers. When one of the numbers is much bigger than the other, the smaller number is just ignored as being not significant enough:

	multi sub g(Int $x, Int $y) {
	   return $x + $y;
	}

	multi sub g(Int $x, Int $y where {$y &gt; 1_000_000 * $x}) {
	   return $y;
	}

Call the function with integer arguments and see how Perl 6 picks the correct variant:

	say g(1, 2);          _# 3_
	say g(3, 10_000_000); _# 10000000_

Didn’t you forget that the prototype insists on two integers? Try it out passing floating-point numbers:

	say g(pi, e);

We got a compile-time error:

	===SORRY!=== Error while compiling proto-int.pl
	Calling g(Num, Num) will never work with proto signature (Int $x, Int $y)
	at proto-int.pl:13
	------&gt; say ⏏g(pi, e);

The prototype has caught the error in the function usage. What happens if there is no proto for the g sub? The function is still not called, but the error message is different. It happens at run-time this time:

	Cannot resolve caller g(3.14159265358979e0, 2.71828182845905e0); none of these signatures match:
	 (Int $x, Int $y)
	 (Int $x, Int $y where { ... })
	 in block &lt;unit&gt; at proto-int.pl line 13

We still have no acceptable signature for the floating-point numbers, but the compiler cannot see that until the program flow reaches the code.

### Share this:

* [Twitter][1]
* [Facebook][2]
* [Google][3]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2017/12/21/the-proto-keyword/?share=twitter "Click to share on Twitter"
  [2]: https://perl6.online/2017/12/21/the-proto-keyword/?share=facebook "Click to share on Facebook"
  [3]: https://perl6.online/2017/12/21/the-proto-keyword/?share=google-plus-1 "Click to share on Google+"