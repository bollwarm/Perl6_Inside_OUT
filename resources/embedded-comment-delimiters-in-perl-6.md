In Perl 6, you can leave a comment inside the line of code using the \#\`(...) syntax:

	my Int **#`(Integer variable)** $i = **#`(initialising the variable**) 42;
	say **#`( Printing it )** $i;

This program is equivalent to the following:

	my Int $i = 42;
	say $i;

The body of the embedded comment is located between the pair of brackets, and you are not limited to parentheses only. For example, both \{\} or [] perfectly work:

	my Int #`(Integer variable) $i = #`[initialising the variable] 42;
	say #`{ Printing it } $i;

Perl 6 allows even more. The following program is also a correct Perl 6 program with the same inline comments that in the above samples:

	my Int #`﹝Integer variable﹞ $i = #`⸨initialising the variable⸩ 42;
	say #`∈ Printing it ∋ $i;

Let us see which other brackets are available for the programmer and where it is defined in the source code.

So, here is a place for extracting an embedded comment in the Grammar (src/core/Grammar.nqp):

	proto token comment { &lt;...&gt; }

	. . .

	token comment:sym&lt;#`(...)&gt; {
	    **'#`' &lt;?opener&gt;** {}
	    [ &lt;.quibble(self.slang_grammar('Quote'))&gt; || &lt;.typed_panic: 'X::Syntax::Comment::Embedded'&gt; ]
	}

