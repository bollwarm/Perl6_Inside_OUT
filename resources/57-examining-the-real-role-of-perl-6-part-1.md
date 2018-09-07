During the last few days, we talked a lot about the Real role. Lets us then look at it more precisely. The code is located in the src/core/Real.pm file.

It contains the role itself and a few subroutines implementing different infixes. The Real role in its turn implements the Numeric role:

	my role Real does Numeric {
	    . . .
	}

It is interesting that the class definition also needs some knowledge about the Complex class, that’s why there is a forward class declaration in the first line of the file:

	my class Complex { ... }

The Real role defines many trigonometrical functions as methods, and as we already saw, [they are using the Bridge method][1]:

	method sqrt() { self.Bridge.sqrt }
	method rand() { self.Bridge.rand }
	method sin() { self.Bridge.sin }
	method asin() { self.Bridge.asin }
	method cos() { self.Bridge.cos }
	method acos() { self.Bridge.acos }
	method tan() { self.Bridge.tan }
	method atan() { self.Bridge.atan }

Another set of methods include generic methods that manipulate the value directly:

	method abs() { self &lt; 0 ?? -self !! self }
	proto method round(|) {*}
	multi method round(Real:D:) {
	    (self + 1/2).floor; # Rat NYI here, so no .5
	}
	multi method round(Real:D: Real() $scale) {
	    (self / $scale + 1/2).floor * $scale;
	}
	method truncate(Real:D:) {
	    self == 0 ?? 0 !! self &lt; 0 ?? self.ceiling !! self.floor
	}

There’s a really interesting and useful variant of the round method, which allows you to align the number to the grid you need:

	&gt; 11.5.round(3)
	12
	&gt; 10.1.round(3)
	9

Another set of methods are used to convert a number to different data types:

	method Rat(Real:D: Real $epsilon = 1.0e-6) { self.Bridge.Rat($epsilon) }
	method Complex() { Complex.new(self.Num, 0e0) }
	multi method Real(Real:D:) { self }
	multi method Real(Real:U:) {
	    self.Mu::Real; # issue a warning;
	    self.new
	}
	method Bridge(Real:D:) { self.Num }
	method Int(Real:D:) { self.Bridge.Int }
	method Num(Real:D:) { self.Bridge.Num }
	multi method Str(Real:D:) { self.Bridge.Str }

And here we have a problem in the matrix. The Bridge method is defined in such a way that it calls the Num method. In its turn, Num is calling Bridge, which calls Num.

Run one of the following lines of code, and Rakudo will hang:

	Real.new.say;

	Real.new.Str;

### Share this:

* [Twitter][2]
* [Facebook][3]
* [Google][4]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2018/02/11/53-going-over-the-bridge-part-1/
  [2]: https://perl6.online/2018/02/15/57-examining-the-real-role-of-perl-6-part-1/?share=twitter "Click to share on Twitter"
  [3]: https://perl6.online/2018/02/15/57-examining-the-real-role-of-perl-6-part-1/?share=facebook "Click to share on Facebook"
  [4]: https://perl6.online/2018/02/15/57-examining-the-real-role-of-perl-6-part-1/?share=google-plus-1 "Click to share on Google+"