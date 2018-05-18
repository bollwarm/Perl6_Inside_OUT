What happens if you’ll try to create a new variable and immediately initialise it by itself, as shown in the following test code:

	my $x = $x;

This does not work (which is expected), but Perl 6 is so kind to the user  that it gives an error message prepared especially for this case:

	===SORRY!=== Error while compiling:
	**Cannot use variable $x in declaration to initialize itself**
	------&gt; my $x = $⏏x;
	  expecting any of:
	  term

Let us find the place in the code where the error message is triggered. This case is captured in the Grammar of Perl 6, at the place where variable is parsed:

	token variable {
	    . . .
	    | &lt;sigil&gt;
	      [ $&lt;twigil&gt;=['.^'] &lt;desigilname=desigilmetaname&gt;
	        | &lt;twigil&gt;? &lt;desigilname&gt; ]
	      [ &lt;?{ !$*IN_DECL &amp;&amp; $*VARIABLE &amp;&amp; $*VARIABLE eq
	        $&lt;sigil&gt; ~ $&lt;twigil&gt; ~ $&lt;desigilname&gt; }&gt;
	          {
	              self.typed_panic: 'X::Syntax::Variable::Initializer',
	              name =&gt; $*VARIABLE
	          }
	      ]?
	    . . .
	}

The condition to throw an exception is a bit wordy, but you can clearly see here that the whole variable name is checked, including both sigil and potential twigil.

The exception itself is located in src/core/Exception.pm6 (notice that file extensions were changed from .pm to .pm6 recently), and it is used only for the above case:

	my class X::Syntax::Variable::Initializer does X::Syntax {
	    has $.name = '&lt;anon&gt;';
	    method message() {
	        "Cannot use variable $!name in declaration to initialize itself"
	    }
	}

And that’s all for today. Rakudo Perl 6 sources can be really transparent sometimes! 🙂

### Share this:

* [Twitter][1]
* [Facebook][2]
* [Google][3]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2018/04/10/75-my-x-x-in-perl-6/?share=twitter "Click to share on Twitter"
  [2]: https://perl6.online/2018/04/10/75-my-x-x-in-perl-6/?share=facebook "Click to share on Facebook"
  [3]: https://perl6.online/2018/04/10/75-my-x-x-in-perl-6/?share=google-plus-1 "Click to share on Google+"