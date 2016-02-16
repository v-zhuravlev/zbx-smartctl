#!/usr/bin/perl

#must be run as root

$first = 1;

print "{\n";
print "\t\"data\":[\n\n";

for (`ls -l /dev/disk/by-id/ | cut -d"/" -f3 | sort -n | uniq -w 3`)
{
#DISK LOOP
$smart_avail=0;
$smart_enabled=0;
$smart_enable_tried=0;

#next when total 0 at output
        if ($_ eq "total 0\n")
                {
                        next;
                }

    print "\t,\n" if not $first;
    $first = 0;

$disk =$_;
chomp($disk);

#SMART STATUS LOOP
foreach(`smartctl -i /dev/$disk | grep SMART`)
{

$line=$_;

        # if SMART available -> continue
        if ($line = /Available/){
                $smart_avail=1;
                next;
                        }

        #if SMART is disabled then try to enable it (also offline tests etc)
        if ($line = /Disabled/ & $smart_enable_tried == 0){

                foreach(`smartctl -i /dev/$disk -s on -o on -S on | grep SMART`) {

                        if (/SMART Enabled/){
                                $smart_enabled=1;
                                next;
                        }
                }
        $smart_enable_tried=1;
        }

        if ($line = /Enabled/){
        $smart_enabled=1;
        }


}

    print "\t{\n";
    print "\t\t\"{#DISKNAME}\":\"$disk\",\n";
    print "\t\t\"{#SMART_ENABLED}\":\"$smart_enabled\"\n";
    print "\t}\n";

}

print "\n\t]\n";
print "}\n";
