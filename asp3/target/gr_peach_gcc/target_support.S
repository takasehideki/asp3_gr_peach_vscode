/*
 *  TOPPERS/ASP Kernel
 *      Toyohashi Open Platform for Embedded Real-Time Systems/
 *      Advanced Standard Profile Kernel
 * 
 *  Copyright (C) 2000-2003 by Embedded and Real-Time Systems Laboratory
 *                              Toyohashi Univ. of Technology, JAPAN
 *  Copyright (C) 2006-2016 by Embedded and Real-Time Systems Laboratory
 *              Graduate School of Information Science, Nagoya Univ., JAPAN
 * 
 *  上記著作権者は，以下の(1)～(4)の条件を満たす場合に限り，本ソフトウェ
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
 *  $Id: target_support.S 720 2016-04-01 22:16:17Z ertl-hiro $
 */

/*
 *		カーネルのターゲット依存部のアセンブリ言語部（GR-PEACH用）
 */

#define TOPPERS_MACRO_ONLY
#define TOPPERS_ASM_MACRO
#define UINT_C(val)			(val)		/* uint_t型の定数を作るマクロ */
#define ULONG_C(val)		(val)		/* ulong_t型の定数を作るマクロ */
#define CAST(type, val)		(val)		/* 型キャストを行うマクロ */
#include "kernel_impl.h"
#include "pl310.h"
#include "core_asm.inc"

/*
 *  低レベルのターゲットシステム依存の初期化
 *
 *  スタートアップモジュールの中で，メモリ初期化の前に呼び出される．
 */
	ATEXT
	AALIGN(2)
	AGLOBAL(hardware_init_hook)
ALABEL(hardware_init_hook)
	/*
	 *  内蔵RAMへのアクセス／書込み許可
	 */
	ldr		r2, =(RZA1_SYSCR3)
	ldr		r0, =0x0f
	strb	r0, [r2]		/* 内蔵保持用RAMのページ0〜3への書込み許可 */
	ldrb	r0, [r2]		/* ダミーリード */

	/* 
	 *  クロック関係の初期化
	 *
	 *  以下の設定とする．
	 *		入力周波数：13.33MHz，CKIO：66.67MHz
	 *		CPUクロック（Iφ）：400.00MHz
	 *		画像処理クロック（Gφ）：266.67MHz
	 *		内部バスクロック（Bφ）：133.33MHz
	 *		周辺クロック1（P1φ）：66.67MHz
	 *		周辺クロック0（P0φ）：33.33MHz
	 */
	
	/*
	 *  L2キャッシュのスタンバイモードをイネーブル（周波数変更時に必要）
	 */
	ldr		r2, =(PL310_POWER_CTRL)
	ldr		r0, [r2]
	orr		r0, r0, #0x01	/* スタンバイモードに */
	str		r0, [r2]

ALABEL(set_frqcr)
	/*
	 *  CPUクロックを「×1倍」に（400MHz）
	 */
	ldr		r2, =(RZA1_FRQCR)
	ldr		r0, =0x1035
	strh	r0, [r2]
	ldrh	r1, [r2]
	cmp		r0, r1
	bne		set_frqcr

#ifdef TOPPERS_RZA1H
	/* 
	 *  画像処理クロックを「×2/3」に（266.67MHz）
	 */
ALABEL(set_frqcr2)
	ldr		r2, =(RZA1_FRQCR2)
	ldr		r0, =0x0001
	strh	r0, [r2]
	ldrh	r1, [r2]
	cmp		r0, r1
	bne		set_frqcr2
#endif /* TOPPERS_RZA1H */

	/* 
	 *  ソフトウェアスタンバイ復帰中でなくなるまで待つ
	 */
wait_isbusy:
	ldr		r2, =(RZA1_CPUSTS)
	ldrb	r0, [r2]
	tst		r0, #0x10
	bne		wait_isbusy

	/*
	 *  L2キャッシュのスタンバイモードをディスエーブル
	 */
	ldr		r2, =(PL310_POWER_CTRL)
	ldr		r0, [r2]
	bfc		r0, #0, #1		/* スタンバイモードをディスエーブル */
	str		r0, [r2]
	bx		lr