The comment token expects the \#\` sequence followed by the opener token. What is an opener? Here we are (still in src/Perl6/Grammar.nqp):

	role STD {
	    token opener {
	        &lt;[
	        \x0028 \x003C \x005B \x007B \x00AB \x0F3A \x0F3C \x169B \x2018 \x201A \x201B
	        \x201C \x201E \x201F \x2039 \x2045 \x207D \x208D \x2208 \x2209 \x220A \x2215
	        \x223C \x2243 \x2252 \x2254 \x2264 \x2266 \x2268 \x226A \x226E \x2270 \x2272
	        \x2274 \x2276 \x2278 \x227A \x227C \x227E \x2280 \x2282 \x2284 \x2286 \x2288
	        \x228A \x228F \x2291 \x2298 \x22A2 \x22A6 \x22A8 \x22A9 \x22AB \x22B0 \x22B2
	        \x22B4 \x22B6 \x22C9 \x22CB \x22D0 \x22D6 \x22D8 \x22DA \x22DC \x22DE \x22E0
	        \x22E2 \x22E4 \x22E6 \x22E8 \x22EA \x22EC \x22F0 \x22F2 \x22F3 \x22F4 \x22F6
	        \x22F7 \x2308 \x230A \x2329 \x23B4 \x2768 \x276A \x276C \x276E \x2770 \x2772
	        \x2774 \x27C3 \x27C5 \x27D5 \x27DD \x27E2 \x27E4 \x27E6 \x27E8 \x27EA \x2983
	        \x2985 \x2987 \x2989 \x298B \x298D \x298F \x2991 \x2993 \x2995 \x2997 \x29C0
	        \x29C4 \x29CF \x29D1 \x29D4 \x29D8 \x29DA \x29F8 \x29FC \x2A2B \x2A2D \x2A34
	        \x2A3C \x2A64 \x2A79 \x2A7D \x2A7F \x2A81 \x2A83 \x2A8B \x2A91 \x2A93 \x2A95
	        \x2A97 \x2A99 \x2A9B \x2AA1 \x2AA6 \x2AA8 \x2AAA \x2AAC \x2AAF \x2AB3 \x2ABB
	        \x2ABD \x2ABF \x2AC1 \x2AC3 \x2AC5 \x2ACD \x2ACF \x2AD1 \x2AD3 \x2AD5 \x2AEC
	        \x2AF7 \x2AF9 \x2E02 \x2E04 \x2E09 \x2E0C \x2E1C \x2E20 \x2E28 \x3008 \x300A
	        \x300C \x300E \x3010 \x3014 \x3016 \x3018 \x301A \x301D \xFD3E \xFE17 \xFE35
	        \xFE37 \xFE39 \xFE3B \xFE3D \xFE3F \xFE41 \xFE43 \xFE47 \xFE59 \xFE5B \xFE5D
	        \xFF08 \xFF1C \xFF3B \xFF5B \xFF5F \xFF62
	    ]&gt;
	}

Wow, quite a lot! Notice that these are only opening brackets. Let’s print them (just copy and paste the list and pass it to say):

	( &lt; [ { « ༺ ༼ ᚛ ‘ ‚ ‛
	“ „ ‟ ‹ ⁅ ⁽ ₍ ∈ ∉ ∊ ∕
	∼ ≃ ≒ ≔ ≤ ≦ ≨ ≪ ≮ ≰ ≲
	≴ ≶ ≸ ≺ ≼ ≾ ⊀ ⊂ ⊄ ⊆ ⊈
	⊊ ⊏ ⊑ ⊘ ⊢ ⊦ ⊨ ⊩ ⊫ ⊰ ⊲
	⊴ ⊶ ⋉ ⋋ ⋐ ⋖ ⋘ ⋚ ⋜ ⋞ ⋠
	⋢ ⋤ ⋦ ⋨ ⋪ ⋬ ⋰ ⋲ ⋳ ⋴ ⋶
	⋷ ⌈ ⌊ 〈 ⎴ ❨ ❪ ❬ ❮ ❰ ❲
	❴ ⟃ ⟅ ⟕ ⟝ ⟢ ⟤ ⟦ ⟨ ⟪ ⦃
	⦅ ⦇ ⦉ ⦋ ⦍ ⦏ ⦑ ⦓ ⦕ ⦗ ⧀
	⧄ ⧏ ⧑ ⧔ ⧘ ⧚ ⧸ ⧼ ⨫ ⨭ ⨴
	⨼ ⩤ ⩹ ⩽ ⩿ ⪁ ⪃ ⪋ ⪑ ⪓ ⪕
	⪗ ⪙ ⪛ ⪡ ⪦ ⪨ ⪪ ⪬ ⪯ ⪳ ⪻
	⪽ ⪿ ⫁ ⫃ ⫅ ⫍ ⫏ ⫑ ⫓ ⫕ ⫬
	⫷ ⫹ ⸂ ⸄ ⸉ ⸌ ⸜ ⸠ ⸨ 〈 《
	「 『 【 〔 〖 〘 〚 〝 ﴾ ︗ ︵
	︷ ︹ ︻ ︽ ︿ ﹁ ﹃ ﹇ ﹙ ﹛ ﹝
	（ ＜ ［ ｛ ｟ ｢

I am almost sure nobody will ever use all this variety in the same program, neither you may be familiar with some characters from the list. Nevertheless, there are not only pure brackets here but also other characters such as _less or equal_, which have the corresponding pair in the Unicode space.

Let us now find the closing brackets. There is a list in nqp/src/HLL/Grammar.pm:

	grammar HLL::Grammar {
	    my $brackets := '&lt;&gt;[](){}' ~ "\x[0028]\x[0029]\x[003C]\x[003E]\x[005B]\x[005D]" ~
	    "\x[007B]\x[007D]\x[00AB]\x[00BB]\x[0F3A]\x[0F3B]\x[0F3C]\x[0F3D]\x[169B]\x[169C]" ~
	    "\x[2018]\x[2019]\x[201A]\x[2019]\x[201B]\x[2019]\x[201C]\x[201D]\x[201E]\x[201D]" ~
	    "\x[201F]\x[201D]\x[2039]\x[203A]\x[2045]\x[2046]\x[207D]\x[207E]\x[208D]\x[208E]" ~
	    "\x[2208]\x[220B]\x[2209]\x[220C]\x[220A]\x[220D]\x[2215]\x[29F5]\x[223C]\x[223D]" ~
	    "\x[2243]\x[22CD]\x[2252]\x[2253]\x[2254]\x[2255]\x[2264]\x[2265]\x[2266]\x[2267]" ~
	    "\x[2268]\x[2269]\x[226A]\x[226B]\x[226E]\x[226F]\x[2270]\x[2271]\x[2272]\x[2273]" ~
	    "\x[2274]\x[2275]\x[2276]\x[2277]\x[2278]\x[2279]\x[227A]\x[227B]\x[227C]\x[227D]" ~
	    "\x[227E]\x[227F]\x[2280]\x[2281]\x[2282]\x[2283]\x[2284]\x[2285]\x[2286]\x[2287]" ~
	    "\x[2288]\x[2289]\x[228A]\x[228B]\x[228F]\x[2290]\x[2291]\x[2292]\x[2298]\x[29B8]" ~
	    "\x[22A2]\x[22A3]\x[22A6]\x[2ADE]\x[22A8]\x[2AE4]\x[22A9]\x[2AE3]\x[22AB]\x[2AE5]" ~
	    "\x[22B0]\x[22B1]\x[22B2]\x[22B3]\x[22B4]\x[22B5]\x[22B6]\x[22B7]\x[22C9]\x[22CA]" ~
	    "\x[22CB]\x[22CC]\x[22D0]\x[22D1]\x[22D6]\x[22D7]\x[22D8]\x[22D9]\x[22DA]\x[22DB]" ~
	    "\x[22DC]\x[22DD]\x[22DE]\x[22DF]\x[22E0]\x[22E1]\x[22E2]\x[22E3]\x[22E4]\x[22E5]" ~
	    "\x[22E6]\x[22E7]\x[22E8]\x[22E9]\x[22EA]\x[22EB]\x[22EC]\x[22ED]\x[22F0]\x[22F1]" ~
	    "\x[22F2]\x[22FA]\x[22F3]\x[22FB]\x[22F4]\x[22FC]\x[22F6]\x[22FD]\x[22F7]\x[22FE]" ~
	    "\x[2308]\x[2309]\x[230A]\x[230B]\x[2329]\x[232A]\x[23B4]\x[23B5]\x[2768]\x[2769]" ~
	    "\x[276A]\x[276B]\x[276C]\x[276D]\x[276E]\x[276F]\x[2770]\x[2771]\x[2772]\x[2773]" ~
	    "\x[2774]\x[2775]\x[27C3]\x[27C4]\x[27C5]\x[27C6]\x[27D5]\x[27D6]\x[27DD]\x[27DE]" ~
	    "\x[27E2]\x[27E3]\x[27E4]\x[27E5]\x[27E6]\x[27E7]\x[27E8]\x[27E9]\x[27EA]\x[27EB]" ~
	    "\x[2983]\x[2984]\x[2985]\x[2986]\x[2987]\x[2988]\x[2989]\x[298A]\x[298B]\x[298C]" ~
	    "\x[298D]\x[2990]\x[298F]\x[298E]\x[2991]\x[2992]\x[2993]\x[2994]\x[2995]\x[2996]" ~
	    "\x[2997]\x[2998]\x[29C0]\x[29C1]\x[29C4]\x[29C5]\x[29CF]\x[29D0]\x[29D1]\x[29D2]" ~
	    "\x[29D4]\x[29D5]\x[29D8]\x[29D9]\x[29DA]\x[29DB]\x[29F8]\x[29F9]\x[29FC]\x[29FD]" ~
	    "\x[2A2B]\x[2A2C]\x[2A2D]\x[2A2E]\x[2A34]\x[2A35]\x[2A3C]\x[2A3D]\x[2A64]\x[2A65]" ~
	    "\x[2A79]\x[2A7A]\x[2A7D]\x[2A7E]\x[2A7F]\x[2A80]\x[2A81]\x[2A82]\x[2A83]\x[2A84]" ~
	    "\x[2A8B]\x[2A8C]\x[2A91]\x[2A92]\x[2A93]\x[2A94]\x[2A95]\x[2A96]\x[2A97]\x[2A98]" ~
	    "\x[2A99]\x[2A9A]\x[2A9B]\x[2A9C]\x[2AA1]\x[2AA2]\x[2AA6]\x[2AA7]\x[2AA8]\x[2AA9]" ~
	    "\x[2AAA]\x[2AAB]\x[2AAC]\x[2AAD]\x[2AAF]\x[2AB0]\x[2AB3]\x[2AB4]\x[2ABB]\x[2ABC]" ~
	    "\x[2ABD]\x[2ABE]\x[2ABF]\x[2AC0]\x[2AC1]\x[2AC2]\x[2AC3]\x[2AC4]\x[2AC5]\x[2AC6]" ~
	    "\x[2ACD]\x[2ACE]\x[2ACF]\x[2AD0]\x[2AD1]\x[2AD2]\x[2AD3]\x[2AD4]\x[2AD5]\x[2AD6]" ~
	    "\x[2AEC]\x[2AED]\x[2AF7]\x[2AF8]\x[2AF9]\x[2AFA]\x[2E02]\x[2E03]\x[2E04]\x[2E05]" ~
	    "\x[2E09]\x[2E0A]\x[2E0C]\x[2E0D]\x[2E1C]\x[2E1D]\x[2E20]\x[2E21]\x[2E28]\x[2E29]" ~
	    "\x[3008]\x[3009]\x[300A]\x[300B]\x[300C]\x[300D]\x[300E]\x[300F]\x[3010]\x[3011]" ~
	    "\x[3014]\x[3015]\x[3016]\x[3017]\x[3018]\x[3019]\x[301A]\x[301B]\x[301D]\x[301E]" ~
	    "\x[FE17]\x[FE18]\x[FE35]\x[FE36]\x[FE37]\x[FE38]\x[FE39]\x[FE3A]\x[FE3B]\x[FE3C]" ~
	    "\x[FE3D]\x[FE3E]\x[FE3F]\x[FE40]\x[FE41]\x[FE42]\x[FE43]\x[FE44]\x[FE47]\x[FE48]" ~
	    "\x[FE59]\x[FE5A]\x[FE5B]\x[FE5C]\x[FE5D]\x[FE5E]\x[FF08]\x[FF09]\x[FF1C]\x[FF1E]" ~
	    "\x[FF3B]\x[FF3D]\x[FF5B]\x[FF5D]\x[FF5F]\x[FF60]\x[FF62]\x[FF63]\x[27EE]\x[27EF]" ~
	    "\x[2E24]\x[2E25]\x[27EC]\x[27ED]\x[2E22]\x[2E23]\x[2E26]\x[2E27]"
	#?if js
	    ~ nqp::chr(0x2329) ~ nqp::chr(0x232A)
	#?endif
	    ;

Here is its visualisation:

	&lt;&gt;[](){}()&lt;&gt;[]{}«»༺༻༼༽᚛᚜‘’‚’‛’“”„”‟”‹›⁅⁆
	⁽⁾₍₎∈∋∉∌∊∍∕⧵∼∽≃⋍≒≓≔≕≤≥≦≧≨≩≪≫≮≯≰≱≲≳≴≵≶≷≸≹≺≻≼≽
	≾≿⊀⊁⊂⊃⊄⊅⊆⊇⊈⊉⊊⊋⊏⊐⊑⊒⊘⦸⊢⊣⊦⫞⊨⫤⊩⫣⊫⫥⊰⊱⊲⊳⊴⊵⊶⊷⋉⋊
	⋋⋌⋐⋑⋖⋗⋘⋙⋚⋛⋜⋝⋞⋟⋠⋡⋢⋣⋤⋥⋦⋧⋨⋩⋪⋫⋬⋭⋰⋱⋲⋺⋳⋻⋴⋼⋶⋽
	⋷⋾⌈⌉⌊⌋〈〉⎴⎵❨❩❪❫❬❭❮❯❰❱❲❳❴❵⟃⟄⟅⟆⟕⟖⟝⟞⟢⟣⟤⟥⟦⟧⟨⟩⟪⟫
	⦃⦄⦅⦆⦇⦈⦉⦊⦋⦌⦍⦐⦏⦎⦑⦒⦓⦔⦕⦖⦗⦘⧀⧁⧄⧅⧏⧐⧑⧒⧔⧕⧘⧙⧚⧛⧸⧹⧼⧽⨫⨬⨭⨮⨴⨵⨼⨽⩤⩥
	⩹⩺⩽⩾⩿⪀⪁⪂⪃⪄⪋⪌⪑⪒⪓⪔⪕⪖⪗⪘⪙⪚⪛⪜⪡⪢⪦⪧⪨⪩⪪⪫⪬⪭⪯⪰⪳⪴⪻⪼⪽⪾⪿⫀⫁⫂
	⫃⫄⫅⫆⫍⫎⫏⫐⫑⫒⫓⫔⫕⫖⫬⫭⫷⫸⫹⫺⸂⸃⸄⸅⸉⸊⸌⸍⸜⸝⸠⸡⸨⸩〈〉《》「」『』【】
	〔〕〖〗〘〙〚〛〝〞︗︘︵︶︷︸︹︺︻︼︽︾︿﹀﹁﹂
	﹃﹄﹇﹈﹙﹚﹛﹜﹝﹞（）＜＞［］｛｝｟｠｢｣⟮⟯⸤⸥⟬⟭⸢⸣⸦⸧

So just pick a pair you like the most and amaze your colleagues.

In the peek\_delimiters method of the HLL::Grammar, you may see the following way of finding the closing pair:

	my str $stop := $start;
	my int **$brac := nqp::index($brackets, $start)**;
	if $brac &gt;= 0 {
	    # if it's a closing bracket, that's an error also
	    if $brac % 2 {
	        self.panic('Use of a closing delimiter for an opener is reserved');
	    }

	    # it's an opener, so get the closing bracket
	    **$stop := nqp::substr($brackets, $brac + 1, 1)**;

It finds the opening character in the $brackets string and takes the next one as its closing pair. As the most obvious brackets are located in the beginning of the string, the presence of the rest should not influence the performance at all.

༺ And that’s all for today. ༻

### Share this:

* [Twitter][1]
* [Facebook][2]
* [Google][3]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2018/01/23/embedded-comment-delimiters-in-perl-6/?share=twitter "Click to share on Twitter"
  [2]: https://perl6.online/2018/01/23/embedded-comment-delimiters-in-perl-6/?share=facebook "Click to share on Facebook"
  [3]: https://perl6.online/2018/01/23/embedded-comment-delimiters-in-perl-6/?share=google-plus-1 "Click to share on Google+"