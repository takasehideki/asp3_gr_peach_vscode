/* This file is generated from target_rename.def by genrename. */

#ifndef TOPPERS_TARGET_RENAME_H
#define TOPPERS_TARGET_RENAME_H

/*
 *  target_kernel_impl.c
 */
#define target_initialize			_kernel_target_initialize
#define target_exit					_kernel_target_exit

/*
 *  target_timer.c
 */
#define target_ovrtimer_initialize	_kernel_target_ovrtimer_initialize
#define target_ovrtimer_terminate	_kernel_target_ovrtimer_terminate
#define target_ovrtimer_start		_kernel_target_ovrtimer_start
#define target_ovrtimer_stop		_kernel_target_ovrtimer_stop
#define target_ovrtimer_get_current	_kernel_target_ovrtimer_get_current
#define target_ovrtimer_handler		_kernel_target_ovrtimer_handler

/*
 *  tTraceLog.c
 */
#define log_dsp_enter				_kernel_log_dsp_enter
#define log_dsp_leave				_kernel_log_dsp_leave
#define log_inh_enter				_kernel_log_inh_enter
#define log_inh_leave				_kernel_log_inh_leave
#define log_exc_enter				_kernel_log_exc_enter
#define log_exc_leave				_kernel_log_exc_leave


#include "chip_rename.h"

#endif /* TOPPERS_TARGET_RENAME_H */
