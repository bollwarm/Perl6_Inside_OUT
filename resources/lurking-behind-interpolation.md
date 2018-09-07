In the previous articles, we’ve seen that the undefined value cannot be easily interpolated in a string, as an exception occurs. Today, our goal is to see where exactly that happens in the source code of Rakudo.

So, as soon as we’ve looked at the Boolean values, let’s continue with them. Open perl6 in the REPL mode and create a variable:

	$ perl6
	To exit type 'exit' or '^D'
	&gt; my $b
	(Any)

The variable is undefined, so be ready to get an exception when interpolating it:

	&gt; "$b"
	Use of uninitialized value $b of type Any in string context.
	Methods .^name, .perl, .gist, or .say can be used to stringify it to something meaningful.
	 in block  at  line 1

Interpolation uses the Str method. For undefined values, this method is absent in the Bool class. So we have to trace back to the Mu class, where we can see the following collection of base methods:

	proto method Str(|) {*}

	multi method Str(Mu:U \v:) {
	   my $name = (defined($*VAR_NAME) ?? $*VAR_NAME !! try v.VAR.?name) // '';
	   $name ~= ' ' if $name ne '';

	   warn "Use of uninitialized value {$name}of type {self.^name} in string"
	      ~ " context.\nMethods .^name, .perl, .gist, or .say can be"
	      ~ " used to stringify it to something meaningful.";
	   ''
	}

	multi method Str(Mu:D:) {
	    nqp::if(
	        nqp::eqaddr(self,IterationEnd),
	        "IterationEnd",
	        self.^name ~ '&lt;' ~ nqp::tostr_I(nqp::objectid(self)) ~ '&gt;'
	    )
	}

The proto-definition gives the pattern for the Str methods. The vertical bar in the signature indicates that the proto does not validate the type of the argument and can also capture more arguments.

In the Str(Mu:U) method you can easily see the text of the error message. This method is called for the undefined variable. In our case, with the Boolean variable, there’s no Str(Bool:U) method in the Bool class, so the call is dispatched to the method of the Mu class.

Notice how the variable name is obtained:

	my $name = (defined($*VAR_NAME) ?? $*VAR_NAME !! try v.VAR.?name) // '';

It tries either the dynamic variable $\*VAR\_NAME or the name method of the VAR object.

You can easily see which branch is used: just add a couple of printing instructions to the Mu class and recompile Rakudo:

	proto method Str(|) {*}
	multi method Str(Mu:U \v:) {
	    warn "VAR_NAME=$*VAR_NAME" if defined $*VAR_NAME;
	    warn "v.VAR.name=" ~ v.VAR.name if v.VAR.?name;
	    . . .

Now execute the same interpolation:

	&gt; my $b ;
	(Any)
	&gt; "$b"
	VAR_NAME=$b
	  in block  at  line 1

So, the name was taken from the $\*VAR\_NAME variable.

What about the second multi-method Str(Mu:D:)? It is important to understand that it will not be called for a defined Boolean object because the Bool class has a proper variant already.

### Share this:

* [Twitter][1]
* [Facebook][2]
* [Google][3]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2017/12/25/lurking-behind-interpolation/?share=twitter "Click to share on Twitter"
  [2]: https://perl6.online/2017/12/25/lurking-behind-interpolation/?share=facebook "Click to share on Facebook"
  [3]: https://perl6.online/2017/12/25/lurking-behind-interpolation/?share=google-plus-1 "Click to share on Google+"