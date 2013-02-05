ccflags-y += -I$(src)
obj-m += compat.o
#compat-objs :=

obj-$(CONFIG_COMPAT_FIRMWARE_CLASS) += compat_firmware_class.o
obj-$(CONFIG_COMPAT_NET_SCH_CODEL) += sch_codel.o

sch_fq_codel-y = sch_fq_codel_core.o flow_dissector.o

obj-$(CONFIG_COMPAT_NET_SCH_FQ_CODEL) += sch_fq_codel.o

compat-y += main.o

# Compat kernel compatibility code
compat-$(CONFIG_COMPAT_KERNEL_2_6_14) += compat-2.6.14.o
compat-$(CONFIG_COMPAT_KERNEL_2_6_18) += compat-2.6.18.o
compat-$(CONFIG_COMPAT_KERNEL_2_6_19) += compat-2.6.19.o
compat-$(CONFIG_COMPAT_KERNEL_2_6_21) += compat-2.6.21.o
compat-$(CONFIG_COMPAT_KERNEL_2_6_22) += compat-2.6.22.o
compat-$(CONFIG_COMPAT_KERNEL_2_6_23) += compat-2.6.23.o
compat-$(CONFIG_COMPAT_KERNEL_2_6_24) += compat-2.6.24.o
compat-$(CONFIG_COMPAT_KERNEL_2_6_25) += \
	compat-2.6.25.o \
	pm_qos_params.o

compat-$(CONFIG_COMPAT_KERNEL_2_6_26) += compat-2.6.26.o
compat-$(CONFIG_COMPAT_KERNEL_2_6_27) += compat-2.6.27.o
compat-$(CONFIG_COMPAT_KERNEL_2_6_28) += compat-2.6.28.o
compat-$(CONFIG_COMPAT_KERNEL_2_6_29) += compat-2.6.29.o
compat-$(CONFIG_COMPAT_KERNEL_2_6_32) += compat-2.6.32.o
compat-$(CONFIG_COMPAT_KERNEL_2_6_33) += compat-2.6.33.o
compat-$(CONFIG_COMPAT_KERNEL_2_6_34) += compat-2.6.34.o
compat-$(CONFIG_COMPAT_KERNEL_2_6_35) += compat-2.6.35.o
compat-$(CONFIG_COMPAT_KERNEL_2_6_36) += compat-2.6.36.o

compat-$(CONFIG_COMPAT_KFIFO) += kfifo.o

compat-$(CONFIG_COMPAT_KERNEL_2_6_37) += compat-2.6.37.o
compat-$(CONFIG_COMPAT_KERNEL_2_6_38) += compat-2.6.38.o
compat-$(CONFIG_COMPAT_KERNEL_2_6_39) += \
	compat-2.6.39.o \
	kstrtox.o
compat-$(CONFIG_COMPAT_KERNEL_3_0) += compat-3.0.o
compat-$(CONFIG_COMPAT_KERNEL_3_1) += compat-3.1.o
compat-$(CONFIG_COMPAT_KERNEL_3_2) += compat-3.2.o
compat-$(CONFIG_COMPAT_KERNEL_3_3) += \
	compat-3.3.o
compat-$(CONFIG_COMPAT_KERNEL_3_4) += compat-3.4.o
compat-$(CONFIG_COMPAT_KERNEL_3_5) += \
	compat-3.5.o \
	user_namespace.o
compat-$(CONFIG_COMPAT_KERNEL_3_7) += compat-3.7.o
compat-$(CONFIG_COMPAT_KERNEL_3_8) += compat-3.8.o

compat-$(CONFIG_COMPAT_CORDIC) += cordic.o
compat-$(CONFIG_COMPAT_CRC8) += crc8.o

ifndef CONFIG_64BIT
ifndef CONFIG_GENERIC_ATOMIC64
  compat-y += compat_atomic.o
endif
endif
