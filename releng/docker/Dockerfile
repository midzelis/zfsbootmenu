# syntax=docker/dockerfile:1

# This Dockerfile creates a container that will create an EFI executable and
# separate kernel/initramfs components from a ZFSBootMenu repository. The
# container will pre-populate its /zbm directory with a clone of the master
# branch of the upstream ZFSBootMenu branch and build the images from that.
#
# To use a different ZFSBootMenu repository or version, bind-mound the
# repository you want on /zbm inside the container.

# Use the official Void Linux container
FROM ghcr.io/void-linux/void-glibc-full 
LABEL org.opencontainers.image.authors="ZFSBootMenu Team, https://zfsbootmenu.org"

ARG ZBM_COMMIT_HASH
ARG PACKAGES=
ARG XBPS_REPOS="https://repo-fastly.voidlinux.org/current"
ARG KERNELS="linux5.10 linux5.15 linux6.1" 

RUN mkdir -p /etc/xbps.d
RUN <<EOF
for repo in "${XBPS_REPOS}"; do
  echo "repository=$repo" >> /etc/xbps.d/00-custom-repos.conf
done
EOF

# Ensure everything is up-to-date
RUN xbps-install -Suy xbps && xbps-install -uy bash
SHELL ["/bin/bash", "-c"]

# Prefer an LTS version over whatever Void thinks is current
RUN <<-EOF
echo "ignorepkg=linux" >> /etc/xbps.d/10-nolinux.conf
echo "ignorepkg=linux-headers" >> /etc/xbps.d/10-nolinux.conf
EOF

# Prevent initramfs kernel hooks from being installed
RUN <<-EOF
echo "noextract=/usr/libexec/mkinitcpio/*" >> /etc/xbps.d/15-noinitramfs.conf
echo "noextract=/usr/libexec/dracut/*" >> /etc/xbps.d/15-noinitramfs.conf
EOF

# Install ZFSBootMenu dependencies and components necessary to build images
RUN xbps-query -Rp run_depends zfsbootmenu | xargs xbps-install -y
RUN <<-EOF
if [ -n "${KERNELS}" ]; then
	for _kern in "${KERNELS}"; do
		kern_headers+=( "${_kern}-headers" )
	done
	echo installing ${KERNELS} ${kern_headers}
	xbps-install -y ${KERNELS} ${kern_headers}
fi
EOF

RUN xbps-install -y zstd make rsync gummiboot-efistub curl yq-go bash kbd terminus-font \
  dracut mkinitcpio dracut-network gptfdisk iproute2 iputils parted curl \
  dosfstools e2fsprogs efibootmgr cryptsetup openssh util-linux kpartx

# Remove headers and development toolchain, but keep binutils for objcopy
RUN echo "ignorepkg=dkms" > /etc/xbps.d/10-nodkms.conf
RUN xbps-pkgdb -m manual binutils make

RUN <<-EOF
if [ -n "${KERNELS}" ]; then
	for _kern in "${KERNELS}"; do
		kern_headers+=( "${_kern}-headers" )
	done
	xbps-remove -Roy ${kern_headers}
fi
EOF

RUN xbps-remove -Roy dkms
RUN rm -f /var/cache/xbps/*

# Install custom packages
RUN <<-EOF
if [ -n "${PACKAGES}" ]; then
	xbps-install -y $PACKAGES
fi
EOF

# Record a commit hash if one was provided
RUN <<-EOF
if [ -n "${ZBM_COMMIT_HASH}" ]; then
	echo "${ZBM_COMMIT_HASH}" > /etc/zbm-commit-hash
fi
EOF

# Copy the build script
COPY build-init.sh /build-init.sh

# Run the build script with no arguments by default
ENTRYPOINT [ "/build-init.sh" ]
CMD [ ]
