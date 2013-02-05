#ifndef LINUX_3_3_COMPAT_H
#define LINUX_3_3_COMPAT_H

#include <linux/version.h>

#if (LINUX_VERSION_CODE < KERNEL_VERSION(3,3,0))

#include <linux/pci_regs.h>

/* include to override NL80211_FEATURE_SK_TX_STATUS */
#include <linux/nl80211.h>
#include <linux/skbuff.h>
#include <net/sch_generic.h>
#include <linux/mii.h>
#include <linux/netdevice.h>

/*
 * BQL was added as of v3.3 but some Linux distributions
 * have backported BQL to their v3.2 kernels or older. To
 * address this we assume that they also enabled CONFIG_BQL
 * and test for that here and simply avoid adding the static
 * inlines if it was defined
 */
#ifndef CONFIG_BQL
#if (LINUX_VERSION_CODE > KERNEL_VERSION(2,6,26))
static inline void netdev_tx_sent_queue(struct netdev_queue *dev_queue,
					unsigned int bytes)
{
}
#endif

static inline void netdev_sent_queue(struct net_device *dev, unsigned int bytes)
{
}

#if (LINUX_VERSION_CODE > KERNEL_VERSION(2,6,26))
static inline void netdev_tx_completed_queue(struct netdev_queue *dev_queue,
					     unsigned pkts, unsigned bytes)
{
}
#endif

static inline void netdev_completed_queue(struct net_device *dev,
					  unsigned pkts, unsigned bytes)
{
}

#if (LINUX_VERSION_CODE > KERNEL_VERSION(2,6,26))
static inline void netdev_tx_reset_queue(struct netdev_queue *q)
{
}
#endif

static inline void netdev_reset_queue(struct net_device *dev_queue)
{
}
#endif /* CONFIG_BQL */

/**
 * ethtool_adv_to_mii_adv_t
 * @ethadv: the ethtool advertisement settings
 *
 * A small helper function that translates ethtool advertisement
 * settings to phy autonegotiation advertisements for the
 * MII_ADVERTISE register.
 */
static inline u32 ethtool_adv_to_mii_adv_t(u32 ethadv)
{
	u32 result = 0;

	if (ethadv & ADVERTISED_10baseT_Half)
		result |= ADVERTISE_10HALF;
	if (ethadv & ADVERTISED_10baseT_Full)
		result |= ADVERTISE_10FULL;
	if (ethadv & ADVERTISED_100baseT_Half)
		result |= ADVERTISE_100HALF;
	if (ethadv & ADVERTISED_100baseT_Full)
		result |= ADVERTISE_100FULL;
	if (ethadv & ADVERTISED_Pause)
		result |= ADVERTISE_PAUSE_CAP;
	if (ethadv & ADVERTISED_Asym_Pause)
		result |= ADVERTISE_PAUSE_ASYM;

	return result;
}

/**
 * mii_adv_to_ethtool_adv_t
 * @adv: value of the MII_ADVERTISE register
 *
 * A small helper function that translates MII_ADVERTISE bits
 * to ethtool advertisement settings.
 */
static inline u32 mii_adv_to_ethtool_adv_t(u32 adv)
{
	u32 result = 0;

	if (adv & ADVERTISE_10HALF)
		result |= ADVERTISED_10baseT_Half;
	if (adv & ADVERTISE_10FULL)
		result |= ADVERTISED_10baseT_Full;
	if (adv & ADVERTISE_100HALF)
		result |= ADVERTISED_100baseT_Half;
	if (adv & ADVERTISE_100FULL)
		result |= ADVERTISED_100baseT_Full;
	if (adv & ADVERTISE_PAUSE_CAP)
		result |= ADVERTISED_Pause;
	if (adv & ADVERTISE_PAUSE_ASYM)
		result |= ADVERTISED_Asym_Pause;

	return result;
}

/**
 * ethtool_adv_to_mii_ctrl1000_t
 * @ethadv: the ethtool advertisement settings
 *
 * A small helper function that translates ethtool advertisement
 * settings to phy autonegotiation advertisements for the
 * MII_CTRL1000 register when in 1000T mode.
 */
