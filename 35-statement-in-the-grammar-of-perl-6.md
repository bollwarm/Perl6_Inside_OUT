At the beginning of the year, we [began reading Perl 6’s Grammar][1]. That exercise is very interesting but not that easy.

Today, let us take one more step and look at the statement.

The statement token is relatively compact. It is reproduced here with some simplifications (refer to src/Perl6/Grammar.nqp for the full code):

	token statement($*LABEL = '') {
	    &lt;!before &lt;.[\])}]&gt; | $ &gt;
	    &lt;!stopper&gt;
	    [
	    | &lt;label&gt; &lt;statement($*LABEL)&gt; { $*LABEL := '' if $*LABEL }
	    | &lt;statement_control&gt;
	    | &lt;EXPR&gt;
	        [
	        || &lt;?MARKED('endstmt')&gt;
	        || &lt;.ws&gt; &lt;statement_mod_cond&gt; &lt;statement_mod_loop&gt;?
	        || &lt;.ws&gt; &lt;statement_mod_loop&gt;
	            {
	                my $sp := $&lt;EXPR&gt;&lt;statement_prefix&gt;;
	                if $sp &amp;&amp; $sp&lt;sym&gt; eq 'do' {
	                my $s := $&lt;statement_mod_loop&gt;&lt;sym&gt;;
	                $/.obs("do..." ~ $s, "repeat...while or repeat...until");
	            }
	        }
	    ]?
	    | &lt;?[;]&gt;
	    | &lt;?stopper&gt;
	    | {} &lt;.panic: "Bogus statement"&gt;
	    ]
	}

According to the definition, a statement cannot start with the closing ], ), or \}. Neither it can be an empty string (don’t be confused by the word _before_).

	&lt;!before &lt;.[\])}]&gt; | $ &gt;

If you are not familiar with Perl 6 regexes, this is a character class &lt;[  ]&gt; that includes the above-listed characters, having the square brackets escaped within the character class.

The stopper rule is a bit difficult to track down immediately, so let us skip it for now.

Finally, a list of alternatives follows in the pair of square brackets (which create a non-capturing group in Perl 6 regexes).

One of the alternatives is a labelled statement:

	&lt;label&gt; &lt;statement($*LABEL)&gt;

Notice that as rules and tokens are methods (and grammar is a class), you can pass parameters to them.

A label is an identifier followed by a colon:

	token label {
	    &lt;identifier&gt; ':' &lt;?[\s]&gt; &lt;.ws&gt;
	}

(Again, I do not show the code which is not important for us at the moment; real definition includes some NQP code.)

Another alternative is a statement\_control. It is a subject of separate research. Just look at the list of different rules and tokens that fall under the definition of statement controls:

	proto rule statement_control         { &lt;...&gt; }

	rule statement_control:sym&lt;**if**&gt;       { . . . }
	rule statement_control:sym&lt;**unless**&gt;   { . . . }
	rule statement_control:sym&lt;**without**&gt;  { . . . }
	rule statement_control:sym&lt;**while**&gt;    { . . . }
	rule statement_control:sym&lt;**repeat**&gt;   { . . . }
	rule statement_control:sym&lt;**for**&gt;      { . . . }
	rule statement_control:sym&lt;**whenever**&gt; { . . . }
	rule statement_control:sym&lt;**foreach**&gt;  { . . . }
	token statement_control:sym&lt;**loop**&gt;    { . . . }
	rule statement_control:sym&lt;**need**&gt;     { . . . }
	token statement_control:sym&lt;**import**&gt;  { . . . }
	token statement_control:sym&lt;**no**&gt;      { . . . }
	token statement_control:sym&lt;**use**&gt;     { . . . }

Finally, a statement can be an expression, EXPR. An expression can be followed by one of the keywords like if or unless:

	proto rule statement_mod_cond { &lt;...&gt; }

	rule statement_mod_cond:sym&lt;**if**&gt; { &lt;sym&gt;&lt;.kok&gt; &lt;modifier_expr('if')&gt; }
	rule statement_mod_cond:sym&lt;**unless**&gt; { &lt;sym&gt;&lt;.kok&gt; &lt;modifier_expr('unless')&gt; }
	rule statement_mod_cond:sym&lt;**when**&gt; { &lt;sym&gt;&lt;.kok&gt; &lt;modifier_expr('when')&gt; }
	rule statement_mod_cond:sym&lt;**with**&gt; { &lt;sym&gt;&lt;.kok&gt; &lt;modifier_expr('with')&gt; }
	rule statement_mod_cond:sym&lt;**without**&gt;{ &lt;sym&gt;&lt;.kok&gt; &lt;modifier_expr('without')&gt; }

	proto rule statement_mod_loop { &lt;...&gt; }

	rule statement_mod_loop:sym&lt;**while**&gt; { &lt;sym&gt;&lt;.kok&gt; &lt;smexpr('while')&gt; }
	rule statement_mod_loop:sym&lt;**until**&gt; { &lt;sym&gt;&lt;.kok&gt; &lt;smexpr('until')&gt; }
	rule statement_mod_loop:sym&lt;**for**&gt; { &lt;sym&gt;&lt;.kok&gt; &lt;smexpr('for')&gt; }
	rule statement_mod_loop:sym&lt;**given**&gt; { &lt;sym&gt;&lt;.kok&gt; &lt;smexpr('given')&gt; }

The two alternative ending schemes:

	|| &lt;.ws&gt; &lt;statement_mod_cond&gt; &lt;statement_mod_loop&gt;?
	|| &lt;.ws&gt; &lt;statement_mod_loop&gt;

Double vertical bar allows the grammar to stop after the first match. Unlike a single bar, which chooses the longest match.

In the case the statement modifier comes with the do keyword, an error occurs:

	{
	    my $sp := $&lt;EXPR&gt;&lt;statement_prefix&gt;;
	    if $sp &amp;&amp; $sp&lt;sym&gt; eq 'do' {
	    my $s := $&lt;statement_mod_loop&gt;&lt;sym&gt;;
	    $/.obs("do..." ~ $s, "repeat...while or repeat...until");
	}

We already talked about this piece of code when we were discussing [error messages for obsolete syntax][2].

And it’s time to stop for today. See you tomorrow with more exciting details about Perl 6’s internals.

### Share this:

* [Twitter][3]
* [Facebook][4]
* [Google][5]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2018/01/01/the-start-of-the-grammar/
  [2]: https://perl6.online/2017/12/30/obsolete-syntax-warnings-part-2/
  [3]: https://perl6.online/2018/01/24/35-statement-in-the-grammar-of-perl-6/?share=twitter "Click to share on Twitter"
  [4]: https://perl6.online/2018/01/24/35-statement-in-the-grammar-of-perl-6/?share=facebook "Click to share on Facebook"
  [5]: https://perl6.online/2018/01/24/35-statement-in-the-grammar-of-perl-6/?share=google-plus-1 "Click to share on Google+"