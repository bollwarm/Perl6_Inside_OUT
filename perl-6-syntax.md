In Perl 6, you can restrict the content of a variable container by specifying its type, for example:

	my Int $i;

There is only one value in a scalar variable. You can extend the concept to arrays and let its element to keep only integers, as it is done in the next example:

	&gt; my Int @i;
	[]

	&gt; @i.push(42);
	[42]

	&gt; @i.push('Hello');
	Type check failed in assignment to @i;
	expected Int but got Str ("Hello")
	  in block &lt;unit&gt; at &lt;unknown file&gt; line 1

Hashes keeps pairs, so you can specify the type of both keys and values. The syntax is not deductible from the above examples.

First, let us announce the type of the value:

	my Str %s;

Now, it is possible to have strings as values:

	&gt; %s&lt;Hello&gt; = 'World'
	World

	&gt; %s&lt;42&gt; = 'Fourty-two'
	Fourty-two

But it’s not possible to save integers:

	&gt; %s&lt;x&gt; = 100
	Type check failed in assignment to %s;
	expected Str but got Int (100)
	  in block &lt;unit&gt; at &lt;unknown file&gt; line 1

(By the way, notice that in the case of %s&lt;42&gt; the key is a string.)

To specify the type of the second dimension, namely, of the hash keys, give the type in curly braces:

	my %r{Rat};

This variable is also referred to as _object hash_.

Having this, Perl expects you to have Rat keys for this variable:

	&gt; %r&lt;22/7&gt; = pi
	3.14159265358979

	&gt; %r
	{22/7 =&gt; 3.14159265358979}

Attempts to use integers or strings, for example, fail:

	&gt; %r&lt;Hello&gt; = 1
	Type check failed in binding to parameter 'key';
	expected Rat but got Str ("Hello")
	  in block &lt;unit&gt; at &lt;unknown file&gt; line 1

	&gt; %r{23} = 32
	Type check failed in binding to parameter 'key';
	expected Rat but got Int (23)
	  in block &lt;unit&gt; at &lt;unknown file&gt; line 1

Finally, you can specify the types of both keys and values:

	my Str %m{Int};

This variable can be used for translating month number to month names but not vice versa:

	&gt; %m{3} = 'March'
	March

	&gt; %m&lt;March&gt; = 3
	Type check failed in binding to parameter 'key';
	expected Int but got Str ("March")
	  in block &lt;unit&gt; at &lt;unknown file&gt; line 1

In Perl 5, I used to set timeouts using signals (or, at least, that was an easy and predictable way). In Perl 6, you can use promises. Let us see how to do that.

To imitate a long-running task, create an infinite loop that prints its state now and then. Here it is:

	for 1 .. * {
	    .say if $_ %% 100_000;
	}

As soon as the loop gets control, it will never quit. Our task is to stop the program in a couple of seconds, so the timer should be set before the loop:

	Promise.in(2).then({
	    exit;
	});

	for 1 .. * {
	    .say if $_ %% 100_000;
	}

Here, the Promise.in method creates a promise that is automatically kept after the given number of seconds. On top of that promise, using then, we add another promise, whose code will be run after the timeout. The only statement in the body here is exit that stops the main program.

Run the program to see how it works:

	$ time perl6 timeout.pl
	100000
	200000
	300000
	. . .
	3700000
	3800000
	3900000

	real 0m2.196s
	user 0m2.120s
	sys 0m0.068s

The program counts up to about four millions on my computer and quits in two seconds. That is exactly the behaviour we needed.

For comparison, here is the program in Perl 5:

	use v5.10;

	alarm 2;
	$SIG{ALRM} = sub {
	    exit;
	};

	for (my $c = 1; ; $c++) {
	    say $c unless $c % 1_000_000;
	}

(It manages to count up to 40 million, but that’s another story.)

N. B. The examples below require a fresh Rakudo compiler, at least of the version 2017.09.

