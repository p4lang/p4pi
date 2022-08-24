#!/usr/bin/env python3

import os
import sys
import platform
import re

from scapy.all import sendp, Packet, Ether, StrFixedLenField, XByteField, IntField, bind_layers

DST_ADDR = "10:04:00:00:10:10"


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


class NumParseError(Exception):
    pass


class Token:
    def __init__(self, token_type, value=None):
        self.type = token_type
        self.value = value


def get_wireless_interface():
    """
    Get defult wireless interface
    """
    for device_name in os.listdir('/sys/class/net'):
        if os.path.exists(f'/sys/class/net/{device_name}/wireless'):
            return device_name
    print("Can't find WiFi interface")
    sys.exit(1)


def input_parser_numeric(s, i, ts):
    pattern = "^\\s*([0-9]+)\\s*"
    match = re.match(pattern, s[i:])
    if match:
        ts.append(Token('num', match.group(1)))
        return i + match.end(), ts
    raise NumParseError('Expected number literal.')


def input_parser_operator(s, i, ts):
    pattern = "^\\s*([-+&|^])\\s*"
    match = re.match(pattern, s[i:])
    if match:
        ts.append(Token('num', match.group(1)))
        return i + match.end(), ts
    raise NumParseError("Expected binary operator '-', '+', '&', '|', or '^'.")


def make_seq(p1, p2):
    def parse(s, i, ts):
        i, ts2 = p1(s, i, ts)
        return p2(s, i, ts2)
    return parse


def main():
    bind_layers(Ether, P4calc, type=0x1234)

    user_input_parser = make_seq(
        input_parser_numeric,
        make_seq(input_parser_operator, input_parser_numeric)
    )

    if platform.system() == 'Linux':
        iface_name = get_wireless_interface()
    else:
        iface_name = input("Please enter wireless interface name: ")
    print(f"Using interface: {iface_name}")

    while True:
        user_command = input('Expression [1 + 2]: ')
        if user_command == '':
            user_command = '1 + 2'
        if user_command in ["quit", "q"]:
            break
        try:
            _, user_input = user_input_parser(user_command, 0, [])

            operator = user_input[1].value
            operand_a = int(user_input[0].value)
            operand_b = int(user_input[2].value)

            packet = Ether(dst=DST_ADDR, type=0x1234)
            packet /= P4calc(op=operator, operand_a=operand_a,
                             operand_b=operand_b)

            print("Sending packet with payload: ")
            print(f"\t{operand_a} {operator} {operand_b}")
            sendp(packet, iface=iface_name)
        except Exception as error:
            print(error)


if __name__ == '__main__':
    main()
