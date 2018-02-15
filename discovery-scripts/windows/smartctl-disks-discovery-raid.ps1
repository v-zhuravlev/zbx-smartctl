$script:smartctl = "C:\Program Files\smartmontools\bin\smartctl.exe"

function GetSMARTDevice()
{
$scan = & $smartctl "--scan"

if ($scan -like "/dev/csmi*") # For Intel Onboard Controllers
{
    $scan=$scan | Select-String -Pattern '/dev/csmi*' 
    $script:scan=$scan -replace ".-d.*"        
    $script:AnzahlGeraete=$scan.count
}
elseif ($scan -like "/dev/sd*") # The other Controllers - At this moment.. maybe there are more Controllertypes.. :)
{
    $scan=$scan | Select-String -Pattern '/dev/sd*'
    $script:scan=$scan -replace ".-d.*"
    $script:AnzahlGeraete=$scan.count
}
}

function createjson($disks,$DeviceCount)
{
$idx =1

write-host "{"
write-host " `"data`":[`n"

Foreach ($smartctl_disk_name in $disks)
{
      #Device-Check
        # If SMART is Enabled, $smart_enabled will be 1.
        # The Value will be used in the Discovery Rule            
        $smart_enabled = & $smartctl "-i" $smartctl_disk_name | select-string "SMART.+Enabled$" 
        if($smart_enabled) {$smart_enabled = 1} 
        else {$smart_enabled = 0}

        # Is it HDD, SSD or ODD
        # The SMART Values for HDD/SSD are different sometimes
        # I have 2 Discovery-Rules with Filtering 0 or 1.                       
        # 0 is for HDD
        # 1 is for SSD
        # 2 is for ODD and will be ignored
        $Drive = & $smartctl "-i" $smartctl_disk_name  | select-string "Rotation Rate:" 
        if($Drive -like "*Solid State Device*") {$DriveType = "1"} 
        elseif ($Drive -like "*rpm*") {$DriveType = "0"}
        else { $DriveType = "2"}
        

        # Device Name
        # If there is a device-description, it will be used
        # If not, the /dev/... Value will be used
        $model=& $smartctl "-a" $smartctl_disk_name | select-string "Device Model:"
        $model=$model -replace "Device Model:"
        $model=$model.trim()            
        if($model) {$model = "$model" } 
        else {$model = "$smartctl_disk_name"}

      #JSON 
        if ($idx -lt $DeviceCount) 
        {                
            $line= "`t{`n " + "`t`t`"{#DISKNAME}`":`""+$smartctl_disk_name+"`""+ ",`n" + "`t`t`"{#SMART_ENABLED}`":`""+$smart_enabled+"`"" +",`n" + "`t`t`"{#SSDODERHDD}`":`""+$DriveType+"`"" +",`n" + "`t`t`"{#DEVICENAME}`":`""+$Model+"`"" +"`n`t},`n"        
            write-host $line
        }

        if ($idx -ge $DeviceCount)
        {
            $line= "`t{`n " + "`t`t`"{#DISKNAME}`":`""+$smartctl_disk_name+"`""+ ",`n" + "`t`t`"{#SMART_ENABLED}`":`""+$smart_enabled+"`"" +",`n" + "`t`t`"{#SSDODERHDD}`":`""+$DriveType+"`"" +",`n" + "`t`t`"{#DEVICENAME}`":`""+$Model+"`"" +"`n`t}`n"        
            write-host $line
        }
            $idx++;

} # End of Foreach

write-host
write-host " ]"
write-host "}"    
} # End Of Function

getsmartdevice
createjson -disks $scan -DeviceCount $AnzahlGeraete