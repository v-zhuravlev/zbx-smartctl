# zbx-smartctl

## Description

This is the template and discovery scripts for monitoring disks SMART attributes using smartmontools in Zabbix.  
Zabbix server 3.4+ is recommended with dependendent items support but there are also older templates for 3.2, 3.0, 2.4, 2.2 provided as is. Discovery scripts should work with them too.

### Main features

- Supports SATA, SAS and NVMe devices
- Disks discovery:
  - Two discovery scripts - for Linux/BSD/MacOS and Windows
  - Simple discovery in MacOS by scanning `/dev/disk/*` (macos)
  - Discover with `smartctl --scan-open` (nix, windows)
  - Discover NVMe devices with `smartctl --scan-open -dnvme` (nix, windows)
  - Discover Hardware RAID with `sg_scan` (nix only)
  - Discover NVMe devices with `nvme-cli` (nix only)
  - Handling usbjmicron (nix only)
  - Handling Areca SATA RAID (nix only)
  - Try to enable SMART if it is disabled(nix, macos, windows)
  - (new) static discovery (nix only)
  - HDD(0), SSD/NVMe(1), `other`(2) classification in {#DISKTYPE} macro (nix, macos, windows)
  - LLD macros in output: {#DISKNAME}, {#DISKCMD}, {#DISKTYPE}, {#DISKMODEL}, {#DISKSN}. {#SMART_ENABLED} (nix, macos, windows)
- Templates:
  - For all templates:
    - Zabbix agent required with UserParameter
    - LLD discovery of disks
    - 'Problems first' approach. Collect items that can help to detect disk failures
    - Skip disks if SMART_ENABLED != 1
    - SATA devices support
  - 3.4+ template:
    - Two discovery rules: for HDD and SSD/NVMe to reduce the number of unsupported
    - Server side regex parsing, so, very simple UserParameters in agent configs
    - No excessive calls to disks. Collect all items in the single smartctl run
    - SAS devices support
    - NVMe devices support
    - Static discovery support with {$SMARTCTL_STATIC_DISKS}

#### About static discovery

Static discovery is useful for disks that cannot be easily discovered, such as disks hidden behind some hardware RAIDs or when agent is installed on Windows or Mac where automatic discovery is not so powerful.

`{$SMARTCTL_STATIC_DISKS}` - If some disks cannot be discovered automatically no matter how hard you try, you can add additional disks with -d option in this macro on the host level. Such disks will be discovered in addition to any disks that will be discovered with smartctl --scan-open, sg_scan and so on.

Replace all spaces with `_` inside each disk command. Separate multiple disks with space ' '.
For example, to discover 2 drives behind hardware RAID, set this macro on the host level:

`{$SMARTCTL_STATIC_DISKS} = /dev/sda_-d_sat+megaraid,00 /dev/sda_-d_sat+megaraid,01`

## Installation

### Linux/BSD/Mac OSX

- Make sure that smartmontools package is installed
- (optional) Install `sg3-utils` if you need to monitor hardware RAIDs. See [#29](https://github.com/v-zhuravlev/zbx-smartctl/pull/29)
- (optional) Install `nvme-cli` if you need to monitor NVMe devices.  
- Copy the following contents of `sudoers_zabbix_smartctl` file to `/etc/sudoers.d/sudoers_zabbix_smartctl`:

```text
Cmnd_Alias SMARTCTL = /usr/sbin/smartctl
Cmnd_Alias SMARTCTL_DISCOVERY = /etc/zabbix/scripts/smartctl-disks-discovery.pl
zabbix ALL= (ALL) NOPASSWD: SMARTCTL, SMARTCTL_DISCOVERY
Defaults!SMARTCTL !logfile, !syslog, !pam_session
Defaults!SMARTCTL_DISCOVERY !logfile, !syslog, !pam_session
```

- Copy `zabbix_smartctl.conf` to `/etc/zabbix/zabbix_agentd.d`
- Copy script `smartctl-disks-discovery.pl` to `/etc/zabbix/scripts`
  - Then run
  
```text
chown zabbix:zabbix /etc/zabbix/scripts/smartctl-disks-discovery.pl
chmod u+x /etc/zabbix/scripts/smartctl-disks-discovery.pl
```

- Test the discovery script by running it as sudo. You should receive JSON object in the script output.
- Restart zabbix-agent


#### Building deb package

You can create .deb package `zabbix-agent-extra-smartctl` for Debian/Ubuntu distributions:

```shell
dpkg-buildpackage -tc -Zgzip
```

#### Ansible playbook

There is an ansible playbook available in this repo, feel free to try it.

### Windows

- Install [smartmontools](https://www.smartmontools.org/wiki/Download#InstalltheWindowspackage), prefer default installation path
- Install Zabbix agent using [official MSI package](https://www.zabbix.com/download_agents), prefer default installation path
- Copy script `smartctl-disks-discovery.ps1` to `Zabbix Agent` folder
- Copy file `zabbix_smartctl.win.conf` to `Zabbix Agent\zabbix_agentd.conf.d` folder
  - Check that path to smartmontools bin folder and to discovery script `smartctl-disks-discovery.ps1` are correct
- Restart Zabbix Agent service
- Test items
  - Test discovery and retrieval of disks data:

```text
PS C:\Program Files\Zabbix Agent> .\zabbix_agentd.exe -c .\zabbix_agentd.conf -t uHDD.discovery
uHDD.discovery                                [t|{
 "data":[
         {
                "{#DISKSN}":"ZZZZZZZZZZZZ",
                "{#DISKMODEL}":"THNSN5512GPUK TOSHIBA",
                "{#DISKNAME}":"/dev/sda",
                "{#DISKCMD}":"/dev/sda -dnvme",
                "{#SMART_ENABLED}":"0",
                "{#DISKTYPE}":"1"
         }
 ]
}]
PS C:\Program Files\Zabbix Agent> .\zabbix_agentd.exe -c .\zabbix_agentd.conf -t uHDD.get["/dev/sda -d nvme"]
uHDD.get[/dev/nvme1]                          [t|smartctl 6.6 2017-11-05 r4594 [x86_64-w64-mingw32-w10-b17134] (sf-6.6-1)..DISK OUTPUT HERE.....]
```


## Examples

Items in 3.4:
![image](https://user-images.githubusercontent.com/14870891/30012649-3b1cc758-914a-11e7-82d5-9c80abb1328f.png)
Catch SSD problems in Zabbix 2.4:
![image](https://user-images.githubusercontent.com/14870891/45471572-30d43580-b73a-11e8-8aa9-6d3260162ef3.png)

## Contributing

Please keep in mind key concepts when submitting a PR:

- The template should work with Windows, Linux, MacOS.
- Discovery scripts should not have any dependencies (apart from smartctl)
- Discovery scripts should deduplicate disks (using serial number as unique id)
- Discovery scripts should output the following set of macros:
  - {#DISKSN} - Disk serial number
  - {#DISKMODEL} - Disk model
  - {#DISKNAME} - Disk name you would like to use in item name
  - {#DISKCMD} - System disk name with -d param to be used in running smartctl
  - {#SMART_ENABLED} - 1 or 0
  - {#DISKTYPE} - 0 - HDD, 1 - SSD/NVMe, 2 - Other(ODD etc)
  
  To make sure that the sources of these macro is available everywhere, it is best to use output of `smartctl -i` or `smartctl --scan-open`. Other macros may be added, but try to edit both windows and nix scripts at the same time.

Please also keep in mind things that require improvement (welcome!)

- Absolute paths used(especially in Windows(UserParameters,inside powershell script))
- Discovery script should probably fail if not run under Admin/root(since its impossible to collect proper data)
- usbjmicron is not implemented in Windows, only in Linux discovery script
- There are no proper tests. It's nice to run discovery scripts automatically using `/tests/examples` directory contents as mocks. So it's easier to accept PRs. BTW you can also PR your outputs to examples folder
- MacOS disks discovery is very limited. Feel free to improve it.

## Troubleshooting

1. SELinux. Turn it off or add a selinux policy:

```text
yum install policycoreutils-python
semanage permissive -a zabbix_agent_t
semodule -DB
# from zabbox_server issue:
zabbix_get -s host -k uHDD.discovery
zabbix_get -s host -k uHDD.get[/dev/sda]

cat /var/log/audit/audit.log | grep zabbix_agent_t | grep denied | audit2allow -M zabbix_smartctl
semodule -i zabbix_smartctl.pp
semanage permissive -d zabbix_agent_t
semodule -B
```

## License

GPL v3 or newer.

## More info

http://habrahabr.ru/company/zabbix/blog/196218/  
http://www.lanana.org/docs/device-list/devices-2.6+.txt  
https://www.smartmontools.org/wiki/Supported_RAID-Controllers  
https://www.percona.com/blog/2017/02/09/using-nvme-command-line-tools-to-check-nvme-flash-health/
