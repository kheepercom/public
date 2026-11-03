# Changelog

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
