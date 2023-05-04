%{!?examplesroot: %global examplesroot /usr/share/p4pi/t4p4s}
%{!?t4p4sroot: %global t4p4sroot /root/t4p4s}
%{!?bmv2root: %global bmv2root /root/bmv2}
Name:           p4pi-examples
Version:        0.0.0
Release:        0%{?dist}
Summary:        P4Pi examples
License:        Apache 2.0
URL:            https://github.com/p4lang/p4pi
Source0:        %{name}-%{version}.tar.gz
Requires:       p4edge-t4p4s
Packager:       Dávid Kis <kidraai@.inf.elte.hu>

%description
P4Pi examples

%prep
%autosetup

%build

%install

rm -rf %{buildroot}

mkdir -p %{buildroot}%{examplesroot}
cp -r t4p4s/arp_icmp/ %{buildroot}%{examplesroot}
cp -r t4p4s/calc/ %{buildroot}%{examplesroot}
cp -r t4p4s/l2switch/ %{buildroot}%{examplesroot}
cp -r t4p4s/stateful_firewall/ %{buildroot}%{examplesroot}
cp -r t4p4s/traffic_filter/ %{buildroot}%{examplesroot}
cp -r t4p4s/basic_mirror/ %{buildroot}%{examplesroot}
cp -r t4p4s/reflector/ %{buildroot}%{examplesroot}
%ifarch arm64
cp pi-examples.cfg %{buildroot}%{examplesroot}
%else
cp apu-examples.cfg %{buildroot}%{examplesroot}
%endif

mkdir -p %{buildroot}%{bmv2root}/bin
mkdir -p %{buildroot}%{bmv2root}/examples/uploaded_switch

cp -r bmv2/arp_icmp/ %{buildroot}%{bmv2root}/examples
cp -r bmv2/calc/ %{buildroot}%{bmv2root}/examples
cp -r bmv2/l2switch/ %{buildroot}%{bmv2root}/examples
cp -r bmv2/stateful_firewall/ %{buildroot}%{bmv2root}/examples
cp -r bmv2/traffic_filter/ %{buildroot}%{bmv2root}/examples
cp -r bmv2/basic_mirror/ %{buildroot}%{bmv2root}/examples
cp -r bmv2/reflector/ %{buildroot}%{bmv2root}/examples

%post
ln -s %{examplesroot} %{t4p4sroot}/examples/p4pi

%files
%{examplesroot}/arp_icmp/*
%{examplesroot}/calc/*
%{examplesroot}/l2switch/*
%{examplesroot}/stateful_firewall/*
%{examplesroot}/traffic_filter/*
%{examplesroot}/basic_mirror/*
%{examplesroot}/reflector/*
%{examplesroot}/*.cfg
%{bmv2root}/*
