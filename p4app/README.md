# Start programming P4 in p4app 

Introduction
-----------
This repository is designed for participants without any knowledge on P4.
We encourage beginners to start with p4app to get familiar with P4 and develop their own P4 programs. Then the team will help participants to migrate the developed P4 program to the Raspberry Pi and test.

Installation
------------

1. Install [docker](https://docs.docker.com/engine/installation/) if you don't
   already have it.

2. Clone the repository to local 

    ```
    git clone https://github.com/p4lang/p4pi.git  
    ```

3. ```
    cd p4app 
   ```
4. ```
   ./p4app run basic.p4app
   ```
When you execute `p4app run` at the first time, it will take some time to download the docker image.

5. [Optional] Move `p4app` to $PATH so that `p4app` can be run from any location, for example:
``` 
cp p4app /usr/local/bin
```
6. You are ready!

**We strongly recommend participants to finish the installation before the hackathon so that there will be more time left for hands-on exercises.**

P4 cheet sheet
--------------
To quickly get familiar with P4, a cheet sheet is available [here](https://github.com/p4lang/tutorials/blob/master/p4-cheat-sheet.pdf).


Network topology
--------
![topo](topo.png)
The network topology used in our tutorial is triangular, and each host connects to a switch. The details of hosts (i.e., `h1`, `h2`, and `h3`) and switches (i.e., `S1`, `S2`, and `S3`) are shown in the figure.

Exercise I: Simple L3 forwarding 
--------------

### Step 1: Run the (incomplete) starter code
1.  ```
    ./p4app run basic.p4app 
    ```
    After this step you'll see the terminal of **mininet**

2. Try to ping between hosts in the topology:
```
mininet> pingall
```
or 
```
mininet> h1 ping h2
```
At the moment there should be no connection among hosts

3. Quit mininet
```
mininet > exit
```
### Step 2: Implement the forwarding logic

The `basic.p4app/p4src/basic.p4` file contains a skeleton P4 program with key pieces of
logic replaced by `TODO` comments. Your implementation should follow
the structure given in this file---replace each `TODO` with logic
implementing the missing piece.

A complete `basic.p4` will contain the following components:

1. Header type definitions for Ethernet (`ethernet_t`) and IPv4 (`ipv4_t`).
2. **TODO:** Parsers for Ethernet and IPv4 that populate `ethernet_t` and `ipv4_t` fields.
3. An action to drop a packet, using `mark_to_drop()`.
4. **TODO:** An action (called `ipv4_forward`) that:
	1. Sets the egress port for the next hop.
	2. Updates the ethernet source address with the address of the switch.
	3. Updates the ethernet destination address with the address of the next hop.
	4. Decrements the TTL.
5. **TODO:** Fix ingress control logic that:
    1. `ipv4_lpm` table should be applied only when IPv4 header is valid
6. **TODO:** A deparser that selects the order
    in which fields inserted into the outgoing packet.

### Step 3: Populate flow rules
There is a control plane logic here: you need to define different flow rules in each switch so that they know how to forward the traffic to the destination.  
`commands1.txt`, `commands2.txt`, `commands3.txt` represent the rules for the tables in the switch `S1`, `S2`, and `S3`, respectively.

The format of adding flow rules in `commands[1-3].txt` should be like:
```
table_add [table name] [action name] [table key] => [action parameter] [action parameter 2] [...]
```
An example using ipv4_lpm table in `basic.p4`:
```
table_add ipv4_lpm ipv4_forward 10.0.1.1/32 => 00:00:00:00:01:01 1
```

### Step 4: Run your solution
If the P4 program and the defined flow rules are correct, it is possible to reach all hosts by using `pingall` in mininet:

```
mininet> pingall
*** Ping: testing ping reachability
h1 -> h2 h3
h2 -> h1 h3
h3 -> h1 h2
```

Alternatively, if you want to know more information about the packets, open a new terminal and copy required python scripts to hosts first (not in mininet):
```
./install_scripts
```
**[Sniff traffic in h2]**  
Open a terminal:
```
./p4app exec m h2 python3 receive.py
```


**[Send traffic from h1 to h2]**  
```
mininet> h1 python3 send.py h2 "hello"
```

**[Alternative way to send traffic]** Open another terminal:
```
./p4app exec m h1 python3 send.py h2 "hello"
```

Then you should be able to see the packet contents in h2:
```
sniffing on h2-eth0
got a packet
###[ Ethernet ]###
  dst       = 00:00:00:00:02:02
  src       = 00:00:00:00:02:02
  type      = 0x800
###[ IP ]###
     version   = 4
     ihl       = 5
     tos       = 0x0
     len       = 45
     id        = 1
     flags     =
     frag      = 0
     ttl       = 62
     proto     = tcp
     chksum    = 0x65c8
     src       = 10.0.1.1
     dst       = 10.0.2.2
     \options   \
###[ TCP ]###
        sport     = 54670
        dport     = 1234
        seq       = 0
        ack       = 0
        dataofs   = 5
        reserved  = 0
        flags     = S
        window    = 8192
        chksum    = 0x5aa8
        urgptr    = 0
        options   = []
###[ Raw ]###
           load      = 'hello'
```

### Solution
The solution is available in `basic.p4app/p4src/solution`


Exercise II: calculator
--------------

### Step 1: Run the (incomplete) starter code
1.  ```
    ./p4app run calc.p4app 
    ```
    After this step you'll see the terminal of **mininet**

2. Open another terminal and enter calc.p4app folder
   ```
    cd calc.p4app 
   ```

3. Copy required scripts to the hosts
   ```
    ./install_scripts.sh
   ```

4. We've written a small Python-based driver program that will allow
you to test your calculator. You can choose one of the hosts (i.e., `h1`, `h2` or `h3`) and type the following command in the terminal of **mininet**, for instance:
```
mininet> h1 python3 cal.py
```
**[Alternative]** Run the following command in a new terminal (not in mininet):
```
cd ..
./p4app exec m h1 python3 cal.py
```

5. The driver program will provide a new prompt, at which you can type
basic expressions. The test harness will parse your expression, and
prepare a packet with the corresponding operator and operands. It will
then send a packet to the switch for evaluation. When the switch
returns the result of the computation, the test program will print the
result. However, because the calculator program is not implemented,
you should see an error message.

```
> 1+1
Didn't receive response
>
```

### Step 2: Implement Calculator

To implement the calculator, you will need to define a custom
calculator header, and implement the switch logic to parse header,
perform the requested operation, write the result in the header, and
return the packet to the sender.

We will use the following header format:

             0                1                  2              3
      +----------------+----------------+----------------+---------------+
      |      P         |       4        |     Version    |     Op        |
      +----------------+----------------+----------------+---------------+
      |                              Operand A                           |
      +----------------+----------------+----------------+---------------+
      |                              Operand B                           |
      +----------------+----------------+----------------+---------------+
      |                              Result                              |
      +----------------+----------------+----------------+---------------+


-  P is an ASCII Letter 'P' (0x50)
-  4 is an ASCII Letter '4' (0x34)
-  Version is currently 0.1 (0x01)
-  Op is an operation to Perform:
 -   '+' (0x2b) Result = OperandA + OperandB
 -   '-' (0x2d) Result = OperandA - OperandB
 -   '&' (0x26) Result = OperandA & OperandB
 -   '|' (0x7c) Result = OperandA | OperandB
 -   '^' (0x5e) Result = OperandA ^ OperandB


We will assume that the calculator header is carried over Ethernet,
and we will use the Ethernet type 0x1234 to indicate the presence of
the header.

Given what you have learned so far, your task is to implement the P4
calculator program available in calc.p4app/p4src/calc.p4. There is no control plane logic, so you need only
worry about the data plane implementation.

A working calculator implementation will parse the custom headers,
execute the mathematical operation, write the result in the result
field, and return the packet to the sender.

### Step 3: Run your solution

Follow the instructions from Step 1.  This time, you should see the
correct result:

```
> 1+1
2
>
```

### Solution
The solution is available in `calc.p4app/p4src/solution`

Test on Raspberry Pi
-------------------

Once finishing two hands-on exercises, you can come to tutors and test your developed P4 program on a Raspberry Pi. We use calculator as an example here:
1. Compile the P4 program
```
p4c --target bmv2 --arch v1model --std p4-16 calc.p4
```
2. Run the compiled program. 
```
sudo simple_switch -i 0@veth0 calc.json
```
3. Change the network interface to `veth0-1` in `cal.py` 
```
iface = "veth0-1"
```

4. Run the python script 
```
sudo python cal.py
```

5. Enter an equation and check if you get the correct results.

More information can be found in [Running P4 examples on P4Pi](https://github.com/p4lang/p4pi/wiki/Running-P4-examples-on-P4Pi) .
