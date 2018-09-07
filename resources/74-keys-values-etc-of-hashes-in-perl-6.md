In Perl 6, you can restrict the content of a variable container by specifying its type, for example:

	my Int $i;

There is only one value in a scalar variable. You can extend the concept to arrays and let its element to keep only integers, as it is done in the next example:

	&gt; my Int @i;
	[]

	&gt; @i.push(42);
	[42]

	&gt; @i.push('Hello');
	Type check failed in assignment to @i;
	expected Int but got Str ("Hello")
	  in block &lt;unit&gt; at &lt;unknown file&gt; line 1

Hashes keeps pairs, so you can specify the type of both keys and values. The syntax is not deductible from the above examples.

First, let us announce the type of the value:

	my Str %s;

Now, it is possible to have strings as values:

	&gt; %s&lt;Hello&gt; = 'World'
	World

	&gt; %s&lt;42&gt; = 'Fourty-two'
	Fourty-two

But it’s not possible to save integers:

	&gt; %s&lt;x&gt; = 100
	Type check failed in assignment to %s;
	expected Str but got Int (100)
	  in block &lt;unit&gt; at &lt;unknown file&gt; line 1

(By the way, notice that in the case of %s&lt;42&gt; the key is a string.)

To specify the type of the second dimension, namely, of the hash keys, give the type in curly braces:

	my %r{Rat};

This variable is also referred to as _object hash_.

Having this, Perl expects you to have Rat keys for this variable:

	&gt; %r&lt;22/7&gt; = pi
	3.14159265358979

	&gt; %r
	{22/7 =&gt; 3.14159265358979}

Attempts to use integers or strings, for example, fail:

	&gt; %r&lt;Hello&gt; = 1
	Type check failed in binding to parameter 'key';
	expected Rat but got Str ("Hello")
	  in block &lt;unit&gt; at &lt;unknown file&gt; line 1

	&gt; %r{23} = 32
	Type check failed in binding to parameter 'key';
	expected Rat but got Int (23)
	  in block &lt;unit&gt; at &lt;unknown file&gt; line 1

Finally, you can specify the types of both keys and values:

	my Str %m{Int};

This variable can be used for translating month number to month names but not vice versa:

	&gt; %m{3} = 'March'
	March

	&gt; %m&lt;March&gt; = 3
	Type check failed in binding to parameter 'key';
	expected Int but got Str ("March")
	  in block &lt;unit&gt; at &lt;unknown file&gt; line 1

### Share this:

* [Twitter][1]
* [Facebook][2]
* [Google][3]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2018/04/08/74-keys-values-etc-of-hashes-in-perl-6/?share=twitter "Click to share on Twitter"
  [2]: https://perl6.online/2018/04/08/74-keys-values-etc-of-hashes-in-perl-6/?share=facebook "Click to share on Facebook"
  [3]: https://perl6.online/2018/04/08/74-keys-values-etc-of-hashes-in-perl-6/?share=google-plus-1 "Click to share on Google+"