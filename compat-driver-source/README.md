# Linux compat drivers compatibility package

This package provides backport support for drivers from newer kernels
down to older kernels. It currently backports 3 subsystems:

  * Ethernet
  * Wireless
  * Bluetooth
  * GPU

This package provides the latest Linux kernel subsystem enhancements
for kernels 2.6.24 and above. It is technically possible to support
kernels < 2.6.24 but more work is required for that.

# Documentation

This package is documented online and has more-up-to date information
online than on this README file. You should read the wiki page
and not rely on this README!

https://backports.wiki.kernel.org

# License

This work is a subset of the Linux kernel as such we keep the kernel's
Copyright practice. Some files have their own copyright and in those
cases the license is mentioned in the file. All additional work made
to building this package is licensed under the GPLv2.
