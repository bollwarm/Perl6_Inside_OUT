Before moving to the second part of the [Real role][1], let us stop on the polymod method of the Int class.

The method takes a number and a list of arbitrary numbers (units) and returns the corresponding multipliers. So that you can easily say that 550 seconds, for example, is 9 minutes and 10 seconds:

	&gt; 550.polymod(60)
	(10 9)

In the method call, the value of 60 is the number of seconds in a minute. In the result, 9 is a number of minutes, and 10 is a remainder, which is a number of seconds. So, 550 seconds = 10 second + 9 minutes.

If you want more details, add more units. For example, what is it 32768 seconds?

	&gt; 32768.polymod(60, 60, 24)
	(8 6 9 0)

It is 8 seconds, 6 minutes, 9 hours, and 0 days.

Similarly, 132768 seconds are 1 day, 12 hours, 52 minutes, and 48 seconds:

	&gt; 132768.polymod(60, 60, 24)
	(48 52 12 1)

Honestly, it was quite difficult for me to understand how it works and how to read the result.

Another example from the documentation was even harder:

	&gt; 120.polymod(1, 10, 100)
	(0 0 12 0)

What does 12 mean? It is, obviously, 12 times 10. OK, But I asked to give me some information about the number of hundreds. My expectation is to have it like that: 120 is 2 times 10 and 1 time 100.

Try 121:

	&gt; 121.polymod(1, 10)
	(0 1 12)

Erm, why zero? Zero plus 1 times 1 plus 12 times 10? Brr. Ah! You don’t need to specify an explicit 1 in the arguments:

	&gt; 121.polymod(10)
	(1 12)

That makes more sense. Except the fact that I still don’t know how many hundreds are there in 121:

	&gt; 121.polymod(10, 100)
	(1 12 0)
	&gt; 121.polymod(100, 10)
	(21 1 0)

It’s time to take a look at the source code (src/core/Int.pm):

	method polymod(Int:D: +@mods) {
	    fail X::OutOfRange.new(
	        :what('invocant to polymod'), :got(self), :range&lt;0..^Inf&gt;
	    ) if self &lt; 0;

	    gather {
	         my $more = self;
	         if @mods.is-lazy {
	             for @mods -&gt; $mod {
	                $more
	                    ?? $mod
	                    ?? take $more mod $mod
	                    !! Failure.new(X::Numeric::DivideByZero.new:
	                            using =&gt; 'polymod', numerator =&gt; $more)
	                    !! last;
	                $more = $more div $mod;
	            }
	            take $more if $more;
	        }
	        else {
	            for @mods -&gt; $mod {
	                $mod
	                    ?? take $more mod $mod
	                    !! Failure.new(X::Numeric::DivideByZero.new:
	                        using =&gt; 'polymod', numerator =&gt; $more);
	                $more = $more div $mod;
	            }
	            take $more;
	        }
	    }
	}

The method has two branches, one for lazy lists, and another one for non-lazy lists. Let us only focus on the second branch for now:

	for @mods -&gt; $mod {
	    $mod
	        ?? take $more mod $mod
	        !! Failure.new(X::Numeric::DivideByZero.new:
	                       using =&gt; 'polymod', numerator =&gt; $more);
	    $more = $more div $mod;
	}

	take $more;

OK, the last take takes the remainder, that’s easy. In the loop, you divide the number by the next unit and then ‘count’ the intermediate reminder.

I would say I would implement it differently and switch the operators:

	  for @mods -&gt; $mod {
	      $mod
	-           ?? take $more mod $mod
	+           ?? take $more div $div
	          !! Failure.new(X::Numeric::DivideByZero.new:
	                         using =&gt; 'polymod', numerator =&gt; $more);
	-      $more = $more div $mod;
	+      $more = $more mod $mod;
	  }

	  take $more;

With this code, I can get the number of hundreds, tens, and ones in 121:

	&gt; 121.polymod(100, 10, 1)
	(1 2 1 0)

OK, let’s avoid two 1s:

	&gt; 1234.polymod(1000, 100, 10, 1)
	(1 2 3 4 0)

Also works fine with the earlier example with seconds:

	&gt; 132768.polymod(86400, 3600, 60)
	(1 12 52 48)

It is 1 day, 12 hours, 52 minutes, and 48 seconds.

As you see, now you have to use explicit units (8600 instead of 24) and you have to sort them in descending order, but now I can understand and explain the result, which I could hardly do for the original method.

### Share this:

* [Twitter][2]
* [Facebook][3]
* [Google][4]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2018/02/15/57-examining-the-real-role-of-perl-6-part-1/
  [2]: https://perl6.online/2018/02/16/58-a-word-on-polymod-in-perl-6/?share=twitter "Click to share on Twitter"
  [3]: https://perl6.online/2018/02/16/58-a-word-on-polymod-in-perl-6/?share=facebook "Click to share on Facebook"
  [4]: https://perl6.online/2018/02/16/58-a-word-on-polymod-in-perl-6/?share=google-plus-1 "Click to share on Google+"