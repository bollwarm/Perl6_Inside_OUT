A few days ago, we saw how Perl 6 checks the syntax if you are trying to index an array [with negative indices][1]. Since then, I was thinking about implementing the support of @a[-1]. It was not that easy, that’s why I did not demonstrate this last time 🙂

Before going further, a small disclaimer. Negative indices are not allowed in Perl 6 for a reason. Unfortunately, this is not very clear from the documentation why. It is said that you should use @a[\* - 1], which is equivalent to @a[@a.elems - 1], but no further explanation follows. There is the following [phrase in the old design document][2]: _‘Negative subscripts are never allowed for standard subscripts unless the subscript is declared modular.’ _So, today, I will ignore this restriction assuming that I don’t understand the limitation completely (actually, at the end of the post you will see what kind of additional problems arise if you allow negative indices). My goal here is just to see how it can be done internally. (Update: also, see the comment to the post for some thoughts about forbidding negative indices.)

First, once again look at the place in src/Perl6/Actions.nqp (the file tightly connected with the Perl 6 Grammar), that implements the behaviour of the [] postcircumfix brackets. If it detects a negative index, a compile-time exception is thrown.

	method postcircumfix:sym&lt;[ ]&gt;($/) {
	    my $past := QAST::Op.new( :name('&amp;postcircumfix:&lt;[ ]&gt;'), :op('call'), :node($/) );
	    if $&lt;semilist&gt; {
	        my $c := $/;
	        my $ast := $&lt;semilist&gt;.ast;
	        $past.push($ast) if nqp::istype($ast, QAST::Stmts);
	        if $ast.ann('multislice') {
	            $past.name('&amp;postcircumfix:&lt;[; ]&gt;');
	        }
	        # for nqp::split(';', ~$&lt;semilist&gt;) {
	        #     my $ix := $_ ~~ / [ ^ | '..' ] \s* &lt;( '-' \d+ )&gt; \s* $ /;
	        #     if $ix {
	        #         $c.obs("a negative " ~ $ix ~ " subscript to index from the end", "a function such as *" ~ $ix);
	        #     }
	        # }
	    }
	    make WANTED($past, '.[]');
	}

Here, I already commented out the code to remove the check. Of course, it would be too naïve to think that this solves the task.

First, let us try to de-parse what is happening here. The if check looks at the presence of $&lt;semilist&gt;. What is it? Refer to the Grammar (in src/Perl6/Grammar.nqp):

	token postcircumfix:sym&lt;[ ]&gt; {
	    :my $*QSIGIL := '';
	    :dba('subscript')
	    '[' ~ ']' [ &lt;.ws&gt; &lt;semilist&gt; ]
	    &lt;O(|%methodcall)&gt;
	}

So,  &lt;semilist&gt; contains everything in-between the brackets. In the method above, we work with its content as with a string:

	for nqp::split(';', ~$&lt;semilist&gt;) {
	    . . .

That looks promising but it is not possible just to assign a new string value there, so that when the program sees a negative index N, it replaces it with the \* - N string, letting Perl parse it further.

The $&lt;semilist&gt; object is not a string, as you can see from, for example, the following usage of it: $&lt;semilist&gt;.ast. My next idea was to build a piece of AST to replace the negative index. I rejected this idea as soon as I saw the AST output of a simple @a[\*-1] call:

	$ perl6 --target=ast -e'my @a; say @a[*-1]'
	. . .
	 - QAST::Stmts
	 - QAST::WVal(Array)
	 - QAST::Stmts &lt;sunk&gt; my @a; say @a[*-1]
	     - QAST::Stmt &lt;sunk&gt; my @a
	     - QAST::Var(lexical @a) &lt;sinkok&gt; :statement_id&lt;?&gt; @a
	     - QAST::Stmt &lt;sunk final&gt; say @a[*-1]
	     - QAST::Want &lt;sunk&gt;
	         - QAST::Op(call &amp;say) &lt;sunk&gt; :statement_id&lt;?&gt; say @a[*-1]
	         - QAST::Op(call &amp;postcircumfix:&lt;[ ]&gt;) &lt;wanted&gt; [*-1]
	             - QAST::Var(lexical @a) &lt;wanted&gt; @a
	             - QAST::Stmts &lt;wanted&gt; *-1
	             - QAST::Op(p6capturelex) &lt;wanted&gt; :statement_id&lt;?&gt; :past_block&lt;?&gt; :code_object&lt;?&gt;
	                 - QAST::Op(callmethod clone)
	                 - QAST::WVal(WhateverCode) :past_block&lt;?&gt; :code_object&lt;?&gt;
	         - v
	         - QAST::Op(p6sink)
	         - QAST::Op(call &amp;say) &lt;sunk&gt; :statement_id&lt;?&gt; say @a[*-1]
	             - QAST::Op(call &amp;postcircumfix:&lt;[ ]&gt;) &lt;wanted&gt; [*-1]
	             - QAST::Var(lexical @a) &lt;wanted&gt; @a
	             - QAST::Stmts &lt;wanted&gt; *-1
	                 - QAST::Op(p6capturelex) &lt;wanted&gt; :statement_id&lt;?&gt; :past_block&lt;?&gt; :code_object&lt;?&gt;
	                 - QAST::Op(callmethod clone)
	                     - QAST::WVal(WhateverCode) :past_block&lt;?&gt; :code_object&lt;?&gt;
	 - QAST::WVal(Nil)

It looks to scary to reproduce. A different approach is needed.

Meanwhile, take the second look at the regex that extracts a negative index:

	/ [ ^ | '..' ] \s* &lt;( '-' \d+ )&gt; \s* $ /

It accepts only two alternatives: negative integers and something that ends with a range, for example, .. -3. Aha, should I also handle ranges? But in the case of a range, the regex only contains the end of the potentially incorrect string. Again, not clear what to do.

OK, let us then look at that mysterious &lt;semilist&gt;. Here is its definition in the Grammar:

	rule semilist {
	    :dba('list composer')
	    ''
	    [
	    | &lt;?before &lt;.[)\]}]&gt; &gt;
	    | [&lt;statement&gt;&lt;.eat_terminator&gt; ]*
	    ]
	}

