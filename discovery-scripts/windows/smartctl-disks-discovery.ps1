$smartctl = "C:\Program Files\smartmontools\bin\smartctl.exe"

if ((Get-Command $smartctl -ErrorAction SilentlyContinue) -eq $null) 
{ 
   write-host "Unable to find smartctl"
   exit
}


$idx = 0
$global_serials
$smart_scanresults = & $smartctl "--scan-open" 


write-host "{"
write-host " `"data`":[`n"
foreach ($smart_scanresult in $smart_scanresults)
{
    
    $idx++;
    $disk_args = ""
    $disk_name = ""
    $disk_type = ""
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


    # Device sn
    $sn = $line | select-string "serial number:"
    $sn = $sn -ireplace "serial number:"
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
    # Device Model
    $model= $line | select-string "Device Model:"
    $model=$model -replace "Device Model:"
    if ($model) {
    $disk_model=$model.trim() 
    }   
    

    # Is it HDD, SSD or ODD
    # The SMART Values for HDD/SSD are different sometimes
    # I have 2 Discovery-Rules with Filtering 0 or 1.                       
    # 0 is for HDD
    # 1 is for SSD
    # 2 is for ODD and will be ignored
    $Drive = $line  | select-string "Rotation Rate:" 
    if($Drive -like "*Solid State Device*") {$disk_type = "1"} 
    elseif ($Drive -like "*rpm*") {$disk_type = "0"}
    else { 
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
        else {
            $disk_type = "2"
        }
    }

         

    $jsonline= "`t{`n " +
            "`t`t`"{#DISKSN}`":`""+$disk_sn+"`""+ ",`n" +        
            "`t`t`"{#DISKMODEL}`":`""+$disk_model+"`""+ ",`n" +        
            "`t`t`"{#DISKNAME}`":`""+$disk_name+"`""+ ",`n" +
            "`t`t`"{#DISKCMD}`":`""+$disk_name+" "+$disk_args+"`"" +",`n" + 
            "`t`t`"{#SMART_ENABLED}`":`""+$smart_enabled+"`"" +",`n" +
            "`t`t`"{#DISKTYPE}`":`""+$disk_type+"`"" +"`n`t" +
           "}"
    if ($idx -lt  $smart_scanresults.Count)
    {
        $jsonline += ",`n"
    }
    write-host $jsonline
    
}
write-host
write-host " ]"
write-host "}"
