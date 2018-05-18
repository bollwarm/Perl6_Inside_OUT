[Yesterday][1], we went through the code of the roll($N) method, so it will be easier to examine its brother, pick(N$).

The code lives in src/core/List.pm:

	multi method pick(List:D: $number is copy) {
	    fail X::Cannot::Lazy.new(:action('.pick from')) if self.is-lazy;
	    my Int $elems = self.elems;
	    return () unless $elems;

	    $number = nqp::istype($number,Whatever) || $number == Inf
	        ?? $elems
	        !! $number.UInt min $elems;
	    Seq.new(class :: does Iterator {
	        has $!list;
	        has Int $!elems;
	        has int $!number;

	        method !SET-SELF(\list,$!elems,\number) {
	            $!list  := nqp::clone(nqp::getattr(list,List,'$!reified'));
	            $!number = number + 1;
	            self
	        }
	        method new(\list,\elems,\number) {
	            nqp::create(self)!SET-SELF(list,elems,number)
	        }
	        method pull-one() {
	            if ($!number = nqp::sub_i($!number,1)) {
	                my int $i;
	                my \tmp = nqp::atpos($!list,$i = $!elems.rand.floor);
	                nqp::bindpos($!list,$i,
	                    nqp::atpos($!list,nqp::unbox_i(--$!elems))
	                );
	                tmp
	            }
	            else {
	                IterationEnd
	            }
	        }
	        method push-all($target --&gt; IterationEnd) {
	            my int $i;
	            nqp::while(
	                ($!number = nqp::sub_i($!number,1)),
	                nqp::stmts(  # doesn't sink
	                ($target.push(nqp::atpos($!list,$i = $!elems.rand.floor))),
	                (nqp::bindpos($!list,$i,
	                    nqp::atpos($!list,nqp::unbox_i(--$!elems))))
	                )
	            )
	        }
	    }.new(self,$elems,$number))
	}

As you remember, this method should return non-repeating elements. In the case there are no more of them, it should just stop.

Again, the first action is to check if the array is lazy or the requested number is infinite:

	**fail** X::Cannot::Lazy.new(:action('.pick from')) **if self.is-lazy**;

The check for the number sets the $number variable to either the requested number or, if it was infinite, to the length of the list:

	$number = nqp::istype($number,Whatever) || $number == Inf
	    ?? $elems
	    !! $number.UInt min $elems;

The number cannot be bigger than the maximum value for UInt. Indirectly, a test for non-negativeness is performed in the Cool class:

	multi method UInt() {
	    my $got := self.Int;
	    $got &lt; 0
	        ?? Failure.new(X::OutOfRange.new(
	            :what('Coercion to UInt'),
	            :$got,
	            :range&lt;0..^Inf&gt;))
	        !! $got
	}

So, this case is in the end rejected:

	./perl6 -e'say &lt;a b c&gt;.pick(-1)'
	Coercion to UInt out of range. Is: -1, should be in 0..^Inf
	   in block &lt;unit&gt; at -e line 1

## Pull one

If all the filters passed, we get to the point of creating a new Seq element. As in the roll method, an anonymous class implementing the Iterator role is created. This time, two methods are defined: pull-one and push-all. Let us start with the first of them:

	method pull-one() {
	    if ($!number = nqp::sub_i($!number,1)) {
	        my int $i;
	        my \tmp = nqp::atpos($!list,$i = $!elems.rand.floor);
	        nqp::bindpos($!list,$i,
	            nqp::atpos($!list,nqp::unbox_i(--$!elems))
	        );
	        tmp
	    }
	    else {
	        IterationEnd
	    }
	}

If there is nothing to do, in other words, if the $!number variable reached zero, IterationEnd is returned. If the list is not exhausted, a random element is selected. Let us see how Rakudo makes sure that the selected elements are unique. It is all implemented in the next three lines:

	my \tmp = nqp::atpos($!list,$i = $!elems.rand.floor);
	nqp::bindpos($!list,$i,
	    nqp::atpos($!list,nqp::unbox_i(--$!elems))
	);

