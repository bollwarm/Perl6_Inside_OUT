For the last two days, the topic of this blog was the internals of the say routine in Rakudo Perl 6. (By the way, the term _routine_ is a good choice if you need to talk about both subs and methods.)

In src/core/io\_operators.pm, other routines are also defined. The main focus of today is on the implementation details of print, say, put, and note for multiple arguments. Let us look at the functions having this signature: (\*\*@args is raw).

	multi sub print(**@args is raw) {
	    $*OUT.print: @args.join
	}
	multi sub put(**@args is raw) {
	    my $out := $*OUT;
	    $out.print: @args.join ~ $out.nl-out
	}

	multi sub note(**@args is raw) {
	    my $err := $*ERR;
	    my str $str;
	    $str = nqp::concat($str,nqp::unbox_s(.gist)) for @args;
	    $err.print(nqp::concat($str,$err.nl-out));
	}

	multi sub say(**@args is raw) {
	    my str $str;
	    my $iter := @args.iterator;
	    nqp::until(
	      nqp::eqaddr(($_ := $iter.pull-one), IterationEnd),
	      $str = nqp::concat($str, nqp::unbox_s(.gist)));
	    my $out := $*OUT;
	    $out.print(nqp::concat($str,$out.nl-out));
	}

I sorted the functions by the size of their bodies. As you can see, print has the simplest implementation, while say is way more complicated. Let us try to understand if it is possible to simplify it.

First, re-write the body of say in the way note is implemented. The main difference between the behaviour of say and note is the output stream: it is either standard output or standard error. By default, $\*OUT and $\*ERR dynamic variables are connected to STDOUT and STDERR.

Both say and note call the gist method to stringify the values. So, change the name of the variable and copy the rest.

	multi sub say(**@args is raw) {
	    my $out := $*OUT;
	    my str $str;
	    $str = nqp::concat($str,nqp::unbox_s(.gist)) for @args;
	    $out.print(nqp::concat($str,$out.nl-out));
	}

Try it out:

	$ ./perl6 -e'say(Bool::True, 2, 3)'
	True23

Seems to be OK, although such changes must be tested more thoroughly. So, let’s run the spec tests:

	$ make spectest

This command initiates the tests from the [Roast test suite][1]—a huge set of tests covering thousands of syntax corners of Perl 6. The command above also downloads the test suite if needed. The whole run may take a few minutes.

In my case, the only difference between the run on a fresh Rakudo and the one after the modification of say was a failing t/spec/S07-hyperrace/basics.t, which did not happen in the second run and when I ran it individually. So, I think, my change passed the test suite.

The body of say is now more compact but it is still bigger than the implementation of print or put. Let us take them as inspiration. What is missing there is a call to gist, which is easy to add, though:

	multi sub say(**@args is raw) {
	    my $out := $*OUT;
	    $out.print: @args.map([*.gist][2]).join ~ $out.nl-out;
	}

To make sure nothing is broken, run the spec tests again.

### Share this:

* [Twitter][3]
* [Facebook][4]
* [Google][5]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://github.com/perl6/roast
  [2]: https://perl6advent.wordpress.com/2017/12/11/
  [3]: https://perl6.online/2018/01/05/simplifying-the-implementation-of-say-in-perl-6/?share=twitter "Click to share on Twitter"
  [4]: https://perl6.online/2018/01/05/simplifying-the-implementation-of-say-in-perl-6/?share=facebook "Click to share on Facebook"
  [5]: https://perl6.online/2018/01/05/simplifying-the-implementation-of-say-in-perl-6/?share=google-plus-1 "Click to share on Google+"