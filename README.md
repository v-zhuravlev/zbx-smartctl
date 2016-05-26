#Description
This is the template for Zabbix providing SMART monitoring for HDD using smartctl utility.  
*main* branch has the template for Zabbix 3.0. Check other project's branches for [Zabbix 2.4](https://github.com/v-zhuravlev/zbx-smartctl/tree/zabbix2.4_template) and [Zabbix 2.2](https://github.com/v-zhuravlev/zbx-smartctl/tree/zabbix2.2_template) templates  
LLD is used for disks discovery.  Only devices with SMART enabled will be discovered.

#Installation:  
##Linux:  
- Make sure that smartmontools utils are installed:
- install the script smartctl-disks-discovery.pl in /usr/local/bin/
- test the script by running it. You should receive JSON object in the script output
- add the following permissions into /etc/sudoers:  
```
zabbix ALL= (ALL) NOPASSWD: /usr/sbin/smartctl,/usr/local/bin/smartctl-disks-discovery.pl
```
Add the following lines in zabbix_agentd.conf file:  
```
#############SMARTMON
UserParameter=uHDD[*], sudo smartctl -A /dev/$1| grep "$2"| tail -1| cut -c 88-|cut -f1 -d' '
UserParameter=uHDD.model.[*],sudo smartctl -i /dev/$1 |grep "Device Model"| cut -f2 -d: |tr -d " "
UserParameter=uHDD.sn.[*],sudo smartctl -i /dev/$1 |grep "Serial Number"| cut -f2 -d: |tr -d " "
UserParameter=uHDD.health.[*],sudo smartctl -H /dev/$1 |grep "test"| cut -f2 -d: |tr -d " "
UserParameter=uHDD.errorlog.[*],sudo smartctl -l error /dev/$1 |grep "ATA Error Count"| cut -f2 -d: |tr -d " "
UserParameter=uHDD.discovery,sudo /usr/local/bin/smartctl-disks-discovery.pl
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
UserParameter=uHDD[*], for /F "tokens=10" %a in ('C:\usr\zabbix\smartmontools\bin\smartctl.exe -A "$1" ^| find "$2"') do @echo %a
UserParameter=uHDD.health.[*], for /F "tokens=6" %a in ('C:\usr\zabbix\smartmontools\bin\smartctl.exe -H "$1" ^| find "test"') do @echo %a
UserParameter=uHDD.model.[*],for /F "tokens=3*" %a in ('C:\usr\zabbix\smartmontools\bin\smartctl.exe -i "$1" ^| find "Device Model"') do @echo %a %b
UserParameter=uHDD.sn.[*],for /F "tokens=3" %a in ('C:\usr\zabbix\smartmontools\bin\smartctl.exe -i "$1" ^| find "Serial Number"') do @echo %a
UserParameter=uHDD.errorlog.[*], for /F "tokens=4" %a in ('C:\usr\zabbix\smartmontools\bin\smartctl.exe -l error "$1" ^| find "ATA Error Count"') do @echo %a
UserParameter=uHDD.discovery,"C:\Program Files (x86)\Zabbix Agent\smartctl-disks-discovery.bat"
```


##MAC OSX: 
zabbix_agentd_osx_installer https://github.com/mipmip/zabbix_agentd_osx_installer/releases  
- Make sure that smartmontools utils are installed:
smartmontools_osx_installer  http://builds.smartmontools.org/   
- install the script smartctl-disks-discovery.pl in /usr/local/bin/
- test the script by running it. You should receive JSON object in the script output

Add the following lines in zabbix_agentd.conf file:  
```
#############SMARTMON
UserParameter=uHDD[*],smartctl -A /dev/$1| grep "$2"| tail -1| cut -c 88-|cut -f1 -d' '
UserParameter=uHDD.model.[*],smartctl -i /dev/$1 |grep "Device Model"| cut -f2 -d: |tr -d " "
UserParameter=uHDD.sn.[*],smartctl -i /dev/$1 |grep "Serial Number"| cut -f2 -d: |tr -d " "
UserParameter=uHDD.health.[*],smartctl -H /dev/$1 |grep "test"| cut -f2 -d: |tr -d " "
UserParameter=uHDD.errorlog.[*],smartctl -l error /dev/$1 |grep "ATA Error Count"| cut -f2 -d: |tr -d " "
UserParameter=uHDD.discovery,/usr/local/bin/smartctl-disks-discovery.pl
```
#More info:  
http://habrahabr.ru/company/zabbix/blog/196218/  
