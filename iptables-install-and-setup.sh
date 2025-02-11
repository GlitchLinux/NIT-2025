#!/bin/bash

# Uninstall UFW
echo "Uninstalling UFW..."
apt-get remove --purge ufw -y

# Install iptables
echo "Installing iptables..."
apt-get update
apt-get install iptables -y

# Enable iptables
echo "Enabling iptables..."
systemctl enable iptables
systemctl start iptables

# Flush existing rules and set default policies
echo "Flushing existing iptables rules..."
iptables -F
iptables -X
iptables -Z

# Set default policies
echo "Setting default policies..."
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Add INPUT chain rules
echo "Adding INPUT chain rules..."
iptables -A INPUT -p tcp -s 193.10.128.0/17 --dport ssh -j ACCEPT
iptables -A INPUT -p tcp -s 212.25.132.0/23 --dport ssh -j ACCEPT
iptables -A INPUT -p tcp -s 85.226.230.0/24 --dport ssh -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-reply -j ACCEPT
iptables -A INPUT -p icmp --icmp-type destination-unreachable -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p tcp -s 95.202.59.88 --dport ssh -j ACCEPT
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A INPUT -p udp -s 193.10.236.126 --dport domain -j ACCEPT
iptables -A INPUT -p tcp -s 193.10.236.126 --dport domain -j ACCEPT
iptables -A INPUT -p udp --dport domain -j ACCEPT
iptables -A INPUT -p tcp --dport domain -j ACCEPT

# Add OUTPUT chain rules
echo "Adding OUTPUT chain rules..."
iptables -A OUTPUT -o lo -j ACCEPT

# Save iptables rules
echo "Saving iptables rules..."
iptables-save > /etc/iptables/rules.v4

echo "IPTables configuration complete!"
