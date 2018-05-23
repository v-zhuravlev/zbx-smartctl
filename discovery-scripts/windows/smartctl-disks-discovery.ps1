$smartctl = "C:\Program Files\smartmontools\bin\smartctl.exe"

if ((Get-Command $smartctl -ErrorAction SilentlyContinue) -eq $null) 
{ 
   write-host "Unable to find smartctl"
   exit
}


$idx = 0

$smart_scanresults = & $smartctl "--scan" 

write-host "{"
write-host " `"data`":[`n"
foreach ($smart_scanresult in $smart_scanresults)
{
 
    
    $smartctl_disk_name = $smart_scanresult.Substring(0,$smart_scanresult.IndexOf(" "))
    $smart_enabled = & $smartctl "-i" $smartctl_disk_name | select-string "SMART.+Enabled$"
 
             if($smart_enabled) {            
                $smart_enabled = 1
            } else {            
                $smart_enabled = 0
            }

    
    if ($idx -lt  $smart_scanresults.Count-1)
    {
        $line= "`t{`n " + "`t`t`"{#DISKNAME}`":`""+$smartctl_disk_name+"`""+ ",`n" + "`t`t`"{#SMART_ENABLED}`":`""+$smart_enabled+"`"" +"`n`t},`n"
        write-host $line
    }
    elseif ($idx -ge  $smart_scanresults.Count-1)
    {
     
        $line= "`t{`n " + "`t`t`"{#DISKNAME}`":`""+$smartctl_disk_name+"`""+ ",`n" + "`t`t`"{#SMART_ENABLED}`":`""+$smart_enabled+"`"" +"`n`t}"
        write-host $line
    }
    $idx++;
}
write-host
write-host " ]"
write-host "}"
