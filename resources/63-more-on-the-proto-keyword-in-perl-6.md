Before digging into the details of the [EVAL routine][1], we have to reveal some more information [about protos][2] and multiple dispatch. Examine the following program:

	proto sub f($x) {
	    say "proto f($x)";
	}

	multi sub f($x) {
	    say "f($x)"
	}

	multi sub f(Int $x) {
	    say "f(Int $x)"
	}

	multi sub f(Str $x) {
	    say "f(Str $x)"
	}

	f(2);
	f('2');
	f(3);
	f('3');

Here, there are three multi-candidates of the function plus a function declared with the proto keyword. Earlier, we only saw such proto-functions with empty body, such as:

	proto sub f($x) {*}

But this is not a necessity. The function can carry a regular load, as we see in the example:

	proto sub f($x) {
	    say "proto f($x)";
	}

Run the program:

	proto f(2)
	proto f(2)
	proto f(3)
	proto f(3)

All the calls were caught by the proto-candidate. Now, update it and return the \{\*\} block for some dedicated values;

	proto sub f($x) {
	    if $x.Str eq '3' {
	        return {*}
	    }
	    say "proto f($x)";
	}

The if check triggers its block for the last two function calls:

	f(3);
	f('3');

In these cases, the proto-function returns \{\*\}, which makes Perl 6 trying other candidates. As we have enough candidates for both integer and string arguments, the compiler can easily choose one of them:

	proto f(2)
	proto f(2)
	f(Int 3)
	f(Str 3)

### Share this:

* [Twitter][3]
* [Facebook][4]
* [Google][5]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2018/02/20/62-the-eval-routine-in-perl-6-part-1/
  [2]: https://perl6.online/2017/12/21/the-proto-keyword/
  [3]: https://perl6.online/2018/02/21/63-more-on-the-proto-keyword-in-perl-6/?share=twitter "Click to share on Twitter"
  [4]: https://perl6.online/2018/02/21/63-more-on-the-proto-keyword-in-perl-6/?share=facebook "Click to share on Facebook"
  [5]: https://perl6.online/2018/02/21/63-more-on-the-proto-keyword-in-perl-6/?share=google-plus-1 "Click to share on Google+"