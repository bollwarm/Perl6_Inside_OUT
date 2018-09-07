Today, we are continuing reading the source codes of the Bool class: src/core/Bool.pm, and will look at the methods that calculate the next or the previous values, or increment and decrement the values. For the Boolean type, it sounds simple, but you still have to determine the behaviour of the edge cases.

## pred and succ

In Perl 6, there are two complementary methods: pred and succ that should return, correspondingly, the preceding and the succeeding values. This is how they are defined for the Bool type:

	Bool.^add_method('pred', my method pred() { Bool::False });
	Bool.^add_method('succ', my method succ() { Bool::True });

As you see, these methods are regular (not multi) methods and do not distinguish between defined or undefined arguments. The result neither depends on the value!

If you take two Boolean variables, one set to False and another to True, the prec method returns False for both variables:

	my Bool $f = False;
	my Bool $t = True;
	my Bool $u;

	say $f.pred;    _# False_
	say $t.pred;    _# False_
	say $u.pred;    _# False_
	say False.pred; _# False_
	say True.pred;  _# False_

Similarly, the succ method always returns True:

	say $f.succ;    _# True_
	say $t.succ;    _# True_
	say $u.succ;    _# True_
	say False.succ; _# True_
	say True.succ;  _# True_

## Increment and decrement

The variety of the ++ and -- operations is even more, as another dimension—prefix or postfix—is added.

First, the two prefixal forms:

	multi sub prefix:&lt;++&gt;(Bool $a is rw) { $a = True; }
	multi sub prefix:&lt;--&gt;(Bool $a is rw) { $a = False; }

When you read the sources, you start slowly understand that many strangely behaving bits of the language may be well explained, because the developers have to think about huge combinations of arguments, variables, positions, etc., about which you may not even think when using the language.

The prefix forms simply set the value of the variable to either True or False, and it happens for both defined and undefined variables. The is rw trait allows modifying the argument.

Now, the postfix forms. This time, the state of the variable matters.

	multi sub postfix:&lt;++&gt;(Bool:U $a is rw --&gt; False) { $a = True }
	multi sub postfix:&lt;--&gt;(Bool:U $a is rw) { $a = False; }

We see a new element of syntax—the return value is mentioned after an arrow in the sub signature:

	(Bool:U $a is rw --&gt; False)

The bodies of the operators that work on defined variables, are wordier. If you look at the code precisely, you can see that it avoids assigning the new value to a variable if, for example, a variable containing True is incremented.

	multi sub postfix:&lt;++&gt;(Bool:D $a is rw) {
	    if $a {
	        True
	    }
	    else {
	        $a = True;
	        False
	    }
	}

	multi sub postfix:&lt;--&gt;(Bool:D $a is rw) {
	    if $a {
	        $a = False;
	        True
	    }
	    else {
	        False
	    }
	}

As you see, the changed value of the variable after the operation may be different from what the operator returns.

### Share this:

* [Twitter][1]
* [Facebook][2]
* [Google][3]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2017/12/25/exploring-the-bool-type-part-2/?share=twitter "Click to share on Twitter"
  [2]: https://perl6.online/2017/12/25/exploring-the-bool-type-part-2/?share=facebook "Click to share on Facebook"
  [3]: https://perl6.online/2017/12/25/exploring-the-bool-type-part-2/?share=google-plus-1 "Click to share on Google+"