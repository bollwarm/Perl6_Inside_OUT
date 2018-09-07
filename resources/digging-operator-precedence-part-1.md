Today, we’ll once again look at the src/core/Bool.pm file. This is a good example of a full-fledged Perl 6 class, which is still not very difficult to examine.

Look at the definitions of the ? and so operators:

	proto sub prefix:&lt;?&gt;(Mu $) is pure {*}
	multi sub prefix:&lt;?&gt;(Bool:D \a) { a }
	multi sub prefix:&lt;?&gt;(Bool:U \a) { Bool::False }
	multi sub prefix:&lt;?&gt;(Mu \a) { a.Bool }

	proto sub prefix:&lt;so&gt;(Mu $) is pure {*}
	multi sub prefix:&lt;so&gt;(Bool:D \a) { a }
	multi sub prefix:&lt;so&gt;(Bool:U \a) { Bool::False }
	multi sub prefix:&lt;so&gt;(Mu \a) { a.Bool }

There’s no visual difference between the two implementations, but it would be a mistake to conclude that there is no difference between the two of them. Both ? and so cast a value to the Bool type.

## When am I called?

Before we go discussing the precedence, let us first examine when the above subs are called. For simplifying the task, add a few printing instructions into their bodies:

	proto sub prefix:&lt;?&gt;(Mu $) is pure {*}
	multi sub prefix:&lt;?&gt;(Bool:D \a) { **say 1;** a }
	multi sub prefix:&lt;?&gt;(Bool:U \a) { **say 2;** Bool::False }
	multi sub prefix:&lt;?&gt;(Mu \a) { **say 3;** a.Bool }

	proto sub prefix:&lt;so&gt;(Mu $) is pure {*}
	multi sub prefix:&lt;so&gt;(Bool:D \a) { **say 4;** a }
	multi sub prefix:&lt;so&gt;(Bool:U \a) { **say 5;** Bool::False }
	multi sub prefix:&lt;so&gt;(Mu \a) { **say 6;** a.Bool }

Re-compile Rakudo and make a few tests with both ? and so (you’ll get some numbers printed before the prompt appears):

	$ ./perl6
	&gt; my Bool $b;
	(Bool)
	&gt; ?$b;
	2
	&gt; so $b;
	5
	&gt;

At the moment, there are no surprises. For an undefined Boolean variable, those subs are called that have the (Bool:U) signature.

Now, try an integer:

	&gt; my Int $i;
	(Int)
	&gt; ?$i;
	3
	&gt; so $i;
	6

Although the variable is of the Int type, the compiler calls the subs from Bool.pm (notice that those functions are regular subs, not the methods of the Bool class). This time, the subs having the (Mu) signature are called, as Int is a grand-grandchild of Mu (via Cool and Any). For the undefined variable, the subs call the Bool method from the Mu class.

	proto method Bool() {*}
	multi method Bool(Mu:U: --&gt; False) { }
	multi method Bool(Mu:D:) { self.defined }

For a defined integer, the Bool method of the Int class is used instead:

	multi method Bool(Int:D:) {
	    nqp::p6bool(nqp::bool_I(self));
	}

To visualise the routes, add more printing commands to the files. In src/core/Mu.pm:

	proto method Bool() {*}
	multi method Bool(Mu:U:) { nqp::say('7'); False }
	multi method Bool(Mu:D:) { nqp::say('8'); self.defined }

And in src/core/Int.pm:

	multi method Bool(Int:D:) {
	    say 9;
	    nqp::p6bool(nqp::bool_I(self));
	}

During the compilation, a lot of 7s and 8s flood the screen, which means that the changes we’ve just made are already used even during the compilation process.

It’s time to play with defined and undefined integers now:

	&gt; my Int $i;
	(Int)
	&gt; say $i.Bool;
	7
	False
	&gt; $i = 42;
	42
	&gt; say $i.Bool;
	9
	True

For the undefined variable, the method from the Mu class (printing 7) is triggered; for the defined variable, the one from Int (9).

### Share this:

* [Twitter][1]
* [Facebook][2]
* [Google][3]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2017/12/27/digging-operator-precedence-part-1/?share=twitter "Click to share on Twitter"
  [2]: https://perl6.online/2017/12/27/digging-operator-precedence-part-1/?share=facebook "Click to share on Facebook"
  [3]: https://perl6.online/2017/12/27/digging-operator-precedence-part-1/?share=google-plus-1 "Click to share on Google+"