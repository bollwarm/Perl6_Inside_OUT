Yesterday, we saw four different variants of the multi sub called say. Today, let’s look at them more precisely. The functions are located in the src/core/io\_operators.pm file.

Start with the first and the simplest one:

	multi sub say() { $*OUT.print-nl }

It just prints the newline to the $\*OUT stream. Probably, it would be wise mentioning that parentheses are required in the call:

	$ ./perl6 -e'say'
	===SORRY!===
	Argument to "say" seems to be malformed
	at -e:1
	------&gt; say⏏

The following code is correct:

	$ ./perl6 -e'say()'

Move on to the sub that expects a defined string:

	multi sub say(Str:D \x) {    
	    my $out := $*OUT;
	    $out.print(nqp::concat(nqp::unbox_s(x),$out.nl-out));
	}

Even if not everything is clear here, the general idea can be seen: this function passes its argument to the print method if $\*OUT (which equals to STDIN by default) and adds a new line in the end.

The next variant is suitable for the variables of other types:

	multi sub say(\x) {
	    my $out := $*OUT;
	    $out.print(nqp::concat(nqp::unbox_s(x.gist),$out.nl-out));
	}

Can you spot the difference with the previous sub?

It is x.gist instead of x. In the case of a string, there is no need to stringify it. In all other cases, say, for integers, the gist method is called. We already talked [about the gist method of the Bool class][1]. That’s how the call of say with a Boolean argument gets a string representation of it: its gist method just returns a string, either ‘True’ or ‘False’.

OK, one more variant for calls with multiple arguments:

	multi sub say(**@args is raw) {
	    my str $str;
	    my $iter := @args.iterator;
	    nqp::until(
	        nqp::eqaddr(($_ := $iter.pull-one), IterationEnd),
	        $str = nqp::concat($str, nqp::unbox_s(.gist)));
	    my $out := $*OUT;
	    $out.print(nqp::concat($str,$out.nl-out));
	}

Well, it looks complex but again, the main idea is visible with the naked eye: iterate over all arguments, concatenate them and print the resulting string with a newline after it:

	$ ./perl6 -e'say(1, 2, 3)'
	say(**@args is raw)
	123

I would avoid digging in into the details of the NQP calls in this subroutine for now. Especially, if you compare the implementation of say with similar functions print and put:

	multi sub print(**@args is raw) { $*OUT.print: @args.join }

	multi sub put(**@args is raw) {
	    my $out := $*OUT;
	    $out.print: @args.join ~ $out.nl-out
	}

Finally, the variant of say for junctions:

	multi sub say(Junction:D \j) {
	    j.THREAD(&amp;say)
	}

In this implementation, printing a junction means creating a junction, each branch of which is a call of say with the corresponding value. So, say(1|2) is something equivalent to say(1) | say(2), and I assume that the result that you see in the console may be different in each run.

	$ ./perl6 -e'say 1|2'
	say(Junction:D \j)
	1
	2

Notice that say 1|2 is not the same as say 1 ~~ 1|2. In the first case, the sub gets a junction, while in the second case it is called with a single Boolean value:

	$ ./perl6 -e'say 1 ~~ 1|2'
	True

### Share this:

* [Twitter][2]
* [Facebook][3]
* [Google][4]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2017/12/22/bool-1/
  [2]: https://perl6.online/2018/01/04/variants-of-say-in-perl-6/?share=twitter "Click to share on Twitter"
  [3]: https://perl6.online/2018/01/04/variants-of-say-in-perl-6/?share=facebook "Click to share on Facebook"
  [4]: https://perl6.online/2018/01/04/variants-of-say-in-perl-6/?share=google-plus-1 "Click to share on Google+"