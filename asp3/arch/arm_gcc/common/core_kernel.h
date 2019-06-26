/*
 *  TOPPERS/ASP Kernel
 *      Toyohashi Open Platform for Embedded Real-Time Systems/
 *      Advanced Standard Profile Kernel
 * 
 *  Copyright (C) 2000-2003 by Embedded and Real-Time Systems Laboratory
 *                              Toyohashi Univ. of Technology, JAPAN
 *  Copyright (C) 2004-2016 by Embedded and Real-Time Systems Laboratory
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
 *  $Id: core_kernel.h 718 2016-04-01 15:05:01Z ertl-hiro $
 */

/*
 *		kernel.hのコア依存部（ARM用）
 *
 *  このヘッダファイルは，target_kernel.h（または，そこからインクルード
 *  されるファイル）のみからインクルードされる．他のファイルから直接イ
 *  ンクルードしてはならない．
 */

#ifndef TOPPERS_CORE_KERNEL_H
#define TOPPERS_CORE_KERNEL_H

/*
 *  スタックの型
 *
 *  ARMでは，スタックを8バイト境界に配置する必要がある．
 */
#define TOPPERS_STK_T	long long

/*
 *  CPU例外ハンドラ番号の数
 */  
#define TNUM_EXCNO		6

/*
 *  CPU例外ハンドラ番号の定義
 */
#define EXCNO_UNDEF		0
#define EXCNO_SVC		1
#define EXCNO_PABORT	2
#define EXCNO_DABORT	3
#define EXCNO_IRQ		4
#define EXCNO_FIQ		5

#ifndef TOPPERS_MACRO_ONLY

/*
 *  CPU例外の情報を記憶しているメモリ領域の構造
 */
#if __TARGET_ARCH_ARM < 6

typedef struct t_excinf {
	uint32_t	nest_count;				/* 例外ネストカウント */
	uint32_t	intpri;					/* 割込み優先度マスク */
	uint32_t	cpsr;					/* CPU例外発生時のCPSR */
	uint32_t	r0;
	uint32_t	r1;
	uint32_t	r2;
	uint32_t	r3;
	uint32_t	r4;
	uint32_t	r5;
	uint32_t	r12;
	uint32_t	lr;
	uint32_t	pc;						/* 戻り番地 */
} T_EXCINF;

#else /* __TARGET_ARCH_ARM < 6 */

typedef struct t_excinf {
	uint32_t	nest_count;				/* 例外ネストカウント */
	uint32_t	intpri;					/* 割込み優先度マスク */
	uint32_t	r0;
	uint32_t	r1;
	uint32_t	r2;
	uint32_t	r3;
	uint32_t	r4;
	uint32_t	r5;
	uint32_t	r12;
	uint32_t	lr;
	uint32_t	pc;						/* 戻り番地 */
	uint32_t	cpsr;					/* CPU例外発生時のCPSR */
} T_EXCINF;

#endif /* __TARGET_ARCH_ARM < 6 */

#endif /* TOPPERS_MACRO_ONLY */
#endif /* TOPPERS_CORE_KERNEL_H */
