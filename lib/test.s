	.text
	.file	"lib/test.ll"
	.globl	main                    # -- Begin function main
	.p2align	4, 0x90
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# BB#0:
	pushq	%rbx
.Lcfi0:
	.cfi_def_cfa_offset 16
.Lcfi1:
	.cfi_offset %rbx, -16
	callq	initGC
	callq	.LuserMain
	movq	%rax, %rbx
	xorl	%edi, %edi
	callq	fflush
	movq	(%rbx), %rax
	popq	%rbx
	retq
.Lfunc_end0:
	.size	main, .Lfunc_end0-main
	.cfi_endproc
                                        # -- End function
	.p2align	4, 0x90         # -- Begin function fib5
	.type	.Lfib5,@function
.Lfib5:                                 # @fib5
	.cfi_startproc
# BB#0:
	pushq	%rbx
.Lcfi2:
	.cfi_def_cfa_offset 16
	subq	$16, %rsp
.Lcfi3:
	.cfi_def_cfa_offset 32
.Lcfi4:
	.cfi_offset %rbx, -16
	movq	%rdi, (%rsp)
	movl	$8, %edi
	callq	alloc
.Ltmp0:
	movq	(%rsp), %rcx
	movq	$0, (%rax)
	movq	(%rcx), %rbx
	movl	$8, %edi
	callq	alloc
.Ltmp1:
	cmpq	$0, %rbx
	jne	.LBB1_2
# BB#1:                                 # %cond
	movq	$0, (%rax)
	jmp	.LBB1_4
.LBB1_2:                                # %cond1
	movq	(%rsp), %rcx
	movq	$1, (%rax)
	movq	(%rcx), %rbx
	movl	$8, %edi
	callq	alloc
.Ltmp2:
	movq	(%rsp), %rcx
	movq	$1, (%rax)
	cmpq	$1, %rbx
	je	.LBB1_4
# BB#3:                                 # %cond4
	movq	(%rcx), %rbx
	subq	(%rax), %rbx
	movl	$8, %edi
	callq	alloc
.Ltmp3:
	movq	%rbx, (%rax)
	movq	%rax, 8(%rsp)
	movq	%rax, %rdi
	callq	.Lfib5
.Ltmp4:
	movq	%rax, 8(%rsp)
	movl	$8, %edi
	callq	alloc
.Ltmp5:
	movq	(%rsp), %rcx
	movq	$2, (%rax)
	movq	(%rcx), %rbx
	addq	$-2, %rbx
	movl	$8, %edi
	callq	alloc
.Ltmp6:
	movq	%rbx, (%rax)
	movq	%rax, (%rsp)
	movq	%rax, %rdi
	callq	.Lfib5
.Ltmp7:
	movq	8(%rsp), %rcx
	movq	(%rcx), %rbx
	addq	(%rax), %rbx
	movl	$8, %edi
	callq	alloc
.Ltmp8:
	movq	%rbx, (%rax)
.LBB1_4:                                # %end
	addq	$16, %rsp
	popq	%rbx
	retq
.Lfunc_end1:
	.size	.Lfib5, .Lfunc_end1-.Lfib5
	.cfi_endproc
                                        # -- End function
	.p2align	4, 0x90         # -- Begin function userMain
	.type	.LuserMain,@function
.LuserMain:                             # @userMain
	.cfi_startproc
# BB#0:
	pushq	%rax
.Lcfi5:
	.cfi_def_cfa_offset 16
	movl	$8, %edi
	callq	alloc
.Ltmp9:
	movq	$10, (%rax)
	movq	%rax, (%rsp)
	movq	%rax, %rdi
	callq	.Lfib5
.Ltmp10:
	popq	%rcx
	retq
.Lfunc_end2:
	.size	.LuserMain, .Lfunc_end2-.LuserMain
	.cfi_endproc
                                        # -- End function
	.type	__unnamed_1,@object     # @0
	.section	.rodata,"a",@progbits
	.globl	__unnamed_1
