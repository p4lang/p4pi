# Example #1 - Simple L2 Switch

This example describes the default P4 program running on P4Edge with T4P4S. It implements two core functionalities of a simple L2 switch: 1) MAC learning (control plane support is needed) and 2) forwarding of Ethernet frames.

To this end, it consists of two tables: `smac` and `dmac`. Table `smac` stores the source MAC addresses learned by the switch and sends digest messages to the control plane for each unseen source MAC. Table `dmac` is used for forwarding Ethernet frames toward the proper direction (egress port) or applies broadcasting (Note: broadcasting in T4P4S is implemented by setting the egress port to 100). As an extension, packet dropping is also allowed in both tables, so that MAC-based filtering would also be possible.

P4 source code: [l2switch.p4](https://github.com/P4EDGE/t4p4s/tree/master/examples/t4p4s/l2switch/l2switch.p4).

## Testing with WiFi access only

The following figure depicts the setup used in this example:

![Default settings of P4Edge](./img/l2switch_setupA.png)

P4Edge runs a DHCP daemon (dnsmasq) to assign IP addresses to devices connected through WiFi. The generated T4P4S switch interconnects the wireless interface wlan0 and the linux bridge br1. However, the 1GE Ethernet port eth0 is not used in this example. The default management IP address is assigned to br0. Through this IP address the P4Edge node is accessible (e.g., via the web interface or SSH).

### Step 1 - Connecting to P4Edge Access Point

Connect your laptop to the wireless access point called "P4Edge". After that your laptop will get an IP address assigned by the DHCP service (from the default address pool 192.168.4.0/24).

### Step 2 - Test with the ping tool

After connecting to the access point, you should be able to ping the IP assigned to br1 (br1 is inside netns gigport) from your laptop.

```bash
ping 192.168.4.150
```

ICMP Echo requests go through the T4P4S switch and terminate at br1, while Echo replies follow the opposite way back to your laptop.

### Step 3 - Test with blocking ICMP replies

The L2 switch program broadcasts all the incoming packets.

In our simple setup, it only relays packets between the two ports of T4P4S switch.
In this scenario, we simply add a table entry to table `smac` to drop packets coming from br1 and see what happens with ICMP Echo replies.

We first check the MAC address of br1. To this end, add the following command in the SSH terminal:

```bash
sudo ip netns exec gigport ip addr show dev br1 | grep ether
```

Right after "link/ether" you should find the MAC address of br1.

Then, we launch P4Runtime shell that can be used to fill tables. In the SSH terminal:

```bash
t4p4s-p4rtshell l2switch
```

In the P4Runtime shell you can use various commands to read, write and modify objects in the P4 pipeline. For more details, see [the Github site of P4Runtime shell](https://github.com/p4lang/p4runtime-shell). In our case the following commands can be used to create a table entry, set the key and the action and add it to the table:

```python
te = table_entry["ingress.smac"](action="ingress.drop")
te.match["hdr.ethernet.srcAddr"] = "<mac address>"
te.insert
```

As you can see this setup will drop all packets where the Ethernet source MAC is <mac address>. Replacing this with the MAC of br1, the ICMP Echo replies will be dropped. The P4Runtime shell can be left by the 'exit' command. In the SSH terminal, we can easily check what happens:

```bash
sudo ip netns exec gigport tcpdump -i br1 icmp
```

One can see that all the ICMP Echo requests arrive and replies are generated as previously, but they do not return back to the laptop. Running tcpdump on interface br0, we can see that the replies have gone, being removed by the T4P4S switch.

```bash
sudo tcpdump -i br0 icmp
```

## Testing as a hotspot sharing the Internet access of a home router (or a private network domain)

The following figure depicts another setup where P4Edge node acts as a low level relay or proxy between your laptop and your home router (or a private network) connected to the 1GE wired Ethernet port.

![Low level gateway mode of P4Edge](./img/l2switch_setupB.png)

### Step 1 - Connect to P4Edge

Connect to P4Edge wireless access point and open an SSH to the management IP (192.168.4.1).

### Step 2 - Reconfiguring internal network settings

The following script should be executed to turn your P4Edge node into gateway mode:

```bash
sudo /root/setup_eth_wlan_bridge.sh
```

This script will create the settings shown in the previous figure: setup bridge br2 and connect port 1 of T4P4S switch to the 1GE wired interface and configure new management IPs. The possible management IPs through which you can access the P4Edge node (incl. SSH, web interface, etc.) are reported by the script like this example output:

```
+-------------------------------------------------------------
| Management IP on the wired interface: 192.168.1.146/24
| Management IP on the wireless interface: 192.168.1.83/24
| Management IP on the wireless interface: 192.168.4.101/24
+-------------------------------------------------------------
```

The last IP address is configured statically and can be used as a backdoor to the P4Edge node.

### Step 3 - Reconnect your laptop

It may happen that you should disconnect your laptop from the P4Edge access point and reconnect again (or at least renew your IP from the local DHCP server). After that you will be able to access the networking domains (e.g., Internet) behind your P4Edge node.
For example, if the wired port of your P4Edge is connected to your home router, you should be able to access the Internet. Just open your browser to test it. Note that in this case all the traffic go through th P4 pipeline running inside the T4P4S switch.

### Troubleshooting - no route to P4Edge

If you cannot access P4Edge through the management IP, the following trick can help in solving the issue:

- Connect to the P4Edge WiFi access point.
- On your laptop, assign static IP 192.168.4.50/24 to the wireless interface.
- Open a SSH connection to 192.168.4.1.

## Functionalities to be added during the hackathon or later

- VLAN support
- MAC learning control plane (P4Runtime shell cannot handle digests)
