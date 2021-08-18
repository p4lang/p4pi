# Calculator

In this example, we use the default settings of P4Pi as depicted in the following figure:
<p align="center">
  <img alt="Default settings of P4Pi" width="600px" src="../../images/l2switch_setupA.png">
</p>

This example is based on the P4 tutorial exercise called [calc](https://github.com/p4lang/tutorials/tree/master/exercises/calc). 
Accordingly, this P4 program implements a basic calculator using a custom protocol header written in P4. The header contains an operation to perform and two operands. When the switch receives a calculator packet header encapsulated into an Ethernet frame, it executes the operation on the operands, and encodes the result into the packet, swaps the MAC addresses in the Ethernet frame and returns the frame to the sender.

The calculator header is carried over Ethernet, using the Ethernet type 0x1234 to indicate the presence of the header. Table calculator is used to perform the proper calculation on the operands and store the result in one of the header fields. The table only contains constant entries.

The source code of the example is available under [T4P4S examples](https://github.com/P4EDGE/t4p4s/blob/master/examples/calc.p4).

### Step 1 - Connecting to P4Pi
Connect your laptop to the wireless access point called p4pi. After that your laptop will get an IP address assigned by the DHCP service (from the default address pool 192.168.4.0/24).

### Step 2 - Launching the P4 program
Start the P4 program (calc.p4) through the web interface or manually with the following commands in an SSH terminal:
```bash
cd /home/pi/p4pi/t4p4s/t4p4s/
screen -S switch
./t4p4s.sh :calc p4rt
```
Then you can leave the screen with Ctrl+A+D.

### Step 3 - Generating test traffic

We slightly updated the scapy-based python script of [P4 Tutorial](https://github.com/p4lang/tutorials/blob/master/exercises/calc/calc.py). The modifications include the update to Python 3 and the support of Windows OS. You can run the code as follows:
```bash
python3 calc.py
```

This script provides a new prompt for typing basic expressions. After parsing the entered expression, it prepares a packet with the corresponding operator and operands and then send the packet to the switch for evaluation. When the switch returns the result of the computation, the script prints its value. Note that 

```bash
> 24 + 18
.
Sent 1 packets.
Result: 42
``` 

The result can be seen in the last line while additional status messages are also depicted.

Note that calc.py has several dependencies (Python 3 modules): scapy, pyreadline and six.

## Running the test script on Windows OS

The easiest way is to use an Anaconda installation with Python 3: [Installing on Windows](https://docs.anaconda.com/anaconda/install/windows/). The dependencies can be installed inside an Anaconda Prompt: 
```bash
pip3 install scapy
pip3 install pyreadline
pip3 install six
```

Then the iface variable at line 71 of calc.py needs to be set to the name of the used wireless  interface (e.g., 'Wi-Fi' in most Windows systems).
```python
...
    iface = 'Wi-Fi'
...
```

Finally, you can execute calc.py in an Anaconda Prompt as in Linux systems:
```bash
python3 calc.py
```

## Functionalities to be added during the hackathon or later
* Emulating division and multiplication by applying logarithm and exponential tables
