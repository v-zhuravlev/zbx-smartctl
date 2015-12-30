#Description
This is the template for Zabbix providing SMART monitoring for HDD using smartctl utility.  
Please note that current version has item and application names in Russian.  
LLD is used for disks discovery.  

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
TBD. Only non LLD version only available.  


#More info:  
http://habrahabr.ru/company/zabbix/blog/196218/  
