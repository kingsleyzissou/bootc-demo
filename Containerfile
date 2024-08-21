FROM docker.io/webpronl/reveal-md:latest as builder
COPY demo /slides
RUN /app/bin/reveal-md.js /slides/slides.md --static public --theme white

FROM quay.io/fedora/fedora-bootc:latest

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
