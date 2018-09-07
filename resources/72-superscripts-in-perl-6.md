In Perl 6, you can use superscript indices to calculate powers of numbers, for example:

	&gt; 2⁵
	32

	&gt; 7³
	343

It also works with more than one digit in the superscript:

	&gt; 10¹²
	1000000000000

You can guess that the above cases are equivalent to the following:

	&gt; 2**5
	32
	&gt; 7**3
	343

	&gt; 10**12
	1000000000000

But the question is: How on Earth does it work? Let us find it out.

For the Numeric role, the following operation is defined:

	proto sub postfix:&lt;ⁿ&gt;(Mu $, Mu $) is pure {*}
	multi sub postfix:&lt;ⁿ&gt;(\a, \b) { a ** b }

Aha, that is what we need, and the superscript notation is converted to the simple \*\* operator here.

You can visualise what exactly is passed to the operation by printing the operands:

	multi sub postfix:&lt;ⁿ&gt;(\a, \b) {
	**    nqp::say('# a = ' ~ a);**
	**    nqp::say('# b = ' ~ b);**
	    a ** b
	}

In this case, you’ll see the following output for the test examples above:

	&gt; 2⁵
	# a = 2
	# b = 5

	&gt; 10¹²
	# a = 10
	# b = 12

Now, it is time to understand how the postfix that extracts superscripts works. Its name, ⁿ, written in superscript, should not mislead you. This is not a magic trick of the parser, this is just a name of the symbol, and it can be found in the Grammar:

	token postfix:sym&lt;ⁿ&gt; {
	    &lt;sign=[⁻⁺¯]&gt;? &lt;dig=[⁰¹²³⁴⁵⁶⁷⁸⁹]&gt;+ &lt;O(|%autoincrement)&gt;
	}

You see, this symbol is a sequence of superscripted digits with an optional sign before them. (Did you think of a sign before we reached this moment in the Grammar?)

Let us try negative powers, by the way:

	&gt; say 4⁻³
	# a = 4
	# b = -3
	0.015625

Also notice that the whole construct is treated as a postfix operator. It can also be applied to variables, for example:

	&gt; my $x = 9
	9
	&gt; say $x²
	# a = 9
	# b = 2
	81

So, a digit in superscript is not a part of the variable’s name.

OK, the final part of the trilogy, the code in Actions, which parses the index:

	method postfix:sym&lt;ⁿ&gt;($/) {
	    my $Int := $*W.find_symbol(['Int']);
	    my $power := nqp::box_i(0, $Int);
	    **for $&lt;dig&gt; {**
	**        $power := nqp::add_I(**
	**           nqp::mul_I($power, nqp::box_i(10, $Int), $Int),**
	**           nqp::box_i(nqp::index("⁰¹²³⁴⁵⁶⁷⁸⁹", $_), $Int),**
	**           $Int);**
	**    }**

	    $power := nqp::neg_I($power, $Int)
	        if $&lt;sign&gt; eq '⁻' || $&lt;sign&gt; eq '¯';
	    make QAST::Op.new(:op&lt;call&gt;, :name('&amp;postfix:&lt;ⁿ&gt;'),
	                      $*W.add_numeric_constant($/, 'Int', $power));
	}

As you can see here, it scans the digits and updates the $power variable by adding the value at the next decimal position (it is selected in the code above).

The available characters are listed in a string, and to get its value, the offset in the string is used. The $&lt;dig&gt; match contains a digit, you can see it in the Grammar:

	&lt;dig=[⁰¹²³⁴⁵⁶⁷⁸⁹]&gt;+

### Share this:

* [Twitter][1]
* [Facebook][2]
* [Google][3]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2018/04/05/72-superscripts-in-perl-6/?share=twitter "Click to share on Twitter"
  [2]: https://perl6.online/2018/04/05/72-superscripts-in-perl-6/?share=facebook "Click to share on Facebook"
  [3]: https://perl6.online/2018/04/05/72-superscripts-in-perl-6/?share=google-plus-1 "Click to share on Google+"