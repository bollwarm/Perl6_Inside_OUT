Today, we’ll take a look at the implementation of the pick and roll methods. First, a reminder of how they work.

## The User story

If called without arguments, the methods return a random element from a list (or an array, for example):

	my @a = 'a' .. 'z';
	say @a.pick; _# b_
	say @a.roll; _# u_

When called with an integer argument N, the roll method returns N random elements, while pick returns N the elements, which are not repeated. If the initial list is shorter than N, pick returns fewer elements than your ask.

	my @b = 'a' .. 'd';

	say @b.pick(10); _# (c a b d)_
	say @b.roll(10); _# (a c a c c a b a b b)_

## The OOP story

If you grep for method roll, you will see a big list of potential candidates:

	src/core/Any.pm: proto method roll(|) is nodal {*}
	src/core/Any.pm: multi method roll() { self.list.roll }
	src/core/Any.pm: multi method roll($n) { self.list.roll($n) }
	src/core/Baggy.pm: proto method roll(|) {*}
	src/core/Baggy.pm: multi method roll(Baggy:D:) {
	src/core/Baggy.pm: multi method roll(Baggy:D: Whatever) {
	src/core/Baggy.pm: multi method roll(Baggy:D: Callable:D $calculate) {
	src/core/Baggy.pm: multi method roll(Baggy:D: $count) {
	src/core/Bool.pm: Bool.^add_method('roll', my proto method roll(|) {*});
	src/core/Bool.pm: Bool.^add_multi_method('roll', my multi method roll(Bool:U:) { nqp::p6bool(nqp::isge_n(nqp::rand_n(2e0), 1e0)) });
	src/core/Bool.pm: Bool.^add_multi_method('roll', my multi method roll(Bool:U: $n) { self.^enum_value_list.roll($n) });
	src/core/Enumeration.pm: multi method roll(::?CLASS:U:) { self.^enum_value_list.roll }
	src/core/Enumeration.pm: multi method roll(::?CLASS:U: \n) { self.^enum_value_list.roll(n) }
	src/core/Enumeration.pm: multi method roll(::?CLASS:D: *@pos) { self xx +?( @pos[0] // 1 ) }
	src/core/Hash.pm: multi method roll(::?CLASS:D:) {
	src/core/Hash.pm: multi method roll(::?CLASS:D: Callable:D $calculate) {
	src/core/Hash.pm: multi method roll(::?CLASS:D: Whatever $) { self.roll(Inf) }
	src/core/Hash.pm: multi method roll(::?CLASS:D: $count) {
	src/core/List.pm: proto method roll(|) is nodal {*}
	src/core/List.pm: multi method roll() {
	src/core/List.pm: multi method roll(Whatever) {
	src/core/List.pm: multi method roll(\number) {
	src/core/Map.pm: multi method roll(Map:D:) {
	src/core/Map.pm: multi method roll(Map:D: Callable:D $calculate) {
	src/core/Map.pm: multi method roll(Map:D: Whatever $) { self.roll(Inf) }
	src/core/Map.pm: multi method roll(Map:D: $count) {
	src/core/Mixy.pm: multi method roll(Mixy:D:) {
	src/core/Mixy.pm: multi method roll(Mixy:D: Whatever) {
	src/core/Mixy.pm: multi method roll(Mixy:D: Callable:D $calculate) {
	src/core/Mixy.pm: multi method roll(Mixy:D: $count) {
	src/core/Rakudo/Internals.pm: method roll(|c) { self.flat.roll(|c) }
	src/core/Range.pm: proto method roll(|) {*}
	src/core/Range.pm: multi method roll(Range:D: Whatever) {
	src/core/Range.pm: multi method roll(Range:D:) {
	src/core/Range.pm: multi method roll(Int(Cool) $todo) {
	src/core/Setty.pm: proto method roll(|) {*}
	src/core/Setty.pm: multi method roll(Setty:D:) {
	src/core/Setty.pm: multi method roll(Setty:D: Callable:D $calculate) {
	src/core/Setty.pm: multi method roll(Setty:D: Whatever) {
	src/core/Setty.pm: multi method roll(Setty:D: $count) {

For our today’s investigation, only two classes, Any and List, are interesting. In src/core/Any.pm, the definitions are just proxies:

	proto method roll(|) is nodal {*}
	multi method roll()   { self.list.roll }
	multi method roll($n) { self.list.roll($n) }

So, if an object does not offer the roll method, it (the object) will be converted to a list, and then the roll method is called on it.

The same story with pick:

	proto method pick(|) is nodal {*}
	multi method pick()   { self.list.pick }
	multi method pick($n) { self.list.pick($n) }

## The List story

Now, to the actual work, which happens in the methods of the List class. Let us start with the simplest case when pick or roll are called with no arguments.

	proto method roll(|) is nodal {*}
	multi method roll() {
	    self.is-lazy
	        ?? Failure.new(X::Cannot::Lazy.new(:action('.roll from')))
	        !! (my Int $elems = self.elems)
	        ?? nqp::atpos($!reified, $elems.rand.floor)
	        !! Nil
	}

	. . .

	proto method pick(|) is nodal {*}
	multi method pick(List:D:) {
	    self.is-lazy
	        ?? Failure.new(X::Cannot::Lazy.new(:action('.pick from')))
	        !! (my Int $elems = self.elems)
	        ?? nqp::atpos($!reified, $elems.rand.floor)
	        !! Nil
	}

The code of each method does the same. It is not quite clear why the signatures are inconsistent. Can’t we call pick on an undefined list? (The code below is tested in the REPL mode.)

	&gt; my List $l;
	(List)

	&gt; $l.pick;
	**Cannot resolve caller pick(List: )**; none of these signatures match:
	    (List:D $: *%_)
	    (List:D $: Callable:D $calculate, *%_)
	    (List:D $: $number is copy, *%_)
	  in block &lt;unit&gt; at &lt;unknown file&gt; line 1

	&gt; $l.roll;
	**Cannot look up attributes in a List type object**
	  in block &lt;unit&gt; at &lt;unknown file&gt; line 1

OK, nevertheless, the first thing the methods do is checking whether a list is not lazy. If it is, an exception happens:

	&gt; my @a = 1...*;
	[...]

	&gt; @a.WHAT;
	(Array)

	&gt; @a.pick;
	**Cannot .pick from a lazy list**
	  in block &lt;unit&gt; at &lt;unknown file&gt; line 1

	&gt; @a.roll;
	**Cannot .roll from a lazy list**
	  in block &lt;unit&gt; at &lt;unknown file&gt; line 1

Then, if the non-lazy list has elements, a random one is picked up and returned:

	nqp::atpos($!reified, $elems.rand.floor)

Let me stop here for today. In this topic, we still have to explore the other usages of the methods: pick($N) and pick(\*).

### Share this:

* [Twitter][1]
* [Facebook][2]
* [Google][3]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2018/02/02/exploring-the-pick-and-roll-methods-in-perl-6-part-1/?share=twitter "Click to share on Twitter"
  [2]: https://perl6.online/2018/02/02/exploring-the-pick-and-roll-methods-in-perl-6-part-1/?share=facebook "Click to share on Facebook"
  [3]: https://perl6.online/2018/02/02/exploring-the-pick-and-roll-methods-in-perl-6-part-1/?share=google-plus-1 "Click to share on Google+"