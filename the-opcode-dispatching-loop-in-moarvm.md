Let me make some correction work following the [previous post][1]. I felt that something escaped from my view because changing the code did not bring any advances in speed.

Jonathan Worthington left a brilliant comment saying that I was trying to optimise the JIT compiler. Bang! Indeed, I thought that JIT should have had some influence, but I did not notice how I fell to the src/jit directory of MoarVM.

Today, we are looking into a different place where the opcodes are handled. I hope you will enjoy it as much as I did.

## Computed goto

Before we continue, let us take a look at the so-called _computed goto_ mechanism available in some of the C compilers, for example, [in GCC][2].

The following program illustrates the simplest virtual machine. First, it generates a random program and stores it in the prog array. Then, the program is being read opcode by opcode, and the switch statement chooses the path that is executed in response to the opcode.

	#include &lt;stdio.h&gt;
	#include &lt;time.h&gt;
	#include &lt;stdlib.h&gt;

	const int size = 10;

	int prog[size];

	void gen_prog() {
	    for (int c = 0; c != size; c++) {
	        prog[c] = rand() % 3;
	    }
	}

	void exec_prog() {
	    for (int c = 0; c != size; c++) {
	        switch(prog[c]) {
	            case 0:
	                printf("0\n");
	                break;
	            case 1:
	                printf("1\n");
	                break;
	            case 2:
	                printf("2\n");
	                break;
	        }
	    }
	}

	int main() {
	    srand(time(NULL));

	    gen_prog();
	    exec_prog();
	}

There are three different opcodes and thus three different actions that prints 0, 1, or 2. The program contains ten random commands.

This first program is not optimised (we do not take into account the optimisation that a compiler can do for us), and it should check all the branches before it finds the one for the given opcode.

Our next step: move the actions to separate functions:

	void op0() {
	    printf("0\n");
	}

	void op1() {
	    printf("1\n");
	}

	void op2() {
	    printf("2\n");
	}

Having that done, call the functions in switch/case:

	void exec_prog() {
	    for (int c = 0; c != 10; c++) {
	        switch(prog[c]) {
	            case 0:
	                op0();
	                break;
	            case 1:
	                op1();
	                break;
	            case 2:
	                op2();
	                break;
	        }
	    }
	}

At this point, the dispatching code looks uniform and can be replaced with an array containing pointers to the opX functions:

	void exec_prog() {
	    void (*ops[])() = {op0, op1, op2};

	    for (int c = 0; c != 10; c++) {
	        ops[prog[c]]();
	    }
	}

Now, it is really simple and transparent. Opcodes are indices of the array and directly lead to the desired function. Now, we can introduce computed goto. Here is an updated exec\_prog function:

	void exec_prog() {
	    prog[size] = 3;

	    void* ops[] = {&amp;&amp;op0, &amp;&amp;op1, &amp;&amp;op2, &amp;&amp;eop};

	    int c = 0;
	    goto *ops[prog[c++]];
	    op0:
	        printf("0\n");
	        goto *ops[prog[c++]];
	    op1:
	        printf("1\n");
	        goto *ops[prog[c++]];
	    op2:
	        printf("2\n");
	        goto *ops[prog[c++]];
	    eop:
	        NULL;
	}

What’s new here? First of all, there is no explicit loop. Also, all the functions are inlined as it was in the first program. The ops array contains now the addresses of the labels. They can be used as arguments of goto to jump directly to the place you need. From one hand, this is similar to function calls, from another, the code looks like the switch/case sequence and has no function calls.

The switch statement is also gone. On each step, the command pointer is incremented and thus the program jumps to different labels until the program is completely consumed. We intentionally added an end-of-program opcode (value = 3) so that it can stop the command loop.

## Back to MoarVM

It’s time to return to the sources of MoarVM. In src/core/interp.c, you can find our friend, the switch statement that dispatches control:

	DISPATCH(NEXT_OP) {
	    OP(no_op):
	        goto NEXT;
	    OP(const_i8):
	    OP(const_i16):
	    OP(const_i32):
	        MVM_exception_throw_adhoc(tc, "const_iX NYI");
	    OP(const_i64):
	        GET_REG(cur_op, 0).i64 = MVM_BC_get_I64(cur_op, 2);
	        cur_op += 10;
	        goto NEXT;
	    OP(const_n32):
	        MVM_exception_throw_adhoc(tc, "const_n32 NYI");

And it continues for other hundreds of opcodes. The capitalised names are macros depending on the MVM\_CGOTO flag:

	#define NEXT_OP (op = *(MVMuint16 *)(cur_op), cur_op += 2, op)

	**#if MVM_CGOTO**
	#define DISPATCH(op)
	#define OP(name) OP_ ## name
	#define NEXT *LABELS[NEXT_OP]
	**#else**
	#define DISPATCH(op) switch (op)
	#define OP(name) case MVM_OP_ ## name
	#define NEXT runloop
	**#endif**

If the compiler is able to do computed gotos, these macros generate the following code:

	{
	    OP_no_op:
	        goto *LABELS[(op = *(MVMuint16 *)(cur_op), cur_op += 2, op)];
	    OP_const_i8:
	    OP_const_i16:
	    OP_const_i32:
	        MVM_exception_throw_adhoc(tc, "const_iX NYI");
	        cur_op += 10;
	        goto *LABELS[(op = *(MVMuint16 *)(cur_op), cur_op += 2, op)];
	    OP_const_n32:
	        MVM_exception_throw_adhoc(tc, "const_n32 NYI");

For this case, the LABELS are loaded from src/core/oplabels.h:

	static const void * const LABELS[] = {
	    &amp;&amp;OP_no_op,
	    &amp;&amp;OP_const_i8,
	    &amp;&amp;OP_const_i16,
	    &amp;&amp;OP_const_i32,
	    &amp;&amp;OP_const_i64,
	    &amp;&amp;OP_const_n32,
	    &amp;&amp;OP_const_n64,
	    &amp;&amp;OP_const_s,

When the compiler does not support it, macros help to generate a traditional switch/case sequence:

	runloop: {
	    . . .

	    switch ((op = *(MVMuint16 *)(cur_op), cur_op += 2, op)) {
	        case MVM_OP_no_op:
	            goto runloop;
	        case MVM_OP_const_i8:
	        case MVM_OP_const_i16:
	        case MVM_OP_onst_i32:
	            MVM_exception_throw_adhoc(tc, "const_iX NYI");
	        case MVM_OP_const_i64:
	            GET_REG(cur_op, 0).i64 = MVM_BC_get_I64(cur_op, 2);
	            cur_op += 10;
	            goto runloop;
	        case MVM_OP_const_n32:
	            MVM_exception_throw_adhoc(tc, "const_n32 NYI");

And that’s all for today. It was a lot of C code but I hope it was quite useful to lurk into such deep level of the Perl 6 compiler system.

### Share this:

* [Twitter][3]
* [Facebook][4]
* [Google][5]
*

### Like this:

Like Loading...

<>

### _Related_

  [1]: https://perl6.online/2018/01/19/30-how-i-was-optimising-moarvm/
  [2]: https://gcc.gnu.org/onlinedocs/gcc/Labels-as-Values.html
  [3]: https://perl6.online/2018/01/20/the-opcode-dispatching-loop-in-moarvm/?share=twitter "Click to share on Twitter"
  [4]: https://perl6.online/2018/01/20/the-opcode-dispatching-loop-in-moarvm/?share=facebook "Click to share on Facebook"
  [5]: https://perl6.online/2018/01/20/the-opcode-dispatching-loop-in-moarvm/?share=google-plus-1 "Click to share on Google+"