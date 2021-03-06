#include <core.p4>
#include <v1model.p4>

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

header header_0_t {
    bit<16> field_0;
}

header header_1_t {
    bit<16> field_0;
}

header ptp_t {
    bit<4>  transportSpecific;
    bit<4>  messageType;
    bit<4>  reserved;
    bit<4>  versionPTP;
    bit<16> messageLength;
    bit<8>  domainNumber;
    bit<8>  reserved2;
    bit<16> flags;
    bit<64> correction;
    bit<32> reserved3;
    bit<80> sourcePortIdentity;
    bit<16> sequenceId;
    bit<8>  PTPcontrol;
    bit<8>  logMessagePeriod;
    bit<80> originTimestamp;
}

struct metadata {
}

struct headers {
    @name("ethernet") 
    ethernet_t ethernet;
    @name("header_0") 
    header_0_t header_0;
    @name("header_1") 
    header_1_t header_1;
    @name("ptp") 
    ptp_t      ptp;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("parse_ethernet") state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            16w0x88f7: parse_ptp;
            default: accept;
        }
    }
    @name("parse_header_0") state parse_header_0 {
        packet.extract(hdr.header_0);
        transition select(hdr.header_0.field_0) {
            16w0: accept;
            default: parse_header_1;
        }
    }
    @name("parse_header_1") state parse_header_1 {
        packet.extract(hdr.header_1);
        transition select(hdr.header_1.field_0) {
            default: accept;
        }
    }
    @name("parse_ptp") state parse_ptp {
        packet.extract(hdr.ptp);
        transition select(hdr.ptp.reserved2) {
            8w1: parse_header_0;
            default: accept;
        }
    }
    @name("start") state start {
        transition parse_ethernet;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".forward") action forward(bit<9> port) {
        standard_metadata.egress_spec = port;
    }
    @name("._drop") action _drop() {
        mark_to_drop();
    }
    @name(".add_headers") action add_headers() {
        hdr.header_0.setValid();
        hdr.header_1.setValid();
        hdr.ptp.reserved2 = 8w1;
    }
    @name("forward_table") table forward_table {
        actions = {
            forward;
            _drop;
            @default_only NoAction;
        }
        key = {
            hdr.ethernet.dstAddr: exact;
        }
        size = 4;
        default_action = NoAction();
    }
    @name("test_tbl") table test_tbl {
        actions = {
            add_headers;
            @default_only NoAction;
        }
        size = 1;
        default_action = NoAction();
    }
    apply {
        forward_table.apply();
        test_tbl.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ptp);
        packet.emit(hdr.header_0);
        packet.emit(hdr.header_1);
    }
}

control verifyChecksum(in headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
