/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

typedef bit<9>  port_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;
typedef bit<128> ip6Addr_t;
typedef bit<16> mcastGrp_t;

const macAddr_t BROADCAST_ADDR  = 0xffffffffffff;
const mcastGrp_t BROADCAST_MGID = 0x0001;

const ip4Addr_t ALLSPFROUTERS_ADDR = 0xe0000005;

const port_t CPU_PORT           = 0x1;

const bit<16> ARP_OP_REQ        = 0x0001;
const bit<16> ARP_OP_REPLY      = 0x0002;

const bit<16> TYPE_IPV4         = 0x0800;
const bit<16> TYPE_IPV6         = 0x86dd;
const bit<16> TYPE_ARP          = 0x0806;
const bit<16> TYPE_CPU_METADATA = 0x080a;

// standard Ethernet header
header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

//Header for information sent to the CPU
header cpu_metadata_t {
 
 //TODO: Construct the header with the information to send to the CPU
 //This header should be added to all packets sent to the control plane
 
}

//TODO: define all other headers required by the router.



struct headers {
    ethernet_t        ethernet;
    cpu_metadata_t    cpu_metadata;
    //TODO: add all other supported headers
}

struct metadata { }

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {
    state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        // TODO: Parse all the headers supported by the project
        transition accept;
        }
    }
}

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {
    apply {
         // TODO: verify checksum 
    }
}

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {

    action set_egr(port_t port) {
        standard_metadata.egress_spec = port;
    }
    
   action drop() {
        mark_to_drop(standard_metadata);
    }

   action send_to_cpu() {
      //TODO: What should you do here?
    }

  
//TODO: Add all tables and actions

    apply {
        //TODO: Add your control flow
        //The following is a dummy code that will return the packet "as is" to the source
        standard_metadata.egress_spec = standard_metadata.ingress_port
    }
}

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    apply { }
}

control MyComputeChecksum(inout headers  hdr, inout metadata meta) {
    apply {
       // TODO: Update checksum 
    }
}

control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
       //TODO: Add all other headers
    }
}

V1Switch(MyParser(), MyVerifyChecksum(), MyIngress(), MyEgress(), MyComputeChecksum(), MyDeparser()) main;
