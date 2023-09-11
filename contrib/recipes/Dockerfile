# This Dockerfile creates a container that will create an EFI executable and
# separate kernel/initramfs components from a ZFSBootMenu repository. The
# container will pre-populate its /zbm directory with a clone of the master
# branch of the upstream ZFSBootMenu branch and build the images from that.
#
# To use a different ZFSBootMenu repository or version, bind-mound the
# repository you want on /zbm inside the container.

# Use the official Void Linux container
FROM debian:12-slim
ARG ZBM_COMMIT_HASH

ENV TERM xterm 
ENV DEBIAN_FRONTEND=noninteractive

RUN sed -r -i 's/^Components:(.*)$/Components:\1 contrib main non-free non-free-firmware/g' /etc/apt/sources.list.d/debian.sources


# first update and install essential packages: ca-certificates and apt-utils
RUN apt-get update && apt-get install -y ca-certificates apt-utils gpg
ADD https://pkgs.tailscale.com/stable/debian/bookworm.noarmor.gpg  /usr/share/keyrings/tailscale-archive-keyring.gpg 
RUN chmod o+r /usr/share/keyrings/tailscale-archive-keyring.gpg
ADD https://pkgs.tailscale.com/stable/debian/bookworm.tailscale-keyring.list /etc/apt/sources.list.d/tailscale.list
# gum
RUN mkdir -p /etc/apt/keyrings
ADD https://repo.charm.sh/apt/gpg.key /tmp
RUN cat /tmp/gpg.key | gpg --dearmor -o /etc/apt/keyrings/charm.gpg
RUN echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | tee /etc/apt/sources.list.d/charm.list
RUN apt-get update

# no systemd
RUN apt-mark hold systemd

RUN apt-get install -y \
    # base essentials
    locales locales-all \
    # zfsbootmenu essentials
    linux-headers-amd64 linux-image-amd64 kexec-tools kmod \
    zfs-dkms zfsutils-linux zfs-zed \
    dracut git fzf systemd-boot \
    # tailscale 
    tailscale \
    # secure unlock
    pax zstd \
    # nice-to-have
    vim curl \
    # dependencies for dracut-crypt-ssh
    procps libblkid-dev libblkid1 util-linux

# after installing locales, these can be set
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

# zfsbootmenu essentials
ADD https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 /usr/bin/yq-go 
RUN chmod +x /usr/bin/yq-go


# zfsbootmenu: build perl deps
RUN cpan  'Sort::Versions' 'YAML::PP' 'boolean' 'IPC::Run3'

# For testing: to create full partitions easy to put into qemu
RUN apt-get install -y mtools iputils-ping netcat-traditional mbuffer pv strace gum kbd bsdextrautils gdisk parted dosfstools util-linux efibootmgr cryptsetup-bin xfonts-terminus isc-dhcp-client ncurses-bin

RUN git clone https://github.com/powerline/fonts.git --depth=1 /fonts

COPY build-init.sh /build-init.sh
ENTRYPOINT [ "/build-init.sh" ]

