Welcome back! As you might notice, there was a small gap in the daily post flow.

Before we are back to the Rakudo internals, a couple of words about some changes here. First of all, every post is now marked with either 🦋 or 🔬 (or with indistinguishable rectangles □ if your browser cannot display an emoji :-). These characters mean two categories of posts here: a butterfly stands for [Perl 6 syntax][1], while a microscope is for [Perl 6 internals][2]. In the first category, only user-level aspects or Perl 6 are discussed. In the second, we dig into the source codes of Rakudo. All the past post are updated accordingly.

The second change is that I will occasionally post more articles in the Perl 6 syntax category because I found out that non-Russian speakers often like my [Russian blog posts][3]. Those posts are mostly short texts explaining interesting features of Perl 6, such as the =~= operator or promises.

\* \* \*

OK, now we have to talk about the EVAL routine. It is defined in the src/core/ForeignCode.pm file as a multi-function. Let us see at their signatures:

	proto sub EVAL($code is copy where Blob|Cool,
	               Str() :$lang = 'perl6',
	               PseudoStash :$context, *%n)

	multi sub EVAL($code,
	               Str :$lang where { ($lang // '') eq 'Perl5' },
	               PseudoStash :$context)

Notice that one of the function is a [proto][4], while another is the only multi-candidate. Unlike many other cases that you can see in the sources of Rakudo, this proto routine contains code. Refer to [one of the recent blog posts][5] to see how it works.

We start with an example from the [first part][6] of the article.

	EVAL('say 123');

Here, the passed value is Str, and it is caught by the proto sub, as its first argument can be Cool.

The sub creates a compiler for the given language (which is Perl 6 by default).

	my $compiler := nqp::getcomp($lang);

The next step in the sub is to make a _string_ out of $code. In this first example, this task is trivial.

	$code = nqp::istype($code,Blob) ?? $code.decode(
	    $compiler.cli-options&lt;encoding&gt; // 'utf8'
	) !! $code.Str;

Finally, the string is compiled:

	my $compiled := $compiler.compile:
	    $code,
	    :outer_ctx($eval_ctx),
	    :global(GLOBAL),
	    :mast_frames(mast_frames),
	    |(:optimize($_) with nqp::getcomp('perl6').cli-options&lt;optimize&gt;),
	    |(%(:grammar($LANG&lt;MAIN&gt;), :actions($LANG&lt;MAIN-actions&gt;)) if $LANG);

After compilation, you get an object of the ForeignCode type. This class is a child class of Callable, so the object can be called and returned (actually, it’s not quite clear how it happens):

	$compiled();

Now you can understand that single quotes in the second example with curly braces still create an executable code:

	EVAL('say {456}');

Here, the whole string is compiled as it was a Perl 6 code, and the code block there is a code block, which Perl should execute, and thus say gets a code block, so it calls its [gist method][7] to prepare the output:

	&gt; {456}.gist
	**-&gt; ;; $_? is raw { #`(Block|140388575216888) ... }**

### Share this:

* [Twitter][8]
* [Facebook][9]
* [Google][10]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/category/perl-6-syntax/
  [2]: https://perl6.online/category/perl-6-internals/
  [3]: https://perl6.ru/
  [4]: https://perl6.online/2017/12/21/the-proto-keyword/
  [5]: https://perl6.online/2018/02/21/63-more-on-the-proto-keyword-in-perl-6/
  [6]: https://perl6.online/2018/02/20/62-the-eval-routine-in-perl-6-part-1/
  [7]: https://perl6.online/2018/02/27/%f0%9f%a6%8b-64-what-is-gist-in-perl-6/
  [8]: https://perl6.online/2018/02/28/65-the-eval-routine-in-perl-6-part-2/?share=twitter "Click to share on Twitter"
  [9]: https://perl6.online/2018/02/28/65-the-eval-routine-in-perl-6-part-2/?share=facebook "Click to share on Facebook"
  [10]: https://perl6.online/2018/02/28/65-the-eval-routine-in-perl-6-part-2/?share=google-plus-1 "Click to share on Google+"