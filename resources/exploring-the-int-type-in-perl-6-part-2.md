Today, the journey to the internals of Int continues and first let’s make a deep dive into one on of the fascinating methods, is-prime. If you never used it, this is a great method that implements the logic, which is usually not built-in in a programming language. It is also great because primality is an attribute of an integer and you get it for free for all integer numbers in Perl 6.

So, this is how the method is defined in src/core/Int.pm:

	method is-prime(--&gt; Bool:D) {
	    nqp::p6bool(nqp::isprime_I(self,100))
	}

As in many other cases, a Perl module only passes execution to some underlying NQP function. Let us try to track it down. The constant 100 in the call is a number of tests, which I will not touch here: you may get the details of the [algorithm][1] on Wikipedia, for example.

In the NQP sources, you are asked (src/vm/moar/QAST/QASTOperationsMAST.nqp) to go one level further, to MoarVM:

	QAST::MASTOperations.add_core_moarop_mapping('isprime_I', 'isprime_I');

For the JVM backend, the implementation is a bit easier to reach (src/vm/jvm/runtime/org/perl6/nqp/runtime/Ops.java):

	public static long isprime_I(SixModelObject a, long certainty, ThreadContext tc) {
	    BigInteger bi = getBI(tc, a);
	    if (bi.compareTo(BigInteger.valueOf(1)) &lt;= 0) {
	        return 0;
	    }
	    return bi.[isProbablePrime][2]((int)certainty) ? 1 : 0;
	}

It is a surprise that detecting if the number is prime is not 100% precise (the more accuracy you want, the slower it works, and ideally the number of rounds should depend on the tested number, while I hope the chosen number of rounds should give more than enough that you ever need).

For completeness, look briefly at the JavaScript function (src/vm/js/nqp-runtime/bignum.js):

	op.isprime_I = function(n) {
	     return intishBool(sslBignum(getBI(n).toString()).probPrime(50));
	};

For some reason, the number of tests is only 50 here.

Nevertheless, MoarVM is my primary goal, so let us try exploring it further, even if it is not that easy.

There are a few mappings and switches that select between different operations, such as (generated file src/core/ops.h):

	#define MVM_OP_lcm_I 447
	#define MVM_OP_expmod_I 448
	**#define MVM_OP_isprime_I 449**
	#define MVM_OP_rand_I 450
	#define MVM_OP_coerce_In 451

An interesting fact about this generated list is that it is prepared by the script tools/update\_ops.p6, which is a script in Perl 6:

	#!/usr/bin/env perl6
	# This script processes the op list into a C header file that contains
	# info about the opcodes.

The numbers are, actually, opcodes. And then we finally get to the place where it looks like a function call is prepared (src/jit/graph.c):

	case MVM_OP_isprime_I: {
	    MVMint16 dst = ins-&gt;operands[0].reg.orig;
	    MVMint32 invocant = ins-&gt;operands[1].reg.orig;
	    MVMint32 rounds = ins-&gt;operands[2].reg.orig;
	    MVMJitCallArg args[] = { { MVM_JIT_INTERP_VAR, MVM_JIT_INTERP_TC },
	                             { MVM_JIT_REG_VAL, **invocant** },
	                             { MVM_JIT_REG_VAL, **rounds** } };
	    jg_append_call_c(tc, jg, **op_to_func(tc, op)**, 3, args, MVM_JIT_RV_INT, dst);
	    break;
	}

In the list of arguments, you can see that the number of tests (rounds) is also passed. The op\_to\_func function takes the thread context and the opcode. The function is defined in the same file and is a set of another switch/case sequence:

	static void * op_to_func(MVMThreadContext *tc, MVMint16 opcode) {
	    switch(opcode) {
	        case MVM_OP_checkarity: return MVM_args_checkarity;
	        case MVM_OP_say: return MVM_string_say;
	        case MVM_OP_print: return MVM_string_print;
	        . . .
	        **case MVM_OP_isprime_I: return MVM_bigint_is_prime;**

It returns a pointer to a function (void \*) that should finally do the job, so let’s look for MVM\_bigint\_is\_prime. It is found in src/math/bigintops.c in the MoarVM repository:

	MVMint64 MVM_bigint_is_prime(MVMThreadContext *tc, MVMObject *a, MVMint64 b) {
	    /* mp_prime_is_prime returns True for 1, and I think
	     * it's worth special-casing this particular number :-)
	     */
	     MVMP6bigintBody *ba = get_bigint_body(tc, a);

	    if (MVM_BIGINT_IS_BIG(ba) || ba-&gt;u.smallint.value != 1) {
	        mp_int *tmp[1] = { NULL };
	        mp_int *ia = force_bigint(ba, tmp);
	        if (mp_cmp_d(ia, 1) == MP_EQ) {
	            clear_temp_bigints(tmp, 1);
	            return 0;
	        }
	        else {
	            int result;
	            **mp_prime_is_prime(ia, b, &amp;result);**
	            clear_temp_bigints(tmp, 1);
	            return result;
	        }
	    } else {
	        /* we only reach this if we have a smallint that's equal to 1.
	         * which we define as not-prime. */
	        return 0;
	    }
	}

This function passes the job further to a library function mp\_prime\_is\_prime.

If you followed the adventures of the method internals in this blog post, you might be quite exhausted. So let me stop for today because there’s a lot more to say about today’s topic.

### Share this:

* [Twitter][3]
* [Facebook][4]
* [Google][5]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://en.wikipedia.org/wiki/Miller%E2%80%93Rabin_primality_test
  [2]: https://www.tutorialspoint.com/java/math/biginteger_isprobableprime.htm
  [3]: https://perl6.online/2018/01/18/exploring-the-int-type-in-perl-6-part-2/?share=twitter "Click to share on Twitter"
  [4]: https://perl6.online/2018/01/18/exploring-the-int-type-in-perl-6-part-2/?share=facebook "Click to share on Facebook"
  [5]: https://perl6.online/2018/01/18/exploring-the-int-type-in-perl-6-part-2/?share=google-plus-1 "Click to share on Google+"