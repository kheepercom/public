# composefs-base

`us.kheeper.com/public/composefs-base` is [base](../base) rebuilt for bootc's
[composefs backend](https://bootc.dev/blog/2026-may-04-sealed-images-security-chain/),
which is what a [sealed release](https://kheeper.com/docs/guides/sealed-images)
needs. A sealed release boots a UKI signed with your org's Secure Boot key,
whose kernel command line pins the composefs digest of the whole filesystem,
and the kernel checks every file it reads against that digest.

Build on it the way you would build on `base`:

```Containerfile
FROM us.kheeper.com/public/composefs-base:v0.1.0

# install your app, add your firewall openings, drop in unit files, etc.
```

and release with `kheeper releases create --seal`.

## Differences from base

- **systemd-boot**, not bootupd, grub and shim. Sealed hosts boot your
  signed systemd-boot directly rather than through Microsoft's shim.
- **ext4 root.** composefs needs fs-verity, which xfs does not have.
- **No ostree repo.** `base` carries 2G of ostree objects under `/sysroot`
  that a composefs host never reads, and every byte outside `/boot` is part of
  the sealed digest.
- **`rw` on the kernel command line** from `/usr/lib/bootc/kargs.d`. A sealed
  release's command line is fixed when it is sealed, so kernel arguments
  belong in `kargs.d` in your image.

Everything `base` sets up — the firewall, the `admin` user, sshd and
journald — is the same.

## Hosts

A composefs image runs only on a host installed with the composefs backend:
bootc cannot move a host between backends. Install one with
`kheeper hosts ipxe create --composefs`.
