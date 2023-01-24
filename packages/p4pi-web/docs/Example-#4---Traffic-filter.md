# Example #4 - Traffic filter

This example shows how P4Edge can be used as a simple stateless firewall or a traffic filter.

The source code of the example is available under [P4Edge examples](/https://github.com/P4EDGE/t4p4s/tree/master/example/sfirewall.p4).

## How it works

This example works as a stateless traffic filter with support for IPv4 TCP and UDP packets. Rules can be applied for many header fields, and these rules can block packets passing through the P4Edge. When the switch receives a packet it checks if any blocking rule is valid for the packet. If so, it gets dropped. Currently, the following fields are supported:

- srcMAC
- dstMAC
- ethProtocol
- srcIP
- dstIP
- ipProtocol
- tcpSrcPort
- tcpDstPort
- udpSrcPort
- udpDstPort

We use blocklisting, which involves defining which entities should be blocked. So by default, we allow everything to pass through the switch. (See Functionalities to be added during the hackathon or later chapter for improvement ideas)

## Testing with WiFi access only

The following figure depicts the default setup of a P4Edge node:

![Default settings of P4Edge](./img/l2switch_setupA.png)

For more detailed information check the [Simple L2 Switch example](Example-%231---Simple-L2-switch-(default-program))

### Step 1 - Connecting to P4Edge Access Point

Connect your laptop to the wireless access point called "P4Edge". After that your laptop will get an IP address assigned by the DHCP service (from the default address pool 192.168.4.0/24).

### Step 2 - Run the example

```bash
echo 'firewall' > /root/t4p4s-switch
sudo systemctl restart t4p4s.service
```

### Step 3 - Testing without configuring

If no rules are added, everything will pass through the switch.
You can check it by running the following commands.

#### Iperf

Start an iperf server inside the gigport network namespace:

```bash
sudo ip netns exec gigport iperf -s 192.168.4.150
```

And try to connect to it from your laptop.

```bash
iperf -c 192.168.4.150 -t 30 -i 1
```

You can also test UDP traffic with iperf, or use netcat for both cases.

### Step 4 - Filling the blocklist

The next step is to launch P4Runtime shell, that is used to insert blocklist rules. In the SSH terminal run:

```bash
t4p4s-p4rtshell firewall
```

Insert a rule to block all TCP traffic

```python
te = table_entry["MyIngress.ip_proto_filter"](action="MyIngress.drop")
te.match["hdr.ipv4.protocol"] = "6"
te.insert
```

### Step 5 - Testing the configuration

P4Edge

```bash
sudo ip netns exec gigport iperf -s 192.168.4.150
```

And connect to it from your laptop.

```bash
iperf -c 192.168.4.150 -t 30 -i 1
```

Because TCP flows are blocked, it will not connect.

Let's check that UDP still works.

```bash
sudo ip netns exec gigport iperf -s 192.168.4.150 -u -p 5003
```

And connect to it from your laptop.

```bash
iperf -c 192.168.4.150 -t 30 -i 1 -u -p 5003
```

### Step 6 - Add new filters and test them

Any of the previously discussed header fields can be used in the rules. Try to block the UDP 12345 port. (hint: use the udp_dstPort_filter table). Help for the table entry creation:

```python
te = table_entry["MyIngress.table_name"](action="MyIngress.function_name")
te.match["name_of_the_field_to_match"] = "value_as_string"
te.match["if_there_are_more_keys_to_match"] = "value_as_string"
te.action["action_function_parameter_name"] = "value_as_string"
te.insert
```

## Testing as a hotspot sharing the Internet access of a home router (or a private network domain)

The following figure depicts another setup where P4Edge node acts as a low level relay or proxy between your laptop and your home router (or a private network) connected to the 1GE wired Ethernet port.

![Low level gateway mode of P4Edge](./img/l2switch_setupB.png>

### Step 1 - Connect to P4Edge

Connect to the P4Edge wireless access point and open an SSH to the management IP (192.168.4.101).

### Step 2 - Launching traffic filter program

We first launch the traffic filter program. In the SSH terminal:

```bash
echo 'firewall' > /root/t4p4s-switch
sudo systemctl restart t4p4s.service
```

### Step 5 - Testing without configuring

Internet access should work properly on your laptop.

### Step 6 - Insert a HTTP blocking rule

The next step is to launch P4Runtime shell, that is used to create rules. In the SSH terminal run:

```bash
t4p4s-p4rtshell firewall
```

Try to block HTTP traffic

```python
te = table_entry["MyIngress.tcp_dstPort_filter"](action="MyIngress.drop")
te.match["hdr.tcp.dstPort"] = "80"
te.insert
```

### Step 7 - Testing the configuration

Internet access should work properly on your laptop, however, no HTTP website will load. (HTTPS still works fine).

## Functionalities to be added during the hackathon or later

- Try to modify the P4 code to change the blocklist behavior to allowlist. Instead of allowing everything by default, block all traffic and allow only flows that match the inserted rules.
- Add support for IPv6
