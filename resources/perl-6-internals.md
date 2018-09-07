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

Today, we will take a look at a few methods of the Hash class that return all hash keys or values or both:

	&gt; my %h = H =&gt; 'Hydrogen', He =&gt; 'Helium', Li =&gt; 'Lithium';
	{H =&gt; Hydrogen, He =&gt; Helium, Li =&gt; Lithium}

	&gt; %h.**keys**;
	(H Li He)

	&gt; %h.**values**;
	(Hydrogen Lithium Helium)

	&gt; %h.**kv**;
	(H Hydrogen Li Lithium He Helium)

While you may want to go directly to the src/core/Hash.pm6 file to see the definitions of the methods, you will not find them there. The Hash class is a child of Map, and all these methods are defined in src/core/Map.pm6. Getting keys and values is simple:

	multi method keys(Map:D:) {
	    Seq.new(Rakudo::Iterator.Mappy-keys(self))
	}

	multi method values(Map:D:) {
	    Seq.new(Rakudo::Iterator.Mappy-values(self))
	}

For the kv method, more work has to be done:

	multi method kv(Map:D:) {
	    Seq.new(class :: does Rakudo::Iterator::Mappy {
	        has int $!on-value;

	        method pull-one() is raw {
	            . . .
	        }
	        method skip-one() {
	            . . .
	        }
	        method push-all($target --&gt; IterationEnd) {
	            . . .
	        }
	    }.new(self))
	}

As you see, the method returns a sequence that is built using an anonymous class implementing the Rakudo::Iterator::Mappy role. We already saw how this approach is used in combination with [defining pull-one and push-all methods][1].

Let us look at another set of methods, pairs and antipairs. One of them is simple and straightforward:

	multi method pairs(Map:D:) {
	    Seq.new(self.iterator)
	}

Another one is using an intermediate class:

	multi method antipairs(Map:D:) {
	    Seq.new(class :: does Rakudo::Iterator::Mappy {
	        method pull-one() {
	            . . .
	        }
	        method push-all($target --&gt; IterationEnd) {
	        . . .
	        }
	    }.new(self))
	}

Both methods produce results of the same structure:

	&gt; %h.**antipairs**
	(Hydrogen =&gt; H Lithium =&gt; Li Helium =&gt; He)

	&gt; %h.**pairs**
	(H =&gt; Hydrogen Li =&gt; Lithium He =&gt; Helium)

In Perl 6, you can use superscript indices to calculate powers of numbers, for example:

	&gt; 2⁵
	32

	&gt; 7³
	343

It also works with more than one digit in the superscript:

	&gt; 10¹²
	1000000000000

You can guess that the above cases are equivalent to the following:

	&gt; 2**5
	32
	&gt; 7**3
	343

	&gt; 10**12
	1000000000000

But the question is: How on Earth does it work? Let us find it out.

For the Numeric role, the following operation is defined:

	proto sub postfix:&lt;ⁿ&gt;(Mu $, Mu $) is pure {*}
	multi sub postfix:&lt;ⁿ&gt;(\a, \b) { a ** b }

Aha, that is what we need, and the superscript notation is converted to the simple \*\* operator here.

You can visualise what exactly is passed to the operation by printing the operands:

	multi sub postfix:&lt;ⁿ&gt;(\a, \b) {
	**    nqp::say('# a = ' ~ a);**
	**    nqp::say('# b = ' ~ b);**
	    a ** b
	}

In this case, you’ll see the following output for the test examples above:

	&gt; 2⁵
	# a = 2
	# b = 5

	&gt; 10¹²
	# a = 10
	# b = 12

Now, it is time to understand how the postfix that extracts superscripts works. Its name, ⁿ, written in superscript, should not mislead you. This is not a magic trick of the parser, this is just a name of the symbol, and it can be found in the Grammar:

	token postfix:sym&lt;ⁿ&gt; {
	    &lt;sign=[⁻⁺¯]&gt;? &lt;dig=[⁰¹²³⁴⁵⁶⁷⁸⁹]&gt;+ &lt;O(|%autoincrement)&gt;
	}

You see, this symbol is a sequence of superscripted digits with an optional sign before them. (Did you think of a sign before we reached this moment in the Grammar?)

Let us try negative powers, by the way:

	&gt; say 4⁻³
	# a = 4
	# b = -3
	0.015625

