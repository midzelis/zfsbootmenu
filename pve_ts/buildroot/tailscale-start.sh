#!/bin/bash


mkdir -p /var/lib/dhcp
mkdir -p /etc/dhcp
touch /etc/fstab
touch /etc/resolv.conf

cat << EOF > /etc/dhcp/dhclient.conf
timeout 30;

option classless-static-routes code 121 = array of unsigned integer 8;

send dhcp-client-identifier = hardware;

request subnet-mask, broadcast-address, time-offset, routers,
        domain-name, domain-name-servers, domain-search, host-name,
        root-path, interface-mtu, classless-static-routes,
        netbios-name-servers, netbios-scope, ntp-servers,
        dhcp6.domain-search, dhcp6.fqdn,
        dhcp6.name-servers, dhcp6.sntp-servers;
EOF

# Get a list of all network interfaces
interfaces=$(ip link show | awk -F': ' '{print $2}')

# Bring up each interface and get a DHCP IP address
for interface in $interfaces; do
    [[ $interface == 'lo' ]] && continue
    gum style --bold "Bringing up $interface"
    ip link set "$interface" up
    gum spin -s points --show-output --timeout=30s --title="Getting IP address using DHCP" -- dhclient -1 "$interface" -lf /var/lib/dhcp/dhclient.leases -v 
done

mkdir -p /var/run
mkdir -p /etc/dropbear
gum style --bold "Starting SSH server"
dropbear -R -s -j -k -p 
# ln -sf /usr/sbin/iptables-legacy /etc/alternatives/iptables 
# ln -sf /usr/sbin/iptables-legacy-save /etc/alternatives/iptables-save
# ln -sf /usr/sbin/iptables-legacy-restore /etc/alternatives/iptables-restore
# ln -sf /usr/sbin/ip6tables-legacy /etc/alternatives/ip6tables 
# ln -sf /usr/sbin/ip6tables-legacy-save /etc/alternatives/ip6tables-save
# ln -sf /usr/sbin/ip6tables-legacy-restore /etc/alternatives/ip6tables-restore

gum style --bold "Starting tailscale"
mkdir -p /var/log/tailscale
tailscaled --statedir=/var/lib/tailscale > /var/log/tailscale/tailscale.log 2>&1 &
tailscale up & 