__unnamed_1:
	.ascii	"runPoll"
	.size	__unnamed_1, 7


	.section	".note.GNU-stack","",@progbits
	.section	.llvm_stackmaps,"a",@progbits
__LLVM_StackMaps:
	.byte	3
	.byte	0
	.short	0
	.long	2
	.long	0
	.long	11
	.quad	.Lfib5
	.quad	24
	.quad	9
	.quad	.LuserMain
	.quad	8
	.quad	2
	.quad	2882400000
	.long	.Ltmp0-.Lfib5
	.short	0
	.short	5
	.byte	4
	.byte	0
	.short	8
	.short	0
	.short	0
	.long	0
	.byte	4
	.byte	0
	.short	8
	.short	0
	.short	0
	.long	0
	.byte	4
	.byte	0
	.short	8
	.short	0
	.short	0
	.long	0
	.byte	3
	.byte	0
	.short	8
	.short	7
	.short	0
	.long	0
	.byte	3
	.byte	0
	.short	8
	.short	7
	.short	0
	.long	0
	.p2align	3
	.short	0
	.short	0
	.p2align	3
	.quad	2882400000
	.long	.Ltmp1-.Lfib5
	.short	0
	.short	5
	.byte	4
	.byte	0
	.short	8
	.short	0
	.short	0
	.long	0
	.byte	4
	.byte	0
	.short	8
	.short	0
	.short	0
	.long	0
	.byte	4
	.byte	0
	.short	8
	.short	0
	.short	0
	.long	0
	.byte	3
	.byte	0
	.short	8
	.short	7
	.short	0
	.long	0
	.byte	3
	.byte	0
	.short	8
	.short	7
	.short	0
	.long	0
	.p2align	3
	.short	0
	.short	0
	.p2align	3
	.quad	2882400000
	.long	.Ltmp2-.Lfib5
	.short	0
	.short	5
	.byte	4
	.byte	0
	.short	8
	.short	0
	.short	0
	.long	0
	.byte	4
	.byte	0
	.short	8
	.short	0
	.short	0
	.long	0
	.byte	4
	.byte	0
	.short	8
	.short	0
	.short	0
	.long	0
	.byte	3
	.byte	0
	.short	8
	.short	7
	.short	0
	.long	0
	.byte	3
	.byte	0
	.short	8
	.short	7
	.short	0
	.long	0
	.p2align	3
	.short	0
	.short	0
	.p2align	3
	.quad	2882400000
	.long	.Ltmp3-.Lfib5
	.short	0
	.short	5
	.byte	4
	.byte	0
	.short	8
	.short	0
	.short	0
	.long	0
	.byte	4
	.byte	0
	.short	8
	.short	0
	.short	0
	.long	0
	.byte	4
	.byte	0
	.short	8
	.short	0
	.short	0
	.long	0
	.byte	3
	.byte	0
	.short	8
	.short	7
	.short	0
	.long	0
	.byte	3
	.byte	0
	.short	8
	.short	7
	.short	0
	.long	0
	.p2align	3
	.short	0
	.short	0
	.p2align	3
	.quad	2882400000
	.long	.Ltmp4-.Lfib5
	.short	0
	.short	7
	.byte	4
	.byte	0
	.short	8
	.short	0
	.short	0
	.long	8
	.byte	4
	.byte	0
	.short	8
	.short	0
	.short	0
	.long	0
	.byte	4
	.byte	0
	.short	8
	.short	0
	.short	0
	.long	0
	.byte	3
	.byte	0
	.short	8
	.short	7
	.short	0
	.long	8
	.byte	3
	.byte	0
	.short	8
	.short	7
	.short	0
	.long	8
	.byte	3
	.byte	0
	.short	8
	.short	7
	.short	0
	.long	0
	.byte	3
	.byte	0
	.short	8
	.short	7
	.short	0
	.long	0
	.p2align	3
	.short	0
	.short	0
	.p2align	3
	.quad	2882400000
	.long	.Ltmp5-.Lfib5
	.short	0
	.short	7
	.byte	4
	.byte	0
	.short	8
	.short	0
	.short	0
	.long	0
	.byte	4
	.byte	0
	.short	8
	.short	0
	.short	0
	.long	0
	.byte	4
	.byte	0
	.short	8
	.short	0
	.short	0
	.long	0
	.byte	3
	.byte	0
	.short	8
	.short	7
	.short	0
	.long	0
	.byte	3
	.byte	0
	.short	8
	.short	7
	.short	0
	.long	0
	.byte	3
	.byte	0
	.short	8
	.short	7
	.short	0
	.long	8
	.byte	3
	.byte	0
	.short	8
	.short	7
	.short	0
	.long	8
	.p2align	3
	.short	0
	.short	0
	.p2align	3
	.quad	2882400000
	.long	.Ltmp6-.Lfib5
	.short	0
	.short	5
	.byte	4
	.byte	0
	.short	8
	.short	0
	.short	0
	.long	0
	.byte	4
	.byte	0
	.short	8
	.short	0
	.short	0
	.long	0
	.byte	4
	.byte	0
	.short	8
	.short	0
	.short	0
	.long	0
	.byte	3
	.byte	0
	.short	8
	.short	7
	.short	0
	.long	8
	.byte	3
	.byte	0
	.short	8
	.short	7
	.short	0
	.long	8
	.p2align	3
	.short	0
	.short	0
	.p2align	3
	.quad	2882400000
	.long	.Ltmp7-.Lfib5
	.short	0
	.short	7
	.byte	4
	.byte	0
	.short	8
	.short	0
	.short	0
	.long	8
	.byte	4
	.byte	0
	.short	8
	.short	0
	.short	0
	.long	0
	.byte	4
	.byte	0
	.short	8
	.short	0
	.short	0
	.long	0
	.byte	3
	.byte	0
	.short	8
	.short	7
	.short	0
	.long	0
	.byte	3
	.byte	0
	.short	8
	.short	7
	.short	0
	.long	0
	.byte	3
	.byte	0
	.short	8
	.short	7
	.short	0
	.long	8
	.byte	3
	.byte	0
	.short	8
	.short	7
	.short	0
	.long	8
	.p2align	3
	.short	0
	.short	0
	.p2align	3
	.quad	2882400000
	.long	.Ltmp8-.Lfib5
	.short	0
	.short	3
	.byte	4
	.byte	0
	.short	8
	.short	0
	.short	0
	.long	0
	.byte	4
	.byte	0
	.short	8
	.short	0
	.short	0
	.long	0
	.byte	4
	.byte	0
	.short	8
	.short	0
	.short	0
	.long	0
	.p2align	3
	.short	0
	.short	0
	.p2align	3
	.quad	2882400000
	.long	.Ltmp9-.LuserMain
	.short	0
	.short	3
	.byte	4
	.byte	0
	.short	8
	.short	0
	.short	0
	.long	0
	.byte	4
	.byte	0
	.short	8
	.short	0
	.short	0
	.long	0
	.byte	4
	.byte	0
	.short	8
	.short	0
	.short	0
	.long	0
	.p2align	3
	.short	0
	.short	0
	.p2align	3
	.quad	2882400000
	.long	.Ltmp10-.LuserMain
	.short	0
	.short	5
	.byte	4
	.byte	0
	.short	8
	.short	0
	.short	0
	.long	8
	.byte	4
	.byte	0
	.short	8
	.short	0
	.short	0
	.long	0
	.byte	4
	.byte	0
	.short	8
	.short	0
	.short	0
	.long	0
	.byte	3
	.byte	0
	.short	8
	.short	7
	.short	0
	.long	0
	.byte	3
	.byte	0
	.short	8
	.short	7
	.short	0
	.long	0
	.p2align	3
	.short	0
	.short	0
	.p2align	3

.globl __LLVM_StackMaps