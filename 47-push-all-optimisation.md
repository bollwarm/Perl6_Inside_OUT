Last evening, I made a [commit][1] based on my recent observation. Let me devote today’s post to that.

In the last few days, we were talking about the two methods for getting random elements from a list — pick and roll. When you pass an integer to the methods, both of them internally use an instance of the class implementing the Iterator role. Depending on the situation, either pull-one or push-all method is called on that object.

Just as a reminder, here’s the skeleton of the two methods from src/core/List.pm (the samples are not working code):

	multi method roll(\number) {
	    Seq.new(class :: does Iterator {
	        **method** **pull-one()** is raw {
	        }
	    }.new(self,number.Int))
	}

	multi method pick(List:D: $number is copy) {
	    Seq.new(class :: does Iterator {
	        **method** **pull-one()** {
	        }
	        **method** **push-all($target)** {
	        }
	    }.new(self,$elems,$number))
	}

The problem is that in the case of roll, Rakudo calls pull-one for each element of the list, while in the case of pick, it just gets the whole list at one go.

In this program, both methods are using pull-one:

	say &lt;a b c d e&gt;.roll(4);
	say &lt;a b c d e&gt;.pick(4);

Although if you change it, only pick switches to push-one, while roll makes as many pull-one calls as you need to fetch all the requested elements individually:

	my @r = &lt;a b c d e&gt;.roll(4);
	say @r;

	my @p = &lt;a b c d e&gt;.pick(4);
	say @p;

What I did, I added the push-all method to the roll method:

	method push-all($target --&gt; IterationEnd) {
	    nqp::while(
	        $!todo,
	        nqp::stmts(
	            ($target.push(nqp::atpos($!list,$!elems.rand.floor))),
	            ($!todo = $!todo - 1)
	        )
	    )
	}

Now, in the above example, pick is also using the push-all method.

Compare the speed of the program before and after the change:

	$ time ./perl6 -e'my @a = "a".."z"; for ^500_000 {my @b = @a.roll(20)}'
	real	0m26.321s
	user	**0m26.010s**
	sys	0m0.163s

	$ time ./perl6 -e'my @a = "a".."z"; for ^500_000 {my @b = @a.roll(20)}'
	real	0m20.829s
	user	**0m20.701s**
	sys	0m0.130s

With the given data, it works 20% faster. Add some more code and gain some speed 🙂

P. S. Also read [Zoffix’s post][2] (or its part) in the Rakudo.party blog with more information about the push-all method.

### Share this:

* [Twitter][3]
* [Facebook][4]
* [Google][5]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://github.com/rakudo/rakudo/commit/65d6fe48033a31a02dfee7b0cfbc6cf4c08af2d2
  [2]: https://perl6.party/post/Perl-6-Seqs-Drugs-and-Rock-n-Roll--Part-2#pushitrealgood...
  [3]: https://perl6.online/2018/02/05/47-push-all-optimisation/?share=twitter "Click to share on Twitter"
  [4]: https://perl6.online/2018/02/05/47-push-all-optimisation/?share=facebook "Click to share on Facebook"
  [5]: https://perl6.online/2018/02/05/47-push-all-optimisation/?share=google-plus-1 "Click to share on Google+"