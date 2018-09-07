Welcome to the new year! Today, let us switch for a while from the discussion about obsolete messages to something different.

## Stages

If you followed the exercises in the previous posts, you might have noticed that some statistics was printed in the console when compiling Rakudo:

	Stage start      :   0.000
	Stage parse      :  44.914
	Stage syntaxcheck:   0.000
	Stage ast        :   0.000
	Stage optimize   :   4.245
	Stage mast       :   9.476
	Stage mbc        :   0.200

You could have also noticed that the bigger the file you changed, the slower it is compiled, up to dozens of seconds when you modify Grammar.pm.

It is also possible to see the statistics for your own programs. The --stagestats command-line option does the job:

	$ ./perl6 --stagestats -e'say 42'
	Stage start      :   0.000
	Stage parse      :   0.065
	Stage syntaxcheck:   0.000
	Stage ast        :   0.000
	Stage optimize   :   0.001
	Stage mast       :   0.003
	Stage mbc        :   0.000
	Stage moar       :   0.000
	42

So, let’s look at these stages. Roughly, half of them is about Perl 6, and half is about MoarVM. In the case Rakudo is configured to work with the JVM backend, the output will differ in the second half.

The Perl 6 part is clearly visible in the src/main.nqp file:

	# Create and configure compiler object.
	my $comp := Perl6::Compiler.new();
	$comp.language('perl6');
	**$comp.parsegrammar(Perl6::Grammar);**
	**$comp.parseactions(Perl6::Actions);**
	**$comp.addstage('syntaxcheck', :before);**
	**$comp.addstage('optimize', :after);**
	hll-config($comp.config);
	nqp::bindhllsym('perl6', '$COMPILER_CONFIG', $comp.config);

Look at the selected lines. If you have played with Perl 6 Grammars, you know that big grammars are usually split into two parts: the grammar itself and the actions. The Perl 6 compiler does exactly the same thing for the Perl 6 grammar. There are two files: src/Perl6/Grammar.nqp and src/Perl6/Actions.nqp.

When looking at src/main.nqp, it is not quite clear that there are eight stages. Add the following line to the file:

	for ($comp.stages()) { nqp::say($_) }

Now, recompile Rakudo and run any program:

	$ ./perl6 -e'say 42'
	start
	parse
	syntaxcheck
	ast
	optimize
	mast
	mbc
	moar
	42

Here they are.

The names of the first three stages—_start_, _parse_, and _syntaxcheck_—are quite self-explanatory. The _ast_ stage is the stage of building an abstract syntax tree, which is then optimized in the _optimize_ stage.

At this point, your Perl 6 program has been transformed into the abstract syntax tree and is about to be passed to the backend, MoarVM virtual machine in our case. The stages names start with _m_. The _mast_ stage is the stage of the MoarVM assembly (not abstract) syntax tree, _mbc_ stands for MoarVM bytecode and _moar_ is when the VM executes the code.

## Targets

Now that we know the stages of the Perl 6 program workflow, let’s make use of them. The --target option lets the compiler to stop at the given stage and display the result of it. This option supports the following values: parse, syntaxcheck, ast, optimize, and mast. With those options, Rakudo prints the output as a tree, and you can see how the program changes at different stages.

Even for small programs, the output, especially with the abstract syntax tree or an assembly tree of the VM is quite verbose. Let’s look at the parse tree of the ‘Hello, World!’ program, for example:

	$ ./perl6 --target=parse -e'say "Hello, World!"'
	- statementlist: say "Hello, World!"
	  - statement: 1 matches
	    - EXPR: say "Hello, World!"
	      - args:  "Hello, World!"
	        - arglist: "Hello, World!"
	          - EXPR: "Hello, World!"
	            - value: "Hello, World!"
	              - quote: "Hello, World!"
	                - nibble: Hello, World!
	      - longname: say
	        - name: say
	          - identifier: say
	          - morename:  isa NQPArray
	        - colonpair:  isa NQPArray

All the names here correspond to rules, tokens, or methods of the Grammar. You can find them in src/Perl6/Grammar.nqp. As an exercise, try predicting if the name is a method, or a rule, or a token. Say, a value should be a token, as it is supposed to be a compact string, while a statementlist is a rule.

### Share this:

* [Twitter][1]
* [Facebook][2]
* [Google][3]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2017/12/31/compiler-stages-and-targets/?share=twitter "Click to share on Twitter"
  [2]: https://perl6.online/2017/12/31/compiler-stages-and-targets/?share=facebook "Click to share on Facebook"
  [3]: https://perl6.online/2017/12/31/compiler-stages-and-targets/?share=google-plus-1 "Click to share on Google+"