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

RUN sed -r -i 's/^Components:(.*)$/Components:\1 contrib main non-free non-free-firmware/g' /etc/apt/sources.list.d/debian.sources

RUN apt-get update
RUN apt-get install -y curl
RUN curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.noarmor.gpg | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
RUN curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.tailscale-keyring.list | tee /etc/apt/sources.list.d/tailscale.list
RUN apt-get update

RUN apt-get install -y linux-headers-amd64 zfsutils-linux zfs-dkms zfs-zed 

# extras
RUN apt-get install -y tailscale dropbear apt-utils
RUN apt-get install -y locales locales-all
ENV TERM xterm 
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

RUN apt-get install -y dracut

RUN apt-get install -y git
RUN curl -fsSL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /usr/bin/yq-go &&\
    chmod +x /usr/bin/yq-go
COPY build-init.sh /build-init.sh
RUN cpan  'Sort::Versions' 'YAML::PP' 'boolean' 

RUN apt-get -y install linux-image-amd64
RUN apt-get -y install dracut-network
RUN apt-get -y install procps libblkid-dev libblkid1 util-linux

RUN git clone https://github.com/dracut-crypt-ssh/dracut-crypt-ssh.git
WORKDIR dracut-crypt-ssh
RUN ./configure && make && make install
RUN apt-get -y install kexec-tools
RUN apt-get -y install vim
RUN apt-get -y remove systemd
RUN apt-get -y install fzf pax zstd systemd-boot

ENTRYPOINT [ "/build-init.sh" ]

