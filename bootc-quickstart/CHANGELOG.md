# Changelog

## v0.4.0

### Changes

- Fix switching to images whose SELinux policy has labels Fedora 45's lacks,
  such as AlmaLinux 10: run `bootc switch` from systemd so it gets `install_t`.

## v0.3.0

### Changes

- Fix `bootloader-update.service` failing on Google Cloud hosts after the
  switch: give the handoff image a version, which bootupd requires in the
  install record.
- Update the Fedora 45 base.

## v0.2.0

### Changes

- Remove the SSH key option. Your image provides its own login.
- Build the GCE handoff image from the minimal rootfs, with systemd-networkd, so
  less of it carries over into your image.
- Fix switching to EL10 images such as CentOS Stream and AlmaLinux: put
  /usr/sbin on ostree-finalize-staged's PATH so it finds semodule.

## v0.1.0

### Changes

- Initial release on Fedora 45: GCE handoff image and iPXE kickstart
