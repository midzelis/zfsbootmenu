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
    if gum spin -s points --show-output --timeout=30s --title="Bringing up $interface" -- \
        ip link set "$interface" up; then
        gum style --bold "[ SUCCESS ] Bringing up $interface"
    else 
        gum style --bold "[ FAILED ] Bringing up $interface"
    fi
    if gum spin -s points --show-output --timeout=30s --title="Getting IP address using DHCP" -- \
        dhclient -1 "$interface" -lf /var/lib/dhcp/dhclient.leases -v; then
        gum style --bold "[ SUCCESS ] Getting IP address using DHCP"
    else 
        gum style --bold "[ FAILED ] Getting IP address using DHCP"  
    fi
done

mkdir -p /var/log/tailscale
tailscaled --statedir=/var/lib/tailscale > /var/log/tailscale/tailscale.log 2>&1 &

if gum spin -s points --timeout=30s --title="Starting Tailscale" -- \
    tailscale up; then
    gum style --bold "[ SUCCESS ] Starting SSH" 
else 
    gum style --bold "[ FAILED ] Starting SSH" 
fi

gum spin -s points --title="Remote access setup finished" -- sleep 1