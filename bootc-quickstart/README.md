# bootc quickstart

Boot your own [bootc](https://bootc-dev.github.io/) image on Google Cloud or
bare metal without building any disk images. You bring an image you built with
`podman build` or `docker build` and pushed to any registry; this installs it.

Free, and nothing phones home: there is no account, no agent and no
registration. Only your registry credentials, which stay on your host so it can
pull updates.

## Google Cloud

A public image that, on first boot, reads your image from instance metadata,
switches to it with `bootc switch` and reboots into it.

```sh
gcloud compute instances create my-vm \
  --image-project kheeper --image-family bootc-quickstart \
  --boot-disk-size 20GB \
  --metadata bootc-image=quay.io/you/app:latest
```

| Metadata key    | Required | Value |
| --------------- | -------- | ----- |
| `bootc-image`   | yes      | Fully qualified image ref, e.g. `ghcr.io/you/app:latest` |
| `bootc-auth`    | no       | `user:token` for a private registry. Written to `/etc/ostree/auth.json` for the image's registry. |

Use `--metadata-from-file bootc-auth=auth.txt` if your token contains a comma.
Progress is on the serial console:
`gcloud compute instances get-serial-port-output my-vm`.

Your image must work on GCE on its own. The handoff image has no guest agent,
so give your image a way to log in, such as a baked user or SSH key, or
`cloud-init`.

## Bare metal (iPXE)

Any provider or PXE server that boots an iPXE script, such as
[latitude.sh](https://www.latitude.sh). The script boots the Fedora installer
with [ks.cfg](ks.cfg), which installs your image straight to the first disk.
Everything it needs is on the kernel command line, so nothing about your install
is hosted anywhere.

```
#!ipxe
set mirror http://mirror.rackspace.com/fedora/releases/45/Everything/x86_64/os
kernel ${mirror}/images/pxeboot/vmlinuz initrd=initrd.img inst.repo=${mirror} inst.ks=https://storage.googleapis.com/kheeper-images-public/bootc-quickstart.ks ip=dhcp bootc.image=quay.io/you/app:latest
initrd ${mirror}/images/pxeboot/initrd.img
boot
```

| Kernel argument | Required | Value |
| --------------- | -------- | ----- |
| `bootc.image`   | yes      | Fully qualified image ref |
| `bootc.auth`    | no       | `printf user:token \| base64 -w0` |

The install wipes the first non-removable disk. As on Google Cloud, your image
provides its own way to log in.

## Updates

Both paths leave a normal bootc host tracking your image, so `bootc upgrade`,
or `bootc-fetch-apply-updates.timer` if your image enables it, pulls new pushes
of the same tag.

---

Made by [Kheeper](https://kheeper.com).
