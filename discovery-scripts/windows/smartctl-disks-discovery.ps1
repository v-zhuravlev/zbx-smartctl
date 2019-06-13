# VERSION = 1.5
$smartctl = "$Env:Programfiles\smartmontools\bin\smartctl.exe"

if ((Get-Command $smartctl -ErrorAction SilentlyContinue) -eq $null)
{ 
   write-host "Unable to find smartctl. Check that smartmontools package is installed"
   exit
}


$idx = 0
$global_serials
$smart_scanresults = & $smartctl "--scan-open"
$smart_scanresults += & $smartctl "--scan-open" "-dnvme"

$json = ""

write-host "{"
write-host " `"data`":["
foreach ($smart_scanresult in $smart_scanresults)
{
    
    $idx++;
    $disk_args = ""
    $disk_name = ""
    $disk_type = "2"
    $disk_model = ""
    $disk_sn = ""

    if ($smart_scanresult -match '(-d) ([A-Za-z0-9,\+]+)'){
        $disk_args = $matches[1]+$matches[2]
    }
    
    $disk_name = $smart_scanresult.Substring(0,$smart_scanresult.IndexOf(" "))
    $line = & $smartctl "-i" $disk_name $disk_args
    
    #smart enabled?
    $smart_enabled = $line | select-string "SMART.+Enabled$"
    if($smart_enabled) {
        $smart_enabled = 1
    } else {
        $smart_enabled = 0
    }

    if($disk_args -like "*nvme*" -or $disk_name -like "*nvme*" ) {
        $disk_type = "1"
        $smart_enabled = 1
    }


    # Device sn
    $sn = $line | select-string "serial number:"
    $sn = $sn -ireplace "serial number:"

    # Device Model
    $model = [string] ""
    $model= $line | select-string "Device Model:"
    $model=$model -replace "Device Model:"
    if ($model)
    {
        $disk_model=$model.trim()
    }
    # Model Number
    $model = [string] ""
    $model= $line | select-string "Model Number:"
    $model=$model -replace "Model Number:"
    if ($model)
    {
        $disk_model=$model.trim()
    }
    # Device Model(for SAS)
    $model= $line | select-string "Vendor:"
    $model=$model -replace "Vendor:"
    if ($model)
    {
        $disk_model=$model.trim()
    }
    $model= $line | select-string "Product:"
    $model=$model -replace "Product:"
    if ($model)
    {
        $disk_model+=" "+$model.trim()
    }
    
    
    # Is it HDD, SSD/NVMe or ODD
    # The SMART Values for HDD/SSD are different sometimes
    # I have 2 Discovery-Rules with Filtering 0 or 1.
    # 0 is for HDD
    # 1 is for SSD/NVMe
    # 2 is for ODD and will be ignored
    $Drive = $line  | select-string "Rotation Rate:" 
    if($Drive -like "*Solid State Device*") {$disk_type = "1"}
    elseif ($Drive -like "*rpm*") {$disk_type = "0"}
    
    if($disk_type -eq "2") { 
        #Can't determine, lets go extended
        $extended_line = & $smartctl "-a" $disk_name $disk_args
        
        #search for Spin_Up_Time or Spin_Retry_Count
        if ($extended_line  | select-string "Spin_" -CaseSensitive){
            $disk_type = "0"
        }
        #search for SSD in uppercase
        elseif ($extended_line  | select-string " SSD " -CaseSensitive){
            $disk_type = "1"
        }
        #search for NVMe
        elseif ($extended_line  | select-string "NVMe" -CaseSensitive){
            $disk_type = "1"
            $smart_enabled = "1"
        }
        elseif ($extended_line | select-string "177 Wear_Leveling" -CaseSensitive) {
            $disk_type = "1"
        }
        elseif ($extended_line | select-string "231 SSD_Life_Left" -CaseSensitive) {
            $disk_type = "1"
        }
        elseif ($extended_line | select-string "233 Media_Wearout_" -CaseSensitive) {
            $disk_type = "1"
        }
    }

    if ($sn) {
        $disk_sn=$sn.trim()
    
        if ($global_serials -contains $disk_sn ){
            continue
            #skip duplicated disk, go to next one
        } else {
            #add only smart capable disks to global serials
            if ($smart_enabled -eq 1){
                $global_serials+=$disk_sn
            }
        }
    }


    if ($idx -eq 1)
    {

    } else
    {
        $json +=  ",`n"
    }
    
    $json += "`t {`n " +
            "`t`t`"{#DISKSN}`":`""+$disk_sn+"`""+ ",`n" +
            "`t`t`"{#DISKMODEL}`":`""+$disk_model+"`""+ ",`n" +
            "`t`t`"{#DISKNAME}`":`""+$disk_name+"`""+ ",`n" +
            "`t`t`"{#DISKCMD}`":`""+$disk_name+" "+$disk_args+"`"" +",`n" +
            "`t`t`"{#SMART_ENABLED}`":`""+$smart_enabled+"`"" +",`n" +
            "`t`t`"{#DISKTYPE}`":`""+$disk_type+"`"" +"`n" +
           "`t }"


}
write-host $json
write-host " ]"
write-host "}"
