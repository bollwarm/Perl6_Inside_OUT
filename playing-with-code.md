Yesterday, we looked at the two methods of the Bool class that return strings. The string representation that the functions produce is hardcoded in the source code.

Let’s use this observation and try changing the texts.

So, here is the fragment that we will modify:

	Bool.^add_multi_method('gist', my multi method gist(Bool:D:) {
	    self ?? 'True' !! 'False'
	});

This gist method is used to stringify a defined variable.

To make things happen, you need to have the source codes of Rakudo on your computer so that you can compile them. Clone the project from GitHub first:

	$ git clone https://github.com/rakudo/rakudo.git

Compile with MoarVM:

	$ cd rakudo
	$ perl Configure.pl --gen-moar --gen-nqp --backends=moar
	$ make

Having that done, you get the perl6 executable in the rakudo directory.

Now, open the src/core/Bool.pm file and change the strings of the gist method to use the Unicode thumbs instead of plain text:

	Bool.^add_multi_method('gist', my multi method gist(Bool:D:) {
	    self ?? '👍' !! '👎'
	});

After saving the file, you need to recompile Rakudo. Bool.pm is in the list of files to be compiled in Makefile:

	M_CORE_SOURCES = \
	    src/core/core_prologue.pm\
	    src/core/traits.pm\
	    src/core/Positional.pm\
	    . . .
	    src/core/Bool.pm\
	    . . .

Run make and get the updated perl6. Run it and enjoy the result:

	:~/rakudo$ ./perl6
	To exit type 'exit' or '^D'
	&gt; my Bool $b = True;
	👍
	&gt; $b = !$b;
	👎
	&gt;

As an exercise, let us improve your local Perl 6 by adding the gist method for undefined values. By default, it does not exist, and [we saw that yesterday][1]. It means that an attempt to interpolate an undefined variable in a string will be rejected. Let’s make it better.

Interpolation uses the Str method. It is similar to both gist and perl, so you will have no difficulties in creating the new version.

This is what currently is in Perl 6:

	Bool.^add_multi_method('Str', my multi method Str(Bool:**D**:) {
	    self ?? 'True' !! 'False'
	});

This is what you need to add:

	Bool.^add_multi_method('Str', my multi method Str(Bool:**U**:) {
	    '¯\_(ツ)_/¯'
	});

Notice that self is not needed (and cannot be used) in the second variant.

Compile and run perl6:

	$ ./perl6
	To exit type 'exit' or '^D'
	&gt; my Bool $b;
	(Bool)
	&gt; "Here is my variable: $b"
	Here is my variable: ¯\_(ツ)_/¯
	&gt;

It works as expected. Congratulations, you’ve just changed the behaviour of Perl 6 yourself!

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
  [2]: https://perl6.online/2017/12/23/playing-with-code/?share=twitter "Click to share on Twitter"
  [3]: https://perl6.online/2017/12/23/playing-with-code/?share=facebook "Click to share on Facebook"
  [4]: https://perl6.online/2017/12/23/playing-with-code/?share=google-plus-1 "Click to share on Google+"