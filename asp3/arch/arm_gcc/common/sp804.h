/*
 *  TOPPERS Software
 *      Toyohashi Open Platform for Embedded Real-Time Systems
 * 
 *  Copyright (C) 2015 by Embedded and Real-Time Systems Laboratory
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
 *  $Id: sp804.h 530 2016-01-14 15:17:30Z ertl-hiro $
 */

/*
 *		ARM Dual-Timer Module（SP804）に関する定義
 */

#ifndef TOPPERS_SP804_H
#define TOPPERS_SP804_H

/*
 *  タイマレジスタの番地の定義
 */
#define SP804_LR(base)		((uint32_t *)((base) + 0x00U))
#define SP804_CVR(base)		((uint32_t *)((base) + 0x04U))
#define SP804_CR(base)		((uint32_t *)((base) + 0x08U))
#define SP804_ICR(base)		((uint32_t *)((base) + 0x0cU))
#define SP804_RIS(base)		((uint32_t *)((base) + 0x10U))
#define SP804_MIS(base)		((uint32_t *)((base) + 0x14U))
#define SP804_BGLR(base)	((uint32_t *)((base) + 0x18U))

/*
 *  制御レジスタ（SP804_CR）の設定値
 */
#define SP804_DISABLE			UINT_C(0x00)	/* タイマディスエーブル */
#define SP804_ENABLE			UINT_C(0x80)	/* タイマイネーブル */
#define SP804_INT_ENABLE		UINT_C(0x20)	/* タイマ割込みイネーブル */
#define SP804_MODE_FREERUN		UINT_C(0x00)	/* フリーランニングモード */
#define SP804_MODE_PERIODIC		UINT_C(0x40)	/* 周期モード */
#define SP804_MODE_ONESHOT		UINT_C(0x01)	/* ワンショットモード */
#define SP804_SIZE_32			UINT_C(0x02)	/* 32ビット */
#define SP804_PRESCALE_1		UINT_C(0x00)	/* プリスケーラ ×1 */
#define SP804_PRESCALE_16		UINT_C(0x04)	/* プリスケーラ ×16 */
#define SP804_PRESCALE_256		UINT_C(0x08)	/* プリスケーラ ×256 */

#endif /* TOPPERS_SP804_H */
