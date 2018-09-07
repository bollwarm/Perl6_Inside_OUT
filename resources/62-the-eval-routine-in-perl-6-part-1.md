The EVAL routine in Perl 6 compiles and executes the code that it gets as an argument.  Today, we will see some potential use cases that you may try in your practice. Tomorrow, we will dig into Rakudo sources to see how it works and why it breaks sometimes.

## 1

Let us start with evaluating a simple program:

	EVAL('say 123');

This program prints 123, there’s no surprise here.

## 2

There are, though, more complicated cases. What, do you think, does the following program print?

	EVAL('say {456}');

I guess it prints not what you expected:

	-&gt; ;; $_? is raw { #`(Block|140570649867712) ... }

It parses the content between the curly braces as a pointy block.

## 3

What if you try double quotes?

	EVAL("say {789}");

Now it even refuses to compile:

	===SORRY!=== Error while compiling eval.pl
	EVAL is a very dangerous function!!! (use the MONKEY-SEE-NO-EVAL pragma to override this error,
	but only if you're VERY sure your data contains no injection attacks)
	at eval.pl:6
	------&gt; EVAL("say {789}")⏏;

## 4

We can fix the code by adding a few magic words:

	use MONKEY-SEE-NO-EVAL;

	EVAL("say {789}");

This time, it prints 789.

## 5

The code is executed (we don’t know yet when exactly, that is the topic of tomorrow’s post), so you can make some calculations, for example:

	use MONKEY-SEE-NO-EVAL;

	EVAL("say {7 / 8 + 9}"); _# 9.875_

## 6

Finally, if you try passing a code block directly, you also cannot achieve the goal, even with a blind monkey:

	use MONKEY-SEE-NO-EVAL;

	EVAL {say 123};

The error happens at runtime:

	Constraint type check failed in binding to parameter '$code';
	expected anonymous constraint to be met but got
	-&gt; ;; $_? is raw { #`...
	  in block &lt;unit&gt; at eval.pl line 10

This message looks cryptic, but at least we see once again that we got an anonymous pointy block passed to the function.

## 7

And before we wrap up for today, an attempt to use Perl 5 syntax:

	eval('say 42');

There is no such function in Perl 6, and we get a standard error message:

	===SORRY!=== Error while compiling eval2.pl
	Undeclared routine:
	  eval used at line 5. Did you mean 'EVAL', 'val'?

It looks OK but it can be better.

Stay tuned, tomorrow we will try to understand how all these examples work in Rakudo.

### Share this:

* [Twitter][1]
* [Facebook][2]
* [Google][3]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2018/02/20/62-the-eval-routine-in-perl-6-part-1/?share=twitter "Click to share on Twitter"
  [2]: https://perl6.online/2018/02/20/62-the-eval-routine-in-perl-6-part-1/?share=facebook "Click to share on Facebook"
  [3]: https://perl6.online/2018/02/20/62-the-eval-routine-in-perl-6-part-1/?share=google-plus-1 "Click to share on Google+"