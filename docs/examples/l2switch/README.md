# Simple L2 Switch

This example shows the P4 program running on P4Pi by default. It implements the core functionalities of a simple L2 switch: 1) MAC learning (control plane support is needed) and 2) forwarding of Ethernet frames.

To this end, it consists of two tables: smac and dmac. Table smac is responsible to store the source MAC addresses learned by the switch and send digest messages to the control plane for each unseen source MAC. Table dmac is used for forwarding Ethernet frames toward the proper direction (egress port) or applies broadcasting (Note: broadcasting in T4P4S is implemented by setting the egress port to 100). As an extension we also allow packet dropping in both tables so that MAC-based filtering is also possible for demonstration.

The source code of the example is available under [T4P4S examples](https://github.com/P4EDGE/t4p4s/blob/master/examples/l2switch.p4).

## Testing with WiFi access only
The following figure depicts the default setup of a P4Pi node:
<p align="center">
  <img alt="Default settings of P4Pi" width="600px" src="../../images/l2switch_setupA.png">
</p>

P4Pi runs a DHCP daemon (dnsmasq) to assign IP addresses to devices connected through WiFi. The generated T4P4S switch interconnects the wireless interface wlan0 and the linux bridge br1. However, the 1GE Ethernet port eth0 is not used. The default management IP is assigned to br0. Through this IP address the P4Pi node is accessible (e.g., via the web interface or SSH).

### Step 1 - Connecting to P4Pi
Connect your laptop to the wireless access point called p4pi. After that your laptop will get an IP address assigned by the DHCP service (from the default address pool 192.168.4.0/24).

### Step 2 - Setup br1 in gigport network namespace
First, you should open an SSH connection to the device using its management IP (192.168.4.101 by default) (we refer to it as "SSH terminal"). Then set up the IP address of br1, so that we could send traffic with standard tools like ping.

In the SSH terminal:
```bash
sudo ip netns exec gigport ip addr add 192.168.4.150/24 dev br1
sudo ip netns exec gigport ip link set br1 up
```

Optional: By default the L2 switch program is running, but you can reset and restart it with the following command:

In the SSH terminal:
```bash
/home/pi/p4pi/utils/run_default.sh
```

### Step 3 - Test no.1 with the ping tool
Now, you can ping the IP assigned to br1 from your laptop. ICMP Echo requests go through the T4P4S switch and terminate at br1, while Echo replies follow the opposite way back to your laptop.

On your laptop:
```bash
ping 192.168.4.150
```

### Step 4 - Test no.2 with blocking ICMP replies
By default the L2 switch program broadcasts all the incoming packets. In our simple setup, it only relays packets between the two port of T4P4S switch. In this scenario, we simply add a table entry to table smac to drop packets coming from br1 and see what happens with ICMP Echo replies.

We first check the MAC address of br1. To this end, add the following command in the SSH terminal:
```bash
sudo ip netns exec gigport ip addr show dev br1 | grep ether
```
Right after "link/ether" you should find the MAC address of br1.

Then, we launch P4Runtime shell that can be used to fill tables. In the SSH terminal:
```bash
/home/pi/p4pi/utils/run_default_p4rtshell.sh
```

In the P4Runtime shell you can use various commands to read, write and modify objects in the P4 pipeline. For more details, see [the Github site of P4Runtime shell](https://github.com/p4lang/p4runtime-shell). In our case the following commands can be used to create a table entry, set the key and the action and add it to the table:
```python
te = table_entry["ingress.smac"](action="ingress.drop")
te.match["hdr.ethernet.srcAddr"] = "<mac address>"
te.insert
```

As you can see this setup will drop all packets where the Ethernet source MAC is <mac address>. Replacing this with the MAC of br1, the ICMP Echo replies will be dropped. The P4Runtime shell can be left by the 'exit' command. In the SSH terminal, we can easily check what happens:
```bash
sudo ip netns exec gigport sudo tcpdump -i br1 icmp
```

One can see that all the ICMP Echo requests arrive and replies are generated as previously, but they do not return back to the laptop. Running tcpdump on interface br0, we can see that the replies have gone, being removed by the T4P4S switch.
```bash
sudo tcpdump -i br0 icmp
```

## Testing as a hotspot sharing the Internet access of a home router (or a private network domain)
The following figure depicts another setup where P4Pi node acts as a low level relay or proxy between your laptop and your home router (or a private network) connected to the 1GE wired Ethernet port.
<p align="center">
  <img alt="Low level gateway mode of P4Pi" width="900px" src="../../images/l2switch_setupB.png">
</p>

### Step 1 - Connect to P4Pi
Connect to p4pi wireless access point and open an SSH to the management IP (192.168.4.101).

### Step 2 - Launching L2 Switch program
We first launch L2 Switch program. In the SSH terminal:
```bash
/home/pi/p4pi/utils/run_default.sh
```

### Step 3 - Reconfiguring internal network settings
The following script should be executed to turn your P4Pi node into gateway mode:
```bash
/home/pi/p4pi/utils/setup_eth_wlan_bridge.sh
```

This script will create the settings shown in the previous figure: setup bridge br2 and connect port 1 of T4P4S switch to the 1GE wired interface and configure new management IPs. The possible management IPs through which you can access the P4Pi node (incl. SSH, web interface, etc.) are reported by the script like this example output:
```
+-------------------------------------------------------------
| Management IP on the wired interface: 192.168.1.146/24
| Management IP on the wireless interface: 192.168.1.83/24
| Management IP on the wireless interface: 192.168.4.101/24
+-------------------------------------------------------------
```

The last IP address is configured statically and can be used as a backdoor to the P4Pi node.

### Step 4 - Reconnect your laptop
It may happen that you should disconnect your laptop from the p4pi access point and reconnect again (or at least renew your IP from the local DHCP server). After that you will be able to access the networking domains (e.g., Internet) behind your P4Pi node.
For example, if the wired port of your P4Pi is connected to your home router, your can access the Internet. Just open your browser to test it. Note that in this case all the traffic go through th P4 pipeline running inside the T4P4S switch.

### Troubleshooting - no route to P4Pi
If you cannot access P4Pi through the management IP, the following trick can help in solving the issue:
* Connect to the p4pi WiFi access point.
* On your laptop, assign static IP 192.168.4.50/24 to the wireless interface.
* Open a SSH connection to 192.168.4.101.

## Functionalities to be added during the hackathon or later
* VLAN support
* MAC learning control plane (P4Runtime shell cannot handle digests)