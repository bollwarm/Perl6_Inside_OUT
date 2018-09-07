Yesterday, we talked about how modification of the value such as [0 but True][1] works in Rakudo Perl 6. Today, we’ll try to fix a missing fragment in the implementation, which does not let you correctly dumping an object with the perl method (there is a [bug report #126097][2] for that).

Let us see what happens now:

	$ perl6
	To exit type 'exit' or '^D'
	&gt; my $v = 0 but True;
	0
	&gt; **$v.perl**
	**0**

The result of calling perl is 0, so the information about the mixed-in Boolean role is lost. Our goal for today is to understand why and how to fix that.

First of all, we should realise which routine is triggered when you call it as $v.perl. If you add a Boolean role, you effectively add the Bool method to the (cloned) object:

	&gt; $v.^methods
	(**Bool** Range asech perl truncate acosech sin ACCEPTS asinh floor abs asec cosec acotan ceiling acos acosec unpolar exp acotanh gist Num round DUMP asin log10 expmod msb FatRat isNaN cotanh atanh sign sqrt Bridge atan2 tan acosh conj narrow base Str Numeric new pred cosh sech log Rat roots cotan sinh tanh is-prime Bool sec Real Int cis cos rand succ chr polymod Capture WHICH lsb cosech Complex atan)

If you mix-in, for example, an integer, you add an Int method:

	&gt; my $x = 0 but 42;
	0
	&gt; $x.Int
	42
	&gt; $x.^methods
	(**Int** Range asech perl truncate acosech sin ACCEPTS asinh floor abs asec cosec acotan ceiling acos acosec unpolar exp acotanh gist Num round DUMP asin log10 expmod msb FatRat isNaN cotanh atanh sign sqrt Bridge atan2 tan acosh conj narrow base Str Numeric new pred cosh sech log Rat roots cotan sinh tanh is-prime Bool sec Real Int cis cos rand succ chr polymod Capture WHICH lsb cosech Complex atan)

In both examples, the perl method comes from the Int class:

	multi method perl(Int:D:) {
	    self.Str;
	}

It knows nothing about the but clause. One of the ways is to modify it so that it tries to test if there are mixed-in roles in the object. Probably, this is not the best solution as it affects all the other objects that might use the method.

Let us solve it differently and instead of teaching the ‘global’ method just add our own method to the object at the moment the but infix is processed. Refer to the [previous post][3] to refresh the details about the infix.

First, add a method that only prints the but part. Add the following lines to the GENERATE-ROLE-FROM-VALUE function:

	my $perl_meth := method () { **" but $val"** };
	$perl_meth.set_name('perl');
	$role.^add_method('perl', $perl_meth);

This is done exactly in the same way as the Bool method would be added for 0 but True.

Compile and test:

	&gt; my $v = 0 but True;
	0
	&gt; $v.perl
	** but True**

It works as expected but, of course, only the alternative value is printed. Also, check the list of the methods on our object:

	&gt; $v.^methods
	(**perl** Bool Range asech **perl** truncate acosech sin ACCEPTS asinh floor abs asec cosec acotan ceiling acos acosec unpolar exp acotanh gist Num round DUMP asin log10 expmod msb FatRat isNaN cotanh atanh sign sqrt Bridge atan2 tan acosh conj narrow base Str Numeric new pred cosh sech log Rat roots cotan sinh tanh is-prime Bool sec Real Int cis cos rand succ chr polymod Capture WHICH lsb cosech Complex atan)

You see that there are two perl methods now. And, actually, to dump the original value, we just need to call the original method and concatenate its result with our additional string. Unfortunately, it is not that easy to do that from the GENERATE-ROLE-FROM-VALUE function as it only takes a value, not the object or its class. You can try using the $?CLASS variable or just copy the body of the function to the infix body, which I did and got the following code. Notice how I call the original perl method:

	multi sub infix:&lt;but&gt;(Mu \obj, Mu:D $val) is raw {
	    my $role := Metamodel::ParametricRoleHOW.new_type();
	    my $meth := method () { $val };
	    $meth.set_name($val.^name);
	    $role.^add_method($meth.name, $meth);

	 **   my $perl_meth := method () { obj.perl ~ " but $val" };
	    $perl_meth.set_name('perl');
	    $role.^add_method('perl', $perl_meth);**

	    $role.^set_body_block(
	        -&gt; |c { nqp::list($role, nqp::hash('$?CLASS', c&lt;$?CLASS&gt;)) });

	    obj.clone.^mixin($role.^compose);
	}

Compile and test:

	&gt; my $v = 0 but True;
	0
	&gt; $v.perl
	**0 but True**

	&gt; $v = 42 but False;
	42
	&gt; $v.perl
	**42 but False**
	&gt; ?$v
	False

The goal has been achieved. The only thing that is not really cool is duplication of code. What if we just pass the prepared version of the perl method to the routine, and it will compose it to the object?

	multi sub infix:&lt;but&gt;(Mu \obj, Mu:D $val) is raw {
	    **my $perl_meth := method () { obj.perl ~ " but $val" };**

	    obj.clone.^mixin(GENERATE-ROLE-FROM-VALUE($val, **$perl_meth**));
	}

	sub GENERATE-ROLE-FROM-VALUE($val, **$perl_meth?**) {
	    my $role := Metamodel::ParametricRoleHOW.new_type();
	    my $meth := method () { $val };
	    $meth.set_name($val.^name);
	    $role.^add_method($meth.name, $meth);

	   ** if $perl_meth {**
	**        $perl_meth.set_name('perl');**
	**        $role.^add_method('perl', $perl_meth);**
	**    }**

	    $role.^set_body_block(
	        -&gt; |c { nqp::list($role, nqp::hash('$?CLASS', c&lt;$?CLASS&gt;)) });
	    $role.^compose;
	}

Here, I pass the method as an optional parameter, as the function is also used in other places.

	$ ./perl6
	To exit type 'exit' or '^D'
	&gt; my $v = 0 but True;
	0

	&gt; $v.perl
	**0 but True**

Alternatively, we could make a multi-method. I will ask what Perl 6 people think in the IRC channel and let you know. Update: I [asked][4] and I won’t fix that 😀

### Share this:

* [Twitter][5]
* [Facebook][6]
* [Google][7]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2018/02/06/48-how-does-0-but-true-work-in-perl-6/
  [2]: https://rt.perl.org/Public/Bug/Display.html?id=126097
  [3]: https://perl6.online/2018/02/06/48-how-does-0-but-true-work-in-perl-6/
  [4]: http://colabti.org/irclogger/irclogger_log/perl6?date=2018-02-08
  [5]: https://perl6.online/2018/02/07/49-dumping-0-but-true-in-perl-6/?share=twitter "Click to share on Twitter"
  [6]: https://perl6.online/2018/02/07/49-dumping-0-but-true-in-perl-6/?share=facebook "Click to share on Facebook"
  [7]: https://perl6.online/2018/02/07/49-dumping-0-but-true-in-perl-6/?share=google-plus-1 "Click to share on Google+"