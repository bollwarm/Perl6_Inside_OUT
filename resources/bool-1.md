Today, we will be digging into the internals of the Bool type using the source code of Rakudo, [available on GitHub][1].

Perl 6 is written in the Perl 6 and NQP (Not Quite Perl 6) languages, which makes it relatively easy to read the sources. Of course, there are many things that are not easy to understand or which are not reflected in the publicly available documentation of the Perl 6 language. Neither you can find the deep details in the [Perl 6 books][2] so far. Anyway, this is still possible with some intermediate understanding of Perl 6.

OK, so back to the src/core/Bool.pm file. It begins with a few BEGIN phasers that add some methods and multi-methods to the Bool class. We’ll talk about the details of metamodels and class construction next time. Today, the more interesting for us is what the methods of the Bool class are doing.

## gist and perl

The gist and perl methods return the string representation of the object: gist is implicitly called when a variable is stringified, perl is supposed to be called directly. It works for any object in Perl 6, but of course, the behaviour should be defined somewhere. And here they are:

	Bool.^add_method('gist', my proto method gist(|) {*});
	Bool.^add_multi_method('gist', my multi method gist(Bool:D:) {
	    self ?? 'True' !! 'False'
	});
	Bool.^add_multi_method('gist', my multi method gist(Bool:U:) {
	    '(Bool)'
	});

	Bool.^add_method('perl', my proto method perl(|) {*});
	Bool.^add_multi_method('perl', my multi method perl(Bool:D:) {
	    self ?? 'Bool::True' !! 'Bool::False'
	});
	Bool.^add_multi_method('perl', my multi method perl(Bool:U:) {
	    'Bool'
	});

Try out the methods in the following simple program:

	my Bool $b = True;
	say $b;      _# True_
	say "[$b]";  _# [True]_
	$b.perl.say; _# Bool::True_

As you can see, the True string is returned by the gist method, while the perl method returns Bool::True.

Both methods are multi-methods, and in the above example, the version with a defined argument was used. If you look at the signatures, you will see that the methods are different in the way an argument is specified: Bool:D: or Bool:U:. The letters D and U stay for _defined_ and _undefined_, correspondingly. The first colon adds an attribute to the type, while the second one indicates that the argument is actually an invocant.

So, different versions of the methods are triggered depending on whether they are called on a defined or an undefined Boolean variable. To demonstrate the behaviour of the other two variants, simply remove the initialiser part from the code:

	my Bool $b;
	say $b;      _# (Bool)_
	$b.perl.say; _# Bool_

As the variable $b has a type, Perl 6 knows the type of the object, on which it should call methods. Then it is dispatched to the versions with the (Bool:U:) signature because the variable is not defined yet.

When an undefined variable appears in the string, for example, say "[$b]", the gist method is not called. Instead, you get an error message.

	Use of uninitialized value $b of type Bool in string context.
	Methods .^name, .perl, .gist, or .say can be used to stringify it to something meaningful.
	 in block  at bool-2.pl line 3
	[]

The error message says that Perl knows of what type the variable was, but refuses to call a stringifying method.

That’s all for today. Next time, we’ll look at other methods defined for the Bool data type.

### _Related_

  [1]: https://github.com/rakudo/rakudo/blob/master/src/core/Bool.pm
  [2]: http://allperlbooks.com/tag/perl6.0