Also notice that the whole construct is treated as a postfix operator. It can also be applied to variables, for example:

	&gt; my $x = 9
	9
	&gt; say $x²
	# a = 9
	# b = 2
	81

So, a digit in superscript is not a part of the variable’s name.

OK, the final part of the trilogy, the code in Actions, which parses the index:

	method postfix:sym&lt;ⁿ&gt;($/) {
	    my $Int := $*W.find_symbol(['Int']);
	    my $power := nqp::box_i(0, $Int);
	    **for $&lt;dig&gt; {**
	**        $power := nqp::add_I(**
	**           nqp::mul_I($power, nqp::box_i(10, $Int), $Int),**
	**           nqp::box_i(nqp::index("⁰¹²³⁴⁵⁶⁷⁸⁹", $_), $Int),**
	**           $Int);**
	**    }**

	    $power := nqp::neg_I($power, $Int)
	        if $&lt;sign&gt; eq '⁻' || $&lt;sign&gt; eq '¯';
	    make QAST::Op.new(:op&lt;call&gt;, :name('&amp;postfix:&lt;ⁿ&gt;'),
	                      $*W.add_numeric_constant($/, 'Int', $power));
	}

As you can see here, it scans the digits and updates the $power variable by adding the value at the next decimal position (it is selected in the code above).

The available characters are listed in a string, and to get its value, the offset in the string is used. The $&lt;dig&gt; match contains a digit, you can see it in the Grammar:

	&lt;dig=[⁰¹²³⁴⁵⁶⁷⁸⁹]&gt;+

Hello! Yesterday, I was giving my [Perl 6 Intro course][2] at the German Perl Workshop in Gummersbash. It was a great pleasure to prepare and run this one-day course, and, while it was difficult to cover everything, we touched all main aspects of the Perl 6 language: from variables to regexes and parallel computing. Of course, it was only a top-level overview, and there was not enough time to make all the exercises. You can do them at home, here’s the [Perl 6 Intro – Exercises][3] PDF file.

Among the rest, we tried to implement the sleep method for integers. The rationale behind that is that it is possible to say:

	&gt; 10.rand
	9.9456903794802

But not:

	&gt; 10.sleep
	No such method 'sleep' for invocant of type 'Int'
	  in block &lt;unit&gt; at &lt;unknown file&gt; line 1

