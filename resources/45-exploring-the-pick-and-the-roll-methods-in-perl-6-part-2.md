Today, we continue examining the internals of the pick and roll methods. Yesterday, [we discovered][1] how they work without arguments. It is time to see what the methods do to return multiple values.

We start with roll, as it is simpler as it does not care about returning unique elements. The roll($N) is a separate multi-sub with quite a few lines of code:

	multi method roll(\number) {
	    number == Inf
	        ?? self.roll(*)
	        !! self.is-lazy
	        ?? X::Cannot::Lazy.new(:action('.roll from')).throw
	        !! self.elems   # this allocates/reifies
	            ?? Seq.new(class :: does Iterator {
	                    has $!list;
	                    has Int $!elems;
	                    has int $!todo;
	                    method !SET-SELF(\list,\todo) {
	                        $!list := nqp::getattr(list,List,'$!reified');
	                        $!elems = nqp::elems($!list);
	                        $!todo  = todo;
	                        self
	                    }
	                    method new(\list,\todo) {
	                        nqp::create(self)!SET-SELF(list,todo)
	                    }
	                    method pull-one() is raw {
	                        if $!todo {
	                            $!todo = $!todo - 1;
	                            nqp::atpos($!list,$!elems.rand.floor)
	                        }
	                        else {
	                            IterationEnd
	                        }
	                    }
	                }.new(self,number.Int))
	            !! Seq.new(Rakudo::Iterator.Empty)
	}

Let us try to understand what is happening here. First, the method delegates its work if the requested number of elements is infinite (we will discuss this case later) and rejects lazy lists with an exception:

	&gt; (1...Inf).roll(10);
	Cannot .roll from a lazy list
	  in block &lt;unit&gt; at &lt;unknown file&gt; line 1

The next check is a test whether the list has no elements: self.elems ??. If there are none, an empty sequence is returned:

	!! Seq.new(Rakudo::Iterator.Empty)

By the way, this result differs from what a roll with no arguments would return for an empty list:

	&gt; say [].roll;
	Nil

	&gt; say [].roll(1);
	()

OK, we cut off all the edge cases and look at the central part of the routine, which is not that simple. Let us dig it step by step. First, a new sequence is prepared — it will be returned to the calling code.

	**Seq.new(**

	**)**

What do we see between the parentheses? A new object is created:

	Seq.new(             
	    **{**

	**    }.new(self,number.Int)**
	)

What kind of object? This object is an instance of the anonymous class that implements the Iterator role.

	Seq.new(             
	    **class :: does Iterator** {

	    }.new(self,number.Int)
	)

Finally, the class is filled with its attributes and methods. The role dictates the newly-built class to have some predefined methods, such as pull-one. The name suggests that the method returns one element each time it is called.

	method pull-one() is raw {
	    if $!todo {
	        $!todo = $!todo - 1;
	        nqp::atpos($!list,$!elems.rand.floor)
	    }
	    else {
	        IterationEnd
	    }
	}

You may immediately understand how this works if I tell you that the $!todo attribute is an integer which is set to the value that was passed to the roll method. Thus, it works as a countdown counter. When zero is reached, IterationEnd is returned (which [means to stop][2] making more calls of pull-one).

You can trace the initialisation of the attributes in the anonymous class constructor as an exercise.

### Share this:

* [Twitter][3]
* [Facebook][4]
* [Google][5]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2018/02/02/exploring-the-pick-and-roll-methods-in-perl-6-part-1/
  [2]: https://docs.perl6.org/type/Iterator#IterationEnd
  [3]: https://perl6.online/2018/02/03/45-exploring-the-pick-and-the-roll-methods-in-perl-6-part-2/?share=twitter "Click to share on Twitter"
  [4]: https://perl6.online/2018/02/03/45-exploring-the-pick-and-the-roll-methods-in-perl-6-part-2/?share=facebook "Click to share on Facebook"
  [5]: https://perl6.online/2018/02/03/45-exploring-the-pick-and-the-roll-methods-in-perl-6-part-2/?share=google-plus-1 "Click to share on Google+"