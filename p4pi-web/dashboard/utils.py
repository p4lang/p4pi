import re
from pathlib import Path
import pycountry


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
