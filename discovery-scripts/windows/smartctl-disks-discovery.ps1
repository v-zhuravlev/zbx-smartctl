$smartctl = "C:\Program Files\smartmontools\bin\smartctl.exe"

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

    
    if ($idx -lt $disks.Count-1)
    {
        $line= "`t{`n " + "`t`t`"{#DISKNAME}`":`""+$smartctl_disk_name+"`""+ ",`n" + "`t`t`"{#SMART_ENABLED}`":`""+$smart_enabled+"`"" +"`n`t},`n"
        write-host $line
    }
    elseif ($idx -ge $disks.Count-1)
    {
     
        $line= "`t{`n " + "`t`t`"{#DISKNAME}`":`""+$smartctl_disk_name+"`""+ ",`n" + "`t`t`"{#SMART_ENABLED}`":`""+$smart_enabled+"`"" +"`n`t}"
        write-host $line
    }
    $idx++;
}
write-host
write-host " ]"
write-host "}"
