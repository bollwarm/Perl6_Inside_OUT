Welcome back! Today, we’ll try to do a simple thing using some knowledge from the previous days.

Compare the two lines:

	say 'Hello, World';
	'Hello, World'.say;

Is there any difference between them? Well, of course. Although the result is the same in both cases, syntactically they differ a lot.

In the first case, say is a stand-alone function that gets a string argument. In the second case, the say method is called on a string.

Compare the two lines on the parse level. First, as a function call:

	- statementlist: say 'Hello, World'
	  - statement: 1 matches
	    - EXPR: say 'Hello, World'
	      - args:  'Hello, World'
	        - arglist: 'Hello, World'
	          - EXPR: 'Hello, World'
	            - value: 'Hello, World'
	              - quote: 'Hello, World'
	                - nibble: Hello, World
	      - longname: say
	        - name: say
	          - identifier: say
	          - morename:  isa NQPArray
	        - colonpair:  isa NQPArray

Second, as a method:

	- statementlist: 'Hello, World'.say
	  - statement: 1 matches
	    - EXPR: .say
	      - 0: 'Hello, World'
	        - value: 'Hello, World'
	          - quote: 'Hello, World'
	            - nibble: Hello, World
	      - dotty: .say
	        - sym: .
	        - dottyop: say
	          - methodop: say
	            - longname: say
	              - name: say
	                - identifier: say
	                - morename:  isa NQPArray
	              - colonpair:  isa NQPArray
	        - O:
	      - postfix_prefix_meta_operator:  isa NQPArray
	      - OPER: .say
	        - sym: .
	        - dottyop: say
	          - methodop: say
	            - longname: say
	              - name: say
	                - identifier: say
	                - morename:  isa NQPArray
	              - colonpair:  isa NQPArray
	        - O:

Although the result of the two lines is the same, the parse trees look different, which is quite explainable. Instead of examining the parse trees, let us try locating the place where Perl 6 prints the string.

## The say sub

This function is a multi-sub, which is defined in the src/core/io\_operators.pm file in four different variants:

	proto sub say(|) {*}
	multi sub say() { . . . }
	multi sub say(Junction:D \j) { . . . }
	multi sub say(Str:D \x) { . . . }
	multi sub say(\x) { . . . }

It should be quite logically that say 'Hello, World' is using the say(Str:D) function. To prove it, add a printing instruction as usual:

	multi sub say(Str:D \x) {
	    **nqp::say('say(Str:D \x)');**
	    my $out := $*OUT;
	    $out.print(nqp::concat(nqp::unbox_s(x),$out.nl-out));
	}

Be very careful here not to type it like this:

	say('say(Str:D \x)');

I did that mistake and faced an infinite loop that wanted all CPU and memory resources because our additional instruction used the same variant say(Str:D) for a defined string. Even more, the real printing never happened as the $out.print method is called a bit later and is never reached.

Using the nqp:: namespace easily bypasses the problem.

	$ ./perl6 -e'say "Hello, World"'
	say(Str:D \x)
	Hello, World

## The say method

Now, let’s try guessing where the say method can be located. I am talking about our second one-liner, 'Hello, World'.say. The first idea is to look for it in src/core/Str.pm, although you will not see it there.

The method is located in the grandgrandparent class Mu (Str←Cool←Any←Mu). You may be surprised to see how it looks like:

	proto method say(|) {*}
	multi method say() { say(self) }

The fact that it has a prototype and that it is a multi-sub, although there is only one implementation, is not that important now. What is interesting, is that the method barely calls the say sub, which we examined in the previous section.

Add another nqp::say to the method of Mu:

	multi method say() { **nqp::say('Mu.say()');** say(self) }

Now, run the second program:

	$ ./perl6 -e'"Hello, World".say'
	Mu.say()
	say(Str:D \x)
	Hello, World

As you see, we ended up in the same function. Although the difference between the two parse trees was quite big, the actual work was done by the same function in the end.

That’s all for today. Tomorrow, let’s examine other variants of the say sub.

### Share this:

* [Twitter][1]
* [Facebook][2]
* [Google][3]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2018/01/03/traversing-say/?share=twitter "Click to share on Twitter"
  [2]: https://perl6.online/2018/01/03/traversing-say/?share=facebook "Click to share on Facebook"
  [3]: https://perl6.online/2018/01/03/traversing-say/?share=google-plus-1 "Click to share on Google+"