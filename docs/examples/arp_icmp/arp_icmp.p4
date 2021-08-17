/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

const bit<16> TYPE_IPV4  = 0x0800;
const bit<16> TYPE_ARP   = 0x0806;
const bit<8>  PROTO_ICMP = 1;

// ARP RELATED CONSTS
const bit<16> ARP_HTYPE = 0x0001;    // Ethernet Hardware type is 1
const bit<16> ARP_PTYPE = TYPE_IPV4; // Protocol used for ARP is IPV4
const bit<8>  ARP_HLEN  = 6;         // Ethernet address size is 6 bytes
const bit<8>  ARP_PLEN  = 4;         // IP address size is 4 bytes
const bit<16> ARP_REQ = 1;           // Operation 1 is request
const bit<16> ARP_REPLY = 2;         // Operation 2 is reply


/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

header arp_t {
  bit<16>   h_type;
  bit<16>   p_type;
  bit<8>    h_len;
  bit<8>    p_len;
  bit<16>   op_code;
  macAddr_t src_mac;
  ip4Addr_t src_ip;
  macAddr_t dst_mac;
  ip4Addr_t dst_ip;
}

header icmp_t {
    bit<8> icmp_type;
    bit<8> icmp_code;
    bit<16> checksum;
    bit<16> identifier;
    bit<16> sequence_number;
    varbit<1024> padding;
}

header ipv4_t {
    bit<8>    versionihl;
    bit<8>    diffserv;
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    ip4Addr_t srcAddr;
    ip4Addr_t dstAddr;
}

struct metadata {
    /* empty */
}

struct headers {
    ethernet_t   ethernet;
    arp_t        arp;
    ipv4_t       ipv4;
    icmp_t       icmp;
}

/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

    state start {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
          TYPE_ARP: parse_arp;
          TYPE_IPV4: parse_ipv4;
          default: accept;
        }
        
    }

    state parse_arp {
      packet.extract(hdr.arp);
        transition select(hdr.arp.op_code) {
          ARP_REQ: accept;
	  default: accept;
      }
    }


    state parse_ipv4 {
      packet.extract(hdr.ipv4);
      transition select(hdr.ipv4.protocol) {
        PROTO_ICMP: parse_icmp;
        default: accept;
      }
    }

    state parse_icmp {
      bit<32> n = (bit<32>) (hdr.ipv4.totalLen) - (bit<32>)(hdr.ipv4.versionihl << 2);
      packet.extract(hdr.icmp, 8*n-64);
      transition accept;
    }
}


/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {   
    apply {  }
}


/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {
    action drop() {
        mark_to_drop(standard_metadata);
    }

    action arp_reply(macAddr_t request_mac) {
        //update operation code from request to reply
        hdr.arp.op_code = ARP_REPLY;
      
        //reply's dst_mac is the request's src mac
        hdr.arp.dst_mac = hdr.arp.src_mac;
      
        //reply's dst_ip is the request's src ip
        hdr.arp.src_mac = request_mac;

        //reply's src ip is the request's dst ip
        hdr.arp.src_ip = hdr.arp.dst_ip;

        //update ethernet header
        hdr.ethernet.dstAddr = hdr.ethernet.srcAddr;
        hdr.ethernet.srcAddr = request_mac;

        //send it back to the same port
        standard_metadata.egress_port = standard_metadata.ingress_port;
    }
    

    action icmp_reply() {
        //set ICMP type to Echo reply
        hdr.icmp.icmp_type = 0;

        //for checksum calculation this field should be zero
        hdr.icmp.checksum = 0;

        //swap the source and destination IP addresses
	bit<32> tmp_ip = hdr.ipv4.srcAddr;
        hdr.ipv4.srcAddr = hdr.ipv4.dstAddr;
        hdr.ipv4.dstAddr = tmp_ip;

        //swap the source and destination MAC addresses
        bit<48> tmp_mac = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = hdr.ethernet.srcAddr;
        hdr.ethernet.srcAddr = tmp_mac;

        //send it back to the same port 
        standard_metadata.egress_port = standard_metadata.ingress_port;
    }


    // ARP table implements an ARP responder
    table arp_exact {
      key = {
        hdr.arp.dst_ip: exact;
      }
      actions = {
        arp_reply;
        drop;
      }
      size = 1024;
      default_action = drop;
    }
    
    // replies to ICMP echo requests if the destination IP matches
    table icmp_responder {
        key = {
            hdr.ethernet.dstAddr: exact;
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            icmp_reply;
            drop;
        }
        size = 1024;
        default_action = drop();
    }

    apply {
        if (hdr.arp.isValid()){
            arp_exact.apply();
        }
        else if (hdr.icmp.isValid())
        {
          icmp_responder.apply();
        }
        else
        {
          drop();       
        }
    }
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    apply {  }
}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/

control MyComputeChecksum(inout headers hdr, inout metadata meta) {
     apply {

        //update ICMP checksum
	update_checksum(
	    hdr.icmp.isValid(),
            {
              hdr.icmp.icmp_type,
              hdr.icmp.icmp_code,
              16w0,
              hdr.icmp.identifier,
              hdr.icmp.sequence_number,
              hdr.icmp.padding
            },
              hdr.icmp.checksum,
              HashAlgorithm.csum16);

        //update IPv4 checksum
        update_checksum(
            hdr.ipv4.isValid(), 
            { 
              hdr.ipv4.versionihl, 
              hdr.ipv4.diffserv, 
              hdr.ipv4.totalLen, 
              hdr.ipv4.identification, 
              hdr.ipv4.fragOffset, 
              hdr.ipv4.ttl, 
              hdr.ipv4.protocol, 
              hdr.ipv4.srcAddr, 
              hdr.ipv4.dstAddr 
            }, 
              hdr.ipv4.hdrChecksum, 
              HashAlgorithm.csum16);
    }
}


/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.arp);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.icmp);
    }
}

/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;
