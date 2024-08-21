FROM docker.io/webpronl/reveal-md:latest as builder
COPY demo /slides
RUN /app/bin/reveal-md.js /slides/slides.md --static public --theme white

FROM quay.io/fedora/fedora-bootc:latest
# thanks Ondrej 🙏
# https://github.com/ondrejbudai/fedora-bootc-raspi/tree/main
# firmware stuff needed to boot on raspberry pi
RUN dnf install -y bcm2711-firmware uboot-images-armv8 && \
  cp -P /usr/share/uboot/rpi_arm64/u-boot.bin /boot/efi/rpi-u-boot.bin && \
  mkdir -p /usr/lib/bootc-raspi-firmwares && \
  cp -a /boot/efi/. /usr/lib/bootc-raspi-firmwares/ && \
  dnf remove -y bcm2711-firmware uboot-images-armv8 && \
  mkdir /usr/bin/bootupctl-orig && \
  mv /usr/bin/bootupctl /usr/bin/bootupctl-orig/ && \
  dnf clean all

RUN dnf -y install tailscale pip cargo httpd fuse-overlayfs && dnf clean all

# Install 2048-cli using pip
RUN pip3 install 2048-cli

# We can preload container images, but it will make
# the overall container image much larger
# + cross-platform is tricky with podman inside podman
# VOLUME /usr/lib/containers
# RUN podman pull docker.io/library/httpd:latest

# /usr is read-only at runtime
COPY --from=builder /slides/public /usr/share/www/html

# shim for the bootloader
COPY bootupctl-shim /usr/bin/bootupctl

COPY passwordless-sudo /etc/sudoers.d/wheel-passwordless-sudo
COPY hostname.service /etc/systemd/system/hostname.service
COPY tailscale.service /etc/systemd/system/tailscale.service
COPY httpd.container /etc/containers/systemd/httpd.container
COPY --from=container-auth . /etc/ostree

ARG HOSTNAME
RUN sed -ie "s/#HOSTNAME/${HOSTNAME}/" /etc/systemd/system/hostname.service

RUN systemctl enable tailscaled.service
RUN systemctl enable hostname.service
RUN systemctl enable tailscale.service

EXPOSE 80