static inline u32 ethtool_adv_to_mii_ctrl1000_t(u32 ethadv)
{
	u32 result = 0;

	if (ethadv & ADVERTISED_1000baseT_Half)
		result |= ADVERTISE_1000HALF;
	if (ethadv & ADVERTISED_1000baseT_Full)
		result |= ADVERTISE_1000FULL;

	return result;
}

/**
 * mii_ctrl1000_to_ethtool_adv_t
 * @adv: value of the MII_CTRL1000 register
 *
 * A small helper function that translates MII_CTRL1000
 * bits, when in 1000Base-T mode, to ethtool
 * advertisement settings.
 */
static inline u32 mii_ctrl1000_to_ethtool_adv_t(u32 adv)
{
	u32 result = 0;

	if (adv & ADVERTISE_1000HALF)
		result |= ADVERTISED_1000baseT_Half;
	if (adv & ADVERTISE_1000FULL)
		result |= ADVERTISED_1000baseT_Full;

	return result;
}

/**
 * mii_lpa_to_ethtool_lpa_t
 * @adv: value of the MII_LPA register
 *
 * A small helper function that translates MII_LPA
 * bits, when in 1000Base-T mode, to ethtool
 * LP advertisement settings.
 */
static inline u32 mii_lpa_to_ethtool_lpa_t(u32 lpa)
{
	u32 result = 0;

	if (lpa & LPA_LPACK)
		result |= ADVERTISED_Autoneg;

	return result | mii_adv_to_ethtool_adv_t(lpa);
}

/**
 * mii_stat1000_to_ethtool_lpa_t
 * @adv: value of the MII_STAT1000 register
 *
 * A small helper function that translates MII_STAT1000
 * bits, when in 1000Base-T mode, to ethtool
 * advertisement settings.
 */
static inline u32 mii_stat1000_to_ethtool_lpa_t(u32 lpa)
{
	u32 result = 0;

	if (lpa & LPA_1000HALF)
		result |= ADVERTISED_1000baseT_Half;
	if (lpa & LPA_1000FULL)
		result |= ADVERTISED_1000baseT_Full;

	return result;
}

/**
 * ethtool_adv_to_mii_adv_x
 * @ethadv: the ethtool advertisement settings
 *
 * A small helper function that translates ethtool advertisement
 * settings to phy autonegotiation advertisements for the
 * MII_CTRL1000 register when in 1000Base-X mode.
 */
static inline u32 ethtool_adv_to_mii_adv_x(u32 ethadv)
{
	u32 result = 0;

	if (ethadv & ADVERTISED_1000baseT_Half)
		result |= ADVERTISE_1000XHALF;
	if (ethadv & ADVERTISED_1000baseT_Full)
		result |= ADVERTISE_1000XFULL;
	if (ethadv & ADVERTISED_Pause)
		result |= ADVERTISE_1000XPAUSE;
	if (ethadv & ADVERTISED_Asym_Pause)
		result |= ADVERTISE_1000XPSE_ASYM;

	return result;
}

/**
 * mii_adv_to_ethtool_adv_x
 * @adv: value of the MII_CTRL1000 register
 *
 * A small helper function that translates MII_CTRL1000
 * bits, when in 1000Base-X mode, to ethtool
 * advertisement settings.
 */
static inline u32 mii_adv_to_ethtool_adv_x(u32 adv)
{
	u32 result = 0;

	if (adv & ADVERTISE_1000XHALF)
		result |= ADVERTISED_1000baseT_Half;
	if (adv & ADVERTISE_1000XFULL)
		result |= ADVERTISED_1000baseT_Full;
	if (adv & ADVERTISE_1000XPAUSE)
		result |= ADVERTISED_Pause;
	if (adv & ADVERTISE_1000XPSE_ASYM)
		result |= ADVERTISED_Asym_Pause;

	return result;
}

/**
 * mii_lpa_to_ethtool_lpa_x
 * @adv: value of the MII_LPA register
 *
 * A small helper function that translates MII_LPA
 * bits, when in 1000Base-X mode, to ethtool
 * LP advertisement settings.
 */
static inline u32 mii_lpa_to_ethtool_lpa_x(u32 lpa)
{
	u32 result = 0;

	if (lpa & LPA_LPACK)
		result |= ADVERTISED_Autoneg;

	return result | mii_adv_to_ethtool_adv_x(lpa);
}

