In Perl 5, I used to set timeouts using signals (or, at least, that was an easy and predictable way). In Perl 6, you can use promises. Let us see how to do that.

To imitate a long-running task, create an infinite loop that prints its state now and then. Here it is:

	for 1 .. * {
	    .say if $_ %% 100_000;
	}

As soon as the loop gets control, it will never quit. Our task is to stop the program in a couple of seconds, so the timer should be set before the loop:

	Promise.in(2).then({
	    exit;
	});

	for 1 .. * {
	    .say if $_ %% 100_000;
	}

Here, the Promise.in method creates a promise that is automatically kept after the given number of seconds. On top of that promise, using then, we add another promise, whose code will be run after the timeout. The only statement in the body here is exit that stops the main program.

Run the program to see how it works:

	$ time perl6 timeout.pl
	100000
	200000
	300000
	. . .
	3700000
	3800000
	3900000

	real 0m2.196s
	user 0m2.120s
	sys 0m0.068s

The program counts up to about four millions on my computer and quits in two seconds. That is exactly the behaviour we needed.

For comparison, here is the program in Perl 5:

	use v5.10;

	alarm 2;
	$SIG{ALRM} = sub {
	    exit;
	};

	for (my $c = 1; ; $c++) {
	    say $c unless $c % 1_000_000;
	}

(It manages to count up to 40 million, but that’s another story.)

### Share this:

* [Twitter][1]
* [Facebook][2]
* [Google][3]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2018/03/03/69-setting-timeouts-in-perl-6/?share=twitter "Click to share on Twitter"
  [2]: https://perl6.online/2018/03/03/69-setting-timeouts-in-perl-6/?share=facebook "Click to share on Facebook"
  [3]: https://perl6.online/2018/03/03/69-setting-timeouts-in-perl-6/?share=google-plus-1 "Click to share on Google+"