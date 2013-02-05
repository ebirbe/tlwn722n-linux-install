--- a/drivers/net/wireless/ath/ath5k/led.c
+++ b/drivers/net/wireless/ath/ath5k/led.c
@@ -55,7 +55,7 @@
 #define ATH_POLARITY(data) ((data) & 0xff)
 
 /* Devices we match on for LED config info (typically laptops) */
-static DEFINE_PCI_DEVICE_TABLE(ath5k_led_devices) = {
+static const struct pci_device_id ath5k_led_devices[] = {
 	/* AR5211 */
 	{ PCI_VDEVICE(ATHEROS, PCI_DEVICE_ID_ATHEROS_AR5211), ATH_LED(0, 0) },
 	/* HP Compaq nc6xx, nc4000, nx6000 */
