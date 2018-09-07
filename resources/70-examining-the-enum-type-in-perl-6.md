In Perl 6, you can create enumerations like this:

	enum colour &lt;red orange yellow green blue violet&gt;;

Having this said, you can use the new name as a type name and create variables of that type:

	my colour $c;

	$c = green;
	say $c;     _# green_
	say $c.Int; _# 3_

As you would rightly expect, the type of the variable is very predictable:

	say $c.^name; _# colour_

Now, try to find the class implementation in Rakudo sources. Surprisingly, there is no file src/core/Enum.pm, but instead, there is src/core/Enumeration.pm. Looking at that file, you cannot say how our program works. Let us dig a bit.

In Grammar (src/Perl6/Grammar.nqp), you can find the following piece:

	proto token type_declarator { &lt;...&gt; }

	token type_declarator:sym&lt;enum&gt; {
	    . . .
	}

So, the enum is not a name of the data type but a predefined keyword, one of a few that exist for type declarations (together with subset and constant).

The token starts with consuming the keyword and making some preparations, which are not very interesting for us at the moment:

	**&lt;sym&gt;**&lt;.kok&gt;
	:my $*IN_DECL := 'enum';
	:my $*DOC := $*DECLARATOR_DOCS;
	{ $*DECLARATOR_DOCS := '' }
	:my $*POD_BLOCK;
	:my $*DECLARAND;
	{
	    my $line_no := HLL::Compiler.lineof(self.orig(), self.from(), :cache(1));
	    if $*PRECEDING_DECL_LINE &lt; $line_no {
	        $*PRECEDING_DECL_LINE := $line_no;
	        $*PRECEDING_DECL := Mu; # actual declarand comes later, in Actions::type_declarator:sym&lt;enum&gt;
	    }
	}
	&lt;.attach_leading_docs&gt;

Then, we expect either a name of the new type or a variable or nothing(?):

	[
	| &lt;longname&gt;
	    {
	     . . .
	    }
	| &lt;variable&gt;
	| &lt;?&gt;
	]

The variable part is not yet implemented:

	&gt; enum $x &lt;a b c&gt;
	===SORRY!=== Error while compiling:
	Variable case of enums not yet implemented. Sorry.
	at line 2

Our test program falls to the first branch:

	**&lt;longname&gt;**
	  {
	      my $longname := $*W.dissect_longname($&lt;longname&gt;);
	      my @name := $longname.type_name_parts('enum name', :decl(1));
	      if $*W.already_declared($*SCOPE, self.package, $*W.cur_lexpad(), @name) {
	          $*W.throw($/, ['X', 'Redeclaration'],
	                    symbol =&gt; $longname.name(),
	          );
	      }
	  }

For example, if you declare enum colour, then the $longname.name() returns colour colour. Thus, we extracted it. (Also notice how [redeclaration][1] is handled.)

Finally, here is the rest of the token body:

	{ $*IN_DECL := ''; }
	&lt;.ws&gt;
	&lt;trait&gt;*
	:my %*MYSTERY;
	[ &lt;?[&lt;(«]&gt; &lt;term&gt; &lt;.ws&gt; || &lt;.panic: 'An enum must supply an expression using &lt;&gt;, «», or ()'&gt; ]
	&lt;.explain_mystery&gt; &lt;.cry_sorrows&gt;

Indeed, we need to explain the mystery here. So, there’s room for optional traits, fine:

	&lt;trait&gt;*

There’s another construct that should match to avoid panic messages:

	&lt;?[&lt;(«]&gt; &lt;term&gt; &lt;.ws&gt;

Don’t be confused by the different number of opening and closing angle brackets here. The first part is a forward assertion with a character class:

	&lt;?  [&lt;(«]  &gt;

It looks if there is one of the &lt;, (, or « opening bracket at this position. The panic message is displayed if it is not found there.

Our next expected guest is a term. Obviously, the whole part &lt;red orange . . . violet&gt; matches with it. Not that bad; what we need to do now is to understand what happens next.

### Share this:

* [Twitter][2]
* [Facebook][3]
* [Google][4]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2018/03/01/67-redeclaration-of-a-symbol/
  [2]: https://perl6.online/2018/03/03/70-examining-the-enum-type-in-perl-6/?share=twitter "Click to share on Twitter"
  [3]: https://perl6.online/2018/03/03/70-examining-the-enum-type-in-perl-6/?share=facebook "Click to share on Facebook"
  [4]: https://perl6.online/2018/03/03/70-examining-the-enum-type-in-perl-6/?share=google-plus-1 "Click to share on Google+"