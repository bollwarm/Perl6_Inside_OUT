Today, we continue [examining the colonpair syntax][1] in Perl 6 and will give an addition to the third branch of the token. Here’s the branch we are looking at today:

	#  branch 3
	| &lt;identifier&gt;
	    { $*key := $&lt;identifier&gt;.Str; }
	    [
	    || &lt;.unsp&gt;? :dba('pair value') &lt;coloncircumfix($*key)&gt; { $*value := $&lt;coloncircumfix&gt;; }
	    || { $*value := 1; }
	    ]

It contains two alternative paths. If you don’t specify the value, it is set to 1:

	sub h(:$value) {
	    say $value;
	}

	h(:value); _# True_

This is handled by the second alternative in this branch:

	|| { $*value := 1; }

But you also may match the first one:

	|| &lt;.unsp&gt;? :dba('pair value') &lt;coloncircumfix($*key)&gt; {
	    $*value := $&lt;coloncircumfix&gt;;
	}

(The unsp is the so-called _unspace_ — an optional space prefixed by the backslash if you want to have some whitespace before the parenthesesis.)

The coloncircumfix token basically allows us to use paired brackets (actually, those defined by circumfix) to enclose the value. This is how it is defined:

	token coloncircumfix($front) {
	    # reset $*IN_DECL in case this colonpair is part of var we're
	    # declaring, since colonpair might have other vars. Don't make those
	    # think we're declaring them
	    :my $*IN_DECL := '';
	    [
	    | '&lt;&gt;' &lt;.worry("Pair with &lt;&gt; really means an empty list, not null string; use :$front" ~ "('') to represent the null string,\n or :$front" ~ "() to represent the empty list more accurately")&gt;
	    | {} &lt;circumfix&gt;
	    ]
	}

The following code is using this option:

	h(:value&lt;10&gt;); _# 10_
	h(:value(11)); _# 11_
	h(:value[12]); _# 12_

You can’t pass an empty string using empty brackets like h(:value&lt;&gt;):

	Potential difficulties:
	  Pair with &lt;&gt; really means an empty list, not null string;
	  use :value('') to represent the null string,
	  or :value() to represent the empty list more accurately

### Share this:

* [Twitter][2]
* [Facebook][3]
* [Google][4]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2018/02/08/50-colonpair-in-perl-6s-grammar-part-1/
  [2]: https://perl6.online/2018/02/09/51-colonpair-in-perl-6s-grammar-part-2/?share=twitter "Click to share on Twitter"
  [3]: https://perl6.online/2018/02/09/51-colonpair-in-perl-6s-grammar-part-2/?share=facebook "Click to share on Facebook"
  [4]: https://perl6.online/2018/02/09/51-colonpair-in-perl-6s-grammar-part-2/?share=google-plus-1 "Click to share on Google+"