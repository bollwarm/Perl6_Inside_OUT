So far, we covered a lot of different error messages that Rakudo Perl 6 generates when you accidentally use the Perl 5 syntax. This is a really nice feature for easy migration to the new language.

Let us continue and cover another couple of errors.

## new X

It was one of the hottest topics in Perl 5 to forbid indirect method calls. Personally, I always preferred to use an arrow for method calls while still feeling better with new X(...) when creating objects. Now, Perl 6 prevents that and it looks like it knows something about my first language:

	$ perl6 -e'say **new Int**;'
	===SORRY!=== Error while compiling -e
	Unsupported use of C++ constructor syntax;
	in Perl 6 please use method call syntax
	at -e:1
	------&gt; say new Int⏏;

The attempt to use a C++ constructor call is blocked by the following rule in the Grammar:

	token term:sym&lt;new&gt; {
	    'new' \h+ &lt;longname&gt; \h* &lt;![:]&gt;
	    &lt;.obs("C++ constructor syntax", "method call syntax")&gt;
	}

It allows the following code, though:

	my $c = new Int:;
	$c++;
	say $c; _# 1_

## -&gt; vs .

Another aspect of object-oriented programming is the way methods are called. In Perl 5, it used to be an arrow while in Perl 6 methods are called with a dot.

So, neither $x-&gt;meth nor $x-&gt;() should work. The rules that catch that are defined as the following:

	# TODO: report the correct bracket in error message
	token postfix:sym«-&gt;» {
	    &lt;sym&gt;
	    [
	    | ['[' | '{' | '(' ] &lt;.obs('-&gt;(), -&gt;{} or -&gt;[] as postfix dereferencer', '.(), .[] or .{} to deref, or whitespace to delimit a pointy block')&gt;
	    | &lt;.obs('-&gt; as postfix', 'either . to call a method, or whitespace to delimit a pointy block')&gt;
	    ]
	}

The token extracts an arrow and prints one of the two messages depending on the next character.

If the character is an opening brace, it would be nice to make a less generic message, and the TODO comment actually agrees that it is the desired thing. Let us try making that at home.

	**method bracket_pair($s) {**
	**    $s eq '{' ?? '}' !! $s eq '[' ?? ']' !! ')'**
	**}**

	token postfix:sym«-&gt;» {
	    &lt;sym&gt;
	    [
	    | **$&lt;openingbracket&gt;=['[' | '{' | '(' ] {**
	**        my $pair := $&lt;openingbracket&gt; ~ self.bracket_pair(~$&lt;openingbracket&gt;);**
	**        self.obs("-&gt;$pair as postfix dereferencer",
	                 ".$pair to deref, or whitespace to delimit a pointy block")**
	**    }**
	    | &lt;.obs('-&gt; as postfix', 'either . to call a method, or whitespace to delimit a pointy block')&gt;
	    ]
	}

The changes are shown in bold. First, I save the opening brace in $&lt;openingbracket&gt;, then, a simple function finds its matching pair, and finally, the $pair variable gets both parts, so either \{\}, or [], or ().

The goal has been achieved:

	$ ./perl6 -e'say Int-&gt;{}'
	===SORRY!=== Error while compiling -e
	Unsupported use of **-&gt;{}** as postfix dereferencer;
	in Perl 6 please use **.{}** to deref, or whitespace
	to delimit a pointy block
	at -e:1
	------&gt; say Int-&gt;⏏{}
	    expecting any of:
	        postfix

Maybe it also worth not mentioning pointy blocks for [] and ().

As homework, try using the method that Rakudo is using itself for [detecting the closing bracket-pair][1] instead of our function above.

### Share this:

* [Twitter][2]
* [Facebook][3]
* [Google][4]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://github.com/rakudo/star/blob/master/docs/announce/2013.05.md
  [2]: https://perl6.online/2018/01/16/obsolete-syntax-error-messages-in-perl-6-part-4/?share=twitter "Click to share on Twitter"
  [3]: https://perl6.online/2018/01/16/obsolete-syntax-error-messages-in-perl-6-part-4/?share=facebook "Click to share on Facebook"
  [4]: https://perl6.online/2018/01/16/obsolete-syntax-error-messages-in-perl-6-part-4/?share=google-plus-1 "Click to share on Google+"