OMG, it can contain statements inside! Indeed, Perl 6 allows, for example, having a function call or a math operation between the brackets:

	say @a[f() + 1];

Yahoo! What does Rakudo say when the calculated index is negative?

	$ perl6 -e'my @a = &lt;a b c&gt;; say @a[2-3]'
	Index out of range. Is: -1, should be in 0..^Inf
	  in block &lt;unit&gt; at -e line 1

This time, an error happens at runtime (ignore the fact the 2-3 expression can be optimised) and the compiler did not catch that (if the case of a function, no optimisation can do that).

The text of the error message leads us to src/core/Array.pm, where among the rest, the AT-POS method is located:

	multi method AT-POS(Array:D: Int:D $pos) is raw {
	    nqp::if(
	      nqp::isge_i($pos,0)
	        &amp;&amp; nqp::isconcrete(nqp::getattr(self,List,'$!reified')),
	      nqp::ifnull(
	        nqp::atpos(nqp::getattr(self,List,'$!reified'),$pos),
	        self!AT-POS-SLOW($pos)
	      ),
	      self!AT-POS-SLOW($pos)
	    )
	}

The logic here is to call nqp::atpos for non-negative indices, which can be accessed in the array—that call returns the required element. For all the rest (including negative subscripts), the AT-POS-SLOW method is called. The above-shown runtime error happens inside AT-POS-SLOW. So, let us try not to pass control to it.

Now, it is time to remember that our idea was to count from the end of the array if the index is negative. In other words, let us modify the $pos variable here. You may find it very useful to consult the [nqp/docs/ops.markdown][3] document that describes NQP operators. After some experimenting, the following lines were added to the method:

	multi method AT-POS(Array:D: Int:D $pos) is raw {
	    **nqp::if(
	      nqp::islt_i($pos, 0),
	      $pos := nqp::add_i($pos, nqp::elems(nqp::getattr(self,List,'$!reified')))
	    );**
	    . . .

If $pos is negative (less than zero), add the length of the array to it. The rest of the method remains the same, as the index should be either zero or positive after the update.

Compile and test!

	$ ./perl6 -e'my @a = &lt;a b c d&gt;; say @a[-1]'
	d

Isn’t it what we wanted? What about slices?

	$ ./perl6 -e'my @a = &lt;a b c d&gt;; say @a[-1,-2]'
	(d c)

They also work!

Ranges?

	$ ./perl6 -e'my @a = &lt;a b c d&gt;; say @a[-3..-2]'
	(b c)

Here you are!

If you want to continue, you have to decide what happens when a negative index it too big for the given array:

	$ ./perl6 -e'my @a = &lt;a b c d&gt;; say @a[10-20]'
	Index out of range. Is: -6, should be in 0..^Inf
	  in block &lt;unit&gt; at -e line 1

For positive indices, going out of the array returns (Any). Probably, this should also be the case for big negative indices. Alternatively, you divide an index by modulo and thus making an index ‘loop.’ I will leave this as an exercise for the reader.

### Share this:

* [Twitter][4]
* [Facebook][5]
* [Google][6]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2017/12/29/obsolete-syntax-warnings-part-1/
  [2]: http://design.perl6.org/S09.html#Negative_and_differential_subscripts
  [3]: https://github.com/perl6/nqp/blob/master/docs/ops.markdown
  [4]: https://perl6.online/2018/01/07/18-implementing-negative-array-subscripts-in-perl-6/?share=twitter "Click to share on Twitter"
  [5]: https://perl6.online/2018/01/07/18-implementing-negative-array-subscripts-in-perl-6/?share=facebook "Click to share on Facebook"
  [6]: https://perl6.online/2018/01/07/18-implementing-negative-array-subscripts-in-perl-6/?share=google-plus-1 "Click to share on Google+"