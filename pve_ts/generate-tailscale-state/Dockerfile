FROM debian:12-slim

ENV TERM xterm 
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

RUN apt-get update
RUN apt-get install -y curl
ADD https://pkgs.tailscale.com/stable/debian/bookworm.noarmor.gpg /usr/share/keyrings/tailscale-archive-keyring.gpg
ADD https://pkgs.tailscale.com/stable/debian/bookworm.tailscale-keyring.list /etc/apt/sources.list.d/tailscale.list
RUN apt-get update

# extras
RUN apt-get install -y tailscale 

CMD [ "bash", "-c", "\
if [ ! -f /tailscaled.state ]; then \
    echo 'Could not find tailscale state, creating' \ 
    tailscaled --state=/ & \
    tailscale login \
    tailscale up --ssh \
fi" ]

