Today, a small excursus into the syntax. Did you know that roles in Perl 6 can have a parameter that makes them similar to generic templates in, say, C++? Here’s a small example:

	role R {
	    has $.value;

	    method add($b) {
	        $.value + $b.value
	    }

	    method div($b) {
	        $.value / $b.value
	    }
	}

The R role defines an interface that has a value and two methods for arithmetical operations: add and div.

Now, create a class using the role, initialise two variables and use the methods to get the results:

	class C does R {}

	my C $x = C.new(value =&gt; 10);
	my C $y = C.new(value =&gt; 3);

	say $x.add($y); _# 13_
	say $x.div($y); _# 3.333333_

Although the values here were integers, Perl did a good job and returned a rational number for the division. You can easily see it by calling the WHAT method:

	say $x.add($y).WHAT; _# (Int)_
	say $x.div($y).WHAT; _# (Rat)_

If you have two integers, the result of their division is always of the Rat type. The actual operator, which is triggered in this case, is the one from src/core/Rat.pm:

	multi sub infix:&lt;/&gt;(Int \a, Int \b) {
	    DIVIDE_NUMBERS a, b, a, b
	}

The DIVIDE\_NUMBERS sub returns a Rat value.

## Defining a role

How to modify the C class so that it performs integer division? One of the options is to use a parameterised role:

	role R**[::T]** {
	    has **T** $.value;

	    method add($b) {
	        **T**.new($.value + $b.value)
	    }

	    method div($b) {
	        **T**.new($.value / $b.value)
	    }
	}

The parameter in square brackets after the role name restricts both the type of the $.value attribute and the return type of the methods, which return a new object of the type T. Here, in the template of the role, T is just a name, which should later be specified when the role is used.

## Using the role

So, let’s make it integer:

	class N does R**[Int]** {}

Now the parts of the role that employ the T name replace it with Int, so the class is equivalent to the following definition:

	class C {
	    has **Int** $.value;

	    method add($b) {
	        **Int**.new($.value + $b.value)
	    }

	    method div($b) {
	        **Int**.new($.value / $b.value)
	    }
	}

The new class operates with integers, and the result of the division is an exact 3:

	class N does R[**Int**] {}

	my N $i = N.new(value =&gt; 10);
	my N $j = N.new(value =&gt; 3);

	say $i.add($j); _# 13_
	say $i.div($j); _# 3_

It is also possible to force floating-point values by instructing the role accordingly:

	class F does R[**Num**] {}

	my F $x = F.new(value =&gt; 10e0);
	my F $y = F.new(value =&gt; 3e0);

	say $x.add($y); _# 13_
	say $x.div($y); _# 3.33333333333333_

Notice that both values, including 13, are of the Num type now, not Int or Rat as it was before:

	say $x.add($y).WHAT; _# (Num)_
	say $x.div($y).WHAT; _# (Num)_

### Share this:

* [Twitter][1]
* [Facebook][2]
* [Google][3]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2018/01/06/parameterised-roles-in-perl-6/?share=twitter "Click to share on Twitter"
  [2]: https://perl6.online/2018/01/06/parameterised-roles-in-perl-6/?share=facebook "Click to share on Facebook"
  [3]: https://perl6.online/2018/01/06/parameterised-roles-in-perl-6/?share=google-plus-1 "Click to share on Google+"