Don’t worry, the original data is not changed, as it was cloned as soon as possible:

	method !SET-SELF(\list,$!elems,\number) {
	     $!list := **nqp::clone**(nqp::getattr(list,List,'$!reified'));
	     $!number = number + 1;
	     self
	}

The interesting fact is that to achieve the goal we do not have to iterate over the list to search for the elements that were not used yet. First, a random element is picked:

	my \tmp = nqp::atpos($!list,$i = $!elems.rand.floor);

From this code, you see that it can be any element from the whole list.

Second, the position of the currently chosen element is filled with the value of one of the elements in the tail of a list. At each call, the tail position is moved to the beginning of the list.

Let me show how it works in practice. I added a few lines to visualise the state of a list:

	my \tmp = nqp::atpos($!list,$i = $!elems.rand.floor);
	**nqp::say('$!number=' ~ $!number);**
	**nqp::say('$i=' ~ $i);**

	nqp::bindpos($!list,$i,
	    nqp::atpos($!list,nqp::unbox_i(--$!elems))
	);

	**nqp::say('$!elems=' ~ $!elems);
	nqp::say(nqp::atpos($!list,0) ~**
	**         nqp::atpos($!list,1) ~**
	**         nqp::atpos($!list,2) ~**
	**         nqp::atpos($!list,3) ~**
	**         nqp::atpos($!list,4));**

Of course, it only works with the lists not longer than five elements but that is enough to get the idea:

	$ ./perl6 -e'say &lt;**a b c d e**&gt;.pick(4)'
	$!number=4
	$i=1
	$!elems=4
	**aecde        **_# **b** is taken here_
	$!number=3
	$i=2
	$!elems=3
	**aedde        **_# **c** is taken here and replaces with d_
	$!number=2
	$i=2
	$!elems=2
	**aedde        **_# again, random element is nr. 2 but it is **d** now_
	$!number=1
	$i=1
	$!elems=1
	**aedde        **_# random is at the position we visited_ already,
	             _# but the element is different now: **e**_
	(b c d e)

As you see, at each iteration the ‘used’ element is replaces with another one, which should not be seen yet.

## Push all

The second method defined in the anonymous class is number-all:

	method push-all($target --&gt; IterationEnd) {
	    my int $i;
	    nqp::while(
	        ($!number = nqp::sub_i($!number,1)),
	        nqp::stmts( # doesn't sink
	        ($target.push(nqp::atpos($!list,$i = $!elems.rand.floor))),
	        (nqp::bindpos($!list,$i,
	            nqp::atpos($!list,nqp::unbox_i(--$!elems))))
	        )
	    )
	}

In general, we see the same algorithm here with the only exception that it writes directly to the $target list.

This method is used when you, for example, assign the result to an array. Compare:

	$ ./perl6 -e'say &lt;a b c d e&gt;.pick(4)'
	pull-one
	pull-one
	pull-one
	pull-one
	pull-one
	(c d a b)

	$ ./perl6 -e'my @a = &lt;a b c d e&gt;.pick(4); say @a'
	push-all
	[d e a c]

That’s all for today. Tomorrow, I will demonstrate how to speed up Rakudo Perl 6 by 20%.

### Share this:

* [Twitter][2]
* [Facebook][3]
* [Google][4]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2018/02/03/45-exploring-the-pick-and-the-roll-methods-in-perl-6-part-2/
  [2]: https://perl6.online/2018/02/04/46-exploring-the-pick-and-the-roll-methods-in-perl-6-part-3/?share=twitter "Click to share on Twitter"
  [3]: https://perl6.online/2018/02/04/46-exploring-the-pick-and-the-roll-methods-in-perl-6-part-3/?share=facebook "Click to share on Facebook"
  [4]: https://perl6.online/2018/02/04/46-exploring-the-pick-and-the-roll-methods-in-perl-6-part-3/?share=google-plus-1 "Click to share on Google+"