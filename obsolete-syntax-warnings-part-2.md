Today, we continue exploring the error messages that Rakudo developers embedded to detect old Perl 5 constructions in the Perl 6 code.

## The obs method

But first, let’s make a small experiment and add a call to the obs method in the rule parsing the for keyword.

	rule statement_control:sym&lt;for&gt; {
	    &lt;sym&gt;&lt;.kok&gt; {}
	    [ &lt;?before 'my'? '$'\w+\s+'(' &gt;
	        **&lt;.obs('Hello', 'World!')&gt;** &lt;.typed_panic: 'X::Syntax::P5'&gt; ]?
	    [ &lt;?before '(' &lt;.EXPR&gt;? ';' &lt;.EXPR&gt;? ';' &lt;.EXPR&gt;? ')' &gt;
	        &lt;.obs('C-style "for (;;)" loop', '"loop (;;)"')&gt; ]?
	    &lt;xblock(1)&gt;
	}

The dot before the name of the method prevents creating a named element in the Match object. Actually, that is not that important as soon as the obs call generates an exception. In many other cases, the dot is very useful, of course.

Compile Rakudo and feed it with the erroneous Perl 6 code:

	$ ./perl6 -e'for my $x (@a) {}'
	===SORRY!=== Error while compiling -e
	Unsupported use of **Hello**; in Perl 6 please use **World!**
	at -e:1
	------&gt; for ⏏my $x (@a) {}

As you see, we’ve generated some rubbish message but the X::Syntax::P5 exception did not have a chance to appear, as the parsing stopped at the place the obs method was called.

## No foreach anymore

Another error message appears when you try using the foreach keyword:

	$ ./perl6 -e'foreach @a {}'
	===SORRY!=== Error while compiling -e
	Unsupported use of 'foreach'; in Perl 6 please use 'for'
	at -e:1
	------&gt; foreach⏏ @a {}

Notice that the compiler stopped even before figuring out that the @a variable is not defined.

Here is the rule that finds the outdated keyword:

	rule statement_control:sym&lt;foreach&gt; {
	    &lt;sym&gt;&lt;.end_keyword&gt; &lt;.obs("'foreach'", "'for'")&gt;
	}

The end\_keyword method is a token that matches the right edge of the keyword; this is not a method to report about the end of support of the keyword 🙂 You can see this method in many other rules in the grammar.

	token end_keyword {
	    » &lt;!before &lt;.[ \( \\ ' \- ]&gt; || \h* '=&gt;'&gt;
	}

## No do anymore

Another potential mistake is creating the do blocks instead of the new repeat/while or repeat/until.

	$ ./perl6 -e'do {} while 1'
	===SORRY!=== Error while compiling -e
	Unsupported use of do...while;
	in Perl 6 please use repeat...while or repeat...until
	at -e:1

This time, the logic for detecting the error is hidden deeply inside the statement token:

	token statement($*LABEL = '') {
	    . . .
	    my $sp := $&lt;EXPR&gt;&lt;statement_prefix&gt;;
	    **if $sp &amp;&amp; $sp&lt;sym&gt; eq 'do'** {
	         my $s := $&lt;statement_mod_loop&gt;&lt;sym&gt;;
	         $/.obs("do..." ~ $s, "repeat...while or repeat...until");
	    }
	    . . .
	}

The second symbol is taken from the $&lt;statement\_mod\_loop&gt;&lt;sym&gt; value, so the error message contains the proper instruction for both do \{\} until and do \{\} for blocks.

Let’s stop here for today. We’ll examine more obsolete syntax in the next year. Meanwhile, I wish you all the best and success with using Perl 6 in 2018!

### Share this:

* [Twitter][1]
* [Facebook][2]
* [Google][3]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2017/12/30/obsolete-syntax-warnings-part-2/?share=twitter "Click to share on Twitter"
  [2]: https://perl6.online/2017/12/30/obsolete-syntax-warnings-part-2/?share=facebook "Click to share on Facebook"
  [3]: https://perl6.online/2017/12/30/obsolete-syntax-warnings-part-2/?share=google-plus-1 "Click to share on Google+"