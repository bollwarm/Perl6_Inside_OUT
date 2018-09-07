In the previous posts, we saw many examples of calling NQP functions from the Perl 6 modules. One of the frequent calls was nqp::getattr. Let us see what that function does.

Here are a couple of recent examples:

	nqp::isge_i($pos,0)
	  &amp;&amp; nqp::isconcrete(**nqp::getattr**(self,List,'$!reified'))

	. . .

	nqp::if(
	  nqp::iseq_i(
	    **nqp::getattr**(
	      **nqp::getattr**($self,Code,'$!signature'),
	      Signature,
	      '$!count'
	  ),1)

When you first look at this, you may think that a string with a dollar such as $!signature or $!count or $!reified is a fancy representation of some internal attribute, and the non-alphabetical characters are used to prevent name clashes.

In fact, this is nothing more than an attribute of the class. A random example from src/core/Any-iterable-methods.pm:

	my class IterateMoreWithPhasers does SlippyIterator {
	    has &amp;!block;
	    has $!source;
	    has $!count;
	    has $!label;
	    has $!value-buffer;
	    has $!did-init;
	    has $!did-iterate;
	    has $!NEXT;
	    has $!CAN_FIRE_PHASERS;

The parameters of the nqp::getattr method are: an object, its class, and the name of the attribute.

Try it out in a simple class:

	use nqp;

	class C {
	    has $!attr;

	    method set_attr($value) {
	        $!attr = $value;
	    }
	}

	my $o := nqp::create(C);
	$o.set_attr('my value');
	nqp::say(nqp::getattr($o, C, '$!attr')); _# my value_

The class A has one private attribute $!attr, which is set with a manual setter method set\_attr.

After the new object is created, the attribute is set to some text value. Then, we use nqp::getattr to read the value from the attribute. Notice that the name of the attributed is passed as a string including the dollar and the exclamation mark characters.

The setter method in this example was needed because you cannot access a private attribute from outside. This is not the case for public attributes, which, in fact, are private attributes, for which Perl 6 creates getter and setter automatically. Here is an updated version of the same program, that employs a public attribute and still uses nqp::getattr:

	use nqp;

	class C {
	    has $.attr is rw;
	}

	my $o := nqp::create(C);
	$o.attr = 'other value';
	nqp::say(nqp::getattr($o, C, '$!attr')); _# other value_

This code is simpler and does not require an explicit setter method anymore.

Although the $.attr field is declared with the dot twigil, the actual attribute still resides in an attribute with the name $!attr. The following code does not work:

	nqp::say(nqp::getattr($o, C, '**$.attr**'));

An exception is thrown in this case:

	P6opaque: no such attribute '$.attr' in type C when trying to get a value
	  in block &lt;unit&gt; at getattr-2.pl line 9

That’s all for today. Today, you were using a tiny bit of NQP in your Perl 6 program!

### Share this:

* [Twitter][1]
* [Facebook][2]
* [Google][3]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2018/01/09/what-does-nqpgetattr-do/?share=twitter "Click to share on Twitter"
  [2]: https://perl6.online/2018/01/09/what-does-nqpgetattr-do/?share=facebook "Click to share on Facebook"
  [3]: https://perl6.online/2018/01/09/what-does-nqpgetattr-do/?share=google-plus-1 "Click to share on Google+"