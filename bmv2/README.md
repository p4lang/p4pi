# BMV2

## Compilation (~1-1.5h)

Latest stable branch is a little bit outdated, so use the main branch:
```bash
git clone --depth=1 https://github.com/p4lang/behavioral-model
```
Thrift 0.11 can be installed as a package to save time(not much).
If compiling add `LDFLAGS="-latomic"` to the end of configure in `travis/install-thrift.sh`

AFAIK manual linkage of the atomic lib is needed because it is not supported by the hardware, only by software so it can't be done by header only template magic. The configure script check for the need of the flag but somehow it still fail to use it.

```bash
./install_deps.sh
./autogen.sh
./configure LDFLAGS="-latomic"
make -j4
sudo make install
sudo ldconfig
```
## Run
Compile basic_mirror.p4, transfer the produced json and run the switch:
```bash
sudo simple_switch -i 0@eth0 basic_mirror.json
```

