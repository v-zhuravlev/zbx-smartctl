$smartctl = "C:\Zabbix\smartmontools\bin\smartctl.exe"

if ((Get-Command $smartctl -ErrorAction SilentlyContinue) -eq $null) 
{ 
   write-host "Unable to find smartctl"
   exit
}

$disks = GET-WMIOBJECT -query "SELECT * from win32_diskdrive"
$idx = 0

[char[]] $abc_array = ([char]'a'..[char]'z')

write-host "{"
write-host " `"data`":[`n"
foreach ($disk in $disks)
{
 
    $smartctl_disk_name = "/dev/hd" + $abc_array[$idx]
    $smart_enabled = & $smartctl "-i" $smartctl_disk_name | select-string "SMART.+Enabled$"
 
             if($smart_enabled) {            
                $smart_enabled = 1
            } else {            
                $smart_enabled = 0
            }

    $disk_type = $disk.Model

             if($disk_type -match 'SSD|KINGSTON') {            
                $disk_type = 0
            } else {            
                $disk_type = 1
            }     


    
    if ($idx -lt $disks.Count-1)
    {
        $line= "`t{`n " + "`t`t`"{#DISKNAME}`":`""+$smartctl_disk_name+"`""+ ",`n" + "`t`t`"{#DISK_STATUS}`":`""+$smart_enabled+","+$disk_type+"`"" +"`n`t},`n"
        write-host $line
    }
    elseif ($idx -ge $disks.Count-1)
    {
     
        $line= "`t{`n " + "`t`t`"{#DISKNAME}`":`""+$smartctl_disk_name+"`""+ ",`n" + "`t`t`"{#DISK_STATUS}`":`""+$smart_enabled+","+$disk_type+"`"" +"`n`t}"
        write-host $line
    }
    $idx++;
}
write-host
write-host " ]"
write-host "}"
