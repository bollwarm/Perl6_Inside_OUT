One of the additional user-friendly features of Perl 6 is its great error reporting. It is not a mandatory part of the language grammar or semantics, but it really helps a developer to fix the errors in the code.

Run the following program:

	$ perl6 -e'my $var1; say $var2'

It leads to a compile-time error:

	===SORRY!=== Error while compiling -e
	**Variable '$var2' is not declared. Did you mean '$var1'?**
	at -e:1
	------&gt; my $var1; say ⏏$var2

Not only Perl 6 says that there is no such variable but it also suggests a correct candidate.

The smartness does not stop here. Rakudo Perl 6 offers you more variants if it sees other options:

	$ perl6 -e'my $var1; my $var2; say $var3'
	===SORRY!=== Error while compiling -e
	**Variable '$var3' is not declared. Did you mean any of these?**
	**    $var2**
	**    $var1**

	at -e:1
	------&gt; my $var1; my $var2; say ⏏$var3

Let us see how Perl 6 gets an idea of how to correct our typo. The exception is easy to spot:

	my class X::Undeclared does X::Comp {
	    has $.what = 'Variable';
	    has $.symbol;
	    has @.suggestions;
	    method message() {
	        my $message := "$.what '$.symbol' is not declared";
	        if +@.suggestions == 1 {
	            $message := "$message. Did you mean '@.suggestions[0]'?";
	        } elsif +@.suggestions &gt; 1 {
	            $message := "$message. Did you mean any of these?\n { @.suggestions.join("\n ") }\n";
	        }
	        $message;
	    }
	}

First of all, we see both cases there: when there are only one or more suggestions. They come from the @.suggestions attribute. The error $message is formed accordingly. By the way, notice how a code block is interpolated in the double-quoted string:

	" . . . **{ @.suggestions.join("\n ") }**\n";

The X::Undeclared class is only a part of the whole family of exceptions:

	my class X::Attribute::Undeclared is X::Undeclared
	my class X::Attribute::Regex is X::Undeclared
	my class X::Undeclared::Symbols does X::Comp

For the unknown variable, the exception is thrown from the check\_variable method in the Grammar. I will not copy it here as the method is quite big and will only show the relevant lines so that you can see the picture:

	method check_variable($var) {
	    my $varast := $var.ast;
	    . . .
	    my $name := $varast.name;
	    . . .
	    my @suggestions := $*W.suggest_lexicals($name);
	    . . .
	    $*W.throw($var, ['X', 'Undeclared'],
	              symbol =&gt; $name,
	              suggestions =&gt; @suggestions,
	              precursor =&gt; '1');
	    . . .
	    self
	}

So, an exception is thrown for the missing symbol $name with one ore more @suggestions.

Now move on to the suggest\_lexicals method that finds similar names. The $\*W variable is Rakudo Perl 6’s _World_ object, so search for it in the src/Perl6/World.nqp file:

	method suggest_lexicals($name) {
	    my @suggestions;
	    my @candidates := [[], [], []];
	    my &amp;inner-evaluator := **make_levenshtein_evaluator**($name, @candidates);
	    . . .
	    **levenshtein_candidate_heuristic**(@candidates, @suggestions);
	    return @suggestions;
	}

Once again, only the most significant code is shown. As you might guess, Rakudo is using the [Levenshtein distance][1] to find the closest matches. Roughly speaking, it counts how many letters you need to replace in a word A to get another word B. The bigger the distance, the less similar are the words.

### Share this:

* [Twitter][2]
* [Facebook][3]
* [Google][4]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://en.wikipedia.org/wiki/Levenshtein_distance
  [2]: https://perl6.online/2018/02/01/43-variable-y-not-declared-did-you-mean-x/?share=twitter "Click to share on Twitter"
  [3]: https://perl6.online/2018/02/01/43-variable-y-not-declared-did-you-mean-x/?share=facebook "Click to share on Facebook"
  [4]: https://perl6.online/2018/02/01/43-variable-y-not-declared-did-you-mean-x/?share=google-plus-1 "Click to share on Google+"