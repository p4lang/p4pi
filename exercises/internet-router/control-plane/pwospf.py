from select import select
from scapy.all import conf, ETH_P_ALL, MTU, plist, Packet, Ether, IP, ARP
from scapy.packet import Packet, bind_layers
from threading import Thread


ARP_OP_REPLY = 0x0002
ARP_OP_REQ = 0x0001
ARP_TIMEOUT = 30
HELLO_TYPE = 0x01
HELLO_TYPE = 0x01
ICMP_ECHO_REPLY_CODE = 0x00
ICMP_ECHO_REPLY_TYPE = 0x00
ICMP_HOST_UNREACHABLE_CODE = 0x01
ICMP_HOST_UNREACHABLE_TYPE = 0x03
ICMP_PROT_NUM = 0x01
LSU_TYPE = 0x04
OSPF_PROT_NUM = 0x59
OSPF_PROT_NUM = 0x59
PWOSPF_HELLO_DEST = '224.0.0.5'
TYPE_CPU_METADATA = 0x080a


def sniff(store=False, prn=None, lfilter=None, stop_event=None, refresh=.1, *args, **kwargs):
    s = conf.L2listen(type=ETH_P_ALL, *args, **kwargs)
    lst = []
    try:
        while True:
            if stop_event and stop_event.is_set():
                break
            sel = select([s], [], [], refresh)
            if s in sel[0]:
                p = s.recv(MTU)
                if p is None:
                    break
                if lfilter and not lfilter(p):
                    continue
                if store:
                    lst.append(p)
                if prn:
                    r = prn(p)
                    if r is not None:
                        print(r)
    except KeyboardInterrupt:
        pass
    finally:
        s.close()
    return plist.PacketList(lst, "Sniffed")


class Interface():
    def __init__(self, addr, mask, helloint, port):
        # TODO: Handle neighbors


class ARPManager(Thread):
    def __init__(self, cntrl):
        super(ARPManager, self).__init__()
        self.cntrl = cntrl

    def run(self):
        # TODO: Handle ARP packets
        pass


class HelloManager(Thread):
    def __init__(self, cntrl, intf):
        super(HelloManager, self).__init__()
        self.cntrl = cntrl
        self.intf = intf

    def run(self):
        # TODO: Handle Hello packets
        pass


class LSUManager(Thread):
    def __init__(self, cntrl, lsuint):
        super(LSUManager, self).__init__()
        self.lsuint = lsuint
        self.cntrl = cntrl

    def run(self):
        # TODO: Handle LSU packets


class RouterController(Thread):
    def __init__(self, sw, routerID, MAC, areaID, intfs, lsuint=2, start_wait=0.3):
        # TODO: Create a PWOSPF Controller
        super(RouterController, self).__init__()
        pass


class CPUMetadata(Packet):
    name = "CPUMetadata"
    fields_desc = [
        # TODO: Create CPUMetadata packet fields
    ]


class PWOSPF(Packet):
    name = "PWOSPF"
    fields_desc = [
        # TODO: Create PWOSPF packet fields
    ]


class Hello(Packet):
    name = "Hello"
    fields_desc = [
        # TODO: Create Hello packet fields
    ]


class LSUad(Packet):
    name = "LSUad"
    fields_desc = [
        # TODO: Create LSUad packet fields
    ]


class LSU(Packet):
    name = "LSU"
    fields_desc = [
        # TODO: Create LSU packet fields
    ]


bind_layers(Ether, CPUMetadata, type=TYPE_CPU_METADATA)
bind_layers(CPUMetadata, IP, origEtherType=0x0800)
bind_layers(CPUMetadata, ARP, origEtherType=0x0806)
bind_layers(IP, PWOSPF, proto=OSPF_PROT_NUM)
bind_layers(PWOSPF, Hello, type=HELLO_TYPE)
bind_layers(PWOSPF, LSU, type=LSU_TYPE)
