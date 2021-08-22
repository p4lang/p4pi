#!/usr/bin/env python3

import os
import sys
import platform

from scapy.all import sniff, Packet, Ether, StrFixedLenField, XByteField, IntField, bind_layers


class P4calc(Packet):
    name = "P4calc"
    fields_desc = [
        StrFixedLenField("P", "P", length=1),
        StrFixedLenField("Four", "4", length=1),
        XByteField("version", 0x01),
        StrFixedLenField("op", "+", length=1),
        IntField("operand_a", 0),
        IntField("operand_b", 0),
        IntField("result", 0xDEADBABE)
    ]


def get_wireless_interface():
    """
    Get defult wireless interface
    """
    for device_name in os.listdir('/sys/class/net'):
        if os.path.exists(f'/sys/class/net/{device_name}/wireless'):
            return device_name
    print("Can't find WiFi interface")
    sys.exit(1)


def packet_filter(packet):
    return packet[Ether].type == 0x1234


def PacketHandler(packet):
    if packet_filter(packet):
        packet.show()


def main():
    bind_layers(Ether, P4calc, type=0x1234)
    if platform.system() == 'Linux':
        iface_name = get_wireless_interface()
    else:
        iface_name = input("Please enter wireless interface name: ")
    print(f"Monitoring P4calc packets on interface: {iface_name}")
    sniff(iface=iface_name, prn=PacketHandler)


if __name__ == '__main__':
    main()
