I was randomly looking at different Rakudo Perl 6 source files and found a syntax construction that I could not recognise. I hope you were reading the documentation more carefully (or you did not forget after you have read it) than me, but nevertheless let me devote today’s post to that feature.

So, this was in the src/core/IO/Spec/QNX.pm file:

	my class IO::Spec::QNX is IO::Spec::Unix {

	    method canonpath ($patharg, :$parent) {
	        my $path = $patharg.Str;
	        my $node = '';
	        if **$path ~~ s {^ ( '//' &lt;-[ / ]&gt;+ ) '/'? $} = ''**
	        or **$path ~~ s {^ ( '//' &lt;-[ / ]&gt;+ ) '/' }   = '/'**
	            { $node = ~ $0; }

	        $path = IO::Spec::Unix.canonpath($path, :$parent);

	        $node ~ $path;
	    }
	}

The unusual construction is shown in bold.

The basic form of substitution, which is the same in both Perls, is the following:

	my $str = 'Perl 5';
	$str ~~ s/5/6/;
	say $str;

Delimiters may be different, but unlike Perl 5, you cannot use two pairs of braces:

	my $str = 'Perl 5';
	$str ~~ s{5}{6};
	say $str;

This code generates a compile-time error:

	===SORRY!=== Error while compiling /Users/ash/s-2.pl
	Unsupported use of brackets around replacement;
	in Perl 6 please use assignment syntax
	at /Users/ash/s-2.pl:2
	------&gt; $str ~~ s{5}⏏{6};

As soon as you use balanced brackets, you are expected to use assignment for the replacement part:

	my $str = 'Perl 5';
	$str ~~ s{5} = '6';
	say $str;

And this is what we see in the original fragment:

	if $path ~~ s {^ ( '//' &lt;-[ / ]&gt;+ ) '/'? $} = ''
	or $path ~~ s {^ ( '//' &lt;-[ / ]&gt;+ ) '/' } = '/'

By the way, [other brackets][1] also work fine, for example:

	my $str = 'Perl 5';
	$str ~~ s《5》 = '6';
	say $str;

You can find the place in the Perl 6 Grammar, where this obsolete syntax bit is caught:

	grammar Perl6::Grammar is HLL::Grammar does STD {
	    . . .

	    # nibbler for s///
	    token sibble($l, $lang2, @lang2tweaks?) {
	        . . .

	        [ &lt;?{ $start ne $stop }&gt;
	            &lt;.ws&gt;
	            **[ &lt;?[ \[ \{ \( \&lt; ]&gt;**
	**            &lt;.obs('brackets around replacement',**
	**                  'assignment syntax')&gt; ]?**

It propagates further to the following exception (src/core/Exception.pm):

	my class X::Obsolete does X::Comp {
	    has $.old;
	    has $.replacement; # can't call it $.new, collides with constructor
	    has $.when = 'in Perl 6';
	    method message() {
	        "??Unsupported use of $.old; $.when please use $.replacement"
	    }
	}

And that’s all for today. See you tomorrow!

### Share this:

* [Twitter][2]
* [Facebook][3]
* [Google][4]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2018/01/23/embedded-comment-delimiters-in-perl-6/
  [2]: https://perl6.online/2018/01/29/40-substitution-and-balanced-brackets-in-perl-6-regexes/?share=twitter "Click to share on Twitter"
  [3]: https://perl6.online/2018/01/29/40-substitution-and-balanced-brackets-in-perl-6-regexes/?share=facebook "Click to share on Facebook"
  [4]: https://perl6.online/2018/01/29/40-substitution-and-balanced-brackets-in-perl-6-regexes/?share=google-plus-1 "Click to share on Google+"