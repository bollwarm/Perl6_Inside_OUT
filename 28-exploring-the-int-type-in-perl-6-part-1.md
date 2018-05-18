Actually, we already [started looking][1] at the internals of the Int data type two days ago, but today we’ll start from the very beginning.

So, the Int data type. It is a great data type for practical programming and it is also widely used in Rakudo itself. For example, the Rational object is an object that keeps two Int values (it may be an [Int plus uint][2] one day but let us not focus on that today).

On a big scale, an Int is a Real:

	my class Int does Real {
	    . . .
	}

At this point, I was always confused. I am not sure if I have this paradox only in my mind, but I always treated integers as being less rich data type than real numbers. On the other side, all properties of integers also exist for real numbers and it would be strange not to inherit them. (Well, as a side story, the object-oriented terminology is extremely vague if you say _subclass_ and _superclass_ instead of _child_ and _parent_.)

The actual value is contained in the private attribute $!value, which is defined somewhere on a deeper level but is directly used in src/core/Int.pm. The value is set in one of the constructors:

	proto method new(|) {*}
	multi method new( **\value**) { self.new: **value.Int** }
	multi method new(int **\value**) {
	    # rebox the value, so we get rid of any potential mixins
	    nqp::fromI_I(nqp::decont(**value**), self)
	}
	multi method new(Int:D **\value** = 0) {
	    # rebox the value, so we get rid of any potential mixins
	    nqp::fromI_I(nqp::decont(**value**), self)
	}

Then, a bunch of simple but useful methods for type conversion follows.

	multi method Bool(Int:D:) {
	    nqp::p6bool(nqp::bool_I(self));
	}

	method Int() { self }

	multi method Str(Int:D:) {
	    nqp::p6box_s(nqp::tostr_I(self));
	}

	method Num(Int:D:) {
	    nqp::p6box_n(nqp::tonum_I(self));
	}

	method Rat(Int:D: $?) {
	    Rat.new(self, 1);
	}
	method FatRat(Int:D: $?) {
	    FatRat.new(self, 1);
	}

All these methods operate with the only Int object, so you may be confused by the fact that most of the methods still take an argument. The colon after the type means that this is not a regular function parameter but an invocant, i.e. the object on which you call the given method.

The following test program should clarify the syntax:

	class X {
	    has $.value;

	    method a() {
	        say $!value
	    }
	    method b(X $x) {
	        say $x.value
	    }
	    method c(X $x:) {
	        say $x.value
	    }
	}

	my X $x = X.new(value =&gt; 42);
	my X $y = X.new(value =&gt; 43);

	$x.a();   _# 42_
	$x.b($y); _# 43_
	$x.c();   _# 42_

The three methods print the value of the only attribute. In the first case, the method has no parameters and $!value refers to the attribute of the object in hand. In the second case, the argument of the method is a different variable, which is not connected with the object on which the method is called. Finally, the third method demonstrates how you introduce an invocant in the method signature. This method behaves exactly like the first one.

So, return to the Int class. There are no questions about the logic of the methods. Some of them are implemented via NQP functions. The most charming method in the series is Int(), which just returns self. (Homework: re-write the method using an invocant in the signature.)

Moving further.

	method Bridge(Int:D:) {
	    nqp::p6box_n(nqp::tonum_I(self));
	}

This is another very interesting method. If you grep for its name, you will see that the method is used as a polymorphic method:

	src/core/Real.pm: method sqrt() { self.Bridge.sqrt }
	src/core/Real.pm: method rand() { self.Bridge.rand }
	src/core/Real.pm: method sin()  { self.Bridge.sin }
	src/core/Real.pm: method asin() { self.Bridge.asin }
	src/core/Real.pm: method cos()  { self.Bridge.cos }
	src/core/Real.pm: method acos() { self.Bridge.acos }
	src/core/Real.pm: method tan()  { self.Bridge.tan }
	src/core/Real.pm: method atan() { self.Bridge.atan }

It is implemented in other classes, too. For example, in the Num class, which is also a descendant of Real:

	my class Num does Real {
	    method Bridge(Num:D:) { self }
	}

OK, enough of the easy stuff for today 🙂 Let us dig deeper tomorrow.

### Share this:

* [Twitter][3]
* [Facebook][4]
* [Google][5]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2018/01/15/26-native-integers-and-uint-in-perl-6/
  [2]: https://github.com/rakudo/rakudo/commit/6977680bd9137801f2c43ec90a3a29f9e9f996ce
  [3]: https://perl6.online/2018/01/17/28-exploring-the-int-type-in-perl-6-part-1/?share=twitter "Click to share on Twitter"
  [4]: https://perl6.online/2018/01/17/28-exploring-the-int-type-in-perl-6-part-1/?share=facebook "Click to share on Facebook"
  [5]: https://perl6.online/2018/01/17/28-exploring-the-int-type-in-perl-6-part-1/?share=google-plus-1 "Click to share on Google+"