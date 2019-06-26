/* This file is generated from core_rename.def by genrename. */

/* This file is included only when core_rename.h has been included. */
#ifdef TOPPERS_CORE_RENAME_H
#undef TOPPERS_CORE_RENAME_H

/*
 *  kernel_cfg.c
 */
#undef inh_table
#undef intcfg_table
#undef exc_table

/*
 *  core_support.S
 */
#undef dispatch
#undef start_dispatch
#undef exit_and_dispatch
#undef call_exit_kernel
#undef start_r
#undef irq_handler
#undef undef_handler
#undef svc_handler
#undef pabort_handler
#undef dabort_handler
#undef fiq_handler

/*
 *  core_kernel_impl.c
 */
#undef excpt_nest_count
#undef arm_mmu_initialize
#undef core_initialize
#undef core_terminate
#undef xlog_sys
#undef xlog_fsr
#undef default_int_handler
#undef default_exc_handler

/*
 *  gic_kernel_impl.c
 */
#undef gicc_initialize
#undef gicc_terminate
#undef gicd_initialize
#undef gicd_terminate

/*
 *  gic_support.S
 */
#undef irc_begin_int
#undef irc_end_int
#undef irc_get_intpri
#undef irc_begin_exc
#undef irc_end_exc

/*
 *  pl310.c
 */
#undef pl310_initialize
#undef pl310_disable
#undef pl310_invalidate_all
#undef pl310_clean_and_invalidate_all

/*
 *  target_kernel_impl.c
 */
#undef arm_tnum_memory_area
#undef arm_memory_area


#endif /* TOPPERS_CORE_RENAME_H */
