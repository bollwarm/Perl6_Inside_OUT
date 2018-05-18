A Friday story for your pleasure. An attentive reader could notice [yesterday][1] that MoarVM is using many switch/case choices when it processes the bytecode.

In src/jit/graph.c, there is code which returns the address of the function corresponding to the given opcode:

	static void * op_to_func(MVMThreadContext *tc, MVMint16 opcode) {
	    switch(opcode) {
	        case MVM_OP_checkarity: return MVM_args_checkarity;
	        case MVM_OP_say: return MVM_string_say;
	        case MVM_OP_print: return MVM_string_print;
	        case MVM_OP_isnull: return MVM_is_null;

In the same file, another function:

	static MVMint32 consume_invoke(MVMThreadContext *tc, MVMJitGraph *jg,
	                               MVMSpeshIterator *iter, MVMSpeshIns *ins) {

	. . .

	    while ((ins = ins-&gt;next)) {
	        switch(ins-&gt;info-&gt;opcode) {
	            case MVM_OP_arg_i:
	            case MVM_OP_arg_n:
	            case MVM_OP_arg_s:
	            case MVM_OP_arg_o:
	            case MVM_OP_argconst_i:
	            case MVM_OP_argconst_n:
	            case MVM_OP_argconst_s:
	                MVM_jit_log(tc, "Invoke arg: &lt;%s&gt;\n", ins-&gt;info-&gt;name);
	                arg_ins[i++] = ins;
	                break;
	            case MVM_OP_invoke_v:
	                return_type = MVM_RETURN_VOID;
	                return_register = -1;
	                code_register = ins-&gt;operands[0].reg.orig;
	                spesh_cand = -1;
	                is_fast = 0;
	                goto checkargs;
	            case MVM_OP_invoke_i:
	                return_type = MVM_RETURN_INT;
	                return_register = ins-&gt;operands[0].reg.orig;
	                code_register = ins-&gt;operands[1].reg.orig;
	                spesh_cand = -1;
	                is_fast = 0;
	                goto checkargs;

(By the way, notice the presence of goto in place of break.)

Similar things happen inside two more functions, consume\_ins and comsume\_reprop, in the same file. Each switch/case set contains hundreds of cases. There are more than 800 different opcodes currently, and many of them have their own branch in every switch/case.

It looks inefficient. Although the GCC compiler can optimise such sequences, what if we replace everything with arrays so that we can index it directly?

The easiest candidate for this operation is the op\_to\_func function: its only job is to return a pointer to the function in response to the given opcode value. So, write a small Perl script that transforms the C source:

	my %func2opcode;
	my %opcode2func;
	for my $f (keys %f) {
	    my $list_of_lists = $f{$f};

	    my @opcodes;
	    for my $list (@$list_of_lists) {
	        for my $opcode (@$list) {
	            push @opcodes, $opcode;
	            $opcode2func{$opcode} = $f;
	        }
	    }

	    $func2opcode{$f} = [@opcodes];
	}

	my @opcodes = ();
	for my $opcode_name (keys %opcode2func) {
	    my $opcode_value = $opcodes{$opcode_name};
	    $opcodes[$opcode_value] = $opcode2func{$opcode_name};
	}

	say 'void* opcode2func[] = {';
	for my $func (@opcodes) {
	    $func //= 'NULL';
	    say "\t$func,";
	}
	say '};';

The script generates an array, where the index of the element is the opcode, and the value is the pointer to a function:

	void* opcode2func[] = {
		NULL,
		NULL,
		NULL,
	        . . .
		MVM_frame_getdynlex,
		MVM_frame_binddynlex,
		NULL,
		NULL,
		MVM_args_set_result_int,
		MVM_args_set_result_num,
		MVM_args_set_result_str,
		MVM_args_set_result_obj,
		MVM_args_assert_void_return_ok,
	        . . .

Now, our initial function is extremely short and clear:

	static void * op_to_func(MVMThreadContext *tc, MVMint16 opcode) {
	    return opcode2func[opcode];
	}

(The thread context variable is used for error reporting, which I ignored here).

The idea behind this change is, among the potential gain of direct indexing, is the observation that the function is called for every opcode that the VM reads from the source. I did not take into account any performance improvements that JIT could add to it.

Anyway, the other switch/case places look less attractive to change. First, you should create many small functions for each branch, and after you have that done, you will lose performance by the need to call a function (push arguments on stack, etc.).

To test the changes, I ran the following program:

	for 1..100 {my @a; @a[$_] = $_ ** $_ for 1..5000;}

Before the change, it took 41 seconds on my laptop. After the change, it became 44 🙂

Ah, wait, let’s in-place accessing the array in all 142 places where the function is called:

	- jg_append_call_c(tc, jg, **op_to_func(tc, op)**, 3, args, MVM_JIT_RV_PTR, dst);
	+ jg_append_call_c(tc, jg, **opcode2func[op]**, 3, args, MVM_JIT_RV_PTR, dst);

This change resulted in 41 seconds again, as it was with the original code.

OK, so a naïve ad hoc attempt to find the bottleneck by just looking at the source code failed. It would be a good idea to try profiling the code next time.

I could conclude here with the statement that MoarVM is already well optimised but I would still want 10x speeding up. The same program (with the corresponding tiny syntax changes) takes only 4 seconds on the same computer when run by Perl 5.

## Update 1

I slipped down to the JIT source in this blog post, so check out my [next post][2] too.

## Update 2

In Perl 5, with the bigint module, you cannot use the range 1..5000, so after some number, all $\_ \*\* $\_ became a bare ‘inf’. Here’s the updated program that you may want to use for testing both Perl 5 and Perl 6. To prevent any misleads, it prints the results so that you can check it and compare the two versions.

Perl 5:

	use v5.10;
	use bigint;

	for (my $i = 1; $i &lt;= 5000; $i++) {
	    say $i ** $i;
	}

Perl 6:

	for 1 .. 5000 -&gt; $i {
	    say $i ** $i;
	}

On my laptop, the programs with maximum of 1000 took 3.9 and 4.1 seconds (Perl 5 and Perl 6), and for 5000 values, it took 12m45s for Perl 5 and 11m3s for Perl 6. Notice that these times also include disk I/O.

### Share this:

* [Twitter][3]
* [Facebook][4]
* [Google][5]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2018/01/18/exploring-the-int-type-in-perl-6-part-2/
  [2]: https://perl6.online/2018/01/20/the-opcode-dispatching-loop-in-moarvm/
  [3]: https://perl6.online/2018/01/19/30-how-i-was-optimising-moarvm/?share=twitter "Click to share on Twitter"
  [4]: https://perl6.online/2018/01/19/30-how-i-was-optimising-moarvm/?share=facebook "Click to share on Facebook"
  [5]: https://perl6.online/2018/01/19/30-how-i-was-optimising-moarvm/?share=google-plus-1 "Click to share on Google+"