/*
 * Copyright 2012  Luis R. Rodriguez <mcgrof@do-not-panic.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 *
 * Compatibility file for Linux wireless for kernels 3.5.
 */

#include <linux/module.h>
#include <linux/highuid.h>

/*
 * Commit 7a4e7408c5cadb240e068a662251754a562355e3
 * exported overflowuid and overflowgid for all
 * kernel configurations, prior to that we only
 * had it exported when CONFIG_UID16 was enabled.
 * We are technically redefining it here but
 * nothing seems to be changing it, except
 * kernel/ code does epose it via sysctl and
 * proc... if required later we can add that here.
 */
#ifndef CONFIG_UID16
int overflowuid = DEFAULT_OVERFLOWUID;
int overflowgid = DEFAULT_OVERFLOWGID;

EXPORT_SYMBOL(overflowuid);
EXPORT_SYMBOL(overflowgid);
#endif
