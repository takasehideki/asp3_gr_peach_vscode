/*
 *  TOPPERS/ASP Kernel
 *      Toyohashi Open Platform for Embedded Real-Time Systems/
 *      Advanced Standard Profile Kernel
 * 
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
 *  $Id: chip_timer.c 777 2017-02-03 23:20:57Z ertl-hiro $
 */

/*
 *		タイマドライバ（RZ/A1 OSタイマ用）
 *
 *  RZ/A1は2チャンネルのOSタイマを持つが，その内の1つを用いて高分解能タ
 *  イマを，もう1つを用いてオーバランタイマを実現する．
 */

#include "kernel_impl.h"
#include "time_event.h"
#ifdef TOPPERS_SUPPORT_OVRHDR
#include "overrun.h"
#endif /* TOPPERS_SUPPORT_OVRHDR */
#include "target_timer.h"
#include <sil.h>
#include "rza1.h"

/*
 *  タイマの起動処理
 */
void
target_hrt_initialize(intptr_t exinf)
{
	/*
	 *  OSタイマをフリーランニングコンペアモードに設定する．
	 */
	sil_wrb_mem(OSTM_CTL(OSTM0_BASE), OSTM_CTL_FRCMP);

	/*
	 *  OSタイマの設定値を最大値にしておく．
	 */
	sil_wrw_mem(OSTM_CMP(OSTM0_BASE), 0xffffffff);

	/*
	 *  OSタイマを動作開始する．
	 */
	sil_wrb_mem(OSTM_TS(OSTM0_BASE), OSTM_TS_START);

	/*
	 *  タイマ割込み要求をクリアする．
	 */
	clear_int(INTNO_OSTM0);
}

/*
 *  タイマの停止処理
 */
void
target_hrt_terminate(intptr_t exinf)
{
	/*
	 *  OSタイマを停止する．
	 */
	sil_wrb_mem(OSTM_TT(OSTM0_BASE), OSTM_TT_STOP);

	/*
	 *  タイマ割込み要求をクリアする．
	 */
	clear_int(INTNO_OSTM0);
}

/*
 *  高分解能タイマへの割込みタイミングの設定
 */
void
target_hrt_set_event(HRTCNT hrtcnt)
{
	uint32_t	cnt = hrtcnt * 33 + hrtcnt / 3 + 1;
	uint32_t	current;

	/*
	 *  現在のカウント値を読み，hrtcnt後に割込みが発生するように設定する．
	 */
	current = sil_rew_mem(OSTM_CNT(OSTM0_BASE));
	sil_wrw_mem(OSTM_CMP(OSTM0_BASE), current + cnt);

	/*
	 *  上で現在のカウント値を読んで以降に，cnt以上カウントアップしてい
	 *  た場合には，割込みを発生させる．
	 */
	if (sil_rew_mem(OSTM_CNT(OSTM0_BASE)) - current >= cnt) {
		raise_int(INTNO_OSTM0);
	}
}

/*
 *  高分解能タイマ割込みの要求
 */
void
target_hrt_raise_event(void)
{
	raise_int(INTNO_OSTM0);
}

/*
 *  タイマ割込みハンドラ
 */
void
target_hrt_handler(void)
{
	/*
	 *  高分解能タイマ割込みを処理する．
	 */
	signal_time();
}
/*
 *  オーバランタイマドライバ
 */
#ifdef TOPPERS_SUPPORT_OVRHDR

/*
 *  オーバランタイマの初期化処理
 */
void
target_ovrtimer_initialize(intptr_t exinf)
{
	/*
	 *  OSタイマをインターバルタイマモードに設定する．
	 */
	sil_wrb_mem(OSTM_CTL(OSTM1_BASE), OSTM_CTL_INTERVAL);

	/*
	 *  オーバランタイマ割込み要求をクリアする．
	 */
	clear_int(INTNO_OSTM1);
}

/*
 *  オーバランタイマの停止処理
 */
void
target_ovrtimer_terminate(intptr_t exinf)
{
	/*
	 *  OSタイマを停止する．
	 */
	sil_wrb_mem(OSTM_TT(OSTM1_BASE), OSTM_TT_STOP);

	/*
	 *  オーバランタイマ割込み要求をクリアする．
	 */
	clear_int(INTNO_OSTM1);
}

/*
 *  オーバランタイマの停止
 */
PRCTIM
target_ovrtimer_stop(void)
{
	uint32_t	cnt;

	/*
	 *  OSタイマを停止する．
	 */
	sil_wrb_mem(OSTM_TT(OSTM1_BASE), OSTM_TT_STOP);

	if (probe_int(INTNO_OSTM1)) {
		/*
		 *  割込み要求が発生している場合
		 */
		clear_int(INTNO_OSTM1);
		return(0U);
	}
	else {
		cnt = sil_rew_mem(OSTM_CNT(OSTM1_BASE));
		return((PRCTIM)((cnt + 34) / 5 * 3 / 20));
	}
}

/*
 *  オーバランタイマの現在値の読出し
 */
PRCTIM
target_ovrtimer_get_current(void)
{
	uint32_t	cnt;

	if (probe_int(INTNO_OSTM1)) {
		/*
		 *  割込み要求が発生している場合
		 */
		return(0U);
	}
	else {
		cnt = sil_rew_mem(OSTM_CNT(OSTM1_BASE));
		return((PRCTIM)((cnt + 34) / 5 * 3 / 20));
	}
}

/*
 *  オーバランタイマ割込みハンドラ
 *
 *  このルーチンに来るまでに，target_ovrtimer_stopが呼ばれているため，
 *  OSタイマを停止する必要はない．
 */
void
target_ovrtimer_handler(void)
{
	call_ovrhdr();					/* オーバランハンドラの起動処理 */
}

#endif /* TOPPERS_SUPPORT_OVRHDR */
