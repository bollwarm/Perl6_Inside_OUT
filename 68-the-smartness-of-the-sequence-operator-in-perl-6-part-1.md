In Perl 6, you can ask the sequence operator to build a desired sequence for you. It can be arithmetic or geometric progression. All you need is to show the beginning of the sequence to Perl, for example:

	.say for 3, 5 ... 11;

This prints numbers 3, 5, 7, 9, and 11. Or:

	.say for 2, 4, 8 ... 64;

This code prints powers of 2 from 2 to 64: 2, 4, 8, 16, 32, and 64.

I am going to try understanding how that works in Rakudo. First of all, look into the src/core/operators.pm file, which keeps a lot of different operators, including a few versions of the ... operator. The one we need looks really simple:

	multi sub infix:&lt;...&gt;(\a, Mu \b) {
	    Seq.new(SEQUENCE(a, b).iterator)
	}

Now, the main work is done inside the SEQUENCE sub. Before we dive there, it is important to understand what its arguments a and b receive.

In the case of, say, 3, 5 ... 11, the first argument is a list 3, 5, and the second argument is a single value 11.

These values land in the parameters of the routine:

	sub SEQUENCE(\left, Mu \right, :$exclude_end) {
	    . . .
	}

What happens next is not that easy to grasp. Here is a screenshot of the complete function:

<img src="https://inperl6.files.wordpress.com/2018/03/sequence.png?w=148&amp;h=1024" width="148" height="1024" alt="sequence" class=" size-large wp-image-687 aligncenter" />

It contains about 350 lines of code and includes a couple of functions. Nevertheless, let’s try.

What you see first, is creating iterators for both left and right operands:

	my \righti := (nqp::iscont(right) ?? right !! [right]).iterator;

	my \lefti := left.iterator;

Then, the code loops over the left operand and builds an array @tail out of its data:

	while !((my \value := lefti.pull-one) =:= IterationEnd) {
	    $looped = True;
	    if nqp::istype(value,Code) { $code = value; last }
	    if $end_code_arity != 0 {
	        @end_tail.push(value);
	        if +@end_tail &gt;= $end_code_arity {
	            @end_tail.shift xx (@end_tail.elems - $end_code_arity)
	                unless $end_code_arity ~~ -Inf;

	            if $endpoint(|@end_tail) {
	                $stop = 1;
	                @tail.push(value) unless $exclude_end;
	                last;
	            }
	        }
	    }
	    elsif value ~~ $endpoint {
	        $stop = 1;
	        @tail.push(value) unless $exclude_end;
	        last;
	    }
	    @tail.push(value);
	}

I leave you reading and understand this piece of code as an exercise, but for the given example, the @tail array will just contain two values: 3 and 5.

	&gt; .say for 3,5...11;
	multi sub infix:&lt;...&gt;(\a, Mu \b)
	List    # nqp::say(a.^name);
	~~3     # nqp::say('~~' ~ value);
	~~5     # nqp::say('~~' ~ value);
	elems=2 # nqp::say('elems='~@tail.elems);
	0=3     # nqp::say('0='~@tail[0]);
	1=5     # nqp::say('1='~@tail[1]);

This output shows some debug data print outs that I added to the source code to see how it works. The green comments show the corresponding print instructions.

That’s it for today. See you tomorrow with more stuff from the sequence operator. Tomorrow, we have to understand how the list 3, 5 tells Perl 6 to generate increasing values with step 1.

### Share this:

* [Twitter][1]
* [Facebook][2]
* [Google][3]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2018/03/02/68-the-smartness-of-the-sequence-operator-in-perl-6-part-1/?share=twitter "Click to share on Twitter"
  [2]: https://perl6.online/2018/03/02/68-the-smartness-of-the-sequence-operator-in-perl-6-part-1/?share=facebook "Click to share on Facebook"
  [3]: https://perl6.online/2018/03/02/68-the-smartness-of-the-sequence-operator-in-perl-6-part-1/?share=google-plus-1 "Click to share on Google+"