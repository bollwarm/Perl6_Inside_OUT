Welcome to the 50th post in this series!

Today, we’ll talk about a small syntax construction, which is nevertheless is quite complicated in terms of Grammar. Let us look at the whole colonpair token first:

	token colonpair {
	    :my $*key;
	    :my $*value;

	    **':'**
	    :dba('colon pair')
	    [
	    | '!' [ &lt;identifier&gt; || &lt;.panic: "Malformed False pair; expected identifier"&gt; ]
	        [ &lt;[ \[ \( \&lt; \{ ]&gt; {
	        $/.typed_panic('X::Syntax::NegatedPair', key =&gt; ~$&lt;identifier&gt;) } ]?
	        { $*key := $&lt;identifier&gt;.Str; $*value := 0 }
	    | $&lt;num&gt; = [\d+] &lt;identifier&gt; [ &lt;?before &lt;.[ \[ \( \&lt; \{ ]&gt;&gt; {} &lt;.sorry("Extra argument not allowed; pair already has argument of " ~ $&lt;num&gt;.Str)&gt; &lt;.circumfix&gt; ]?
	        &lt;?{
	            . . . # Some NQP things happen here, refer to the code if needed
	        }&gt;
	        { $*key := $&lt;identifier&gt;.Str; $*value := nqp::radix_I(10, $&lt;num&gt;, 0, 0, $*W.find_symbol(['Int']))[0]; }
	    | &lt;identifier&gt;
	        { $*key := $&lt;identifier&gt;.Str; }
	        [
	        || &lt;.unsp&gt;? :dba('pair value') &lt;coloncircumfix($*key)&gt; { $*value := $&lt;coloncircumfix&gt;; }
	        || { $*value := 1; }
	        ]
	    | :dba('signature') '(' ~ ')' &lt;fakesignature&gt;
	    | &lt;coloncircumfix('')&gt;
	        { $*key := ""; $*value := $&lt;coloncircumfix&gt;; }
	    | &lt;var=.colonpair_variable&gt;
	        { $*key := $&lt;var&gt;&lt;desigilname&gt;.Str; $*value := $&lt;var&gt;; self.check_variable($*value); }
	    ]
	}

The token always starts matching from a colon. Then, there are six main alternatives. Let us briefly come through the first half of them.

Each branch ends with assignments to the two dynamic variables: $\*key and $\*value.

## 1

The first variant is used when you want to pass a False value as a named parameter, for example:

	sub f($x, :$print = 1) {
	    say $x if $print;
	}

	f(3);          _# 3_
	f(4, :!print); # nothing

This function prints its first parameter if you do not set the :$print named argument to a False value. In Perl 6, this can be done using the shortcut :!print. Thus, in the second call, the function prints nothing.

## 2

The second branch of the token is for a special form of passing numeric values. Examine the following code snippet:

	sub g(:$value) {
	    say $value;
	}

	g(:10value); _# 10_

A function takes a named argument, and you can pass its value in a bit weird format: :10value, which means make the value of :$value equals 10.

## 3

The third option is probably the most common way to use colon syntax. This branch is triggered in the following example:

	sub g(:$value) {
	    say $value;
	}

	g(:value(10));_ # 10_

Here is the same function as in the previous section, but the value is passed differently.

This option is also used when you need somewhat opposite to the first one. In this case, you use the named argument as a Boolean flag and set its value to True. The next example demonstrates that:

	sub h(:$value) {
	    say $value;
	}

	h(:value); _# True_

Notice that this is False if you negate it with an exclamation mark (in that case, the first branch of the token works):

	h(:!value); _# False_

### Share this:

* [Twitter][1]
* [Facebook][2]
* [Google][3]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2018/02/08/50-colonpair-in-perl-6s-grammar-part-1/?share=twitter "Click to share on Twitter"
  [2]: https://perl6.online/2018/02/08/50-colonpair-in-perl-6s-grammar-part-1/?share=facebook "Click to share on Facebook"
  [3]: https://perl6.online/2018/02/08/50-colonpair-in-perl-6s-grammar-part-1/?share=google-plus-1 "Click to share on Google+"