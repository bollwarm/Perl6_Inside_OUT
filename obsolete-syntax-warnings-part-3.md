A couple of weeks ago, we looked at some [error messages][1] that Perl 6 generates when it sees the Perl 5 constructions. Let us continue and go through another portion of the messages that are there in today’s Rakudo.

## \\x[]

We start with a simple error message that informs you to use new syntax when embedding a character by its code. In Perl 5, you could use \\x\{23\} to get a hash characters, while in Perl 6 it is an error:

	$ perl6 -e'say "\x{23}"'
	===SORRY!=== Error while compiling -e
	Unsupported use of curlies around escape argument;
	in Perl 6 please use square brackets
	at -e:1
	------&gt; say "\x{⏏23}"

Neither it works with regexes, for example:

	say "###" ~~ /\x{23}/

Replacing braces with square brackets helps:

	$ perl6 -e'say "\x[23]"'
	#

Similarly, Perl 6 expects the brackets for octal numbers:

	$ perl6 -e'say "\o[123]"'
	S

In the Grammar, this situation is caught by the following tokens.

For quoted strings:

	role b1 {
	    token backslash:sym&lt;x&gt; {
	        :dba('hex character') &lt;sym&gt; [ &lt;hexint&gt; |
	        '[' ~ ']' &lt;hexints&gt; | '{' &lt;.obsbrace1&gt; ] }
	    . . .
	}

For regexes:

	token backslash:sym&lt;x&gt; {
	    :i :dba('hex character') &lt;sym&gt; [ &lt;hexint&gt; |
	    '[' ~ ']' &lt;hexints&gt; | '{' &lt;.obsbrace&gt; ] }

	. . .

	token metachar:sym&lt;{}&gt; { \\&lt;[xo]&gt;'{' &lt;.obsbrace&gt; }

The obsbrace method itself is just a simple error message call:

	token obsbrace { &lt;.obs('curlies around escape argument',
	                       'square brackets')&gt; }

## Old regex modifiers

As soon as we are talking about regexes, here’s another set of error catchers complaining about the Perl 5 syntax of the regex modifiers:

	token old_rx_mods {
	    (&lt;[ i g s m x c e ]&gt;)
	    {
	        my $m := $/[0].Str;
	        if $m eq 'i' { $/.obs('/i',':i'); }
	        elsif $m eq 'g' { $/.obs('/g',':g'); }
	        elsif $m eq 'm' { $/.obs('/m','^^ and $$ anchors'); }
	        elsif $m eq 's' { $/.obs('/s','. or \N'); }
	        elsif $m eq 'x' { $/.obs('/x','normal default whitespace'); }
	        elsif $m eq 'c' { $/.obs('/c',':c or :p'); }
	        elsif $m eq 'e' { $/.obs('/e','interpolated {...} or s{} = ... form'); }
	        else { $/.obs('suffix regex modifiers','prefix adverbs'); }
	    }
	}

This code is quite self-explanatory, so a simple example would be enough:

	$ ./perl6 -e'"abc" ~~ **/a/i**'
	===SORRY!=== Error while compiling -e
	Unsupported use of /i; in Perl 6 please use :i
	at -e:1
	------&gt; "abc" ~~ /a/i⏏&lt;EOL&gt;

One of the following correct forms is expected:

	$ ./perl6 -e'say "abc" ~~ **m:i**/A/'
	｢a｣

	$ ./perl6 -e'say "abc" ~~ /[**:i** A]/'
	｢a｣

As an exercise, write an incorrect Perl 6 code that generates the last error message, _Unsupported use of suffix regex modifiers, in Perl 6 please use prefix adverbs_.

## tr///

Another regex-related construct, y/// does not exist in Perl 6, only the tr/// form is supported now:

	token quote:sym&lt;y&gt; {
	    &lt;sym&gt;
	    &lt;?before \h*\W&gt;
	    {} &lt;.qok($/)&gt;
	    **&lt;.obs('y///','tr///')&gt;**
	}

Here is an example of the correct program:

	my $x = "abc";
	$x ~~ tr/b/p/;
	say $x; # apc

That’s it for today. We will continue with more obsolete errors in a few days.

### Share this:

* [Twitter][2]
* [Facebook][3]
* [Google][4]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2017/12/29/obsolete-syntax-warnings-part-1/
  [2]: https://perl6.online/2018/01/13/obsolete-syntax-warnings-part-3/?share=twitter "Click to share on Twitter"
  [3]: https://perl6.online/2018/01/13/obsolete-syntax-warnings-part-3/?share=facebook "Click to share on Facebook"
  [4]: https://perl6.online/2018/01/13/obsolete-syntax-warnings-part-3/?share=google-plus-1 "Click to share on Google+"