Discussing parallel computing earlier or later leads to solving race conditions. Let us look at a simple counter that is incremented by two parallel threads:

	my $c = 0;

	await do for 1..10 {
	    start {
	        $c++ for 1 .. 1_000_000
	    }
	}

	say $c;

If you run the program a few times, you will immediately see that the results are very different:

	$ perl6 atomic-1.pl
	3141187
	$ perl6 atomic-1.pl
	3211980
	$ perl6 atomic-1.pl
	3174944
	$ perl6 atomic-1.pl
	3271573

Of course, the idea was to increase the counter by 1 million in all of the ten threads, but about ⅓ of the steps were lost. It is quite easy to understand why that happens: the parallel threads read the variable and write to it ignoring the presence of other threads and not thinking that the value can be changed in-between. Thus, some of the threads work with an outdated value of the counter.

Perl 6 offers a solution: atomic operations. The syntax of the language is equipped with the _Atom Symbol_ (U+0x269B) ⚛ character (no idea of why it is displayed in that purple colour). Instead of $c++, you should type $c⚛++.

	my **atomicint** $c = 0;

	await do for 1..10 {
	    start {
	        $c⚛++ for 1 .. 1_000_000
	    }
	}

	say $c;

And before thinking of the necessity to use a Unicode character, let us look at the result of the updated program:

	$ perl6 atomic-2.pl
	10000000

This is exactly the result we wanted!

Notice also, that the variable is declared as a variable of the atomicint type. That is a synonym for int, which is a [_native_ integer][1] (unlike Int, which is a data type represented by a Perl 6 class).

It is not possible to ask a regular value to be atomic. That attempt will be rejected by the compiler:

	$ perl6 -e'my $c; $c⚛++'
	Expected a modifiable native int argument for '$target'
	  in block  at -e line 1

A few other operators can be atomic, for example, prefix and postfix increments and decrements ++ and --, or += and -=. There are also atomic versions of the assignment operator = and the one for reading: ⚛ _(sic!)_.

If you need atomic operations in your code, you are not forced to use the ⚛ character. There exists a bunch of alternative functions that you can use instead of the operators:

	my atomicint $c = 1;

	my $x = ⚛$c;  $x = atomic-fetch($c);
	$c ⚛= $x;     atomic-assign($c, $x);
	$c⚛++;        atomic-fetch-inc($c);
	$c⚛--;        atomic-fetch-dec($c);
	++⚛$c;        atomic-inc-fetch($c);
	--⚛$c;        atomic-dec-fetch($c);
	$c ⚛+= $x;    atomic-fetch-add($c,$x);

	say $x; _# 1_
	say $c; _# 3_

When you print an object, say, as say $x, Perl 6 calls the gist method. This method is defined for all built-in types: for some of them, it calls the Str method, for some the perl method, for some types it makes the string representation somehow differently.

Let us see how you can use the method to create your own variant:

	class X {
	    has $.value;

	    method gist {
	        '[' ~ $!value ~ ']'
	    }
	}

	my $x = X.new(value =&gt; 42);

	say $x; _# [42]_
	$x.say; _# [42]_

When you call say, the program prints a number in square brackets: [42].

Please notice that the interpolation inside double-quoted strings is using Str, not gist. You can see it here:

	say $x.Str; _# X&lt;140586830040512&gt;_
	say "$x";   _# X&lt;140586830040512&gt;_

If you need a custom interpolation, redefine the Str method:

	class X {
	    has $.value;

	    method gist {
	        '[' ~ $!value ~ ']'
	    }
	    method Str {
	        '"' ~ $!value ~ '"'
	    }
	}

	my $x = X.new(value =&gt; 42);

	say $x;     _# [42]_
	$x.say;     _# [42]_

	say $x.Str; _# "42"_
	say "$x";   _# "42"_

Now, we got the desired behaviour.

