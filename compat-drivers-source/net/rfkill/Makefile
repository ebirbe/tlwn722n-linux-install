#
# Makefile for the RF switch subsystem.
#

rfkill_backport-y			+= core.o
rfkill_backport-$(CONFIG_RFKILL_BACKPORT_INPUT)	+= input.o
obj-$(CONFIG_RFKILL_BACKPORT)		+= rfkill_backport.o
obj-$(CONFIG_RFKILL_REGULATOR)	+= rfkill-regulator.o
obj-$(CONFIG_RFKILL_GPIO)	+= rfkill-gpio.o
