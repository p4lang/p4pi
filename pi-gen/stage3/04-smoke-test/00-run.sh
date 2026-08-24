#!/bin/bash -e
on_chroot << EOF
set -e
echo "=== Smoke tests ==="

# Verify binaries exist
which p4c-bm2-ss || { echo "FAIL: p4c-bm2-ss missing"; exit 1; }
which p4c-dpdk   || { echo "FAIL: p4c-dpdk missing"; exit 1; }
which simple_switch || { echo "FAIL: simple_switch missing"; exit 1; }
which simple_switch_CLI || { echo "FAIL: simple_switch_CLI missing"; exit 1; }

# Minimal P4 program for compile tests
mkdir -p /tmp/smoke && cd /tmp/smoke
cat > smoke_v1model.p4 <<'P4EOF'
#include <core.p4>
#include <v1model.p4>
struct metadata { }
struct headers { }
parser MyParser(packet_in p, out headers h, inout metadata m,
                inout standard_metadata_t s) { state start { transition accept; } }
control MyVerify(inout headers h, inout metadata m) { apply { } }
control MyIngress(inout headers h, inout metadata m,
                  inout standard_metadata_t s) { apply { } }
control MyEgress(inout headers h, inout metadata m,
                 inout standard_metadata_t s) { apply { } }
control MyCompute(inout headers h, inout metadata m) { apply { } }
control MyDeparser(packet_out p, in headers h) { apply { } }
V1Switch(MyParser(), MyVerify(), MyIngress(), MyEgress(),
         MyCompute(), MyDeparser()) main;
P4EOF

p4c-bm2-ss --p4v 16 -o smoke.json smoke_v1model.p4
[ -s smoke.json ] || { echo "FAIL: BMv2 JSON not produced"; exit 1; }
echo "PASS: BMv2 JSON smoke test"

cd / && rm -rf /tmp/smoke
echo "=== Smoke tests passed ==="
EOF
