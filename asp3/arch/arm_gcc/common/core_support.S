/*
 *  TOPPERS/ASP Kernel
 *      Toyohashi Open Platform for Embedded Real-Time Systems/
 *      Advanced Standard Profile Kernel
 * 
 *  Copyright (C) 2000-2004 by Embedded and Real-Time Systems Laboratory
 *                              Toyohashi Univ. of Technology, JAPAN
 *  Copyright (C) 2006-2017 by Embedded and Real-Time Systems Laboratory
 *              Graduate School of Information Science, Nagoya Univ., JAPAN
 * 
 *  上記著作権者は，以下の(1)〜(4)の条件を満たす場合に限り，本ソフトウェ
 *  ア（本ソフトウェアを改変したものを含む．以下同じ）を使用・複製・改
 *  変・再配布（以下，利用と呼ぶ）することを無償で許諾する．
 *  (1) 本ソフトウェアをソースコードの形で利用する場合には，上記の著作
 *      権表示，この利用条件および下記の無保証規定が，そのままの形でソー
 *      スコード中に含まれていること．
 *  (2) 本ソフトウェアを，ライブラリ形式など，他のソフトウェア開発に使
 *      用できる形で再配布する場合には，再配布に伴うドキュメント（利用
 *      者マニュアルなど）に，上記の著作権表示，この利用条件および下記
 *      の無保証規定を掲載すること．
 *  (3) 本ソフトウェアを，機器に組み込むなど，他のソフトウェア開発に使
 *      用できない形で再配布する場合には，次のいずれかの条件を満たすこ
 *      と．
 *    (a) 再配布に伴うドキュメント（利用者マニュアルなど）に，上記の著
 *        作権表示，この利用条件および下記の無保証規定を掲載すること．
 *    (b) 再配布の形態を，別に定める方法によって，TOPPERSプロジェクトに
 *        報告すること．
 *  (4) 本ソフトウェアの利用により直接的または間接的に生じるいかなる損
 *      害からも，上記著作権者およびTOPPERSプロジェクトを免責すること．
 *      また，本ソフトウェアのユーザまたはエンドユーザからのいかなる理
 *      由に基づく請求からも，上記著作権者およびTOPPERSプロジェクトを
 *      免責すること．
 * 
 *  本ソフトウェアは，無保証で提供されているものである．上記著作権者お
 *  よびTOPPERSプロジェクトは，本ソフトウェアに関して，特定の使用目的
 *  に対する適合性も含めて，いかなる保証も行わない．また，本ソフトウェ
 *  アの利用により直接的または間接的に生じたいかなる損害に関しても，そ
 *  の責任を負わない．
 * 
 *  $Id: core_support.S 793 2017-07-03 04:49:27Z ertl-hiro $
 */

/*
 *		カーネルのコア依存部のアセンブリ言語部（ARM用）
 */

#define TOPPERS_MACRO_ONLY
#define TOPPERS_ASM_MACRO
#define UINT_C(val)			(val)		/* uint_t型の定数を作るマクロ */
#define ULONG_C(val)		(val)		/* ulong_t型の定数を作るマクロ */
#define CAST(type, val)		(val)		/* 型キャストを行うマクロ */
#include "kernel_impl.h"
#include "offset.h"
#include "core_asm.inc"

/*
 *  例外ベクタ
 */
	ASECTION(.vector)
	AALIGN(5)
	AGLOBAL(vector_table)
ALABEL(vector_table)
	ldr		pc, reset_vector		/* リセット */
	ldr		pc, undef_vector		/* 未定義命令 */
	ldr		pc, svc_vector			/* ソフトウェア割込み */
	ldr		pc, pabort_vector		/* プリフェッチアボート */
	ldr		pc, dabort_vector		/* データアボート */
	ldr		pc, reset_vector		/* 未使用 */
	ldr		pc, irq_vector			/* IRQ */
	ldr		pc, fiq_vector			/* FIQ */

/*
 *  例外ベクタの命令から参照されるジャンプ先アドレス
 */
	AGLOBAL(vector_ref_table)
ALABEL(vector_ref_table)
ALABEL(reset_vector)
	ALONG	start
ALABEL(undef_vector)
	ALONG	undef_handler
ALABEL(svc_vector)
	ALONG	svc_handler
ALABEL(pabort_vector)
	ALONG	pabort_handler
ALABEL(dabort_vector)
	ALONG	dabort_handler
ALABEL(irq_vector)
	ALONG	irq_handler
ALABEL(fiq_vector)
	ALONG	fiq_handler

/*
 *  タスクディスパッチャ
 */
	ATEXT
	AALIGN(2)
	AGLOBAL(dispatch)
ALABEL(dispatch)
	/*
	 *  このルーチンは，タスクコンテキスト・CPUロック状態・割込み優先度
	 *  マスク全解除状態・ディスパッチ許可状態で呼び出される．
	 */
	push	{r12,lr}				/* 戻り番地を保存，r12はダミー */
#ifdef TOPPERS_SUPPORT_OVRHDR
	bl		ovrtimer_stop
