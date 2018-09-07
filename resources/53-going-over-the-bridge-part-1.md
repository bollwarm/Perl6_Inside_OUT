In the classes that handle numbers in Perl 6, we saw the Bridge method, which is used polymorphically. Let us spend some time and try to understand 1) how it works and 2) is it necessary.

## Classes and Roles

Our first step is to look where the method is defined. Here is the list of classes and roles that we need:

* Duration
* Instant
* Int
* Num
* Rational
* Real

To anticipate the next step, let us add some more details about their relations:

* class Duration is Cool does Real
* class Instant is Cool does Real
* class Int _is Cool_ does Real
* class Num _is Cool_ does Real
* role Rational does Real
* role Real does Numeric

In the italic font, I added pseudo-declarations that are not explicitly spelled in the corresponding files in src/core but are set via src/Perl6/Metamodel/BOOTSTRAP.nqp:

	Int.HOW.add_parent(Int, Cool);
	. . .
	Num.HOW.add_parent(Num, Cool);

For the complete picture, we could look at the place of other classes such as Rat, or Complex in this hierarchy, but let us focus on the above list first.

## The Bridge methods

Now, let us see the definitions of the Bridge methods in those classes and roles.

The two classes, Duration and Instand, stand a bit apart from the rest, as they represent time rather than numbers (although time is represented by numbers, of course). The Bridge methods are defined in the following way (in this and the following extracts, you can easily see the class in which the method is defined by looking at the type of the argument):

	method Bridge(Duration:D:) { $!tai.Num }

	method Bridge(Instant:D:) { $!tai.Bridge }

The $!tai class attribute is a Rat number that keeps the number of seconds since 1970.

Okay, moving to the numbers. For the Num class and the Real role, there are no comments:

	method Bridge(Num:D:) { self }

	method Bridge(Real:D:) { self.Num }

The definition in the Rational role looks a bit outstanding and does not include the clear argument, so it can accept both defined and undefined invocants:

	method Bridge() { self.Num } _# Rational role_

Finally, the Int class builds the bridge using NQP:

	method Bridge(Int:D:) {
	    nqp::p6box_n(nqp::tonum_I(self));
	}

It converts an Int number to a native number and boxes it to a Perl 6 Num value. This is important, and we should see it in the REPL output, for example:

	$ perl6
	To exit type 'exit' or '^D'
	&gt; **Int**.new.Bridge.WHAT;
	(**Num**)

So, the bridge from Int is Num. Actually, other bridges also give us the same data type. It is clearly visible from the definitions of the method that we just saw. The only exception is the Instant class: it calls .Bridge on the Rat value. The Rat class does not define the method, but it is inherited from the Rational role:

	my class Rat is Cool does Rational

We know that the method from that role returns self.Num.

Feeling dizzy? Let’s take a break and continue in the next post.

### Share this:

* [Twitter][1]
* [Facebook][2]
* [Google][3]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2018/02/11/53-going-over-the-bridge-part-1/?share=twitter "Click to share on Twitter"
  [2]: https://perl6.online/2018/02/11/53-going-over-the-bridge-part-1/?share=facebook "Click to share on Facebook"
  [3]: https://perl6.online/2018/02/11/53-going-over-the-bridge-part-1/?share=google-plus-1 "Click to share on Google+"