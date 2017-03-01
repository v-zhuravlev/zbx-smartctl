#Description
This is the template for Zabbix providing SMART monitoring for HDD using smartctl utility.
*main* branch has the templates for Zabbix 3.0, 2.4 and 2.2. Only devices with SMART enabled will be discovered.

#Installation:
##Linux/BSD/Mac OSX:
- Make sure that smartmontools utils are installed:
- install the script smartctl-disks-discovery.pl in /etc/zabbix/scripts/
- test the script by running it. You should receive JSON object in the script output
- add the following permissions into /etc/sudoers:
```
zabbix ALL= (ALL) NOPASSWD: /usr/sbin/smartctl,/etc/zabbix/scripts/smartctl-disks-discovery.pl
```
Add the following lines in zabbix_agentd.conf file:
```
#############SMARTMON
UserParameter=uHDD[*], sudo smartctl -A $1| grep -i "$2"| tail -1| cut -c 88-|cut -f1 -d' '
UserParameter=uHDD.model.[*],sudo smartctl -i $1 |grep -i "Device Model"| cut -f2 -d: |tr -d " "
UserParameter=uHDD.sn.[*],sudo smartctl -i $1 |grep -i "Serial Number"| cut -f2 -d: |tr -d " "
UserParameter=uHDD.health.[*],sudo smartctl -H $1 |grep -i "test"| cut -f2 -d: |tr -d " "
UserParameter=uHDD.errorlog.[*],sudo smartctl -l error $1 |grep -i "ATA Error Count"| cut -f2 -d: |tr -d " "
UserParameter=uHDD.discovery,sudo /etc/zabbix/scripts/smartctl-disks-discovery.pl
```
###Building deb package
You can create .deb package `zabbix-agent-extra-smartctl` for Debian/Ubuntu distributions:
```shell
dpkg-buildpackage -tc -Zgzip
```

##Windows:
Powershell required.

- Make sure that smartmontools utils are installed:
- install the script smartctl-disks-discovery.ps1
- test the script by running it with
```
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Program Files (x86)\Zabbix Agent\smartctl-disks-discovery.ps1".
```
You should receive JSON object in the output output
- Add the following lines in zabbix_agentd.conf file (note the path to smartctl.exe):
```
#############SMARTMON
UserParameter=uHDD[*], for /F "tokens=10" %a in ('C:\usr\zabbix\smartmontools\bin\smartctl.exe -A $1 ^| find "$2"') do @echo %a
UserParameter=uHDD.health.[*], for /F "tokens=6" %a in ('C:\usr\zabbix\smartmontools\bin\smartctl.exe -H $1 ^| find "test"') do @echo %a
UserParameter=uHDD.model.[*],for /F "tokens=3*" %a in ('C:\usr\zabbix\smartmontools\bin\smartctl.exe -i $1 ^| find "Device Model"') do @echo %a %b
UserParameter=uHDD.sn.[*],for /F "tokens=3" %a in ('C:\usr\zabbix\smartmontools\bin\smartctl.exe -i $1 ^| find "Serial Number"') do @echo %a
UserParameter=uHDD.errorlog.[*], for /F "tokens=4" %a in ('C:\usr\zabbix\smartmontools\bin\smartctl.exe -l error $1 ^| find "ATA Error Count"') do @echo %a
UserParameter=uHDD.discovery,powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Program Files (x86)\Zabbix Agent\smartctl-disks-discovery.ps1"
```

#License
GPL v3 or newer.

#More info:  
http://habrahabr.ru/company/zabbix/blog/196218/  
http://www.lanana.org/docs/device-list/devices-2.6+.txt  
https://www.smartmontools.org/wiki/Supported_RAID-Controllers  
