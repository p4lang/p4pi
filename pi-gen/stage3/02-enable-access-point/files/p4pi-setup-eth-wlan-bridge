#!/bin/bash

echo "Bridging eth0 and wlan0 through the T4P4S switch."

myip=`ip addr show eth0 | grep 'inet ' | awk '{print($2);}'`

if [ "$myip" == "" ]
then
	echo "eth0 is connected to a network without DHCP server."
	echo "Reconfiguration stopped."
	exit -1
fi

#echo "YOUR NEW MANAGEMENT IP IS $myip"

echo "Stopping DHCP service"
service dnsmasq stop

echo "Redirecting veth1 end-point"
ip netns exec gigport ip link set veth1-1 netns 1
ip link set dev veth1-1 up
brctl addbr br2
brctl setageing br2 0
ip link set dev br2 up

echo "Connecting eth0 to br2"
ip link set eth0 promisc on
brctl addif br2 eth0
brctl addif br2 veth1-1

echo "Requesting IP for br2 from the external DHCP server"
dhclient br2

myip=`ip addr show br2 | grep 'inet ' | awk '{print($2);}'`

echo "Requesting IP for br0 from the external DHCP server"
dhclient br0
ip addr add 192.168.4.101/24 dev br0

echo "+-------------------------------------------------------------"
echo "| Management IP on the wired interface: $myip"
ip addr show br0 | grep 'inet ' | awk '{printf("| Management IP on the wireless interface: %s\n",$2);}'
echo "+-------------------------------------------------------------"
ifconfig eth0 0.0.0.0 up




