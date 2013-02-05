#if (LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,34))
/*
 * XXX: The include guard was sent upstream, drop this
 * once the guard is merged.
 */
#ifndef LINUX_VGA_SWITCHEROO_H /* in case this gets upstream */
#include_next <linux/vga_switcheroo.h>
#ifndef LINUX_VGA_SWITCHEROO_H /* do not redefine once this gets upstream */
#define LINUX_VGA_SWITCHEROO_H
#endif /* case 1 LINUX_VGA_SWITCHEROO_H */
#endif /* case 2 LINUX_VGA_SWITCHEROO_H */
#endif /* (LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,34)) */
