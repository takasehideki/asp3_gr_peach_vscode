/*
 *  TOPPERS/ASP Kernel
 *      Toyohashi Open Platform for Embedded Real-Time Systems/
 *      Advanced Standard Profile Kernel
 * 
 *  Copyright (C) 2000-2003 by Embedded and Real-Time Systems Laboratory
 *                              Toyohashi Univ. of Technology, JAPAN
 *  Copyright (C) 2005-2016 by Embedded and Real-Time Systems Laboratory
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
 *  $Id: chip_timer.h 742 2016-04-07 13:11:22Z ertl-hiro $
 */

/*
 *		タイマドライバ（RZ/A1 OSタイマ用）
 *
 *  RZ/A1は2チャンネルのOSタイマを持つが，その内の1つを用いて高分解能タ
 *  イマを，もう1つを用いてオーバランタイマを実現する．
 */

#ifndef TOPPERS_CHIP_TIMER_H
#define TOPPERS_CHIP_TIMER_H

#include <sil.h>
#include "rza1.h"

/*
 *  タイマ割込みハンドラ登録のための定数
 */
#define INHNO_TIMER		INTNO_OSTM0			/* 割込みハンドラ番号 */
#define INTNO_TIMER		INTNO_OSTM0			/* 割込み番号 */
#define INTPRI_TIMER	(TMAX_INTPRI - 1)	/* 割込み優先度 */
#define INTATR_TIMER	TA_EDGE				/* 割込み属性 */

/*
 *  オーバランタイマ割込みハンドラ登録のための定数
 */
#ifdef TOPPERS_SUPPORT_OVRHDR
#define INHNO_OVRTIMER		INTNO_OSTM1			/* 割込みハンドラ番号 */
#define INTNO_OVRTIMER		INTNO_OSTM1			/* 割込み番号 */
#define INTPRI_OVRTIMER		TMAX_INTPRI			/* 割込み優先度 */
#define INTATR_OVRTIMER		TA_EDGE				/* 割込み属性 */
#endif /* TOPPERS_SUPPORT_OVRHDR */

/*
 *  OSタイマの周波数の想定値のチェック
 *
 *  現在の実装は，クロックが33.33…MHzの場合のみに対応している．
 */
#if OSTM_CLK != 33333333UL
#error Unsupported OS time clock.
#endif /* OSTM_CLK != 33333333UL */

/*
 *  OSタイマレジスタの番地の定義
 */
#define OSTM_CMP(base)		((uint32_t *)(base + 0x00U))
#define OSTM_CNT(base)		((uint32_t *)(base + 0x04U))
#define OSTM_TE(base)		((uint8_t *)(base + 0x10U))
#define OSTM_TS(base)		((uint8_t *)(base + 0x14U))
#define OSTM_TT(base)		((uint8_t *)(base + 0x18U))
#define OSTM_CTL(base)		((uint8_t *)(base + 0x20U))

/*
 *  OSタイマ カウント開始トリガレジスタの設定値の定義
 */
#define OSTM_TS_START		0x01U

/*
 *  OSタイマ カウント停止トリガレジスタの設定値の定義
 */
#define OSTM_TT_STOP		0x01U

/*
 *  OSタイマ 制御レジスタの設定値の定義
 */
#define OSTM_CTL_INTERVAL	0x00U		/* インターバルタイマモード */
#define OSTM_CTL_FRCMP		0x02U		/* フリーランニングコンペアモード */

#ifndef TOPPERS_MACRO_ONLY

/*
 *  高分解能タイマの起動処理
 */
extern void	target_hrt_initialize(intptr_t exinf);

/*
 *  高分解能タイマの停止処理
 */
extern void	target_hrt_terminate(intptr_t exinf);

/*
 *  高分解能タイマの現在のカウント値の読出し
 */
Inline HRTCNT
target_hrt_get_current(void)
{
	uint32_t	cnt, cnt1;

	cnt = sil_rew_mem(OSTM_CNT(OSTM0_BASE));

	/* μ秒単位に変換（クロックが33.33…MHzである前提）*/
	cnt1 = cnt / 1000000000;
	return((HRTCNT)((cnt - cnt1 * 999999999) * 3 / 100 + cnt1 * 30000000));
}

/*
 *  高分解能タイマへの割込みタイミングの設定
 *
 *  高分解能タイマを，hrtcntで指定した値カウントアップしたら割込みを発
 *  生させるように設定する．
 */
extern void target_hrt_set_event(HRTCNT hrtcnt);

/*
 *  高分解能タイマ割込みの要求
 */
extern  void target_hrt_raise_event(void);

/*
 *  割込みタイミングに指定する最大値
 */
#define HRTCNT_BOUND	100000002U

/*
 *  高分解能タイマ割込みハンドラ
 */
extern void	target_hrt_handler(void);

#ifdef TOPPERS_SUPPORT_OVRHDR

/*
 *  オーバランタイマの初期化処理
 */
extern void target_ovrtimer_initialize(intptr_t exinf);

/*
 *  オーバランタイマの停止処理
 */
extern void target_ovrtimer_terminate(intptr_t exinf);

/*
 *  オーバランタイマの動作開始
 */
Inline void
target_ovrtimer_start(PRCTIM ovrtim)
{
	uint32_t	cnt = ovrtim * 33 + ovrtim / 3 + 1;

	sil_wrw_mem(OSTM_CMP(OSTM1_BASE), cnt);
	sil_wrb_mem(OSTM_TS(OSTM1_BASE), OSTM_TS_START);
}

/*
 *  オーバランタイマの停止
 */
extern PRCTIM target_ovrtimer_stop(void);

/*
 *  オーバランタイマの現在値の読出し
 */
extern PRCTIM target_ovrtimer_get_current(void);

/*
 *  オーバランタイマ割込みハンドラ
 */
extern void	target_ovrtimer_handler(void);

#endif /* TOPPERS_SUPPORT_OVRHDR */
#endif /* TOPPERS_MACRO_ONLY */
#endif /* TOPPERS_CHIP_TIMER_H */
