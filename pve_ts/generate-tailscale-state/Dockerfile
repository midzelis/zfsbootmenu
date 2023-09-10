FROM debian:12-slim

ENV TERM xterm 

RUN apt-get update && apt-get install -y ca-certificates
ADD https://pkgs.tailscale.com/stable/debian/bookworm.noarmor.gpg /usr/share/keyrings/tailscale-archive-keyring.gpg
RUN chmod o+r /usr/share/keyrings/tailscale-archive-keyring.gpg
ADD https://pkgs.tailscale.com/stable/debian/bookworm.tailscale-keyring.list /etc/apt/sources.list.d/tailscale.list
RUN apt-get update

# extras
RUN apt-get install -y bash tailscale 

COPY login.sh /
CMD  "/login.sh" 

