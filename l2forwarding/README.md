# Layer Forwarding

## Description

This application simply looks up on layer header and either drops or forwards
packets toward destination.

## Running Demo

We provide a small demo to let you test the program.

- [run_switch.sh](run_switch.sh): compile the P4 program and starts the switch,
  also configures the data plane by running the CLI [commands](commands.txt)
- [icmp.pcap](../pcap/icmp.pcap): ICMP packet to feed in the switch

To run the demo:
- create virtual interfaces (need to run only if the VM has restarted): 
`sudo ../veth_setup.sh`
- start the switch: `sudo ./run_switch.sh`
- start tcpdump: `sudo tcpdump -i veth2`
- use tcpreplay to send packet: `sudo tcpreplay -i veth4 ../pcap/icmp.pcap`