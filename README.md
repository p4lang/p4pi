<p align="center">
  <img alt="P4Pi Logo" width="256px" src="p4pi-web/dashboard/static/assets/images/logo.png">
</p>

-------------------------------------------------------------------------------

P4Pi (pronounced papi or puppy) allows to design and deploy network data planes
written in P4 using the Raspberry Pi platform.

# Common

To setup your Raspberry Pi for the first time, follow the instructions on [the Raspberry Pi Website](https://projects.raspberrypi.org/en/projects/raspberry-pi-setting-up), using the operating system noted below.

Start from the latest(_at the time of writing_) [64 bit Raspberry Pi OS lite](https://downloads.raspberrypi.org/raspios_lite_arm64/images/raspios_lite_arm64-2021-04-09/2021-03-04-raspios-buster-arm64-lite.zip)

Update packages
```bash
sudo apt-get update && sudo apt-get full-upgrade -y
sudo apt-get install -y git
```

To use pcap poll mode driver install `libpcap-dev` before compiling dpdk
```bash
sudo apt-get install -y libpcap-dev
```

# Performance tuning

## Isolate CPU core(s)
Add kernel parameters for cpu isolation in `/boot/cmdline.txt` eg:
```
isolcpus=2
```

## Tap Poll Mode Driver
Install `bridge-utils`
```bash
sudo apt-get install -y bridge-utils
```
Use `--vdev net_tap0` in `opts_dpdk.cfg`
Start basic_mirror to create dtap0 then bridge it to eth0/wlan0:
```bash
sudo brctl addbr br0
sudo brctl addif br0 <eth0/wlan0> dtap0
sudo ifconfig br0 up
```

# Testing

## Direct Ethernet connection
Connect pi to pc with ethernet
The pi should have something like `169.254.146.157/16` as ip(, assigned automatically without dhcp).

Configure static ip in the same subnet for the pc and add manual arp entry for a non-existant destination

```bash
sudo ip ad add 169.254.146.158/16 dev <eno0>
sudo arp -s 169.254.146.159 00:50:ba:85:85:ca
```

Start basic_mirror on the pi. On the pc run the iperf server and client(targeting the non-existant destination) as well
eg:
```bash
iperf3 -s 169.254.146.158
iperf3 -t 120 -c 169.254.146.159
```

## Pi as WiFi AP

[Based on this](https://www.raspberrypi.org/documentation/configuration/wireless/access-point-routed.md)

### Install hostapd and dnsmasq
```bash
sudo apt-get install -y hostapd dnsmasq
sudo systemctl unmask hostapd
```

### Configure static ip for the pi
Append to `/etc/dhcpcd.conf`
```bash
interface wlan0
    static ip_address=192.168.0.1/24
    nohook wpa_supplicant
```
### Configure dhcp
Replace `/etc/dnsmasq.conf` with
```bash
interface=wlan0
dhcp-range=192.168.0.2,192.168.0.20,255.255.255.0,24h
```
### Configure hostapd
Edit `/etc/hostapd/hostapd.conf`:  (fiddle with channel if needed, unfortunately the auto channel scan is not supported by the hardware)
```bash
country_code=HU
interface=wlan0
ssid=<NameOfNetwork>
hw_mode=a
channel=48
ieee80211d=1
ieee80211n=1
ieee80211ac=1
wmm_enabled=1
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=<Password>
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
```

### Start hostapd
```bash
sudo systemctl start hostapd # or enable and restart
```

On the pc add a manual arp entry for a non-existant destination in the same subnet and run iperf with that as a destination eg
```bash
sudo arp -s 192.168.0.10 00:50:ba:85:85:ca
```

# Configuration settings

## Environmental variables

```
export P4PI=/home/pi/p4pi/t4p4s/pi
export GRPC=/home/pi/p4pi/t4p4s/grpc
export GRPCPP=/home/pi/p4pi/t4p4s/P4Runtime_GRPCPP
```

## Creating veth pairs

By default the following command is executed on start-up by `p4pi-setup.service`.

```bash
sudo p4pi-setup
```
It creates two virtual Ethernet devices pairs and two bridge interfaces
are used in T4P4S examples to process packets.

In order to add the wireless access point interface to a bridge used T4P4S,
uncomment the following line in `/etc/hostapd/hostapd.conf`:

```
#bridge=br0
```


# Results

With pcap PMD

## Ethernet

baseline:
```
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-120.00 sec  13.1 GBytes   941 Mbits/sec    1             sender
[  5]   0.00-120.00 sec  13.1 GBytes   941 Mbits/sec                  receiver

```

bmv2:
```
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-120.00 sec   639 MBytes  44.7 Mbits/sec  19456             sender
[  5]   0.00-120.00 sec   639 MBytes  44.7 Mbits/sec                  receiver
```
dpdk (with hugepages and isolated cpu core)
```
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-120.00 sec  1.18 GBytes  84.6 Mbits/sec  2478             sender
[  5]   0.00-120.01 sec  1.18 GBytes  84.5 Mbits/sec                  receiver
```

T4P4S:
```
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-120.00 sec   973 MBytes  68.0 Mbits/sec  2965             sender
[  5]   0.00-120.02 sec   970 MBytes  67.8 Mbits/sec                  receiver

```

T4P4S with Tap PMD:
```
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-120.00 sec  2.57 GBytes   184 Mbits/sec  522             sender
[  5]   0.00-120.04 sec  2.57 GBytes   184 Mbits/sec                  receiver

```

## WiFi

Baseline:
```
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-120.00 sec   827 MBytes  57.8 Mbits/sec    0             sender
[  5]   0.00-120.02 sec   824 MBytes  57.6 Mbits/sec                  receiver
```

T4P4s:
```
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-120.00 sec   396 MBytes  27.7 Mbits/sec  401             sender
[  5]   0.00-120.06 sec   393 MBytes  27.5 Mbits/sec                  receiver

```
T4P4S with  Tap PMD:
```
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-120.00 sec   415 MBytes  29.0 Mbits/sec    1             sender
[  5]   0.00-120.09 sec   413 MBytes  28.8 Mbits/sec                  receiver
```