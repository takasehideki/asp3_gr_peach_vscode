/* This file is generated from target_rename.def by genrename. */

/* This file is included only when target_rename.h has been included. */
#ifdef TOPPERS_TARGET_RENAME_H
#undef TOPPERS_TARGET_RENAME_H

/*
 *  target_kernel_impl.c
 */
#undef target_initialize
#undef target_exit

/*
 *  target_timer.c
 */
#undef target_ovrtimer_initialize
#undef target_ovrtimer_terminate
#undef target_ovrtimer_start
#undef target_ovrtimer_stop
#undef target_ovrtimer_get_current
#undef target_ovrtimer_handler

/*
 *  tTraceLog.c
 */
#undef log_dsp_enter
#undef log_dsp_leave
#undef log_inh_enter
#undef log_inh_leave
#undef log_exc_enter
#undef log_exc_leave


#include "chip_unrename.h"

#endif /* TOPPERS_TARGET_RENAME_H */
