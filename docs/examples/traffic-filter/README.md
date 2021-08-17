# Traffic filter
This example shows how P4Pi can be used as a simple stateless firewall or a traffic filter.

The source code of the example is available under [T4P4S examples](https://github.com/P4EDGE/t4p4s/blob/master/examples/firewall.p4).
## How it works
This example works as a stateless traffic filter with support for IPv4 TCP and UDP packets. Rules can be applied for many header fields, and these rules can block packets passing through the P4Pi. When the switch receives a packet it checks if any blocking rule is valid for the packet. If so, it gets dropped. Currently, the following fields are supported:
* srcMAC
* dstMAC
* ethProtocol
* srcIP
* dstIP
* ipProtocol
* tcpSrcPort
* tcpDstPort
* udpSrcPort
* udpDstPort

We use blocklisting, which involves defining which entities should be blocked. So by default, we allow everything to pass through the switch. (See Functionalities to be added during the hackathon or later chapter for improvement ideas)

## Testing with WiFi access only
The following figure depicts the default setup of a P4Pi node:
<p align="center">
  <img alt="Default settings of P4Pi" width="600px" src="../../images/l2switch_setupA.png">
</p>

For more detailed information check the [Simple L2 Switch example](../l2switch/README.md#testing-with-wifi-access-only)

### Step 1 - [Connect to the P4Pi](../l2switch/README.md#step-1---connecting-to-p4pi)
### Step 2 - [Setup br1 in gigport network namespace](../l2switch/README.md#step-2---setup-br1-in-gigport-network-namespace)
### Step 3 - Run the example
```bash
echo "Stopping T4P4S switch..."
screen -X -S switch quit >> /dev/null
echo "Launching T4P4S switch with the default program"
pushd /home/pi/p4pi/t4p4s/t4p4s >> /dev/null
screen -dmS switch bash -c "source ~/.bashrc;PYTHON3=python3.9 ./t4p4s.sh :firewall p4rt;/bin/bash"
popd
```
### Step 4 - Testing without configuring
If no rules are added, everything will pass through the switch.
You can check it by running the following commands.
#### Iperf
Start an iperf server in the gigaport namespace.
```
sudo ip netns exec gigport iperf -s 192.168.4.150
```
And try to connect to it from your laptop.
```
iperf -c 192.168.4.150 -t 30 -i 1
```
You can also test UDP traffic with iperf, or use netcat for both cases.

### Step 4 - Filling the blocklist
The next step is to launch P4Runtime shell, that is used to insert blocklist rules. In the SSH terminal run:
```bash
echo "Generating the required files for P4 runtime"
p4c-bm2-ss --p4v 16 --p4runtime-file firewall.p4runtime --p4runtime-format text --toJSON firewall.json  ~/p4pi/t4p4s/examples/firewall.p4
echo "Starting the P4 runtime..."
python3.9 -m p4runtime_sh --grpc-addr localhost:50051 --device-id 1 --election-id 0,1 --config firewall.p4runtime,firewall.json
```
Insert a rule to block all TCP traffic
```
te = table_entry["MyIngress.ip_proto_filter"](action="MyIngress.drop")
te.match["hdr.ipv4.protocol"] = "6"
te.insert
```

### Step 5 - Testing the configuration
P4Pi
```
sudo ip netns exec gigport iperf -s 192.168.4.150
```
And connect to it from your laptop.
```
iperf -c 192.168.4.150 -t 30 -i 1
```
Because TCP flows are blocked, it will not connect.

Let's check that UDP still works.

```
sudo ip netns exec gigport iperf -s 192.168.4.150 -u -p 5003
```
And connect to it from your laptop.
```
iperf -c 192.168.4.150 -t 30 -i 1 -u -p 5003
```
### Step 6 - Add new filters and test them
Any of the previously discussed header fields can be used in the rules. Try to block the UDP 12345 port. (hint: use the udp_dstPort_filter table). Help for the table entry creation:
```
te = table_entry["MyIngress.table_name"](action="MyIngress.function_name")
te.match["name_of_the_field_to_match"] = "value_as_string"
te.match["if_there_are_more_keys_to_match"] = "value_as_string"
te.action["action_function_parameter_name"] = "value_as_string"
te.insert
```

## Testing as a hotspot sharing the Internet access of a home router (or a private network domain)
The following figure depicts another setup where P4Pi node acts as a low level relay or proxy between your laptop and your home router (or a private network) connected to the 1GE wired Ethernet port.
<p align="center">
  <img alt="Low level gateway mode of P4Pi" width="900px" src="../../images/l2switch_setupB.png">
</p>

### Step 1 - Connect to P4Pi
Connect to the p4pi wireless access point and open an SSH to the management IP (192.168.4.101).

### Step 2 - Launching traffic filter program
We first launch the traffic filter program. In the SSH terminal:
```bash
echo "Stopping T4P4S switch..."
screen -X -S switch quit >> /dev/null
echo "Launching T4P4S switch with the default program"
pushd /home/pi/p4pi/t4p4s/t4p4s >> /dev/null
screen -dmS switch bash -c "source ~/.bashrc;PYTHON3=python3.9 ./t4p4s.sh :firewall p4rt;/bin/bash"
popd
```

### Step 3 - [Reconfiguring internal network settings](../l2switch/README.md#step-3---reconfiguring-internal-network-settings)
### Step 4 - [Reconnect your laptop](../l2switch/README.md#step-4---reconnect-your-laptop)


### Step 5 - Testing without configuring
Internet access should work properly on your laptop.

### Step 6 - Insert a HTTP blocking rule
The next step is to launch P4Runtime shell, that is used to create rules. In the SSH terminal run:
```bash
echo "Generating the required files for P4 runtime"
p4c-bm2-ss --p4v 16 --p4runtime-file firewall.p4runtime --p4runtime-format text --toJSON firewall.json  ~/p4pi/t4p4s/examples/firewall.p4
echo "Starting the P4 runtime..."
python3.9 -m p4runtime_sh --grpc-addr localhost:50051 --device-id 1 --election-id 0,1 --config firewall.p4runtime,firewall.json
```
Try to block HTTP traffic
```
te = table_entry["MyIngress.tcp_dstPort_filter"](action="MyIngress.drop")
te.match["hdr.tcp.dstPort"] = "80"
te.insert
```

### Step 7 - Testing the configuration
Internet access should work properly on your laptop, however, no HTTP website will load. (HTTPS still works fine).

## Functionalities to be added during the hackathon or later
* Try to modify the P4 code to change the blocklist behavior to allowlist. Instead of allowing everything by default, block all traffic and allow only flows that match the inserted rules.
* Add support for IPv6
