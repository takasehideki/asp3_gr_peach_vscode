/*
 *  TOPPERS Software
 *      Toyohashi Open Platform for Embedded Real-Time Systems
 *
 *  Copyright (C) 2006-2015 by Embedded and Real-Time Systems Laboratory
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
 *  $Id: arm.c 438 2015-08-09 01:37:47Z ertl-hiro $
 */

/*
 *		ARMコアサポートモジュール
 */

#include "arm.h"

/*
 *  キャッシュの操作
 */

/*
 *  データキャッシュのイネーブル
 */
void
arm_enable_dcache(void)
{
	uint32_t	reg;

	CP15_READ_SCTLR(reg);
	if ((reg & CP15_SCTLR_DCACHE) == 0U) {
		arm_invalidate_dcache();

		reg |= CP15_SCTLR_DCACHE;
		CP15_WRITE_SCTLR(reg);
	}
}

/*
 *  データキャッシュのディスエーブル
 *
 *  データキャッシュが無効な状態でclean_and_invalidateを実行すると暴走
 *  する場合があるため，データキャッシュの状態を判断して，無効な場合は，
 *  無効化のみを行う．
 */
void
arm_disable_dcache(void)
{
	uint32_t	reg;

	CP15_READ_SCTLR(reg);
	if ((reg & CP15_SCTLR_DCACHE) == 0U) {
		arm_invalidate_dcache();
	}
	else {
		reg &= ~CP15_SCTLR_DCACHE;
		CP15_WRITE_SCTLR(reg);

		arm_clean_and_invalidate_dcache();
	}
}

/*
 *  命令キャッシュのイネーブル
 */
void
arm_enable_icache(void)
{
	uint32_t	reg;

	CP15_READ_SCTLR(reg);
	if ((reg & CP15_SCTLR_ICACHE) == 0U) {
		arm_invalidate_icache();

		reg |= CP15_SCTLR_ICACHE;
		CP15_WRITE_SCTLR(reg);
	}
}

/*
 *  命令キャッシュのディスエーブル
 */
void
arm_disable_icache(void)
{
	uint32_t	reg;

	CP15_READ_SCTLR(reg);
	reg &= ~CP15_SCTLR_ICACHE;
	CP15_WRITE_SCTLR(reg);

	arm_invalidate_icache();
}

/*
 *  ARMv5におけるデータキャッシュのクリーンと無効化
 */
#if __TARGET_ARCH_ARM <= 5

void
armv5_clean_and_invalidate_dcache(void)
{
	ARMV5_CLEAN_AND_INVALIDATE_DCACHE();
}

#endif /* __TARGET_ARCH_ARM <= 5 */

/*
 *  ARMv7におけるデータキャッシュの無効化
 *
 *  レベル0のキャッシュのみを無効化する．
 */
#if __TARGET_ARCH_ARM == 7

void
armv7_invalidate_dcache(void)
{
	uint32_t	reg;
	uint32_t	way, no_ways, shift_way;
	uint32_t	set, no_sets, shift_set;

	CP15_WRITE_CSSELR(0U);
	CP15_READ_CCSIDR(reg);
	no_sets = ((reg >> 13) & 0x7fffU) + 1;
	shift_set = (reg & 0x07U) + 4;
	no_ways = ((reg >> 3) & 0x3ffU) + 1;
	shift_way = count_leading_zero(no_ways);

	for (way = 0; way < no_ways; way++){
		for (set = 0; set < no_sets; set++) {
			reg = (way << shift_way) | (set << shift_set);
			CP15_WRITE_DCISW(reg);
		}
	}
}

#endif /* __TARGET_ARCH_ARM == 7 */

/*
 *  ARMv7におけるデータキャッシュのクリーンと無効化
 *
 *  レベル0のキャッシュのみをクリーンと無効化する．
 */
#if __TARGET_ARCH_ARM == 7

void
armv7_clean_and_invalidate_dcache(void)
{
	uint32_t	reg;
	uint32_t	way, no_ways, shift_way;
	uint32_t	set, no_sets, shift_set;

	CP15_WRITE_CSSELR(0U);
	CP15_READ_CCSIDR(reg);
	no_sets = ((reg >> 13) & 0x7fffU) + 1;
	shift_set = (reg & 0x07U) + 4;
	no_ways = ((reg >> 3) & 0x3ffU) + 1;
	shift_way = count_leading_zero(no_ways);

	for (way = 0; way < no_ways; way++){
		for (set = 0; set < no_sets; set++) {
			reg = (way << shift_way) | (set << shift_set);
			CP15_WRITE_DCCISW(reg);
		}
	}
}

#endif /* __TARGET_ARCH_ARM == 7 */
