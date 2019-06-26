/*
 *  TOPPERS/ASP Kernel
 *      Toyohashi Open Platform for Embedded Real-Time Systems/
 *      Advanced Standard Profile Kernel
 * 
 *  Copyright (C) 2007-2017 by Embedded and Real-Time Systems Laboratory
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
 *  $Id: target_kernel_impl.c 791 2017-07-02 18:46:36Z ertl-hiro $
 */

/*
 *		カーネルのターゲット依存部（CT11MPCore用）
 */

#include "kernel_impl.h"
#include <sil.h>
#include "arm.h"

/*
 *  カーネル動作時のメモリマップと関連する定義
 *
 *  0x00000000 - 0x00100000：ベクター領域（1MB）
 *  0x00100000 - 0x0FFFFFFF：DRAM（255MB）
 *  0x10000000 - 0x100FFFFF：Emulation Baseboard上のリソース（1MB）
 *  0x10100000 - 0x101FFFFF：Private Memory Region（1MB）(*)
 *  0x48000000 - 0x4BFFFFFF：SRAM（4MB）
 *
 *  (*) Private Memory Regionの先頭番地は，ボードの設定で変更できる．
 */

/*
 *  MMUへの設定属性（第1レベルディスクリプタ）
 */
#define MMU_ATTR_RAM	(ARM_MMU_DSCR1_SHARED|ARMV6_MMU_DSCR1_APX0 \
							|ARM_MMU_DSCR1_TEX001|ARM_MMU_DSCR1_AP11 \
							|ARM_MMU_DSCR1_CB11)
#define MMU_ATTR_IODEV	(ARM_MMU_DSCR1_SHARED|ARMV6_MMU_DSCR1_APX0 \
							|ARM_MMU_DSCR1_TEX000|ARM_MMU_DSCR1_AP11 \
							|ARM_MMU_DSCR1_CB01|ARMV6_MMU_DSCR1_NOEXEC)
#define MMU_ATTR_VECTOR	(ARMV6_MMU_DSCR1_APX0 \
							|ARM_MMU_DSCR1_TEX001|ARM_MMU_DSCR1_AP11 \
							|ARM_MMU_DSCR1_CB11)

/*
 *  メモリ領域の先頭番地とサイズ
 */
#define SDRAM_ADDR		0x00100000
#define SDRAM_SIZE		0x0ff00000		/* 255MB */
#define SDRAM_ATTR		MMU_ATTR_RAM

#define SRAM_ADDR		0x48000000
#define SRAM_SIZE		0x04000000		/* 16MB */
#define SRAM_ATTR		MMU_ATTR_RAM

/*
 *  デバイスレジスタ領域の先頭番地とサイズ
 */
#define EB_SYS_ADDR		EB_SYS_BASE
#define EB_SYS_SIZE		0x00100000		/* 1MB */
#define EB_SYS_ATTR		MMU_ATTR_IODEV

#define PMR_ADDR		MPCORE_PMR_BASE
#define PMR_SIZE		0x00100000		/* 1MB */
#define PMR_ATTR		MMU_ATTR_IODEV

/*
 *  ベクタテーブルを置くメモリ領域
 */
#define VECTOR_ADDR		0x01000000
#define VECTOR_SIZE		0x00100000		/* 1MB */
#define VECTOR_ATTR		MMU_ATTR_VECTOR

/*
 *  MMUの設定情報（メモリエリアの情報）
 */
ARM_MMU_CONFIG arm_memory_area[] = {
	{ 0x00000000, VECTOR_ADDR, VECTOR_SIZE, VECTOR_ATTR },
	{ SRAM_ADDR, SRAM_ADDR, SRAM_SIZE, SRAM_ATTR },
	{ EB_SYS_ADDR, EB_SYS_ADDR, EB_SYS_SIZE, EB_SYS_ATTR },
	{ PMR_ADDR, PMR_ADDR, PMR_SIZE, PMR_ATTR },
	{ SDRAM_ADDR, SDRAM_ADDR, SDRAM_SIZE, SDRAM_ATTR }
};

/*
 *  MMUの設定情報の数（メモリエリアの数）
 */
const uint_t arm_tnum_memory_area
					= sizeof(arm_memory_area) / sizeof(ARM_MMU_CONFIG);

/*
 *  システムログの低レベル出力のための初期化
 *
 *  セルタイプtPutLogCT11MPCore内に実装されている関数を直接呼び出す．
 */
extern void	tPutLogCT11MPCore_initialize(void);

/*
 *  ターゲット依存の初期化
 */
void
target_initialize(void)
{
	uint32_t	reg;

	/*
	 *  チップ依存の初期化
	 */
	chip_initialize();
	
	/*
	 *  Emulation Baseboardの割込みモードの設定
	 */
	sil_wrw_mem(EB_SYS_LOCK, EB_SYS_LOCK_UNLOCK);	/* ロック解除 */

	reg = sil_rew_mem(EB_SYS_PLD_CTRL1);
	reg &= ~EB_SYS_PLD_CTRL1_INTMODE_MASK;
	reg |= EB_SYS_PLD_CTRL1_INTMODE_NEW_NODCC;
	sil_wrw_mem(EB_SYS_PLD_CTRL1, reg);

	sil_wrw_mem(EB_SYS_LOCK, EB_SYS_LOCK_LOCK);		/* ロック */
	
	/*
	 *  UARTを初期化
	 */
#ifndef TOPPERS_OMIT_TECS
	tPutLogCT11MPCore_initialize();
#endif /* TOPPERS_OMIT_TECS */
}

/*
 *  ターゲット依存の終了処理
 */
void
target_exit(void)
{
	/*
	 *  チップ依存の終了処理
	 */
	chip_terminate();

	/*
	 *  ターゲット依存の終了処理
	 */
#if defined(TOPPERS_USE_QEMU) && !defined(TOPPERS_OMIT_QEMU_SEMIHOSTING)
	/*
	 *  QEMUを終了させる．
	 */
	Asm("mov r0, #24\n\t"
		"svc 0x00123456");
#endif
	while (true) ;
}