OK, so let’s first implement the simplest form of sleep for Ints only. Go to src/core/Int.pm6 and add the following:

	my class Int does Real {

	**    method sleep() {**
	**        nqp::sleep($!value);**
	**    }**

Here’s a [photo from the screen][4]:

<img src="https://inperl6.files.wordpress.com/2018/04/29695497_10156162162038326_7927919948344098147_n.jpg?w=502&amp;h=498" width="502" height="498" alt="29695497_10156162162038326_7927919948344098147_n" class="  wp-image-700 aligncenter" />

There is no declaration of the $!value attribute in this file, but we know that it can be found somewhere in Perl6/Metamodel/BOOTSTRAP.nqp:

	# class Int is Cool {
	# has bigint $!value is box_target;
	Int.HOW.add_parent(Int, Cool);
	**Int.HOW.add_attribute(Int,
	****    BOOTSTRAPATTR.new(:name&lt;$!value&gt;, :type(bigint),
	                      :box_target(1), :package(Int)));
	**Int.HOW.set_boolification_mode(Int, 6);
	Int.HOW.publish_boolification_spec(Int);
	Int.HOW.compose_repr(Int);

Compile and run. The desired code works now:

	&gt; 3.sleep
	_# sleeping 3 seconds_
	&gt;

What can be changed here? The first idea is to allow non-integer numbers as the delay duration. As Int does the Real role, just move the method to src/core/Real.pm and get the value using the Num method instead of reading $!value directly (there is no such attribute in the Real role):

	my role Real does Numeric {

	**    method sleep() { **
	**        nqp::sleep(self.Num);**
	**    }**

Now it also works with rationals and floating-point numbers:

	&gt; 2.sleep
	2

	&gt; 3.14.sleep
	3.14

	&gt; pi.sleep
	3.14159265358979

Before wrapping it up, let us take a look at the body of the sleep _subroutine_. It is defined in src/core/Date.pm6:

	proto sub sleep(|) {*}
	multi sub sleep(--&gt; Nil) { sleep(*) }
	multi sub sleep($seconds --&gt; Nil) {
	    # 1e9 seconds is a large enough value that still makes VMs sleep
	    # larger values cause nqp::sleep() to exit immediatelly (esp. on 32-bit)
	    if nqp::istype($seconds,Whatever) || $seconds == Inf {
	        nqp::sleep(1e9) while True;
	    }
	    elsif $seconds &gt; 1e9 {
	        nqp::sleep($_) for gather {
	            1e9.take xx ($seconds / 1e9);
	            take $seconds - 1e9 * ($seconds / 1e9).Int;
	        }
	    }
	    elsif $seconds &gt; 0e0 {
	        nqp::sleep($seconds.Num);
	    }
	}

The code is very clear and does not need any comments.

And maybe just to see why our modified Rakudo printed the time after sleep in the tests above, let’s refer to the documentation of NQP to see that its sleep function’s return value is the number of seconds:

	## sleep
	* `sleep(num $seconds --&gt; num)`

	Sleep for the given number of seconds (no guarantee is made
	how exact the time sleeping is spent.)
	Returns the passed in number.

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

For example, if you declare enum colour, then the $longname.name() returns colour colour. Thus, we extracted it. (Also notice how [redeclaration][5] is handled.)

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

In Perl 6, you can ask the sequence operator to build a desired sequence for you. It can be arithmetic or geometric progression. All you need is to show the beginning of the sequence to Perl, for example:

	.say for 3, 5 ... 11;

This prints numbers 3, 5, 7, 9, and 11. Or:

	.say for 2, 4, 8 ... 64;

This code prints powers of 2 from 2 to 64: 2, 4, 8, 16, 32, and 64.

I am going to try understanding how that works in Rakudo. First of all, look into the src/core/operators.pm file, which keeps a lot of different operators, including a few versions of the ... operator. The one we need looks really simple:

	multi sub infix:&lt;...&gt;(\a, Mu \b) {
	    Seq.new(SEQUENCE(a, b).iterator)
	}

Now, the main work is done inside the SEQUENCE sub. Before we dive there, it is important to understand what its arguments a and b receive.

In the case of, say, 3, 5 ... 11, the first argument is a list 3, 5, and the second argument is a single value 11.

These values land in the parameters of the routine:

	sub SEQUENCE(\left, Mu \right, :$exclude_end) {
	    . . .
	}

What happens next is not that easy to grasp. Here is a screenshot of the complete function:

<img src="https://inperl6.files.wordpress.com/2018/03/sequence.png?w=148&amp;h=1024" width="148" height="1024" alt="sequence" class=" size-large wp-image-687 aligncenter" />

It contains about 350 lines of code and includes a couple of functions. Nevertheless, let’s try.

What you see first, is creating iterators for both left and right operands:

	my \righti := (nqp::iscont(right) ?? right !! [right]).iterator;

	my \lefti := left.iterator;

Then, the code loops over the left operand and builds an array @tail out of its data:

	while !((my \value := lefti.pull-one) =:= IterationEnd) {
	    $looped = True;
	    if nqp::istype(value,Code) { $code = value; last }
	    if $end_code_arity != 0 {
	        @end_tail.push(value);
	        if +@end_tail &gt;= $end_code_arity {
	            @end_tail.shift xx (@end_tail.elems - $end_code_arity)
	                unless $end_code_arity ~~ -Inf;

	            if $endpoint(|@end_tail) {
	                $stop = 1;
	                @tail.push(value) unless $exclude_end;
	                last;
	            }
	        }
	    }
	    elsif value ~~ $endpoint {
	        $stop = 1;
	        @tail.push(value) unless $exclude_end;
	        last;
	    }
	    @tail.push(value);
	}

I leave you reading and understand this piece of code as an exercise, but for the given example, the @tail array will just contain two values: 3 and 5.

	&gt; .say for 3,5...11;
	multi sub infix:&lt;...&gt;(\a, Mu \b)
	List    # nqp::say(a.^name);
	~~3     # nqp::say('~~' ~ value);
	~~5     # nqp::say('~~' ~ value);
	elems=2 # nqp::say('elems='~@tail.elems);
	0=3     # nqp::say('0='~@tail[0]);
	1=5     # nqp::say('1='~@tail[1]);

This output shows some debug data print outs that I added to the source code to see how it works. The green comments show the corresponding print instructions.

That’s it for today. See you tomorrow with more stuff from the sequence operator. Tomorrow, we have to understand how the list 3, 5 tells Perl 6 to generate increasing values with step 1.

Today, we will see how Perl 6 helps to keep our programs better.

## Redeclaration of a variable

Examine the following program:

	my $x = 1;
	my $x = 2;
	say $x;

You can immediately see that this program is not entirely correct. Either we meant to assign a new value to $x or to create a new variable with a different name. In either case, compiler has no idea and complains:

	$ perl6 redecl.pl
	Potential difficulties:
	    Redeclaration of symbol '$x'
	    at /Users/ash/redecl.pl:2
	    ------&gt; my $x⏏ = 2;
	2

You see a runtime warning, while the program does not stop. Let us find out where it happens in the source code.

When you declare a variable, the grammar matches the corresponding text and calls the variable\_declarator action method. It is quite compact but nevertheless I will not quote it completely.

	class Perl6::Actions is HLL::Actions does STDActions {
	    . . .

	    method variable_declarator($/) {
	        . . .
	    }

	    . . .
	}

By the way, you can see here how Perl 6 treats a variable name:

	 my $past := $&lt;variable&gt;.ast;
	 my $sigil := $&lt;variable&gt;&lt;sigil&gt;;
	 my $twigil := $&lt;variable&gt;&lt;twigil&gt;;
	 my $desigilname := ~$&lt;variable&gt;&lt;desigilname&gt;;
	 **my $name := $sigil ~ $twigil ~ $desigilname;**

The name of a variable is a concatenation of a sigil, a twigil and an identifier (which is called desigiled name in the code).

Then, if we’ve got a proper variable name, check it against an existing lexpad:

	if $&lt;variable&gt;&lt;desigilname&gt; {
	    my $lex := $*W.cur_lexpad();
	    if $lex.symbol($name) {
	        $/.typed_worry('X::Redeclaration', symbol =&gt; $name);
	    }

If the name is known, generate a warning. If everything is fine, create a variable declaration:

	make declare_variable($/, $past, ~$sigil, ~$twigil, $desigilname,
	                      $&lt;trait&gt;, $&lt;semilist&gt;, :@post);

## Redeclaration of a routine

Now, let us try to re-create a subroutine:

	sub f() {}
	sub f() {}

This may only be OK if the subs are declared as multi-subs. With the given code, the program will not even compile:

	===SORRY!=== Error while compiling /Users/ash/redecl.pl
	Redeclaration of routine 'f' (did you mean to declare a multi-sub?)
	at /Users/ash/redecl.pl:6
	------&gt; sub f() {}⏏&lt;EOL&gt;

This time, it happens in a much more complicated method, routine\_def:

	method routine_def($/) {
	     . . .

	     my $predeclared := $outer.symbol($name);
	     if $predeclared {
	         my $Routine := $*W.find_symbol(['Routine'], :setting-only);
	         unless nqp::istype( $predeclared&lt;value&gt;, $Routine)
	                &amp;&amp; nqp::getattr_i($predeclared&lt;value&gt;, $Routine, '$!yada') {
	              $*W.throw($/, ['X', 'Redeclaration'],
	                        symbol =&gt; ~$&lt;deflongname&gt;.ast,
	                        what =&gt; 'routine',
	              );
	         }
	     }

## The exception

The code of the exception is rather simple. Here it is:

	my class X::Redeclaration does X::Comp {
	    has $.symbol;
	    has $.postfix = '';
	    has $.what = 'symbol';
	    method message() {
	        "Redeclaration of $.what '$.symbol'"
	        ~ (" $.postfix" if $.postfix)
	        ~ (" (did you mean to declare a multi-sub?)" if $.what eq 'routine');
	    }
	}

As you see, depending on the value of $.what, it prints either a short message or adds a suggestion to use the multi keyword.

  [1]: https://perl6.online/2018/02/05/47-push-all-optimisation/
  [2]: http://act.yapc.eu/gpw2018/talk/7314
  [3]: https://inperl6.files.wordpress.com/2018/04/perl-6-intro-exercises.pdf "Perl 6 Intro - Exercises"
  [4]: https://www.facebook.com/groups/perl6/permalink/2071209013145447/
  [5]: https://perl6.online/2018/03/01/67-redeclaration-of-a-symbol/