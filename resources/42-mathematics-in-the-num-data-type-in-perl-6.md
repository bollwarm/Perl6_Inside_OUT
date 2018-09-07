The first full month of Perl 6 blogging is over. Daily Perl 6 insights of [perl6.online][1]:

![Screen Shot 2018-01-31 at 21.54.55][2]

And a sister story of [perl6.ru][3], where I write about the ‘user-level’ elements of Perl 6.

![Screen Shot 2018-01-31 at 21.55.04.png][4]

My original plan was to have the whole year of posts, so about 1/12 is done.

Let us look at the Num class, specifically at its mathematical elements. So, our focus is mainly on the src/core/Num.pm file today.

## Constants

First of all, we see a few definitions of mathematical constants:

	my constant tau = 6.28318_53071_79586_476e0;
	my constant pi  = 3.14159_26535_89793_238e0;
	my constant e   = 2.71828_18284_59045_235e0;

As the constants are written in the scientific notation, they are all Nums. The alternative Unicode spellings are presented next to these definitions:

	my constant π := pi;
	my constant τ := tau;
	#?if moar
	my constant 𝑒 := e;
	#?endif

It looks like 𝑒 is MoarVM-specific only. Also, notice that these names are bindings to the ASCII ones, not their copies.

## Functions

A lot of trigonometric functions are defined for the Num class. Mostly, they look alike, so let us see at one of the examples, the sine function.

Functions exist as methods of the class:

	my class Num does Real {
	    . . .
	    proto method sin(|) {*}
	    multi method sin(Num:D: ) {
	        nqp::p6box_n(nqp::sin_n(nqp::unbox_n(self)));
	    }
	    . . .
	}

Also, each method is duplicated as a standalone subroutine:

	multi sub sin(num $x --&gt; num) {
	    nqp::sin_n($x);
	}

You should immediately notice that the argument of the subroutine, unlike the one of the method, is a native type.

There are other variants of the sin function in src/core/Numeric.pm:

	proto sub sin($) is pure {*}
	multi sub sin(Numeric \x) { x.sin }
	multi sub sin(Cool \x) { x.Numeric.sin }

Also, there is a method in the Cool class:

	my class Cool {
	    . . .
	    method sin() { self.Numeric.sin }
	    . . .
	}

Finally, the Real role is also equipped with the method:

	my role Real does Numeric {
	    . . .
	    method sin() { self.Bridge.sin }
	    . . .
	}

The Bridge method is used here, which is our friend from the [previous material][5].

On the JIT level of MoarVM, such functions are linked directly to the C library (if I understand if correctly):

	case MVM_OP_sin_n: return sin;
	case MVM_OP_cos_n: return cos;
	case MVM_OP_tan_n: return tan;
	case MVM_OP_asin_n: return asin;
	case MVM_OP_acos_n: return acos;
	case MVM_OP_atan_n: return atan;

## Exercise

As an exercise, trace the calls for the following code:

	say pi.sin;
	say 3.sin;

	say sin(3);
	say sin(pi);

	say 3.14.sin;
	say sin(3.14);

	say 314e-2.sin;
	say sin(314e-2);

### Share this:

* [Twitter][6]
* [Facebook][7]
* [Google][8]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online
  [2]: https://inperl6.files.wordpress.com/2018/01/screen-shot-2018-01-31-at-21-54-55.png?w=1100
  [3]: https://perl6.ru
  [4]: https://inperl6.files.wordpress.com/2018/01/screen-shot-2018-01-31-at-21-55-04.png?w=1100
  [5]: https://perl6.online/2018/01/22/33-the-cmp-infix-in-perl-6/
  [6]: https://perl6.online/2018/01/31/42-mathematics-in-the-num-data-type-in-perl-6/?share=twitter "Click to share on Twitter"
  [7]: https://perl6.online/2018/01/31/42-mathematics-in-the-num-data-type-in-perl-6/?share=facebook "Click to share on Facebook"
  [8]: https://perl6.online/2018/01/31/42-mathematics-in-the-num-data-type-in-perl-6/?share=google-plus-1 "Click to share on Google+"