/**
 * ethtool_rxfh_indir_default - get default value for RX flow hash indirection
 * @index: Index in RX flow hash indirection table
 * @n_rx_rings: Number of RX rings to use
 *
 * This function provides the default policy for RX flow hash indirection.
 */
static inline u32 ethtool_rxfh_indir_default(u32 index, u32 n_rx_rings)
{
	return index % n_rx_rings;
}

#define ETHTOOL_FWVERS_LEN	32

#if !((LINUX_VERSION_CODE >= KERNEL_VERSION(3,2,9) && LINUX_VERSION_CODE < KERNEL_VERSION(3,3,0)) || (LINUX_VERSION_CODE >= KERNEL_VERSION(3,0,23) && LINUX_VERSION_CODE < KERNEL_VERSION(3,1,0)))
#if (LINUX_VERSION_CODE > KERNEL_VERSION(2,6,37))
/* mask qdisc_cb_private_validate as RHEL6 backports this */
#define qdisc_cb_private_validate(a,b) compat_qdisc_cb_private_validate(a,b)
static inline void qdisc_cb_private_validate(const struct sk_buff *skb, int sz)
{
	BUILD_BUG_ON(sizeof(skb->cb) < sizeof(struct qdisc_skb_cb) + sz);
}
#else
/* mask qdisc_cb_private_validate as RHEL6 backports this */
#define qdisc_cb_private_validate(a,b) compat_qdisc_cb_private_validate(a,b)
static inline void qdisc_cb_private_validate(const struct sk_buff *skb, int sz)
{
	/* XXX ? */
}
#endif
#endif

extern struct sk_buff *__pskb_copy(struct sk_buff *skb,
				   int headroom, gfp_t gfp_mask);

static inline void skb_complete_wifi_ack(struct sk_buff *skb, bool acked)
{
	WARN_ON(1);
}
#define NL80211_FEATURE_SK_TX_STATUS 0

typedef u32 netdev_features_t;

/* source include/linux/device.h */
/**
 * module_driver() - Helper macro for drivers that don't do anything
 * special in module init/exit. This eliminates a lot of boilerplate.
 * Each module may only use this macro once, and calling it replaces
 * module_init() and module_exit().
 *
 * Use this macro to construct bus specific macros for registering
 * drivers, and do not use it on its own.
 */
#define module_driver(__driver, __register, __unregister) \
static int __init __driver##_init(void) \
{ \
	return __register(&(__driver)); \
} \
module_init(__driver##_init); \
static void __exit __driver##_exit(void) \
{ \
	__unregister(&(__driver)); \
} \
module_exit(__driver##_exit);

/* source include/linux/usb.h */
/**
 * module_usb_driver() - Helper macro for registering a USB driver
 * @__usb_driver: usb_driver struct
 *
 * Helper macro for USB drivers which do not do anything special in module
 * init/exit. This eliminates a lot of boilerplate. Each module may only
 * use this macro once, and calling it replaces module_init() and module_exit()
 */
#define module_usb_driver(__usb_driver) \
	module_driver(__usb_driver, usb_register, \
		       usb_deregister)


/*
 * PCI_EXP_TYPE_RC_EC was added via 1b6b8ce2 on v2.6.30-rc4~20 :
 *
 * mcgrof@frijol ~/linux-next (git::master)$ git describe --contains 1b6b8ce2
 * v2.6.30-rc4~20^2
 *
 * but the fix for its definition was merged on v3.3-rc1~101^2~67
 *
 * mcgrof@frijol ~/linux-next (git::master)$ git describe --contains 1830ea91
 * v3.3-rc1~101^2~67
 *
 * while we can assume it got merged and backported on v3.2.28 (which it did
 * see c1c3cd9) we cannot assume every kernel has it fixed so lets just undef
 * it here and redefine it.
 */
#undef PCI_EXP_TYPE_RC_EC
#define  PCI_EXP_TYPE_RC_EC    0xa     /* Root Complex Event Collector */

#endif /* (LINUX_VERSION_CODE < KERNEL_VERSION(3,3,0)) */

#endif /* LINUX_3_3_COMPAT_H */
