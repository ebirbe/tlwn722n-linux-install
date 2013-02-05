# compat-driver unified driver backport patches

compat-drivers supports developers to supply a unified
driver git tree which is being used to target support
for getting the driver in line with requirements for
linux-next. Once the driver gets upstream the driver
gets removed and we cherry pick updated version of the
driver directly from linux upstream.

The code provided on this tree must try to adhere to
conventions for targetting inclusion into linux-next.
The compat-drivers patches/unified-drivers/ directory
allows for any additional required backport delta to
be addressed for the supplied driver. This allows
development and transformation of the driver to always
be targetting linux-next and allows for backporting
to be dealt with separately.
