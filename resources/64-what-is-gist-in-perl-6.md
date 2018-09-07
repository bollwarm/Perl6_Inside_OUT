When you print an object, say, as say $x, Perl 6 calls the gist method. This method is defined for all built-in types: for some of them, it calls the Str method, for some the perl method, for some types it makes the string representation somehow differently.

Let us see how you can use the method to create your own variant:

	class X {
	    has $.value;

	    method gist {
	        '[' ~ $!value ~ ']'
	    }
	}

	my $x = X.new(value =&gt; 42);

	say $x; _# [42]_
	$x.say; _# [42]_

When you call say, the program prints a number in square brackets: [42].

Please notice that the interpolation inside double-quoted strings is using Str, not gist. You can see it here:

	say $x.Str; _# X&lt;140586830040512&gt;_
	say "$x";   _# X&lt;140586830040512&gt;_

If you need a custom interpolation, redefine the Str method:

	class X {
	    has $.value;

	    method gist {
	        '[' ~ $!value ~ ']'
	    }
	    method Str {
	        '"' ~ $!value ~ '"'
	    }
	}

	my $x = X.new(value =&gt; 42);

	say $x;     _# [42]_
	$x.say;     _# [42]_

	say $x.Str; _# "42"_
	say "$x";   _# "42"_

Now, we got the desired behaviour.

### Share this:

* [Twitter][1]
* [Facebook][2]
* [Google][3]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2018/02/27/64-what-is-gist-in-perl-6/?share=twitter "Click to share on Twitter"
  [2]: https://perl6.online/2018/02/27/64-what-is-gist-in-perl-6/?share=facebook "Click to share on Facebook"
  [3]: https://perl6.online/2018/02/27/64-what-is-gist-in-perl-6/?share=google-plus-1 "Click to share on Google+"