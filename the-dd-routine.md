In Rakudo, there is a useful routine dd, which is not a part of Perl 6 itself. It dumps its argument(s) in a way that you immediately see the type and content of a variable. For example:

	$ ./perl6 -e'my Bool $b = True; dd($b)'
	Bool $b = Bool::True

It works well with data of other types, for example, with arrays:

	$ ./perl6 -e'my @a = &lt; a b c &gt;; dd(@a)'
	Array @a = ["a", "b", "c"]

Today, we will look at the definition of the dd routine.

It is located in the src/core/Any.pm module as part of the Any class. The code is quite small, so let us show it here:

	sub dd(|) {
	    my Mu $args := nqp::p6argvmarray();
	    if nqp::elems($args) {
	        while $args {
	            my $var  := nqp::shift($args);
	            my $name := try $var.VAR.?name;
	            my $type := $var.WHAT.^name;
	            my $what := $var.?is-lazy
	              ?? $var[^10].perl.chop ~ "... lazy list)"
	              !! $var.perl;
	            note $name ?? "$type $name = $what" !! $what;
	        }
	    }
	    else { _# tell where we are_
	        note .name
	          ?? "{lc .^name} {.name}{.signature.gist}"
	          !! "{lc .^name} {.signature.gist}"
	          with callframe(1).code;
	    }
	    return
	}

## Call with arguments

The vertical bar, which we have already seen earlier, is a signature that captures argument lists with no type checking. It is not possible to omit it and leave empty parentheses, as in that case the routine can only be called without arguments.

Inside, some NQP-magic happens but that is quite readable for us. If there are arguments, the routine loops over them, shifting the next argument in each cycle.

Then, there is an attempt to get the name, type and content:

	my $name := try $var.VAR.?name;
	my $type := $var.WHAT.^name;

Notice the presence of try and ? in the method call. We already saw the pattern when we were taking about string interpolation. The ?name is only called on an object if the method exists there, and does not generate an error if not.

The content is a bit more difficult thing:

	my $what := $var.?is-lazy
	    ?? $var[^10].perl.chop ~ "... lazy list)"
	    !! $var.perl;

The result depends on whether an object is a lazy list or not. For example, try dumping an infinite range:

	$ ./perl6 -e'dd 1..∞'
	(1, 2, 3, 4, 5, 6, 7, 8, 9, 10... lazy list)

Only the first ten items are listed. For a non-lazy object, the perl method is called.

Finally, the result is printed to STDERR:

	note $name ?? "$type $name = $what" !! $what;

## Call with no arguments

The second branch of the dd routine is triggered when there are no arguments. In that case, the routine tries to give some information about the place where it is called. Look at the following example:

	sub f() { dd }
	f;

The result of running this program shows the name and the signature of the function:

	_sub f()_

A good use case can be thus to use dd in multi-functions instead of printing manual text messages.

	multi sub f(Int) { dd }
	multi sub f(Str) { dd }

	f(42);
	f('42');

Run the program, and it prints an extremely useful debugging information:

	_sub f(Int)_
	_sub f(Str)_

That’s all for today. See you tomorrow!

### Share this:

* [Twitter][1]
* [Facebook][2]
* [Google][3]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2017/12/26/the-dd-routine/?share=twitter "Click to share on Twitter"
  [2]: https://perl6.online/2017/12/26/the-dd-routine/?share=facebook "Click to share on Facebook"
  [3]: https://perl6.online/2017/12/26/the-dd-routine/?share=google-plus-1 "Click to share on Google+"