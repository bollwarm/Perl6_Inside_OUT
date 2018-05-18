Yesterday, we saw that the ternary operator is treated as an infix in the Perl 6 Grammar. The code between the two parts of the operator is caught by the &lt;EXPR&gt; method:

	token infix:sym&lt;?? !!&gt; {
	    :my $*GOAL := '!!';
	    $&lt;sym&gt;='??'
	    &lt;.ws&gt;
	**    &lt;EXPR('i=')&gt;**
	    [ '!!'
	    . . .
	    ]
	    &lt;O(|%conditional, :reducecheck&lt;ternary&gt;, :pasttype&lt;if&gt;)&gt;
	}

Now, our attraction comes to O. Namely, to its reducecheck named argument. It passes some information about the fact that this is a ternary operator.

Now, move to the next level of the compiler, to NQP, and examine the nqp/src/HLL/Grammar.nqp file, and specifically, the following method of the HLL::Grammar class there:

	method EXPR_reduce(@termstack, @opstack) {
	    . . .

	    else { # infix op assoc: left|right|ternary|...
	        $op[1] := nqp::pop(@termstack); # right
	        $op[0] := nqp::pop(@termstack); # left

	        $reducecheck := nqp::atkey(%opO, 'reducecheck');
	        self."$reducecheck"($op) unless nqp::isnull($reducecheck);
	        $key := 'INFIX';
	    }

	    self.'!reduce_with_match'('EXPR', $key, $op);
	}

This is only a fragment but even this tiny part contains a few interesting details.

First, we see that the else branch handles not only the ternary operator but also some others. The left and the right operands are taken from some stack and saved in $op.

Another interesting thing is the method call:

	self."$reducecheck"($op)

The name of the method is stored in the $reducecheck variable and for the ternary operator, it should contain ternary.

Here is the method:

	method ternary($match) {
	    $match[2] := $match[1];
	    $match[1] := **$match{'infix'}{'EXPR'}**;
	}

Some swap magic here that we can ignore for now, but what is important is that the infix’s EXPR match is read here. Finally, we spotted all the three operands of the ?? !! operator.

Return to the last line of the EXPR\_recude method:

	self.'!reduce_with_match'('EXPR', $key, $op);

Again, a method is called here; this time the name starts with the exclamation mark. The $op parameter contains the left and the right operands; the value of $key is INFIX.

At this point you should recall that Perl 6 is using a virtual machine, so to see where the actual comparison happens, you have to dig further to the MoarVM assembly tree, which we will not do today. Meanwhile, briefly lurk into nqp/src/QRegex/Cursor.nqp to trace the above call further:

	role NQPMatchRole is export {
	    . . .
	    method !reduce_with_match(str $name, str $key, $match) {
	        my $actions := self.actions;
	        **nqp::findmethod($actions, $name)($actions, $match, $key)**
	        if !nqp::isnull($actions) &amp;&amp; nqp::can($actions, $name);
	    }
	    . . .

The highlighted line with two parentheses in a row is a call of the routine that is returned by nqp::findmethod.

Let us return back to the higher level of the compiler. If you want to visualise the data flow and print the variables, make sure you start the line with a hash character. This is needed because some of the code lands in the gen/moar directory as a collection of generated files and all your printouts will be compiled again. So, hide them from the compiler.

	else { # infix op assoc: left|right|ternary|...
	    $op[1] := nqp::pop(@termstack); # right
	    $op[0] := nqp::pop(@termstack); # left

	**    nqp::say("#left =" ~ $op[0]);**
	**    nqp::say("#right=" ~ $op[1]);**

	    $reducecheck := nqp::atkey(%opO, 'reducecheck');
	    self."$reducecheck"($op) unless nqp::isnull($reducecheck);
	    $key := 'INFIX';
	}

	. . .

	method ternary($match) {
	**    nqp::say('#match=' ~ $match);**
	**    nqp::say('#before 1='~ $match[1]);**
	**    nqp::say('#before 2='~ $match[2]);**
	    $match[2] := $match[1];
	    $match[1] := $match{'infix'}{'EXPR'};
	**    nqp::say('#after 1='~ $match[1]);**
	**    nqp::say('#after 2='~ $match[2]);**
	}

Recompile everything:

	$ cd nqp
	$ make clean
	$ make
	$ make install
	$ cd ..
	$ make clean
	$ make

And run a program with a trivial ternary condition:

	$ ./perl6 -e'say 2 ?? 3 !! 4'
	#left =2
	#right=4
	#match=?? 3 !!
	#before 1=4
	#before 2=
	#after 1=3
	#after 2=4
	3

Great! Today, it was a deep dive into the compiler, and I hope it gave you an understanding of how the ternary operator treats its three operands in Perl 6.

### Share this:

* [Twitter][1]
* [Facebook][2]
* [Google][3]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2018/01/12/23-the-internals-of-the-ternary-operator-in-perl-6/?share=twitter "Click to share on Twitter"
  [2]: https://perl6.online/2018/01/12/23-the-internals-of-the-ternary-operator-in-perl-6/?share=facebook "Click to share on Facebook"
  [3]: https://perl6.online/2018/01/12/23-the-internals-of-the-ternary-operator-in-perl-6/?share=google-plus-1 "Click to share on Google+"