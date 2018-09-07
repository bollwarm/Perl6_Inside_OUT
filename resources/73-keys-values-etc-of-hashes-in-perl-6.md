Today, we will take a look at a few methods of the Hash class that return all hash keys or values or both:

	&gt; my %h = H =&gt; 'Hydrogen', He =&gt; 'Helium', Li =&gt; 'Lithium';
	{H =&gt; Hydrogen, He =&gt; Helium, Li =&gt; Lithium}

	&gt; %h.**keys**;
	(H Li He)

	&gt; %h.**values**;
	(Hydrogen Lithium Helium)

	&gt; %h.**kv**;
	(H Hydrogen Li Lithium He Helium)

While you may want to go directly to the src/core/Hash.pm6 file to see the definitions of the methods, you will not find them there. The Hash class is a child of Map, and all these methods are defined in src/core/Map.pm6. Getting keys and values is simple:

	multi method keys(Map:D:) {
	    Seq.new(Rakudo::Iterator.Mappy-keys(self))
	}

	multi method values(Map:D:) {
	    Seq.new(Rakudo::Iterator.Mappy-values(self))
	}

For the kv method, more work has to be done:

	multi method kv(Map:D:) {
	    Seq.new(class :: does Rakudo::Iterator::Mappy {
	        has int $!on-value;

	        method pull-one() is raw {
	            . . .
	        }
	        method skip-one() {
	            . . .
	        }
	        method push-all($target --&gt; IterationEnd) {
	            . . .
	        }
	    }.new(self))
	}

As you see, the method returns a sequence that is built using an anonymous class implementing the Rakudo::Iterator::Mappy role. We already saw how this approach is used in combination with [defining pull-one and push-all methods][1].

Let us look at another set of methods, pairs and antipairs. One of them is simple and straightforward:

	multi method pairs(Map:D:) {
	    Seq.new(self.iterator)
	}

Another one is using an intermediate class:

	multi method antipairs(Map:D:) {
	    Seq.new(class :: does Rakudo::Iterator::Mappy {
	        method pull-one() {
	            . . .
	        }
	        method push-all($target --&gt; IterationEnd) {
	        . . .
	        }
	    }.new(self))
	}

Both methods produce results of the same structure:

	&gt; %h.**antipairs**
	(Hydrogen =&gt; H Lithium =&gt; Li Helium =&gt; He)

	&gt; %h.**pairs**
	(H =&gt; Hydrogen Li =&gt; Lithium He =&gt; Helium)

### Share this:

* [Twitter][2]
* [Facebook][3]
* [Google][4]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2018/02/05/47-push-all-optimisation/
  [2]: https://perl6.online/2018/04/07/73-keys-values-etc-of-hashes-in-perl-6/?share=twitter "Click to share on Twitter"
  [3]: https://perl6.online/2018/04/07/73-keys-values-etc-of-hashes-in-perl-6/?share=facebook "Click to share on Facebook"
  [4]: https://perl6.online/2018/04/07/73-keys-values-etc-of-hashes-in-perl-6/?share=google-plus-1 "Click to share on Google+"