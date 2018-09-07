Reduction operators are one of the many attractive features of Perl 6. A classical example is calculating factorial:

	say [*] 1..5; _# 120_

It is remarkable that in the AST output (generated with the --target=ast command-line option) you do not see any cycles. There is the METAOP\_REDUCE\_LEFT call, and obviously, the rest is hidden on the deeper levels.

	- QAST::Stmts
	- QAST::WVal(Array)
	- QAST::Stmts &lt;sunk&gt; say [*] 1..5
	    - QAST::Stmt &lt;sunk final&gt; say [*] 1..5
	    - QAST::Want &lt;sunk&gt;
	        - QAST::Op(call &amp;say) &lt;sunk&gt; :statement_id&lt;?&gt; say [*] 1..5
	        - QAST::Op(call) &lt;wanted&gt; [*] 1..5
	            - QAST::Op(call &amp;METAOP_REDUCE_LEFT) &lt;wanted&gt;
	            - QAST::Var(lexical &amp;infix:&lt;*&gt;) &lt;wanted&gt;
	            - QAST::Op(call &amp;infix:&lt;..&gt;) &lt;wanted&gt; ..
	            - QAST::Want &lt;wanted&gt; 1
	                - QAST::WVal(Int)
	                - Ii
	                - QAST::IVal(1)
	            - QAST::Want &lt;wanted&gt; 5
	                - QAST::WVal(Int)
	                - Ii
	                - QAST::IVal(5)

Nevertheless, let us at least look at the Grammar and see how it handles the reduction operator.

	regex term:sym&lt;reduce&gt; {
	    :my $*IN_REDUCE := 1;
	    :my $op;
	    &lt;?before '['\S+']'&gt;
	    &lt;!before '[' &lt;.[ - + ? ~ ^ ]&gt; &lt;.[ \w $ @ ]&gt; &gt; # disallow accidental prefix before termish thing

	    **'['**
	    [
	    || &lt;op=.infixish('red')&gt; &lt;?[\]]&gt;
	    || $&lt;triangle&gt;=[\\]&lt;op=.infixish('tri')&gt; &lt;?[\]]&gt;
	    || &lt;!&gt;
	    ]
	    **']'**
	    { $op := $&lt;op&gt; }

	    &lt;.can_meta($op, "reduce with")&gt;

	    [
	    || &lt;!{ $op&lt;OPER&gt;&lt;O&gt;.made&lt;diffy&gt; }&gt;
	    || &lt;?{ $op&lt;OPER&gt;&lt;O&gt;.made&lt;pasttype&gt; eq 'chain' }&gt;
	    || { self.typed_panic: "X::Syntax::CannotMeta", meta =&gt; "reduce with", operator =&gt; ~$op&lt;OPER&gt;&lt;sym&gt;, dba =&gt; ~$op&lt;OPER&gt;&lt;O&gt;.made&lt;dba&gt;, reason =&gt; 'diffy and not chaining' }
	    ]

	    { $*IN_REDUCE := 0 }
	    &lt;args&gt;
	}

The regex needs a pair of square brackets (shown in blue) and an operator between them. The operator is saved in $&lt;op&gt; but also in the $op local variable: notice how you can use a colon to declare variables inside the regex rules.

Then, the operator is checked if it can be reduced (.can\_meta), and finally, some arguments are parsed. In our case, the &lt;args&gt; rule should match with 1\..5.

What happens in-between with all those diffy and pasttype, is not clear for me. But notice how a dynamic variable $\*IN\_REDUCE is used as a flag so that inner rules understand that they are parsing something inside the reduction meta-operator.

Further adventures of the reduction story are even less clear. Let us just take a brief look at the corresponding action (actually, to its first part):

	method term:sym&lt;reduce&gt;($/) {
	    my $base := $&lt;op&gt;;
	    my $basepast := $base.ast
	        ?? $base.ast[0]
	        !! QAST::Var.new(:name("&amp;infix" ~ $*W.canonicalize_pair('', $base&lt;OPER&gt;&lt;sym&gt;)),
	 :scope&lt;lexical&gt;);
	    my $metaop := baseop_reduce($base&lt;OPER&gt;&lt;O&gt;.made);
	    my $metapast := QAST::Op.new( :op&lt;call&gt;, :name($metaop), WANTED($basepast,'reduce'));
	    my $t := $basepast.ann('thunky') || $base&lt;OPER&gt;&lt;O&gt;.made&lt;thunky&gt;;
	    if $&lt;triangle&gt; {
	        $metapast.push($*W.add_constant('Int', 'int', 1));
	    }
	    my $args := $&lt;args&gt;.ast;
	    # one-arg rule?
	    if +$args.list == 1 &amp;&amp; !$args[0].flat &amp;&amp; !$args[0].named {
	        make QAST::Op.new(:node($/),
	                          :op&lt;call&gt;,
	                          WANTED($metapast,'reduce/meta'),
	                          WANTED($args[0],'reduce/meta'));
	    }

	    . . .

	}

Everything ends with generating an item in QAST.

(By the way, did you know why the name starts with ‘Q’? Originally, it was PAST, short for Parrot AST. Then, a newer version of the tree appeared, and the next letter from the alphabet was used instead.)

### Share this:

* [Twitter][1]
* [Facebook][2]
* [Google][3]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2018/02/10/52-an-attempt-to-understand-how-works-in-perl-6/?share=twitter "Click to share on Twitter"
  [2]: https://perl6.online/2018/02/10/52-an-attempt-to-understand-how-works-in-perl-6/?share=facebook "Click to share on Facebook"
  [3]: https://perl6.online/2018/02/10/52-an-attempt-to-understand-how-works-in-perl-6/?share=google-plus-1 "Click to share on Google+"