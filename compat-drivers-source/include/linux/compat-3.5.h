#ifndef LINUX_3_5_COMPAT_H
#define LINUX_3_5_COMPAT_H

#include <linux/version.h>
#include <linux/fs.h>
#include <linux/etherdevice.h>
#include <linux/net.h>

#if (LINUX_VERSION_CODE < KERNEL_VERSION(3,5,0))

#include <net/netlink.h>

/*
 * This backports:
 * commit 569a8fc38367dfafd87454f27ac646c8e6b54bca
 * Author: David S. Miller <davem@davemloft.net>
 * Date:   Thu Mar 29 23:18:53 2012 -0400
 *
 *     netlink: Add nla_put_be{16,32,64}() helpers.
 */

static inline int nla_put_be16(struct sk_buff *skb, int attrtype, __be16 value)
{
	return nla_put(skb, attrtype, sizeof(__be16), &value);
}

static inline int nla_put_be32(struct sk_buff *skb, int attrtype, __be32 value)
{
	return nla_put(skb, attrtype, sizeof(__be32), &value);
}

static inline int nla_put_be64(struct sk_buff *skb, int attrtype, __be64 value)
{
	return nla_put(skb, attrtype, sizeof(__be64), &value);
}

/*
 * This backports:
 *
 * commit f56f821feb7b36223f309e0ec05986bb137ce418
 * Author: Daniel Vetter <daniel.vetter@ffwll.ch>
 * Date:   Sun Mar 25 19:47:41 2012 +0200
 *
 *     mm: extend prefault helpers to fault in more than PAGE_SIZE
 *
 * The new functions are used by drm/i915 driver.
 *
 */

static inline int fault_in_multipages_writeable(char __user *uaddr, int size)
{
        int ret = 0;
        char __user *end = uaddr + size - 1;

        if (unlikely(size == 0))
                return ret;

        /*
         * Writing zeroes into userspace here is OK, because we know that if
         * the zero gets there, we'll be overwriting it.
         */
        while (uaddr <= end) {
                ret = __put_user(0, uaddr);
                if (ret != 0)
                        return ret;
                uaddr += PAGE_SIZE;
        }

        /* Check whether the range spilled into the next page. */
        if (((unsigned long)uaddr & PAGE_MASK) ==
                        ((unsigned long)end & PAGE_MASK))
                ret = __put_user(0, end);

        return ret;
}

static inline int fault_in_multipages_readable(const char __user *uaddr,
                                               int size)
{
        volatile char c;
        int ret = 0;
        const char __user *end = uaddr + size - 1;

        if (unlikely(size == 0))
                return ret;

        while (uaddr <= end) {
                ret = __get_user(c, uaddr);
                if (ret != 0)
                        return ret;
                uaddr += PAGE_SIZE;
        }

        /* Check whether the range spilled into the next page. */
        if (((unsigned long)uaddr & PAGE_MASK) ==
                        ((unsigned long)end & PAGE_MASK)) {
                ret = __get_user(c, end);
                (void)c;
        }

        return ret;
}

/* switcheroo is available on >= 2.6.34 */
#if (LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,34))
#include <linux/vga_switcheroo.h>
/*
 * This backports:
 *
 *   From 26ec685ff9d9c16525d8ec4c97e52fcdb187b302 Mon Sep 17 00:00:00 2001
 *   From: Takashi Iwai <tiwai@suse.de>
 *   Date: Fri, 11 May 2012 07:51:17 +0200
 *   Subject: [PATCH] vga_switcheroo: Introduce struct vga_switcheroo_client_ops
 *
 */

struct vga_switcheroo_client_ops {
    void (*set_gpu_state)(struct pci_dev *dev, enum vga_switcheroo_state);
    void (*reprobe)(struct pci_dev *dev);
    bool (*can_switch)(struct pci_dev *dev);
};

/* Wrap around the old code and redefine vga_switcheroo_register_client()
 * for older kernels < 3.5.0.
 */
static inline int compat_vga_switcheroo_register_client(struct pci_dev *dev,
		const struct vga_switcheroo_client_ops *ops) {

	return vga_switcheroo_register_client(dev,
					      ops->set_gpu_state,
#if (LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,38))
					      ops->reprobe,
#endif
					      ops->can_switch);
}

#define vga_switcheroo_register_client(_dev, _ops) \
	compat_vga_switcheroo_register_client(_dev, _ops)

#endif

/* This backports
 *
 * commit 14674e70119ea01549ce593d8901a797f8a90f74
 * Author: Mark Brown <broonie@opensource.wolfsonmicro.com>
 * Date:   Wed May 30 10:55:34 2012 +0200
 *
 *     i2c: Split I2C_M_NOSTART support out of I2C_FUNC_PROTOCOL_MANGLING
 */

#define I2C_FUNC_NOSTART 0x00000010 /* I2C_M_NOSTART */

/*
 * This backports:
 *
 *   From a3860c1c5dd1137db23d7786d284939c5761d517 Mon Sep 17 00:00:00 2001
 *   From: Xi Wang <xi.wang@gmail.com>
 *   Date: Thu, 31 May 2012 16:26:04 -0700
 *   Subject: [PATCH] introduce SIZE_MAX
 */

