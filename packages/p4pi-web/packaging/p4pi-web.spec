%{!?srvdir: %global srvdir /srv/p4pi}
Name:           p4pi-web
Version:        0.0.0
Release:        0%{?dist}
Summary:        Web UI for P4Pi
License:        Apache 2.0
URL:            https://github.com/p4lang/p4pi
Source0:        %{name}-%{version}.tar.gz
BuildArch:      noarch
Requires:       python3, python3-pip, lm-sensors, ifstat
Requires:       p4lang-bmv2, p4edge-t4p4s, p4pi-examples
BuildRequires:  debbuild-macros-systemd
Packager:       Dávid Kis <kidraai@.inf.elte.hu>

%description
Web UI for P4Pi

%prep
%autosetup

%build

%install
rm -rf %{buildroot}

mkdir -p %{buildroot}%{srvdir}
cp -r config/ %{buildroot}%{srvdir}
cp -r dashboard/ %{buildroot}%{srvdir}
cp -r terminal/ %{buildroot}%{srvdir}
cp -r fixtures/ %{buildroot}%{srvdir}
cp gunicorn-cfg.py %{buildroot}%{srvdir}
cp manage.py %{buildroot}%{srvdir}
cp poetry.lock %{buildroot}%{srvdir}
cp pyproject.toml %{buildroot}%{srvdir}
cp requirements.txt %{buildroot}%{srvdir}
cp .editorconfig %{buildroot}%{srvdir}
cp dummy_ctrl_plane_connection.py %{buildroot}%{srvdir}
cp generate-statistics.py %{buildroot}%{srvdir}

mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{_unitdir}

install -m 755 packaging/bmv2-start %{buildroot}%{_bindir}
install -m 755 packaging/bmv2-p4rtshell %{buildroot}%{_bindir}
install -m 644 packaging/bmv2.service %{buildroot}%{_unitdir}
install -m 644 packaging/%{name}.service %{buildroot}%{_unitdir}
install -m 644 packaging/%{name}-genstat.service %{buildroot}%{_unitdir}
install -m 644 packaging/%{name}-dummy-ctrl-plane.service %{buildroot}%{_unitdir}

%post
cat > %{srvdir}/.env << EOF
DEBUG=TRUE
ALLOWED_HOSTS=["*"]
SECRET_KEY=`python3 -c "import secrets; print(secrets.token_urlsafe())"`
SQLITE_PATH=%{srvdir}/db.sqlite3
EOF

python3 -m pip install -r %{srvdir}/requirements.txt
python3 -m pip install p4runtime-shell

cd %{srvdir}
python3 -m django migrate --settings=config.settings
python3 -m django loaddata fixtures/users.json --settings=config.settings

%systemd_post %{name}.service
%systemd_post %{name}-genstat.service
%systemd_post %{name}-dummy-ctrl-plane.service
%systemd_post bmv2.service

%preun
%systemd_preun %{name}.service
%systemd_preun %{name}-genstat.service
%systemd_preun %{name}-dummy-ctrl-plane.service
%systemd_preun bmv2.service

%postun
%systemd_postun %{name}.service
%systemd_postun %{name}-genstat.service
%systemd_postun %{name}-dummy-ctrl-plane.service
%systemd_postun bmv2.service

%files
%{srvdir}/*
%{srvdir}/.editorconfig
%{_unitdir}/%{name}.service
%{_unitdir}/%{name}-genstat.service
%{_unitdir}/%{name}-dummy-ctrl-plane.service
%{_unitdir}/bmv2.service
%{_bindir}/bmv2-start
%{_bindir}/bmv2-p4rtshell
