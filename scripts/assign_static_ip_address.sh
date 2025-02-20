#!/bin/bash
echo "Setting eth1 IP address to ${IP_ADDRESS}"
nmcli conn modify 'Wired connection 2' ipv4.addresses "${IP_ADDRESS}/24"
nmcli conn modify 'Wired connection 2' ipv4.method manual
service NetworkManager restart
