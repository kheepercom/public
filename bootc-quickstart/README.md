# bootc quickstart

Boot your own [bootc](https://bootc-dev.github.io/) image on Google Cloud, AWS
or bare metal without building any disk images. You bring an image you built with
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

## AWS

The same handoff image as a public AMI. It reads your image from the `bootc`
key of `#cloud-config` user-data. cloud-init in your image ignores that key, so
the rest of the user-data is still yours.

```sh
aws ec2 run-instances --region us-east-2 \
  --image-id $(aws ec2 describe-images --region us-east-2 --owners 223249276674 \
    --filters 'Name=name,Values=bootc-quickstart-*' 'Name=is-public,Values=true' \
    --query 'sort_by(Images,&CreationDate)[-1].ImageId' --output text) \
  --instance-type t3.small \
  --block-device-mappings 'DeviceName=/dev/xvda,Ebs={VolumeSize=20}' \
  --user-data '#cloud-config
bootc:
  image: "quay.io/you/app:latest"'
```

[kheeper.com/bootc-quickstart](https://kheeper.com/bootc-quickstart) shows the
current AMI ID for each region. It is published in us-east-1, us-east-2,
us-west-1, us-west-2, eu-west-1, eu-west-2, eu-west-3, eu-central-1 and
eu-north-1.

| `bootc` key | Required | Value |
| ----------- | -------- | ----- |
| `image`     | yes      | Fully qualified image ref |
| `auth`      | no       | `user:token` for a private registry |

The handoff needs no instance profile. Progress is on the serial console:
`aws ec2 get-console-output --latest --instance-id <id>`. As on Google Cloud,
your image provides its own way to log in.

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

The kernel command line is capped at 2047 bytes, and iPXE truncates to fit, so
a long `bootc.auth` is cut off silently. With the arguments above there is room
for roughly 1,300 bytes of `user:token` before encoding. A Google Artifact
Registry key or an ECR password does not fit; see below.

## Registry credentials

Whatever you pass is what the installed host keeps pulling updates with, so a
token that expires leaves it stuck on the first install.

| Registry | User | Token | Notes |
| -------- | ---- | ----- | ----- |
| Artifact Registry, GCR | `_json_key_base64` | `base64 -w0 key.json` | Too long for iPXE. |
| Artifact Registry, GCR | `oauth2accesstoken` | `gcloud auth print-access-token` | Fits anywhere, expires in an hour. |
| ECR | `AWS` | `aws ecr get-login-password` | Too long for iPXE, expires in 12 hours. |
| GHCR, Docker Hub, Quay, GitLab | your user or robot | personal access or robot token | Fit anywhere and need not expire. |

After an install with a short-lived token, put a longer-lived credential in
`/etc/ostree/auth.json` on the host so `bootc upgrade` keeps working.

## Updates

Every path leaves a normal bootc host tracking your image, so `bootc upgrade`,
or `bootc-fetch-apply-updates.timer` if your image enables it, pulls new pushes
of the same tag.

---

Made by [Kheeper](https://kheeper.com).