#endif /* TOPPERS_SUPPORT_OVRHDR */
	stmfd	sp!, {r4-r11}			/* 非スクラッチレジスタの保存 */
	ldr		r0, =p_runtsk			/* p_runtsk → r0 */
	ldr		r0, [r0]
	str		sp, [r0,#TCB_sp]		/* スタックポインタを保存 */
	adr		r1, dispatch_r
	str		r1, [r0,#TCB_pc]		/* 実行再開番地を保存 */
	b		dispatcher				/* r0にはp_runtskが格納されている */

ALABEL(dispatch_r)
	ldmfd	sp!, {r4-r11}			/* 非スクラッチレジスタの復帰 */
#ifdef TOPPERS_SUPPORT_OVRHDR
	bl		ovrtimer_start
#endif /* TOPPERS_SUPPORT_OVRHDR */
	pop		{r12,lr}				/* 戻り番地を復帰 */
	bx		lr

/*
 *  ディスパッチャの動作開始
 */
	AGLOBAL(start_dispatch)
ALABEL(start_dispatch)
	/*
	 *  このルーチンは，カーネル起動時に，非タスクコンテキストで，NMIを
	 *  除くすべての割込みを禁止した状態（全割込みロック状態と同等）で
	 *  呼び出される．
	 *
	 *  dispatcher_0へ分岐する前に，タスクコンテキスト・CPUロック状態・
	 *  割込み優先度マスク全解除状態にし，使用するスタックを，IDが1のタ
	 *  スクのスタック領域に切り換えなければならない．
	 */

	/*
	 *	タスクコンテキストに切り換える．
	 */
	ldr		r2, =excpt_nest_count	/* 例外ネストカウントを0に */
	mov		r0, #0
	str		r0, [r2]

	/*
	 *  IDが1のタスクのスタック領域に切り換える．
	 */
	ldr		r0, =tcb_table			/* tcb_table[0] → r0 */
	ldr		r2, [r0,#TCB_p_tinib]	/* tcb_table[0].p_tinib → r2 */
	ldr		r0, [r2,#TINIB_stk]
	ldr		r1, [r2,#TINIB_stksz]
	add		sp, r0, r1

	/*
	 *  CPUロック状態にして，ディスパッチャ本体へ分岐する．
	 */
	msr		cpsr_c, #(CPSR_SVC_MODE AOR CPSR_CPULOCK)
	b		dispatcher_0

/*
 *  現在のコンテキストを捨ててディスパッチ
 */
	AGLOBAL(exit_and_dispatch)
ALABEL(exit_and_dispatch)
	/*
	 *  このルーチンは，タスクコンテキスト・CPUロック状態・割込み優先度
	 *  マスク全解除状態・ディスパッチ許可状態で呼び出される．
	 */
#ifdef LOG_DSP_ENTER
	ldr		r0, =p_runtsk			/* p_runtsk → r0 */
	ldr		r0, [r0]
#endif /* LOG_DSP_ENTER */
	/* ディスパッチャ本体（dispatcher）へ */

/*
 *  ディスパッチャ本体
 */
ALABEL(dispatcher)
#ifdef LOG_DSP_ENTER
	/*
	 * 【この時点のレジスタ状態】
	 *  r0：p_runtsk（タスク切換え前）
	 */
	bl		log_dsp_enter
#endif /* LOG_DSP_ENTER */

ALABEL(dispatcher_0)
	/*
	 *  このルーチンは，タスクコンテキスト・CPUロック状態・割込み優先度
	 *  マスク全解除状態・ディスパッチ許可状態で呼び出される．実行再開番
	 *  地へもこの状態のまま分岐する．
	 */
	ldr		r0, =p_schedtsk		/* p_schedtsk → r4 → p_runtsk */
	ldr		r4, [r0]
	ldr		r1, =p_runtsk
	str		r4, [r1]
	tst		r4, r4				/* p_runtskがNULLならdispatcher_1へ */
	beq		dispatcher_1
	ldr		sp, [r4,#TCB_sp]	/* タスクスタックを復帰 */
#ifdef LOG_DSP_LEAVE
	mov		r0, r4				/* p_runtskをパラメータに渡す */
	bl		log_dsp_leave
#endif /* LOG_DSP_LEAVE */
	ldr		r0, [r4,#TCB_pc]	/* 実行再開番地を復帰 */
	bx		r0					/* p_runtskをr4に入れた状態で分岐する */

	/*
	 *  アイドル処理
	 *
	 *  割込みをすべて許可し，CPUロック解除状態にして割込みを待つ．
	 *
	 *  ターゲットによっては，省電力モード等に移行するため，標準の方法
	 *  と異なる手順が必要な場合がある．そのようなターゲットでは，ター
	 *  ゲット依存部でTOPPERS_CUSTOM_IDLEを定義し，アセンブラマクロとし
	 *  て，toppers_asm_custom_idleを用意すればよい．
	 */
ALABEL(dispatcher_1)
#ifdef TOPPERS_CUSTOM_IDLE
	toppers_asm_custom_idle
#else /* TOPPERS_CUSTOM_IDLE */
	msr		cpsr_c, #CPSR_SVC_MODE	/* 割込みを許可（スーパバイザモード）*/
#endif /* TOPPERS_CUSTOM_IDLE */
	b		dispatcher_1			/* 割込み待ち */

/*
 *  カーネルの終了処理の呼出し
 *
 *  割込みロック状態にし，使用するスタックを非タスクコンテキスト用のスタッ
 *  ク領域に切り替え，exit_kernelを呼び出す．
 */
	AGLOBAL(call_exit_kernel)
ALABEL(call_exit_kernel)
	msr		cpsr_c, #(CPSR_SVC_MODE AOR CPSR_INTLOCK)
	ldr		r0, =istkpt				/* 非タスクコンテキストのスタックへ */
	ldr		sp, [r0]
	b		exit_kernel

/*
 *  タスクの実行開始時処理
 */
	ATEXT
	AALIGN(2)
	AGLOBAL(start_r)
	/*
	 *  ディスパッチャ本体から呼び出されるため，p_runtskはr4に入っている．
	 */
ALABEL(start_r)
#ifdef TOPPERS_SUPPORT_OVRHDR
	bl		ovrtimer_start
#endif /* TOPPERS_SUPPORT_OVRHDR */
	msr		cpsr_c, #(CPSR_SVC_MODE AOR CPSR_UNLOCK)
									/* CPUロック解除状態に */
	ldr		lr, =ext_tsk			/* タスク本体からの戻り番地を設定 */
	ldr		r2, [r4,#TCB_p_tinib]	/* p_runtsk->p_tinib → r2 */
	ldr		r0, [r2,#TINIB_exinf]	/* exinfをパラメータに */
	ldr		r1, [r2,#TINIB_task]	/* タスク起動番地にジャンプ */
	bx		r1

/*
 *  割込みハンドラの出入口処理
 */
#ifndef OMIT_IRQ_HANDLER
	ATEXT
	AALIGN(2)
	AGLOBAL(irq_handler)
ALABEL(irq_handler)
	/*
	 *  ここには，IRQモードで分岐してくる．
	 */
#if __TARGET_ARCH_ARM < 6
	/*
	 *  スーパバイザモードに切り換え，スクラッチレジスタを保存する．
	 */
	msr		cpsr_c, #(CPSR_SVC_MODE AOR CPSR_IRQ_BIT)
	stmfd	sp!, {r0-r5,r12,lr,pc}		/* pcはスペース確保のため */

	/*
	 *  IRQモードに戻して，戻り番地とspsr（戻り先のcpsr）を取得する．
	 */
	msr		cpsr_c, #(CPSR_IRQ_MODE AOR CPSR_IRQ_BIT)
	sub		r2, lr, #4
	mrs		r1, spsr

	/*
	 *  スーパバイザモードに切り換え，戻り番地とspsrを保存する．
	 */
	msr		cpsr_c, #(CPSR_SVC_MODE AOR CPSR_IRQ_BIT)
	str		r2, [sp,#0x20]			/* 戻り番地をスタックに保存 */
	push	{r1}					/* spsrをスタックに保存 */
#else /* __TARGET_ARCH_ARM < 6 */
	/*
	 *  戻り先（lr）とspsr（cpsr_svc）をスーパバイザモードのスタックに
	 *  保存する．
	 */
	sub		lr, lr, #4				/* 戻り番地の算出 */
	srsfd	#CPSR_SVC_MODE!

	/*
	 *  スーパバイザモードに切り換え，スクラッチレジスタを保存する．
	 */
	cps		#CPSR_SVC_MODE
	stmfd	sp!, {r0-r5,r12,lr}
#endif /* __TARGET_ARCH_ARM < 6 */

	/*
	 *  スタックポインタの調整
	 */
	and		r1, sp, #4
	sub		sp, sp, r1
	push	{r0,r1}					/* r0はスペース確保のため */

	/*
	 *  例外ネストカウントをインクリメントする．割込みが非タスクコンテキ
	 *  ストで発生した場合には，irq_handler_1へ分岐する．
	 */
	ldr		r2, =excpt_nest_count
	ldr		r3, [r2]
	add		r3, r3, #1
	str		r3, [r2]
	teq		r3, #1					/* 割込みが非タスクコンテキストで発生 */
	bne		irq_handler_1			/*			  ならirq_handler_1に分岐 */

#ifdef TOPPERS_SUPPORT_OVRHDR
	/*
	 *  オーバランタイマを停止する．
	 */
	bl		ovrtimer_stop
#endif /* TOPPERS_SUPPORT_OVRHDR */

	/*
	 *  非タスクコンテキスト用のスタックに切り換える．
	 */
	mov		r3, sp					/* この時点のスタックポインタをr3に */
	ldr		r2, =istkpt				/* 非タスクコンテキスト用のスタックに */
	ldr		sp, [r2]
	push	{r0,r3}					/* 切換え前のスタックポインタを保存 */
									/* r0はスペース確保のため */
ALABEL(irq_handler_1)
	/*
	 *  割込みコントローラを操作し，割込み番号を取得する．
	 */
	bl		irc_begin_int
#if TNUM_INHNO <= 256 || __TARGET_ARCH_ARM <= 6
	cmp		r4, #TNUM_INHNO			/* TNUM_INHNOの値によってはエラーになる */
#else /* TNUM_INHNO <= 256 || __TARGET_ARCH_ARM <= 6 */
	movw	r3, #TNUM_INHNO
	cmp		r4, r3
#endif /* TNUM_INHNO <= 256 || __TARGET_ARCH_ARM <= 6 */
	bhs		irq_handler_2			/* スプリアス割込みなら */
									/*  irq_handler_2に分岐 */
	/*
	 *  CPUロック解除状態にする．
	 */
#if __TARGET_ARCH_ARM < 6
	msr		cpsr_c, #(CPSR_SVC_MODE AOR CPSR_UNLOCK)
#else /* __TARGET_ARCH_ARM < 6 */
#ifndef TOPPERS_SAFEG_SECURE
	cpsie	if
#else /* TOPPERS_SAFEG_SECURE */
	cpsie	f
#endif /* TOPPERS_SAFEG_SECURE */
#endif /* __TARGET_ARCH_ARM < 6 */

#ifdef LOG_INH_ENTER
	/*
	 *  ログ出力の呼出し
	 */
	mov		r0, r4					/* 割込み番号をパラメータに渡す */
	bl		log_inh_enter
#endif /* LOG_INH_ENTER */

	/*
	 *  割込みハンドラの呼出し
	 */
	ldr		r2, =inh_table			/* 割込みハンドラテーブルの読込み */
	ldr		r1, [r2,r4,lsl #2]		/* 割込みハンドラの番地 → r1 */
	mov		lr, pc					/* 割込みハンドラの呼出し */
	bx		r1

#ifdef LOG_INH_LEAVE
	/*
	 *  ログ出力の呼出し
	 */
	mov		r0, r4					/* 割込み番号をパラメータに渡す */
	bl		log_inh_leave
#endif /* LOG_INH_LEAVE */

	/*
	 *  カーネル管理の割込みを禁止する．
	 */
#if __TARGET_ARCH_ARM < 6
	msr		cpsr_c, #(CPSR_SVC_MODE AOR CPSR_CPULOCK)
#else /* __TARGET_ARCH_ARM < 6 */
#ifndef TOPPERS_SAFEG_SECURE
	cpsid	i
#else /* TOPPERS_SAFEG_SECURE */
	cpsid	if
#endif /* TOPPERS_SAFEG_SECURE */
#endif /* __TARGET_ARCH_ARM < 6 */

	/*
	 *  割込みコントローラを操作する．
	 */
ALABEL(irq_handler_2)
	bl		irc_end_int

	/*
	 *  例外ネストカウントをデクリメントする．
	 */
	ldr		r2, =excpt_nest_count
	ldr		r3, [r2]
	subs	r3, r3, #1
	str		r3, [r2]				/* 戻り先が非タスクコンテキストなら */
	bne		irq_handler_5			/*				irq_handler_5に分岐 */

	/*
	 *  タスク用のスタックに戻す．
	 */
	pop		{r0,r3}
	mov   	sp, r3

	/*
	 *  p_runtskがNULLか判定する．
	 */
	ldr		r0, =p_runtsk			/* p_runtsk → r0 */
	ldr		r0, [r0]
	tst		r0, r0					/* p_runtskがNULLでなければ */
	bne		irq_handler_3			/*		irq_handler_3に分岐 */

	/*
	 *  タスクのスタックに保存したスクラッチレジスタ等を捨てる．
	 */
	pop		{r0,r1}					/* スタックポインタの調整を元に戻す */
	add		sp, sp, r1
	add		sp, sp, #40				/* スクラッチレジスタを捨てる */
	b		dispatcher_0

	/*
	 *  ディスパッチが必要か判定する．
	 */
ALABEL(irq_handler_3)
	ldr		r1, =p_schedtsk			/* p_schedtsk → r1 */
	ldr		r1, [r1]
	teq		r0, r1					/* p_runtskとp_schedtskが同じなら */
	beq		irq_handler_4			/*				  irq_handler_4へ */

	/*
	 *  コンテキストを保存する．
	 */
	stmfd	sp!, {r6-r11}			/* 非スクラッチレジスタの保存 */
	str		sp, [r0,#TCB_sp]		/* スタックポインタを保存 */
	adr		r1, ret_int_r			/* 実行再開番地を保存 */
	str		r1, [r0,#TCB_pc]
	b		dispatcher				/* r0にはp_runtskが格納されている */

ALABEL(ret_int_r)
	/*
	 *  コンテキストを復帰する．
	 */
	ldmfd	sp!, {r6-r11}			/* 非スクラッチレジスタの復帰 */

ALABEL(irq_handler_4)
#ifdef TOPPERS_SUPPORT_OVRHDR
	/*
	 *  オーバランタイマを動作開始する．
	 */
	bl		ovrtimer_start
#endif /* TOPPERS_SUPPORT_OVRHDR */

	/*
	 *  割込み／CPU例外処理からのリターン
	 *
	 *  割込み／CPU例外処理からのリターンにより，CPUロック解除状態に遷
	 *  移するようにする必要があるが，ARMはCPSRのビットによってCPUロッ
	 *  ク状態を表しているため，CPSRを元に戻してリターンすればよい．
	 */
ALABEL(irq_handler_5)
	pop		{r0,r1}					/* スタックポインタの調整を元に戻す */
	add		sp, sp, r1

#if __TARGET_ARCH_ARM < 6
	ldmfd	sp!, {r0}				/* 戻り先のcpsrをspsrに設定 */
	msr		spsr_cxsf, r0
	ldmfd	sp!, {r0-r5,r12,lr,pc}^	/* コンテキストの復帰 */
									/* ^付きなので，spsr → cpsr */
#else /* __TARGET_ARCH_ARM < 6 */
	ldmfd	sp!, {r0-r5,r12,lr}
	rfefd	sp!
#endif /* __TARGET_ARCH_ARM < 6 */
#endif /* OMIT_IRQ_HANDLER */

/*
 *  CPU例外ハンドラ出入口処理
 */
ALABEL(start_exc_entry)

/*
 *  未定義命令
 */
#ifndef OMIT_UNDEF_HANDLER
	ATEXT
	AALIGN(2)
	AGLOBAL(undef_handler)
ALABEL(undef_handler)
	/*
	 *  ここには，未定義モードで分岐してくる．
	 */
#if __TARGET_ARCH_ARM < 6
	/*
	 *  IビットとFビットをセットし，スーパバイザモードに切り換え，スク
	 *  ラッチレジスタを保存する．
	 */
	msr		cpsr_c, #(CPSR_SVC_MODE AOR CPSR_FIQ_IRQ_BIT)
	stmfd	sp!, {r0-r5,r12,lr,pc}		/* pcはスペース確保のため */

	/*
	 *  未定義モードに戻して，戻り番地とspsrを取得する．
	 */
	msr		cpsr_c, #(CPSR_UND_MODE AOR CPSR_FIQ_IRQ_BIT)
	mov		r2, lr
	mrs		r1, spsr

	/*
	 *  スーパバイザモードに切り換え，戻り番地とspsrを保存する．
	 */
	msr		cpsr_c, #(CPSR_SVC_MODE AOR CPSR_FIQ_IRQ_BIT)
	str		r2, [sp,#0x20]			/* 戻り番地をスタックに保存 */
	push	{r1}					/* spsrをスタックに保存 */
#else /* __TARGET_ARCH_ARM < 6 */
	/*
	 *  戻り先（lr）とspsr（cpsr_svc）をスーパバイザモードのスタックに
	 *  保存する．
	 */
	srsfd	#CPSR_SVC_MODE!

	/*
	 *  スーパバイザモードに切り換え，スクラッチレジスタを保存する．
	 */
	cps		#CPSR_SVC_MODE
	stmfd	sp!, {r0-r5,r12,lr}
#endif /* __TARGET_ARCH_ARM < 6 */
	mov		r4, #EXCNO_UNDEF
	b		exc_handler_1
#endif /* OMIT_UNDEF_HANDLER */

/*
 *  スーパバイザコール
 */
#ifndef OMIT_SVC_HANDLER
	ATEXT
	AALIGN(2)
	AGLOBAL(svc_handler)
ALABEL(svc_handler)
	/*
	 *  ここには，スーパバイザモードで分岐してくる．
	 */
#if __TARGET_ARCH_ARM < 6
	/*
	 *  IビットとFビットをセットし，スクラッチレジスタを保存する．
	 */
	msr		cpsr_c, #(CPSR_SVC_MODE AOR CPSR_FIQ_IRQ_BIT)
	stmfd	sp!, {r0-r5,r12,lr,pc}		/* pcはスペース確保のため */

	/*
	 *  戻り番地とspsrを取得する．
	 */
	mov		r2, lr
	mrs		r1, spsr

	/*
	 *  戻り番地とspsrを保存する．
	 */
	str		r2, [sp,#0x20]			/* 戻り番地をスタックに保存 */
	push	{r1}					/* spsrをスタックに保存 */
#else /* __TARGET_ARCH_ARM < 6 */
	/*
	 *  戻り先（lr）とspsr（cpsr_svc）をスーパバイザモードのスタックに
	 *  保存する．
	 */
	srsfd	#CPSR_SVC_MODE!

	/*
	 *  スーパバイザモードで，スクラッチレジスタを保存する．
	 */
	cps		#CPSR_SVC_MODE			/* 不要と思われる */
	stmfd	sp!, {r0-r5,r12,lr}
#endif /* __TARGET_ARCH_ARM < 6 */
	mov		r4, #EXCNO_SVC
	b		exc_handler_1
#endif /* OMIT_SVC_HANDLER */

/*
 *  プリフェッチアボート
 */
#ifndef OMIT_PABORT_HANDLER
	ATEXT
	AALIGN(2)
	AGLOBAL(pabort_handler)
ALABEL(pabort_handler)
	/*
	 *  ここには，アボートモードで分岐してくる．
	 */
#if __TARGET_ARCH_ARM < 6
	/*
	 *  IビットとFビットをセットし，スーパバイザモードに切り換え，スク
	 *  ラッチレジスタを保存する．
	 */
	msr		cpsr_c, #(CPSR_SVC_MODE AOR CPSR_FIQ_IRQ_BIT)
	stmfd	sp!, {r0-r5,r12,lr,pc}		/* pcはスペース確保のため */

	/*
	 *  アボートモードに戻して，戻り番地とspsrを取得する．
	 */
	msr		cpsr_c, #(CPSR_ABT_MODE AOR CPSR_FIQ_IRQ_BIT)
	mov		r2, lr
	mrs		r1, spsr

	/*
	 *  スーパバイザモードに切り換え，戻り番地とspsrを保存する．
	 */
	msr		cpsr_c, #(CPSR_SVC_MODE AOR CPSR_FIQ_IRQ_BIT)
	str		r2, [sp,#0x20]			/* 戻り番地をスタックに保存 */
	push	{r1}					/* spsrをスタックに保存 */
#else /* __TARGET_ARCH_ARM < 6 */
	/*
	 *  戻り先（lr）とspsr（cpsr_svc）をスーパバイザモードのスタックに
	 *  保存する．
	 */
	srsfd	#CPSR_SVC_MODE!

	/*
	 *  スーパバイザモードに切り換え，スクラッチレジスタを保存する．
	 */
	cps		#CPSR_SVC_MODE
	stmfd	sp!, {r0-r5,r12,lr}
#endif /* __TARGET_ARCH_ARM < 6 */
	mov		r4, #EXCNO_PABORT
	b		exc_handler_1
#endif /* OMIT_PABORT_HANDLER */

/*
 *  データアボート
 */
#ifndef OMIT_DABORT_HANDLER
	ATEXT
	AALIGN(2)
	AGLOBAL(dabort_handler)
ALABEL(dabort_handler)
	/*
	 *  ここには，アボートモードで分岐してくる．
	 *
	 *  データアボートが，CPU例外の入口（start_exc_entryとend_exc_entry
	 *  の間）で発生した場合には，fatal_dabort_handlerに分岐する．アボー
	 *  トモードのspを汎用レジスタの代わりに使用する．
	 */
	ldr		sp, =start_exc_entry+8
	cmp		lr, sp
	bcc		dabort_handler_1
	ldr		sp, =end_exc_entry+8
	cmp		lr, sp
	bcc		fatal_dabort_handler

ALABEL(dabort_handler_1)
#if __TARGET_ARCH_ARM < 6
	/*
	 *  IビットとFビットをセットし，スーパバイザモードに切り換え，スク
	 *  ラッチレジスタを保存する．
	 */
	msr		cpsr_c, #(CPSR_SVC_MODE AOR CPSR_FIQ_IRQ_BIT)
	stmfd	sp!, {r0-r5,r12,lr,pc}		/* pcはスペース確保のため */

	/*
	 *  アボートモードに戻して，戻り番地とspsrを取得する．
	 */
	msr		cpsr_c, #(CPSR_ABT_MODE AOR CPSR_FIQ_IRQ_BIT)
	mov		r2, lr
	mrs		r1, spsr

	/*
	 *  スーパバイザモードに切り換え，戻り番地とspsrを保存する．
	 */
	msr		cpsr_c, #(CPSR_SVC_MODE AOR CPSR_FIQ_IRQ_BIT)
	str		r2, [sp,#0x20]			/* 戻り番地をスタックに保存 */
	push	{r1}					/* spsrをスタックに保存 */
#else /* __TARGET_ARCH_ARM < 6 */
	/*
	 *  戻り先（lr）とspsr（cpsr_svc）をスーパバイザモードのスタックに
	 *  保存する．
	 */
	srsfd	#CPSR_SVC_MODE!

	/*
	 *  スーパバイザモードに切り換え，スクラッチレジスタを保存する．
	 */
	cps		#CPSR_SVC_MODE
	stmfd	sp!, {r0-r5,r12,lr}
#endif /* __TARGET_ARCH_ARM < 6 */
	mov		r4, #EXCNO_DABORT
	b		exc_handler_1
#endif /* OMIT_DABORT_HANDLER */

/*
 *  CPU例外の入口で発生したデータアボート
 */
ALABEL(fatal_dabort_handler)
#if __TARGET_ARCH_ARM < 6
	/*
	 *  IビットとFビットをセットし，スーパバイザモードに切り換え，スタッ
	 *  クポインタを初期化し，スクラッチレジスタを保存する．
	 */
	msr		cpsr_c, #(CPSR_SVC_MODE AOR CPSR_FIQ_IRQ_BIT)
	ldr		sp, =istkpt
	ldr		sp, [sp]
	stmfd	sp!, {r0-r5,r12,lr,pc}		/* pcはスペース確保のため */

	/*
	 *  アボートモードに戻して，戻り番地とspsrを取得する．
	 */
	msr		cpsr_c, #(CPSR_ABT_MODE AOR CPSR_FIQ_IRQ_BIT)
	mov		r2, lr
	mrs		r1, spsr

	/*
	 *  スーパバイザモードに切り換え，戻り番地とspsrを保存する．
	 */
	msr		cpsr_c, #(CPSR_SVC_MODE AOR CPSR_FIQ_IRQ_BIT)
	str		r2, [sp,#0x20]			/* 戻り番地をスタックに保存 */
	push	{r1}					/* spsrをスタックに保存 */
#else /* __TARGET_ARCH_ARM < 6 */
	/*
	 *  IビットとFビットをセットし，スーパバイザモードに切り換え，スタッ
	 *  クポインタを初期化する．
	 */
	cpsid	if, #CPSR_SVC_MODE
	ldr		sp, =istkpt
	ldr		sp, [sp]

	/*
	 *  アボートモードに戻して，戻り先（lr）とspsr（cpsr_svc）をスーパ
	 *  バイザモードのスタックに保存する．
	 */
	cps		#CPSR_ABT_MODE
	srsfd	#CPSR_SVC_MODE!

	/*
	 *  スーパバイザモードに切り換え，スクラッチレジスタを保存する．
	 */
	cps		#CPSR_SVC_MODE
	stmfd	sp!, {r0-r5,r12,lr}
#endif /* __TARGET_ARCH_ARM < 6 */

	/*
	 *  例外ネストカウントの最上位ビットを1にする．
	 */
	ldr		r2, =excpt_nest_count
	ldr		r3, [r2]
	orr		r3, r3, #0x80000000
	str		r3, [r2]

	mov		r4, #EXCNO_DABORT
	b		exc_handler_1

/*
 *  FIQ
 */
#ifndef OMIT_FIQ_HANDLER
	ATEXT
	AALIGN(2)
	AGLOBAL(fiq_handler)
ALABEL(fiq_handler)
	/*
	 *  ここには，FIQモードで分岐してくる．
	 */
#if __TARGET_ARCH_ARM < 6
	/*
	 *  IビットとFビットをセットし，スーパバイザモードに切り換え，スク
	 *  ラッチレジスタを保存する．
	 */
	msr		cpsr_c, #(CPSR_SVC_MODE AOR CPSR_FIQ_IRQ_BIT)
	stmfd	sp!, {r0-r5,r12,lr,pc}		/* pcはスペース確保のため */

	/*
	 *  FIQモードに戻して，戻り番地とspsrを取得する．
	 */
	msr		cpsr_c, #(CPSR_FIQ_MODE AOR CPSR_FIQ_IRQ_BIT)
	mov		r2, lr
	mrs		r1, spsr

	/*
	 *  スーパバイザモードに切り換え，戻り番地とspsrを保存する．
	 */
	msr		cpsr_c, #(CPSR_SVC_MODE AOR CPSR_FIQ_IRQ_BIT)
	str		r2, [sp,#0x20]			/* 戻り番地をスタックに保存 */
	push	{r1}					/* spsrをスタックに保存 */
#else /* __TARGET_ARCH_ARM < 6 */
	/*
	 *  戻り先（lr）とspsr（cpsr_svc）をスーパバイザモードのスタックに
	 *  保存する．
	 */
	srsfd	#CPSR_SVC_MODE!

	/*
	 *  スーパバイザモードに切り換え，スクラッチレジスタを保存する．
	 */
	cps		#CPSR_SVC_MODE
	stmfd	sp!, {r0-r5,r12,lr}
#endif /* __TARGET_ARCH_ARM < 6 */
	mov		r4, #EXCNO_FIQ
	b		exc_handler_1
#endif /* OMIT_FIQ_HANDLER */

ALABEL(end_exc_entry)

/*
 *  CPU例外ハンドラ出入口処理の共通部分
 *
 * 【この時点のレジスタ状態】
 *  r4：CPU例外ハンドラ番号
 */
ALABEL(exc_handler_1)
	/*
	 *  CPU例外が発生した状況の判断に用いるために，CPU例外発生前の割
	 *  込み優先度マスクと例外ネストカウントをスタックに保存する．
	 */
	bl		irc_get_intpri
	push	{r0}					/* 割込み優先度マスクを保存 */
	ldr		r2, =excpt_nest_count
	ldr		r3, [r2]
	push	{r3}					/* 例外ネストカウントを保存 */
	mov		r5, sp					/* CPU例外の情報を記憶している領域の */
									/*				  先頭番地をr5に保存 */
	/*
	 *  スタックポインタの調整
	 */
	and		r1, sp, #4
	sub		sp, sp, r1
	push	{r0,r1}					/* r0はスペース確保のため */

	/*
	 *  カーネル管理外のCPU例外か判定する
	 *
	 *  カーネル管理外のCPU例外は，カーネル実行中，全割込みロック状態，
	 *  CPUロック状態，カーネル管理外の割込みハンドラ実行中に発生した
	 *  CPU例外である．ARMコアの場合は，戻り先のCPSRのIビットかFビット
	 *  のいずれかがセットされているなら，これ該当する．
	 */
	ldr		r1, [r5,#T_EXCINF_cpsr]		/* 例外フレームからcpsrを取得 */
	ands	r1, r1, #CPSR_FIQ_IRQ_BIT
	bne		nk_exc_handler_1		/* カーネル管理外のCPU例外の処理へ */

	/*
	 * 【この時点のレジスタ状態】
	 *  r2：excpt_nest_countの番地
	 *  r3：excpt_nest_countの値
	 *  r4：CPU例外ハンドラ番号
	 *  r5：CPU例外の情報を記憶している領域の先頭番地
	 */

	/*
	 *  例外ネストカウントをインクリメントする．
	 */
	add		r3, r3, #1
	str		r3, [r2]
	teq		r3, #1					/* CPU例外発生前が非タスクコンテキスト */
	bne		exc_handler_2			/*			   ならexc_handler_2に分岐 */

#ifdef TOPPERS_SUPPORT_OVRHDR
	/*
	 *  オーバランタイマを停止する．
	 */
	bl		ovrtimer_stop
#endif /* TOPPERS_SUPPORT_OVRHDR */

	/*
	 *  非タスクコンテキスト用のスタックに切り換える．
	 */
	mov		r3, sp					/* この時点のスタックポインタをr3に */
	ldr		r2, =istkpt				/* 非タスクコンテキスト用のスタックに */
	ldr		sp, [r2]
	push	{r0,r3}					/* 切換え前のスタックポインタを保存 */
									/* r0はスペース確保のため */
ALABEL(exc_handler_2)
	/*
	 * 【この時点のレジスタ状態】
	 *  r4：CPU例外ハンドラ番号
	 *  r5：CPU例外の情報を記憶している領域の先頭番地
	 */

	/*
	 *  （必要なら）割込みコントローラを操作する．
	 */
	bl		irc_begin_exc

	/*
	 *  CPUロック解除状態にする．
	 *
	 *  カーネル管理外のCPU例外ハンドラは別ルーチンで呼び出すため，単純
	 *  に割込みを許可するだけでよい．
	 */
#if __TARGET_ARCH_ARM < 6
	msr		cpsr_c, #(CPSR_SVC_MODE AOR CPSR_UNLOCK)
#else /* __TARGET_ARCH_ARM < 6 */
#ifndef TOPPERS_SAFEG_SECURE
	cpsie	if
#else /* TOPPERS_SAFEG_SECURE */
	cpsie	f
#endif /* TOPPERS_SAFEG_SECURE */
#endif /* __TARGET_ARCH_ARM < 6 */

	/*
	 *  ログ出力の呼出し
	 */
#ifdef LOG_EXC_ENTER
	mov		r0, r4					/* CPU例外番号をパラメータに渡す */
	bl		log_exc_enter
#endif /* LOG_EXC_ENTER */

	/*
	 *  CPU例外ハンドラの呼出し
	 */
	ldr		r2, =exc_table			/* CPU例外ハンドラテーブルの読込み */
	ldr		r3, [r2,r4,lsl #2]		/* CPU例外ハンドラの番地 → r3 */
	mov		r0, r5					/* CPU例外の情報を記憶している領域の */
									/*		先頭番地を第1パラメータに渡す */
	mov		r1, r4					/* CPU例外番号を第2パラメータに渡す */
	mov		lr, pc					/* CPU例外ハンドラの呼出し */
	bx		r3

	/*
	 *  ログ出力の呼出し
	 */
#ifdef LOG_EXC_LEAVE
	mov		r0, r4					/* CPU例外番号をパラメータに渡す */
	bl		log_exc_leave
#endif /* LOG_EXC_LEAVE */

	/*
	 *  カーネル管理の割込みを禁止する．
	 */
#if __TARGET_ARCH_ARM < 6
	msr		cpsr_c, #(CPSR_SVC_MODE AOR CPSR_CPULOCK)
#else /* __TARGET_ARCH_ARM < 6 */
#ifndef TOPPERS_SAFEG_SECURE
	cpsid	i
#else /* TOPPERS_SAFEG_SECURE */
	cpsid	if
#endif /* TOPPERS_SAFEG_SECURE */
#endif /* __TARGET_ARCH_ARM < 6 */

	/*
	 *  割込みコントローラを操作して，割込み優先度マスクを，CPU例外発
	 *  生時の値に設定する．
	 */
	bl		irc_end_exc

	/*
	 *  例外ネストカウントをデクリメントする．
	 */
	ldr		r2, =excpt_nest_count
	ldr		r3, [r2]
	subs	r3, r3, #1
	str		r3, [r2]				/* 戻り先が非タスクコンテキストなら */
	bne		exc_handler_5			/*				exc_handler_5に分岐 */

	/*
	 *  タスク用のスタックに戻す．
	 */
	pop		{r0,r3}
	mov		sp, r3

	/*
	 *  p_runtskがNULLか判定する．
	 */
	ldr		r0, =p_runtsk			/* p_runtsk → r0 */
	ldr		r0, [r0]
	tst		r0, r0					/* p_runtskがNULLでなければ */
	bne		exc_handler_3			/*		exc_handler_3に分岐 */

	/*
	 *  タスクのスタックに保存したスクラッチレジスタ等を捨てる．
	 */
	pop		{r0,r1}					/* スタックポインタの調整を元に戻す */
	add		sp, sp, r1
	add		sp, sp, #48				/* スクラッチレジスタとCPU例外が発生した */
	b		dispatcher_0			/*	状況を判断するための追加情報を捨てる */

	/*
	 *  ディスパッチが必要か判定する．
	 */
ALABEL(exc_handler_3)
	ldr		r1, =p_schedtsk			/* p_schedtsk → r1 */
	ldr		r1, [r1]
	teq		r0, r1					/* p_runtskとp_schedtskが同じなら */
	beq		exc_handler_4			/*				  exc_handler_4へ */

	/*
	 *  コンテキストを保存する．
	 */
	stmfd	sp!, {r6-r11}			/* 非スクラッチレジスタの保存 */
	str		sp, [r0,#TCB_sp]		/* スタックポインタを保存 */
	adr		r1, ret_exc_r			/* 実行再開番地を保存 */
	str		r1, [r0,#TCB_pc]
	b		dispatcher				/* r0にはp_runtskが格納されている */

ALABEL(ret_exc_r)
	/*
	 *  コンテキストを復帰する．
	 */
	ldmfd	sp!, {r6-r11}			/* 非スクラッチレジスタの復帰 */

ALABEL(exc_handler_4)
#ifdef TOPPERS_SUPPORT_OVRHDR
	/*
	 *  オーバランタイマを動作開始する．
	 */
	bl		ovrtimer_start
#endif /* TOPPERS_SUPPORT_OVRHDR */

	/*
	 *  CPU例外処理からのリターン
	 *
	 *  CPU例外処理からのリターンにより，CPUロック解除状態に遷移するよ
	 *  うにする必要があるが，ARMはCPSRのビットによってCPUロック状態を
	 *  表しているため，CPSRを元に戻してリターンすればよい．
	 */
ALABEL(exc_handler_5)
	pop		{r0,r1}					/* スタックポインタの調整を元に戻す */
	add		sp, sp, r1
	add		sp, sp, #8				/* スタック上の情報を捨てる */

#if __TARGET_ARCH_ARM < 6
	ldmfd	sp!, {r0}				/* 戻り先のcpsrをspsrに設定 */
	msr		spsr_cxsf, r0
	ldmfd	sp!, {r0-r5,r12,lr,pc}^	/* コンテキストの復帰 */
									/* ^付きなので，spsr → cpsr */
#else /* __TARGET_ARCH_ARM < 6 */
	ldmfd	sp!, {r0-r5,r12,lr}
	rfefd	sp!
#endif /* __TARGET_ARCH_ARM < 6 */

/*
 *  カーネル管理外のCPU例外の出入口処理
 */
ALABEL(nk_exc_handler_1)
	/*
	 * 【この時点のレジスタ状態】
	 *  r1：CPU例外発生前のCPSRのFビットとIビットの値
	 *  r2：excpt_nest_countの番地
	 *  r3：excpt_nest_countの値
	 *  r4：CPU例外ハンドラ番号
	 *  r5：CPU例外の情報を記憶している領域の先頭番地
	 */

	/*
	 *  例外ネストカウントをインクリメントする．
	 */
	add		r3, r3, #1
	str		r3, [r2]
	teq		r3, #1					/* CPU例外発生前が非タスクコンテキスト */
	bne		nk_exc_handler_2		/*		 	ならnk_exc_handler_2に分岐 */

	/*
	 *  非タスクコンテキスト用のスタックに切り換える．
	 */
	mov		r3, sp					/* この時点のスタックポインタをr3に */
	ldr		r2, =istkpt				/* 非タスクコンテキスト用のスタックに */
	ldr		sp, [r2]
	push	{r0,r3}					/* 切換え前のスタックポインタを保存 */
									/* r0はスペース確保のため */
ALABEL(nk_exc_handler_2)
	/*
	 *  システム状態（コンテキストは除く）を，CPU例外発生時の状態へ
	 */
	orr		r1, r1, #CPSR_SVC_MODE
	msr		cpsr_c, r1

	/*
	 *  CPU例外ハンドラの呼出し
	 */
	ldr		r2, =exc_table			/* CPU例外ハンドラテーブルの読込み */
	ldr		r3, [r2,r4,lsl #2]		/* CPU例外ハンドラの番地 → r3 */
	mov		r0, r5					/* CPU例外の情報を記憶している領域の */
									/*		先頭番地を第1パラメータに渡す */
	mov		r1, r4					/* CPU例外番号を第2パラメータに渡す */
	mov		lr, pc					/* CPU例外ハンドラの呼出し */
	bx		r3

	/*
	 *  例外ネストカウントをデクリメントする．
	 */
	ldr		r2, =excpt_nest_count
	ldr		r3, [r2]
	subs	r3, r3, #1
	str		r3, [r2]				/* 戻り先が非タスクコンテキストなら */
	bne		exc_handler_5			/*				exc_handler_5に分岐 */

	/*
	 *  タスク用のスタックに戻す．
	 */
	pop		{r0,r3}
	mov		sp, r3
	b		exc_handler_5

/*
 *  ステータスレジスタの操作関数
 *
 *  Thumbモードではmrs/msr命令が使用できないため，関数として実現して，
 *  ARMモードに移行して実行する．
 */
#ifdef __thumb__

	ATEXT
	AALIGN(2)
	AWEAK(_kernel_current_cpsr)
ALABEL(_kernel_current_cpsr)
	mrs		r0, cpsr_cxsf
	bx		lr

	AALIGN(2)
	AWEAK(_kernel_set_cpsr)
ALABEL(_kernel_set_cpsr)
	msr		cpsr_cxsf, r0
	bx		lr

#endif /* __thumb__ */

/*
 *  微少時間待ち
 *
 *  キャッシュラインのどの場所にあるかのよって実行時間が変わるため，大
 *  きめの単位でアラインしている．
 */
	ATEXT
	AALIGN(8)
	AGLOBAL(sil_dly_nse)
ALABEL(sil_dly_nse)
	mov		r1, #0
	mcr		p15, 0, r1, c7, c5, 6		/* 分岐予測全体の無効化 */
	asm_inst_sync_barrier r3
	subs	r0, r0, #SIL_DLY_TIM1
	bxls	lr
ALABEL(sil_dly_nse1)
	mcr		p15, 0, r1, c7, c5, 6		/* 分岐予測全体の無効化 */
	asm_inst_sync_barrier r3
	subs	r0, r0, #SIL_DLY_TIM2
	bhi		sil_dly_nse1
	bx		lr
