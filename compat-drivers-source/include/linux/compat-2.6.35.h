#ifndef LINUX_26_35_COMPAT_H
#define LINUX_26_35_COMPAT_H

#include <linux/version.h>

#if (LINUX_VERSION_CODE < KERNEL_VERSION(2,6,35))
#include <linux/etherdevice.h>
#include <net/sock.h>
#include <linux/types.h>
#include <linux/usb.h>
#include <linux/spinlock.h>
#include <net/sch_generic.h>

#define HID_QUIRK_NO_IGNORE                    0x40000000
#define HID_QUIRK_HIDDEV_FORCE                 0x00000010

/* added on linux/kernel.h */
#define USHRT_MAX      ((u16)(~0U))
#define SHRT_MAX       ((s16)(USHRT_MAX>>1))
#define SHRT_MIN       ((s16)(-SHRT_MAX - 1))

#define  SDIO_BUS_ECSI		0x20	/* Enable continuous SPI interrupt */
#define  SDIO_BUS_SCSI		0x40	/* Support continuous SPI interrupt */

#define netdev_hw_addr dev_mc_list

#if (LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,27))
/* Reset all TX qdiscs greater then index of a device.  */
static inline void qdisc_reset_all_tx_gt(struct net_device *dev, unsigned int i)
{
	struct Qdisc *qdisc;

	for (; i < dev->num_tx_queues; i++) {
		qdisc = netdev_get_tx_queue(dev, i)->qdisc;
		if (qdisc) {
			spin_lock_bh(qdisc_lock(qdisc));
			qdisc_reset(qdisc);
			spin_unlock_bh(qdisc_lock(qdisc));
		}
	}
}
#else
static inline void qdisc_reset_all_tx_gt(struct net_device *dev, unsigned int i)
{
}
#endif /* (LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,27)) */

extern int netif_set_real_num_tx_queues(struct net_device *dev,
					unsigned int txq);

/* mask irq_set_affinity_hint as RHEL6 backports this */
#define irq_set_affinity_hint(a,b) compat_irq_set_affinity_hint(a,b)
/*
 * We cannot backport this guy as the IRQ data structure
 * was modified in the kernel itself to support this. We
 * treat the system as uni-processor in this case.
 */
static inline int irq_set_affinity_hint(unsigned int irq,
					const struct cpumask *m)
{
	return -EINVAL;
}

static inline wait_queue_head_t *sk_sleep(struct sock *sk)
{
	return sk->sk_sleep;
}

#define sdio_writeb_readb(func, write_byte, addr, err_ret) sdio_readb(func, addr, err_ret)

/* mask hex_to_bin as RHEL6 backports this */
#define hex_to_bin(a) compat_hex_to_bin(a)

int hex_to_bin(char ch);

extern loff_t noop_llseek(struct file *file, loff_t offset, int origin);

#define pm_qos_request(_qos) pm_qos_requirement(_qos)

/* mask usb_pipe_endpoint as RHEL6 backports this */
#define usb_pipe_endpoint(a,b) compat_usb_pipe_endpoint(a,b)

static inline struct usb_host_endpoint *
usb_pipe_endpoint(struct usb_device *dev, unsigned int pipe)
{
	struct usb_host_endpoint **eps;
	eps = usb_pipein(pipe) ? dev->ep_in : dev->ep_out;
	return eps[usb_pipeendpoint(pipe)];
}

extern ssize_t simple_write_to_buffer(void *to, size_t available, loff_t *ppos,
		const void __user *from, size_t count);

#endif /* (LINUX_VERSION_CODE < KERNEL_VERSION(2,6,35)) */

#endif /* LINUX_26_35_COMPAT_H */
