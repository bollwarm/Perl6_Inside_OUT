After a big work that we had yesterday to understand what’s going on when you try to subscript an array with a negative index, let’s see what actually happens behind the new syntax of getting the last element of an array as @a[\*-1].

So, here’s a test program:

	my @a = &lt;a b c&gt;;
	say @a[*-1];

There is an array of three elements and we are printing the last of them.

On the syntax level, \*-1 is a block of code, namely [WhateverCode][1]. Its task is to convert the construction to the index of the last element, in our case, the number 2.

The square brackets after an array name are translated to a postcircumfix:&lt;[ ]&gt; sub call. There is a file in the source tree, src/core/array\_slice.pm, that contains a huge number of different variants of that routine; and the first line advises keeping the file growing.

	# all sub postcircumfix [] candidates here please

The subs are grouped so that you can easily spot the desired ones with a clear comment above the block. Investigating the file, we can find the definition we need. We need a sub that takes a code block:

	# @a[-&gt;{}]
	multi sub postcircumfix:&lt;[ ]&gt;(\SELF, Callable:D $block ) is raw {
	    nqp::stmts(
	      (my $*INDEX = 'Effective index'),
	      SELF[$block.pos(SELF)]
	    )
	}

Just to make it clear, this is how the WhateverCode class relates to the Callable role:

	my class WhateverCode is Code { . . . }
	my class Code does Callable { . . . }

OK, so the \*-1 presence leads to the postcircumfix call above. The nqp::stmts call takes a list of NQP statements to execute. First, some dynamic variable is set to a string (is that efficient, btw?). Then, another postcircumfix call. Let us look at it carefully:

	SELF[$block.pos(SELF)]

What is SELF here? It is a raw reference to the array in hand (see the signature of the postcircumfix sub). So, this line means @a[$block.pos(@a)] in terms of our program, where $block is a WhateverCode block created out of \*-1.

So, we’re subscripting the array again but this time another candidate of postcircumfix:&lt;[ ]&gt; matches:

	# @a[Int 1]
	multi sub postcircumfix:&lt;[ ]&gt;( \SELF, Int:D $pos ) is raw {
	    SELF.AT-POS($pos);
	}

Finally, it calls the AT-POS method that we saw last time. You may have guessed that at this point, the value of $pos is 2 for the three-element array.

Take a step back, as we skipped the $block.pos(SELF) call. The type of the $block is WhateverCode, so look at src/core/WhateverCode.pm. Actually, the only existing method there is pos:

	my class WhateverCode is Code {
	    # helper method for array slicing
	    **method pos(WhateverCode:D $self: \list)** {
	        nqp::if(
	          nqp::iseq_i(
	            nqp::getattr(
	              nqp::getattr($self,Code,'$!signature'),
	              Signature,
	              '$!count'
	         ),1),
	       $self(nqp::if(nqp::isconcrete(list),list.elems,0)),
	       $self(|(nqp::if(nqp::isconcrete(list),list.elems,0)
	         xx nqp::getattr(
	           nqp::getattr($self,Code,'$!signature'),
	           Signature,
	           '$!count'
	         )
	       ))
	      )
	    }
	}

A bit complicated but still let’s try reading it. So, first of all, the method takes a WhateverCode (as an invocant) and a list (as an argument). The nqp::iseq\_i function compares two integers (you read its name as _is eq_, not _int seq_). If there is only one item in the signature, some actions are done with it, if there are more, all of them are touched  and collected with xx.

The line for our example is:

	$self(nqp::if(nqp::isconcrete(list),list.elems,0))

If I am correct, this is a call of the () postcircumfix method on a code block. So, basically, \{\* - 1\} becomes (-&gt;\{\* - 1\})(list.elems). Its argument is the length of the array (nqp::isconcrete checks if list is an object, not a type object, and returns list.elems).

## Exercise 1

So when you understand it (do you?), modify our initial program to explain the syntax to a friend.

Step 1:

	my @a = &lt;a b c&gt;;
	say @a[ **-&gt; {* - 1}.() **]; _# c_

Step 2:

	my @a = &lt;a b c&gt;;
	say @a[ **-&gt; $n {$n - 1}.(@a.elems)** ]; _# __c_

## Exercise 2

Explain the behaviour of the following cases:

	my @a = &lt;a b c&gt;;
	say @a[* - *];         _# a_
	say @a[* - * + * - 1]; _# c_

Answer: In this case, the second branch of $self(...) call is activated. The WhateverCode block wants two or three arguments, and the xx operator simply copies the value of list.elems the needed number of times, and then | flattens the list.

## Some final notes

A couple of tiny notes to the above story.

1\. The $self(...) call for \*-1 also triggers the following sub (defined in src/core/Int.pm) to calculate the result:

	multi sub infix:&lt;-&gt;(Int:D \a, Int:D \b --&gt; Int:D) {
	    nqp::sub_I(nqp::decont(a), nqp::decont(b), Int);
	}

2\. Other forms of using a star for indexing an array also work, for example:

	my @a = &lt;a b c&gt;;
	say @a[**4 - ***]; _# b_

3\. A single \* does not create a WhateverCode block, and another postcircumfix method involving a Whatever object is called instead:

	# @a[*]
	multi sub postcircumfix:&lt;[ ]&gt;( \SELF, **Whatever:D** ) is raw {
	    SELF[^SELF.elems];
	}

In this case, a slice containing the whole array is returned:

	my @a = &lt;a b c&gt;;
	say @a[*]; _# (a b c)_

### Share this:

* [Twitter][2]
* [Facebook][3]
* [Google][4]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://docs.perl6.org/type/WhateverCode
  [2]: https://perl6.online/2018/01/08/digging-into-a-1/?share=twitter "Click to share on Twitter"
  [3]: https://perl6.online/2018/01/08/digging-into-a-1/?share=facebook "Click to share on Facebook"
  [4]: https://perl6.online/2018/01/08/digging-into-a-1/?share=google-plus-1 "Click to share on Google+"