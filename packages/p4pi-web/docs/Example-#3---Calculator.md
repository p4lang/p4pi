# Example #3 - Calculator

In this example, we use the default settings of P4Edge as depicted in the following figure:

![Default settings of P4Edge](./img/l2switch_setupA.png)

This example is based on the P4 tutorial exercise called [calc](https://github.com/p4lang/tutorials/tree/master/exercises/calc).
Accordingly, this P4 program implements a basic calculator using a custom protocol header written in P4. The header contains an operation to perform and two operands. When the switch receives a calculator packet header encapsulated into an Ethernet frame, it executes the operation on the operands, and encodes the result into the packet, swaps the MAC addresses in the Ethernet frame and returns the frame to the sender.

The calculator header is carried over Ethernet, using the Ethernet type `0x1234` to indicate the presence of the header. Table calculator is used to perform the proper calculation on the operands and store the result in one of the header fields. The table only contains constant entries.

P4 source code: [calc.p4](https://github.com/P4EDGE/t4p4s/tree/master/examples/calc.p4)

### Step 1 - Connecting to P4Edge

Connect your laptop to the wireless access point called P4Edge. After that your laptop will get an IP address assigned by the DHCP service (from the default address pool 192.168.4.0/24).

### Step 2 - Launching the P4 program

Start the P4 program (calc.p4) through the web interface or manually with the following commands in an SSH terminal:

```console
ssh pi@192.168.4.1

pi@P4Edge:~$ sudo -i
root@P4Edge:~# echo 'calc' > /root/t4p4s-switch
root@P4Edge:~# systemctl restart t4p4s.service
```

### Step 3 - Start traffic receiver

You can run the code on your laptop connected to P4Edge as follows:

```bash
sudo python3 receiver.py
```

The receiver script filters packets with Ethernet type `0x1234` and shows their content.
The script prints both packets that have been send as well as received.

### Step 4 - Send test traffic

This script provides a new prompt for typing basic expressions. If no expression has been entered, `1 + 2` will be used. After parsing the entered expression, it creates a packet with the corresponding operator and operands. Then it sends the packet on the wireless interface.

```console
sudo python3 send.py

Using interface: wlp1s0
Payload [1 + 2]: 3 + 4
Sending packet with payload: 3 + 4
.
Sent 1 packets.
Payload [1 + 2]:
Sending packet with payload: 1 + 2
.
Sent 1 packets.
Payload [1 + 2]:
```

The result can be seen in the last line while additional status messages are also depicted.

Note that `send.py` and `receive.py` require the [scapy](https://pypi.org/project/scapy/) dependency to be installed.

## Running the test script on a laptop with Windows OS

The easiest way is to use an Anaconda installation with Python 3: [Installing on Windows](https://docs.anaconda.com/anaconda/install/windows/). The dependencies can be installed inside an Anaconda Prompt:

```bash
pip3 install scapy
```

When running on Windows OS, the `send.py` and `receive.py` scripts display an input prompt to specify the wireless interface name (e.g., 'Wi-Fi' in most Windows systems).

Finally, you can execute the `send.py` and `receive.py` scripts in an Anaconda Prompt as in Linux systems:

```bash
python3 send.py
```

```bash
python3 receive.py
```

## Functionalities to be added during the hackathon or later

- Emulating division and multiplication by applying logarithm and exponential tables
