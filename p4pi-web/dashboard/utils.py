import re
from pathlib import Path
import pycountry

t4p4s_location = '/root/t4p4s'

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
    dnsmasq_conf_fd = Path('/etc/dnsmasq.conf')
    lines = dnsmasq_conf_fd.read_text()
    lines = re.sub(
        r'(interface=wlan0.*)(dhcp-range=.*?)$',
        f'\\g<1>dhcp-range={range_min},{range_max},{lease}',
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
    default = ('GB', 'United Kingdom')
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


def save_p4_example(p4CodeBase64):
    pass