#define SIZE_MAX    (~(size_t)0)


#include <linux/pkt_sched.h>

/*
 * This backports:
 *
 *   From 76e3cc126bb223013a6b9a0e2a51238d1ef2e409 Mon Sep 17 00:00:00 2001
 *   From: Eric Dumazet <edumazet@google.com>
 *   Date: Thu, 10 May 2012 07:51:25 +0000
 *   Subject: [PATCH] codel: Controlled Delay AQM
 */

#ifndef TCA_CODEL_MAX
/* CODEL */

#define COMPAT_CODEL_BACKPORT

enum {
	TCA_CODEL_UNSPEC,
	TCA_CODEL_TARGET,
	TCA_CODEL_LIMIT,
	TCA_CODEL_INTERVAL,
	TCA_CODEL_ECN,
	__TCA_CODEL_MAX
};

#define TCA_CODEL_MAX	(__TCA_CODEL_MAX - 1)

struct tc_codel_xstats {
	__u32	maxpacket; /* largest packet we've seen so far */
	__u32	count;	   /* how many drops we've done since the last time we
			    * entered dropping state
			    */
	__u32	lastcount; /* count at entry to dropping state */
	__u32	ldelay;    /* in-queue delay seen by most recently dequeued packet */
	__s32	drop_next; /* time to drop next packet */
	__u32	drop_overlimit; /* number of time max qdisc packet limit was hit */
	__u32	ecn_mark;  /* number of packets we ECN marked instead of dropped */
	__u32	dropping;  /* are we in dropping state ? */
};

/* This backports:
 *
 * commit 4b549a2ef4bef9965d97cbd992ba67930cd3e0fe
 * Author: Eric Dumazet <edumazet@google.com>
 * Date:   Fri May 11 09:30:50 2012 +0000
 *    fq_codel: Fair Queue Codel AQM
 */

/* FQ_CODEL */

enum {
	TCA_FQ_CODEL_UNSPEC,
	TCA_FQ_CODEL_TARGET,
	TCA_FQ_CODEL_LIMIT,
	TCA_FQ_CODEL_INTERVAL,
	TCA_FQ_CODEL_ECN,
	TCA_FQ_CODEL_FLOWS,
	TCA_FQ_CODEL_QUANTUM,
	__TCA_FQ_CODEL_MAX
};

#define TCA_FQ_CODEL_MAX	(__TCA_FQ_CODEL_MAX - 1)

enum {
	TCA_FQ_CODEL_XSTATS_QDISC,
	TCA_FQ_CODEL_XSTATS_CLASS,
};

struct tc_fq_codel_qd_stats {
	__u32	maxpacket;	/* largest packet we've seen so far */
	__u32	drop_overlimit; /* number of time max qdisc
				 * packet limit was hit
				 */
	__u32	ecn_mark;	/* number of packets we ECN marked
				 * instead of being dropped
				 */
	__u32	new_flow_count; /* number of time packets
				 * created a 'new flow'
				 */
	__u32	new_flows_len;	/* count of flows in new list */
	__u32	old_flows_len;	/* count of flows in old list */
};

struct tc_fq_codel_cl_stats {
	__s32	deficit;
	__u32	ldelay;		/* in-queue delay seen by most recently
				 * dequeued packet
				 */
	__u32	count;
	__u32	lastcount;
	__u32	dropping;
	__s32	drop_next;
};

struct tc_fq_codel_xstats {
	__u32	type;
	union {
		struct tc_fq_codel_qd_stats qdisc_stats;
		struct tc_fq_codel_cl_stats class_stats;
	};
};
#endif /* TCA_CODEL_MAX */

/* Backport ether_addr_equal */
static inline bool ether_addr_equal(const u8 *addr1, const u8 *addr2)
{
    return !compare_ether_addr(addr1, addr2);
}

#define net_ratelimited_function(function, ...)			\
do {								\
	if (net_ratelimit())					\
		function(__VA_ARGS__);				\
} while (0)

#define net_emerg_ratelimited(fmt, ...)				\
	net_ratelimited_function(pr_emerg, fmt, ##__VA_ARGS__)
#define net_alert_ratelimited(fmt, ...)				\
	net_ratelimited_function(pr_alert, fmt, ##__VA_ARGS__)
#define net_crit_ratelimited(fmt, ...)				\
	net_ratelimited_function(pr_crit, fmt, ##__VA_ARGS__)
#define net_err_ratelimited(fmt, ...)				\
	net_ratelimited_function(pr_err, fmt, ##__VA_ARGS__)
#define net_notice_ratelimited(fmt, ...)			\
	net_ratelimited_function(pr_notice, fmt, ##__VA_ARGS__)
#define net_warn_ratelimited(fmt, ...)				\
	net_ratelimited_function(pr_warn, fmt, ##__VA_ARGS__)
#define net_info_ratelimited(fmt, ...)				\
	net_ratelimited_function(pr_info, fmt, ##__VA_ARGS__)
#define net_dbg_ratelimited(fmt, ...)				\
	net_ratelimited_function(pr_debug, fmt, ##__VA_ARGS__)

#endif /* (LINUX_VERSION_CODE < KERNEL_VERSION(3,5,0)) */

#endif /* LINUX_3_5_COMPAT_H */
