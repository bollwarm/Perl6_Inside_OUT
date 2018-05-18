First of all, a new release of the Rakudo Perl 6 compiler was announced today: [2018\.02][1]. There are many fixes and speed improvements there, including one [proposed by me][2]. Let me not go through the changes, as most of them require quite in-depth knowledge of the Rakudo internals.

Instead, let us take a low-hanging fruit and look at the feature that you may see almost immediately when you start reading Rakudo sources.

Ideologically, Perl 6 can (and should) be written in Perl 6. Currently, some parts are written in NQP but still, the vast number of data types—located in the src/core directory—are implemented in Perl 6.

The thing is that some classes are not fully defined there. Or their relation to other classes is not explicit. For example, here’s the whole definition of the Sub class:

	my class Sub { # declared in BOOTSTRAP
	    # class Sub is Routine

	}

Not only you don’t see any methods here, but also its hierarchy is defined ‘via comments.’ Of course, Perl 6 is not that smart to read comments saying ‘make this code great and cool,’ so let’s see what’s going on here.

In the source tree, there is the following file: src/Perl6/Metamodel/BOOTSTRAP.nqp, where the above-mentioned relation is built.

The class itself (the Sub name) is declared as a so-called stub in the very beginning of the file:

	my stub Sub metaclass Perl6::Metamodel::ClassHOW { ... };

Now, the name is known but the definition is not yet ready. We have seen a few examples earlier. Here is the part of the Sub class:

	# class Sub is Routine {
	Sub.HOW.add_parent(Sub, Routine);
	Sub.HOW.compose_repr(Sub);
	Sub.HOW.compose_invocation(Sub);

This code lets the user think that the class definition is the following, as the [documentation][3] says:

	class Sub is Routine {
	}

Other examples of Routine children are Method, Submethod, and Macro. The first two are also defined in BOOTSTRAP:

	# class Method is Routine {
	Method.HOW.add_parent(Method, Routine);
	Method.HOW.compose_repr(Method);
	Method.HOW.compose_invocation(Method);

	# class Submethod is Routine {
	Submethod.HOW.add_parent(Submethod, Routine);
	Submethod.HOW.compose_repr(Submethod);
	Submethod.HOW.compose_invocation(Submethod);

The classes themselves are defined in their corresponding files src/core/Method.pm and src/core/Submethod.pm:

	my class Method { # declared in BOOTSTRAP
	    # class Method is Routine

	    multi method gist(Method:D:) { self.name }
	}

	my class Submethod { # declared in BOOTSTRAP
	    # class Submethod is Routine

	    multi method gist(Submethod:D:) { self.name }
	}

Unlike them, the Marco type’s hierarchy is explicitly announced in src/core/Macro.pm:

	my class Macro is Routine {
	}

As you may see, the classes basically introduce their namespaces and do not add many methods to their Routine parent.

The Routine class in its turn is also defined in two places: in src/core/Routine.pm and in BOOTSTRAP.pm.

	my class Routine { # declared in BOOTSTRAP
	    # class Routine is Block
	    # has @!dispatchees;
	    # has Mu $!dispatcher_cache;
	    # has Mu $!dispatcher;
	    # has int $!rw;
	    # has Mu $!inline_info;
	    # has int $!yada;
	    # has Mu $!package;
	    # has int $!onlystar;
	    # has @!dispatch_order;
	    # has Mu $!dispatch_cache;

This time, there are many methods, some of which are added in src/core/Routine.pm using regular Perl 6 syntax, and some are added through BOOTSTRAP in NQP:

In Perl 6:

	method candidates() {
	    self.is_dispatcher ??
	        nqp::hllize(@!dispatchees) !!
	        (self,)
	}

In NQP:

	Routine.HOW.add_method(Routine, 'dispatcher', nqp::getstaticcode(sub ($self) {
	    nqp::getattr(nqp::decont($self),
	        Routine, '$!dispatcher')
	    }));

Similarly, the attributes from comments are created in NQP:

	Routine.HOW.add_attribute(Routine, Attribute.new(:name&lt;@!dispatchees&gt;, :type(List), :package(Routine)));
	Routine.HOW.add_attribute(Routine, Attribute.new(:name&lt;$!dispatcher_cache&gt;, :type(Mu), :package(Routine)));

As far as I understand, such bootstrapping is needed because Rakudo requires some Perl 6 defined before it can compile itself. For example, if you declare Sub’s relation to Routine completely in src/core/Sub.pm, then you get an error when compiling Rakudo:

	**Representation for Sub must be composed before it can be serialized**

### Share this:

* [Twitter][4]
* [Facebook][5]
* [Google][6]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://github.com/rakudo/rakudo/blob/master/docs/announce/2018.02.md
  [2]: https://perl6.online/2018/02/05/47-push-all-optimisation/
  [3]: https://docs.perl6.org/type/Sub
  [4]: https://perl6.online/2018/02/19/61-declared-in-bootstrap/?share=twitter "Click to share on Twitter"
  [5]: https://perl6.online/2018/02/19/61-declared-in-bootstrap/?share=facebook "Click to share on Facebook"
  [6]: https://perl6.online/2018/02/19/61-declared-in-bootstrap/?share=google-plus-1 "Click to share on Google+"