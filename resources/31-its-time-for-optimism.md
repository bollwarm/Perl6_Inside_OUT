Today, we will not talk about the internals of Rakudo, NQP, or MoarVM; let me pause for a bit and talk about some random things related to Perl 6 and its future.

## Efficiency

If you follow my blog, I have an update to the post about [optimising MoarVM][1], and it appears that when making calculations with many big numbers (e.g., 3000 \*\* 4000), Perl 6 is ~15% faster than Perl 5.

Not to mention that the code is more expressive. Just compare visually.

Perl 5:

	use v5.10;
	use bigint;

	for (my $i = 1; $i &lt;= 5000; $i++) { # Ranges do not work with bigint
	    say $i ** $i;
	}

Perl 6:

	for 1 .. 5000 -&gt; $i {
	    say $i ** $i;
	}

Built-in support for big numbers is pretty awesome (something like the full Unicode support).

## Antihype

If you follow the Perl groups on Facebook (or just visit reddit time to time), you might notice a new wave of semi-haters saying the Perl 6 stole the name, blocked the Perl 5 development, cut Perl jobs in general and even blocked some money flows (was there any?). I was very surprised that that is happening now. It was OK ten years ago, where it could be difficult to believe that Perl 6 would ever be a reality.

Today, although there are still many difficulties, it is so much closer to the language of a dream, and all you need is just work every day in a few areas: compiler improvements, educational activities, writing documentation. No one will bring a new shiny Perl 6 to you; just act and serve yourself.

## FOSDEM ahead

In a few days, on 3-4 February, there’s a great chance to see the Perl 6 people at FOSDEM, the biggest European open source conference. There will be a booth at the venue (building K, I believe) and a full day of talks in the [Perl Programming Languages devroom][2] (notice the plural form).

## Online materials

I can understand a bit why people complain about the lack of documentation. There are tons of outdated materials, which are, actually, not often pop up in Google. But for me, such complains rather indicate human resistance to learn a new language because it is so huge.

There are at least two resources which are quite structural and contain a lot:

Perl 6 Documentation — [docs.perl6.org][3]

Perl 6 Introduction — [perl6intro.com][4]

I do not suggest everyone reading sources of the compiler but it is also a great thing to do 🙂

## Compiler at home

There’s nothing easier than installing [Rakudo Star][5] on your computer. It immediately gives you both a ready-to-use compiler and a set of some modules.

Don’t want downloading any software? Go online and try Perl 6 at [glot.io/new/perl6][6].

## Offline materials

In 2017, seven Perl 6 books were published. They cover many aspects and aim to different audiences. Just grab one, either on paper or as an e-book.

[Perl 6 at a Glance][7] — a brief introduction about new features of Perl 6. A good start if you don’t want to spend weeks on reading a book.

[Perl 6 Deep Dive][8] — a textbook covering almost everything you need to know about the language. For sure, much more than you need to start.

[Using Perl 6][9] — an exercise book with solutions of 100 programming challenges. Just copy-and-paste, or, even better, think through and solve it better.

[Think Perl 6][10] — a Perl 6-based tutorial on programming in general. With very few effort from your side, you get through the whole language and learn both programming and Perl 6.

[Perl 6 Fundamentals][11] — a book with practical examples of the Perl 6 code that you can start using already today. Not only you get the working code, but you also benefit from understanding Perl 6.

[Parsing with Perl 6 Regexes and Grammars][12] — a book that will guide you through another set of programs using regexes and grammars, real killer features of Perl 6.

[Learning to Program in Perl 6][13] without leaving the command line — a small book that you can read in a couple of hours; it demonstrates many little things that can be very useful for daily use.

You can take a look at the books at FOSDEM, too.

## Is Perl 6 Perl?

If you doubt, you are either a pessimist or overloaded with your day job, or just love to complain. Is Perl 6 Perl? Of course it is!

If someone tells you that to create a class method you need to write the following code, ignore it or say that this is an exaggeration:

	method from-ingredients(::?CLASS:U $pizza: @ingredients)

It was a real comment on reddit. Even if you can do that formally, why on Earth you should do it that way instead of writing a simple and clean code.

Fortunately or not, we are all now at the point in time when Perl 6 has all chances to shine. Even if you cannot find a Perl 6 job, just continue your daily work in other languages. If you slowly start adding Perl 6 bits, you will help to bootstrap it. What is needed from us to Perl 6 today is just some additional love to this great language.

### Share this:

* [Twitter][14]
* [Facebook][15]
* [Google][16]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2018/01/19/30-how-i-was-optimising-moarvm/
  [2]: https://fosdem.org/2018/schedule/track/perl_programming_languages/
  [3]: https://docs.perl6.org
  [4]: http://perl6intro.com
  [5]: http://rakudo.org/how-to-get-rakudo/
  [6]: https://glot.io/new/perl6
  [7]: https://deeptext.media/perl6-at-a-glance
  [8]: https://www.packtpub.com/application-development/perl-6-deep-dive
  [9]: https://deeptext.media/using-perl6
  [10]: http://greenteapress.com/wp/think-perl-6/
  [11]: http://www.apress.com/us/book/9781484228982
  [12]: https://www.apress.com/gp/book/9781484232279
  [13]: https://www.amazon.com/Learning-program-Perl-Getting-programming-ebook/dp/B07221XCVL
  [14]: https://perl6.online/2018/01/21/31-its-time-for-optimism/?share=twitter "Click to share on Twitter"
  [15]: https://perl6.online/2018/01/21/31-its-time-for-optimism/?share=facebook "Click to share on Facebook"
  [16]: https://perl6.online/2018/01/21/31-its-time-for-optimism/?share=google-plus-1 "Click to share on Google+"