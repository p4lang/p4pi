# Example #2 - ARP and ICMP responder

In this example, we use the P4Edge setup as depicted in the following figure:

![P4Edge Setup](./img/l2switch_setupA.png)

The P4 program can parse Ethernet, ARP, IPv4 and ICMP (Echo-request) headers. The pipeline consists of two tables implementing the ARP responder and ICMP Echo responder functions.

The first function is implemented by table `arp_exact` that applies an exact match on the destination IP address (IPv4) field of an ARP Request message. If there is a match, action `arp_reply` generates an ARP Reply message filled with MAC address given as action parameter, swaps the Ethernet source and destination addresses and sends the packet back to the origin. In case of table miss, the packet is simply dropped.

The second function is implemented by table `icmp_responder` that consists of a compound key: destination MAC address of the Ethernet header with exact match-kind and the destination IP address with LPM match-kind. Note that an ICMP responder could work with a simple exact matching table on the destination IP address. We added the compound key as a demonstrating example. In case of a match, table `icmp_responder` applies action `icmp_reply` that transforms the incoming packet into an ICMP Echo Reply and swaps both IP addresses in the IP header and MAC addresses in the Ethernet header. Since we swap the source and destination IP addresses, IP checksum needs to be recalculated. However, ICMP header also carries a checksum field that needs to be recomputed whenever the header content is changed. Note that the ICMP header contains a varbit field called padding since the payload bytes are also needed to compute the ICMP checksum. If the payload is longer that the length of this field needs to be extended. The default action of table `icmp_responder` simply drops packets.

The source code of the example is available under [the examples folder of P4Edge's GitHub repository](https://github.com/P4EDGE/t4p4s/tree/master/examples/arp_icmp/arp_icmp.p4).

### Step 1 - Connecting to P4Edge

Connect your laptop to the wireless access point called "P4Edge". After that your laptop will get an IP address assigned by the DHCP service (from the default address pool 192.168.4.0/24).

### Step 2 - Launching the P4 program

Start the P4 program (arp_icmp.p4) through the web interface or manually with the following commands in an SSH terminal:

```bash
echo 'arp_icmp' > /root/t4p4s-switch
systemctl restart t4p4s.service
```

### Step 3 - Filling the tables

1. Connect to P4Edge via ssh:

```bash
ssh pi@192.168.4.1
```

2. Start P4Runtime shell with the following helper script:

```bash
t4p4s-p4rtshell arp_icmp
```

3. Start sending test traffic to an unused IP address with the same prefix as the one of DHCP IP pool from your laptop. For example, you can use ping tool on your laptop:

```bash
ping -n 100 192.168.4.153
```

Ping reports that the destination is unreachable in the network, since there are no replies for the ARP requests.

In the P4Runtime shell you can insert a table entry into table `arp_exact`:

```python
te = table_entry["MyIngress.arp_exact"](action="MyIngress.arp_reply")
te.match["hdr.arp.dst_ip"] = "192.168.4.153"
te.action["request_mac"] = "aa:aa:aa:cc:cc:cc"
te.insert
```

Then you can see that the output of ping changes into "Request timeout." meaning that MAC address of the destination IP was successfully resolved, but there are no replies for the ICMP Echo Requests sent by ping.

Adding the following entry to table `icmp_responder` will handle ICMP Echo Requests by sending replies back to the source:

```python
te = table_entry["MyIngress.icmp_responder"](action="MyIngress.icmp_reply")
te.match["hdr.ethernet.dstAddr"] = "aa:aa:aa:cc:cc:cc"
te.match["hdr.ipv4.dstAddr"] = "192.168.4.152/31"
te.insert
```

After adding this entry, ping reaches the destination and starts reporting its availability.

## Functionalities to be added during the hackathon or later

- Adding support for traceroute by replying ICMP Time-exceeded, etc.
