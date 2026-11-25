# Changelog

## v0.4.1

### Changes

- Rebuild on `base` v0.5.1 (new `fedora-bootc:45` digest)

## v0.4.0

### Changes

- Rebuild on `base` v0.5.0
- Share the dnf cache across builds with a cache mount instead of `dnf clean all`

## v0.3.2

### Changes

- Rebuild on `base` v0.4.2 (new `fedora-bootc:45` digest)

## v0.3.1

### Changes

- Rebuild on `base` v0.4.1 (new `fedora-bootc:45` digest)

## v0.3.0

### Changes

- Rebuild on `base` v0.4.0 (new `fedora-bootc:45` digest)

## v0.2.1

### Changes

- Rebuild on `base` v0.3.1

## v0.2.0

### Changes

- Rebuild on `base` v0.3.0 (Fedora 45)

## v0.1.2

### Changes

- Rebuild on `base` v0.2.7

## v0.1.1

### Changes

- Rebuild on `base` v0.2.6

## v0.1.0

### Features

- `base` v0.2.5 for bootc's composefs backend: systemd-boot instead of
  bootupd, grub and shim, ext4 root by default, and no ostree repo
- Labelled `kheeper.composefs=1`, which `kheeper releases create --seal`
  requires
