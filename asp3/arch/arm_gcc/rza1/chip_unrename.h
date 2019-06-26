/* This file is generated from chip_rename.def by genrename. */

/* This file is included only when chip_rename.h has been included. */
#ifdef TOPPERS_CHIP_RENAME_H
#undef TOPPERS_CHIP_RENAME_H

/*
 *  chip_kernel_impl.c
 */
#undef chip_initialize
#undef chip_terminate

/*
 *  chip_timer.c
 */
#undef target_hrt_initialize
#undef target_hrt_terminate
#undef target_hrt_set_event
#undef target_hrt_raise_event
#undef target_hrt_handler
#undef target_ovrtimer_initialize
#undef target_ovrtimer_terminate
#undef target_ovrtimer_stop
#undef target_ovrtimer_get_current
#undef target_ovrtimer_handler


#include "core_unrename.h"

#endif /* TOPPERS_CHIP_RENAME_H */
