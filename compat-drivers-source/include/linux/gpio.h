#ifndef _COMPAT_LINUX_GPIO_H
#define _COMPAT_LINUX_GPIO_H 1

#include <linux/version.h>

#if (LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,25))
#include_next <linux/gpio.h>
#endif /* (LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,25)) */

#endif	/* _COMPAT_LINUX_GPIO_H */