Before digging into the details of the [EVAL routine][2], we have to reveal some more information [about protos][3] and multiple dispatch. Examine the following program:

	proto sub f($x) {
	    say "proto f($x)";
	}

	multi sub f($x) {
	    say "f($x)"
	}

	multi sub f(Int $x) {
	    say "f(Int $x)"
	}

	multi sub f(Str $x) {
	    say "f(Str $x)"
	}

	f(2);
	f('2');
	f(3);
	f('3');

Here, there are three multi-candidates of the function plus a function declared with the proto keyword. Earlier, we only saw such proto-functions with empty body, such as:

	proto sub f($x) {*}

But this is not a necessity. The function can carry a regular load, as we see in the example:

	proto sub f($x) {
	    say "proto f($x)";
	}

Run the program:

	proto f(2)
	proto f(2)
	proto f(3)
	proto f(3)

All the calls were caught by the proto-candidate. Now, update it and return the \{\*\} block for some dedicated values;

	proto sub f($x) {
	    if $x.Str eq '3' {
	        return {*}
	    }
	    say "proto f($x)";
	}

The if check triggers its block for the last two function calls:

	f(3);
	f('3');

In these cases, the proto-function returns \{\*\}, which makes Perl 6 trying other candidates. As we have enough candidates for both integer and string arguments, the compiler can easily choose one of them:

	proto f(2)
	proto f(2)
	f(Int 3)
	f(Str 3)

The EVAL routine in Perl 6 compiles and executes the code that it gets as an argument.  Today, we will see some potential use cases that you may try in your practice. Tomorrow, we will dig into Rakudo sources to see how it works and why it breaks sometimes.

## 1

Let us start with evaluating a simple program:

	EVAL('say 123');

This program prints 123, there’s no surprise here.

## 2

There are, though, more complicated cases. What, do you think, does the following program print?

	EVAL('say {456}');

I guess it prints not what you expected:

	-&gt; ;; $_? is raw { #`(Block|140570649867712) ... }

It parses the content between the curly braces as a pointy block.

## 3

What if you try double quotes?

	EVAL("say {789}");

Now it even refuses to compile:

	===SORRY!=== Error while compiling eval.pl
	EVAL is a very dangerous function!!! (use the MONKEY-SEE-NO-EVAL pragma to override this error,
	but only if you're VERY sure your data contains no injection attacks)
	at eval.pl:6
	------&gt; EVAL("say {789}")⏏;

## 4

We can fix the code by adding a few magic words:

	use MONKEY-SEE-NO-EVAL;

	EVAL("say {789}");

This time, it prints 789.

## 5

The code is executed (we don’t know yet when exactly, that is the topic of tomorrow’s post), so you can make some calculations, for example:

	use MONKEY-SEE-NO-EVAL;

	EVAL("say {7 / 8 + 9}"); _# 9.875_

## 6

Finally, if you try passing a code block directly, you also cannot achieve the goal, even with a blind monkey:

	use MONKEY-SEE-NO-EVAL;

	EVAL {say 123};

The error happens at runtime:

	Constraint type check failed in binding to parameter '$code';
	expected anonymous constraint to be met but got
	-&gt; ;; $_? is raw { #`...
	  in block &lt;unit&gt; at eval.pl line 10

This message looks cryptic, but at least we see once again that we got an anonymous pointy block passed to the function.

## 7

And before we wrap up for today, an attempt to use Perl 5 syntax:

	eval('say 42');

There is no such function in Perl 6, and we get a standard error message:

	===SORRY!=== Error while compiling eval2.pl
	Undeclared routine:
	  eval used at line 5. Did you mean 'EVAL', 'val'?

It looks OK but it can be better.

Stay tuned, tomorrow we will try to understand how all these examples work in Rakudo.

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

  [1]: https://perl6.online/2018/01/15/26-native-integers-and-uint-in-perl-6/
  [2]: https://perl6.online/2018/02/20/62-the-eval-routine-in-perl-6-part-1/
  [3]: https://perl6.online/2017/12/21/the-proto-keyword/