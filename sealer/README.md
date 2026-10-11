# sealer

`us.kheeper.com/public/sealer` is the tool `kheeper releases create --seal`
runs under podman on your machine, where your org's Secure Boot db key is. You
do not run it yourself.

It is [composefs-base](../composefs-base) plus `ukify`, so the bootc that
computes a release's composefs digest is the bootc your hosts run.

- `kheeper-seal sign-boot` signs systemd-boot with the key at
  `/run/secrets/secureboot_key` and the certificate at
  `/run/secrets/secureboot_cert`, writing `/out/systemd-bootx64.efi.signed`.
- `kheeper-seal uki <image>` computes the composefs digest of `<image>` from
  the caller's container storage, mounted read-only at
  `/run/host-container-storage`, and builds a UKI from the image mounted at
  `/target` whose command line is the image's `kargs.d` plus that digest. It
  writes `/out/<kernel version>.efi`, signed if a key is mounted, and
  `/out/digest`.

The digest is computed from the image's layers, the way the host computes it
when it pulls the release, rather than from the mounted tree: the two can
disagree about directory metadata.
