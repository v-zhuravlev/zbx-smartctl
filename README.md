## Description

This is the template for Zabbix providing SMART monitoring for HDD using smartctl utility.
*main* branch has the template for Zabbix 3.4 with dependendent items support and also old templates for 3.2-3.0, 2.4, 2.2. Only devices with SMART enabled will be discovered.

## Installation

### Linux/BSD/Mac OSX

- Make sure that smartmontools utils are installed:
- (optional) install `sg3-utils` if you need to monitor hardware RAIDs. See [#29](https://github.com/v-zhuravlev/zbx-smartctl/pull/29)
- Install the script smartctl-disks-discovery.pl in /etc/zabbix/scripts/
- Test the script by running it. You should receive JSON object in the script output
- add the following permissions into /etc/sudoers:

```
zabbix ALL= (ALL) NOPASSWD: /usr/sbin/smartctl,/etc/zabbix/scripts/smartctl-disks-discovery.pl
```

Add the following lines in zabbix_agentd.conf file:

```
#############SMARTMONTOOLS
###DEPRECATED. USE for 2.x-3.2 templates
UserParameter=uHDD[*],sudo smartctl -A $1 | awk '$$0 ~ /$2/ { print $$10 }'
UserParameter=uHDD.value[*],sudo smartctl -A $1 | awk '$$0 ~ /$2/ { print $$4 }'
UserParameter=uHDD.raw_value[*],sudo smartctl -A $1 | awk '$$0 ~ /$2/ { print $$10 }'
UserParameter=uHDD.model.[*],sudo smartctl -i $1 | awk -F ': +' '$$0 ~ /Device Model/ { print $$2 }'
UserParameter=uHDD.sn.[*],sudo smartctl -i $1 | awk -F ': +' '$$0 ~ /Serial Number/ { print $$2 }'
UserParameter=uHDD.health.[*],sudo smartctl -H $1 | awk -F ': +' '$$0 ~ /test/ { print $$2 }'
UserParameter=uHDD.errorlog.[*],sudo smartctl -l error $1 |grep -i "ATA Error Count"| cut -f2 -d: |tr -d " " || true
#### 3.4
UserParameter=uHDD.A[*],sudo smartctl -A $1
UserParameter=uHDD.i[*],sudo smartctl -i $1
UserParameter=uHDD.health[*],sudo smartctl -H $1 || true
### Discovery
UserParameter=uHDD.discovery,sudo /etc/zabbix/scripts/smartctl-disks-discovery.pl
```

#### Building deb package

You can create .deb package `zabbix-agent-extra-smartctl` for Debian/Ubuntu distributions:

```shell
dpkg-buildpackage -tc -Zgzip
```

### Windows

Powershell required.

- Make sure that smartmontools utils are installed:
- install the script smartctl-disks-discovery.ps1
- test the script by running it with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Program Files (x86)\Zabbix Agent\smartctl-disks-discovery.ps1".
```

You should receive JSON object in the output.

- Add the following lines in zabbix_agentd.conf file (note the path to smartctl.exe):

```
#############SMARTMON
###DEPRECATED. USE for 2.x-3.2 templates
UserParameter=uHDD[*], for /F "tokens=10 usebackq" %a in (`""%ProgramFiles%\smartmontools\bin\smartctl.exe" -A $1 | find "$2""`) do @echo %a
UserParameter=uHDD.value[*], for /F "tokens=4 usebackq" %a in (`""%ProgramFiles%\smartmontools\bin\smartctl.exe" -A $1 | find "$2""`) do @echo %a
UserParameter=uHDD.raw_value[*], for /F "tokens=10 usebackq" %a in (`""%ProgramFiles%\smartmontools\bin\smartctl.exe" -A $1 | find "$2""`) do @echo %a
UserParameter=uHDD.health.[*], for /F "tokens=6 usebackq" %a in (`""%ProgramFiles%\smartmontools\bin\smartctl.exe" -H $1 | find "test""`) do @echo %a
UserParameter=uHDD.model.[*],for /F "tokens=3*  usebackq" %a in (`""%ProgramFiles%\smartmontools\bin\smartctl.exe" -i $1 | find "Device Model""`) do @echo %a %b
UserParameter=uHDD.sn.[*],for /F "tokens=3 usebackq" %a in (`""%ProgramFiles%\smartmontools\bin\smartctl.exe" -i $1 | find "Serial Number""`) do @echo %a
UserParameter=uHDD.errorlog.[*], for /F "tokens=4 usebackq" %a in (`""%ProgramFiles%\smartmontools\bin\smartctl.exe" -l error $1 | find "ATA Error Count""`) do @echo %a
#### 3.4
UserParameter=uHDD.A[*], for /F "tokens=* usebackq" %a in (`""%ProgramFiles%\smartmontools\bin\smartctl.exe" -A $1"`) do @echo %a
UserParameter=uHDD.i[*], for /F "tokens=* usebackq" %a in (`""%ProgramFiles%\smartmontools\bin\smartctl.exe" -i $1"`) do @echo %a
UserParameter=uHDD.health[*], for /F "tokens=* usebackq" %a in (`""%ProgramFiles%\smartmontools\bin\smartctl.exe" -H $1"`) do @echo %a
### Discovery
UserParameter=uHDD.discovery,powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Program Files (x86)\Zabbix Agent\smartctl-disks-discovery.ps1"
```

## Examples

Items in 3.4:
![image](https://user-images.githubusercontent.com/14870891/30012649-3b1cc758-914a-11e7-82d5-9c80abb1328f.png)

## Contributing

Please keep in mind key concepts when submitting a PR:

- The template should work with Windows, Linux, MacOS.
- Discovery scripts should not have any dependencies (apart from smartctl)
- Discovery scripts deduplicates disks (using serial number as unique id)
- Discovery scripts should output the following set of macros:
  - {#DISKSN} - Disk serial number
  - {#DISKMODEL} - Disk model
  - {#DISKNAME} - Disk name you would like to use in item name
  - {#DISKCMD} - System disk name with -d param to be used in running smartctl
  - {#SMART_ENABLED} - 1 or 0
  - {#DISKTYPE} - 0 - HDD, 1 - SSD, 2 - Other(ODD etc)
  To make sure that the sources of these macro is available everywhere, it is best to use output of `smartctl -i` or `smartctl --scan-open`. Other macros may be added, but try to edit both windows and nix scripts at the same time.


Please also keep in mind things require improvement (welcome!)

- Absolute paths used(especially in Windows(UserParameters,inside powershell script))
- Discovery scripts should probably fail if not run under Admin/root(since its impossible to collect proper data)
- usbjmicron is not implemented in Windows, only in Linux discovery script
- There are no tests. It's nice to run discovery scripts automatically using `/examples` directory contents as mocks. So it's easier to accept PRs. Btw you can also PR your outputs to examples folder
- I don't have MacOS around so sometimes recent changes break stuff there since I can't test it properly 


## Features per platform
|Feature/OS |Linux | Win | MacOS|
|-|-|-|-|
|Discovery with smartctl --scan-open| Y | Y |
|Discovery with sg_scan | Y |  | 
|Disks deduplication by serial number | Y | Y |Y
| Handling usbjmicron (see perl script)|  Y |  |
| SAS disks support |   |  |
| SSD or HHD classification, {#DISKTYPE} | Y | Y |Y 
| {#DISKNAME} | Y | Y |Y 
| {#DISKCMD} | Y | Y |Y 
| {#DISKMODEL} | Y | Y |Y 
| {#DISKSN} | Y | Y |Y 



## License

GPL v3 or newer.

## More info

http://habrahabr.ru/company/zabbix/blog/196218/  
http://www.lanana.org/docs/device-list/devices-2.6+.txt  
https://www.smartmontools.org/wiki/Supported_RAID-Controllers  
