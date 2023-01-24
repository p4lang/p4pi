import re
import base64
import subprocess
from pathlib import Path

import pycountry

t4p4s_location = '/root/t4p4s'
bmv2_location = '/root/bmv2'

def update_dhcpcd_config(static_ip_address):
    dhcpcd_conf_fd = Path('/etc/dhcpcd.conf')
    lines = dhcpcd_conf_fd.read_text()
    lines = re.sub(
        r'(interface wlan0.*)(static ip_address=.*?)$',
        f'\\g<1>static ip_address={static_ip_address}',
        lines,
        flags=re.DOTALL | re.MULTILINE
    )
    dhcpcd_conf_fd.write_text(lines)


def update_dnsmasq_config(range_min, range_max, lease):
    dnsmasq_conf_fd = Path('/etc/dnsmasq.d/p4edge.conf')
    lines = dnsmasq_conf_fd.read_text()
    lines = re.sub(
        r'(interface=br0.*)(dhcp-range=.*?)$',
        f'\\g<1>dhcp-range=set:br0,{range_min},{range_max},255.255.255.0,{lease}',
        lines, flags=re.DOTALL | re.MULTILINE)
    dnsmasq_conf_fd.write_text(lines)


def update_hostapd_config(country_code, ssid, passphrase, channel):
    hostapd_conf_fd = Path('/etc/hostapd/hostapd.conf')
    lines = hostapd_conf_fd.read_text()
    lines = re.sub(r'^country_code=.*$', f'country_code={country_code}', lines, flags=re.MULTILINE)
    lines = re.sub(r'^ssid=.*$', f'ssid={ssid}', lines, flags=re.MULTILINE)
    lines = re.sub(r'^wpa_passphrase=.*$', f'wpa_passphrase={passphrase}', lines, flags=re.MULTILINE)
    lines = re.sub(r'^channel=.*$', f'channel={channel}', lines, flags=re.MULTILINE)
    hostapd_conf_fd.write_text(lines)


def get_countries():
    default = ('HU', 'Hungary')
    countries = [(x.alpha_2, x.name) for x in pycountry.countries]
    countries.sort(key=lambda a: a[1])
    countries.remove(default)
    countries.insert(0, default)
    return countries


def update_opts_dpdk_config(eal_opts, cmd_opts):
    opts_dpdk_config_file = Path(f'{t4p4s_location}/opts_dpdk.cfg')
    opts_dpdk_config = opts_dpdk_config_file.read_text()
    exist = re.search(r'^uploaded_eal.*->.*$', opts_dpdk_config, flags=re.MULTILINE)
    if exist:
        opts_dpdk_config += f'uploaded_eal -> ealopts += {eal_opts}\n'
    else:
        opts_dpdk_config = re.sub(
            r'^uploaded_eal.*->.*$',
            f'uploaded_eal -> ealopts += {eal_opts}',
            opts_dpdk_config,
            flags=re.MULTILINE
        )

    exist = re.search(r'^uploaded_cmd.*->.*$', opts_dpdk_config, flags=re.MULTILINE)
    if not exist:
        opts_dpdk_config += f'uploaded_cmd -> cmdopts += {cmd_opts}\n'
    else:
        opts_dpdk_config = re.sub(
            r'^uploaded_cmd.*->.*$',
            f'uploaded_cmd -> cmdopts += {cmd_opts}',
            opts_dpdk_config,
            flags=re.MULTILINE
        )
    opts_dpdk_config.write_text(opts_dpdk_config)


def update_examples_config(dpdk_opts):
    examples_config_file = Path(f'{t4p4s_location}/examples.cfg')
    examples_config = examples_config_file.read_text()
    exist = re.search(r'^uploaded_switch.*$', examples_config, flags=re.MULTILINE)
    if exist:
        examples_config += f'uploaded_switch {dpdk_opts} uploaded_eal uploaded_cmd\n'
    else:
        examples_config = re.sub(
            r'^uploaded_switch.*$',
            f'uploaded_switch {dpdk_opts} uploaded_eal uploaded_cmd',
            examples_config,
            flags=re.MULTILINE
        )
    examples_config_file.write_text(examples_config)


def update_t4p4s_opts_dpdk(eal_opts, cmd_opts):
    opts_dpdk_fd = Path(f'{t4p4s_location}/opts_dpdk.cfg')
    lines = opts_dpdk_fd.read_text()
    exist = re.search(r'^uploaded_eal.*->.*$', lines, flags=re.MULTILINE)
    if exist:
        lines += f'uploaded_eal -> ealopts += {eal_opts}\n'
    else:
        lines = re.sub(
            r'^uploaded_eal.*->.*$',
            f'uploaded_eal -> ealopts += {eal_opts}',
            lines,
            flags=re.MULTILINE
        )

    exist = re.search(r'^uploaded_cmd.*->.*$', lines, flags=re.MULTILINE)
    if exist:
        lines += f'uploaded_cmd -> cmdopts += {cmd_opts}\n'
    else:
        lines = re.sub(
            r'^uploaded_cmd.*->.*$',
            f'uploaded_cmd -> cmdopts += {cmd_opts}',
            lines,
            flags=re.MULTILINE
        )
    opts_dpdk_fd.write_text(lines)


def update_t4p4s_examples(dpdk_opts):
    examples_fd = Path(f'{t4p4s_location}/examples.cfg')
    lines = examples_fd.read_text()
    exist = re.search(r'^uploaded_switch.*$', lines, flags=re.MULTILINE)
    if exist:
        lines = re.sub(
            r'^uploaded_switch.*$',
            f'uploaded_switch {dpdk_opts} uploaded_eal uploaded_cmd',
            lines,
            flags=re.MULTILINE
        )
    else:
        lines += f'uploaded_switch {dpdk_opts} uploaded_eal uploaded_cmd\n'
    examples_fd.write_text(lines)


def set_t4p4s_switch(example):
    Path('/root/t4p4s-switch').write_text(example)


def restart_web_service():
    try:
        subprocess.call(["systemctl","restart","p4edge-web.service"])
    except:
        pass

def stop_t4p4s_service():
    try:
        subprocess.call(["systemctl","stop","t4p4s.service"])
    except:
        pass

def stop_bmv2_service():
    try:
        subprocess.call(["systemctl","stop","bmv2.service"])
    except:
        pass

def restart_t4p4s_service():
    try:
        subprocess.call(["systemctl","stop","bmv2.service"])
        subprocess.call(["systemctl","disable","bmv2.service"])
    except:
        pass

    try:
        subprocess.check_call(["systemctl", "enable", "t4p4s.service"])
        subprocess.check_call(["systemctl", "restart", "t4p4s.service"])
    except subprocess.CalledProcessError:
        return 'Failed to restart T4P4S service'


def restart_bmv2_service():
    try:
        subprocess.call(["systemctl","stop","t4p4s.service"])
        subprocess.call(["systemctl","disable","t4p4s.service"])
    except:
        pass

    try:
        subprocess.check_call(["systemctl", "enable", "bmv2.service"])
        subprocess.check_call(["systemctl", "restart", "bmv2.service"])
    except subprocess.CalledProcessError:
        return 'Failed to restart BMv2 service'



def upload_p4_program(p4_code, compiler):
    if compiler=="T4P4S":
        Path(f'{t4p4s_location}/examples/uploaded_switch.p4').write_text(p4_code)
        set_t4p4s_switch('uploaded_switch')
        restart_t4p4s_service()
    else:
        Path(f'{bmv2_location}/examples/uploaded_switch/uploaded_switch.p4').write_text(p4_code)
        set_t4p4s_switch('uploaded_switch') 
        restart_bmv2_service()

