#!/usr/bin/perl

#must be run as root
$first = 1;

#add path if needed into $smartctl_cmd
$smartctl_cmd = "smartctl";

my @disks;
if ($^O eq 'darwin') { # if MAC OSX

        while (glob( '/dev/disk*' )) {
            if ($_ =~ /\/(disk+[0-9])$/) {push @disks,$1;}
        }
}
else {
        for (`$smartctl_cmd --scan`) {
            #splitting line like "/dev/sda -d scsi # /dev/sda, SCSI device"
            $disk_path = ( split(/ /) )[0];
            $disk = ( split( /\//, $disk_path ) )[2];
            chomp($disk);
            push @disks,$disk;
        }
}

#print "Disks are @disks";
print "{\n";
print "\t\"data\":[\n\n";

foreach my $disk (@disks) {


    #DISK LOOP
    $smart_avail        = 0;
    $smart_enabled      = 0;
    $smart_enable_tried = 0;
    chomp($disk);

    print ",\n" if not $first;
    $first = 0;

    #SMART STATUS LOOP
    foreach (`$smartctl_cmd -i /dev/$disk | grep SMART`) {

        $line = $_;

        # if SMART available -> continue
        if ( $line = /Available/ ) {
            $smart_avail = 1;
            next;
        }

        #if SMART is disabled then try to enable it (also offline tests etc)
        if ( $line = /Disabled/ & $smart_enable_tried == 0 ) {

            foreach (`smartctl -i /dev/$disk -s on -o on -S on | grep SMART`) {

                if (/SMART Enabled/) {
                    $smart_enabled = 1;
                    next;
                }
            }
            $smart_enable_tried = 1;
        }

        if ( $line = /Enabled/ ) {
            $smart_enabled = 1;
        }

    }

    print "\t\t{\n";
    print "\t\t\t\"{#DISKNAME}\":\"$disk\",\n";
    print "\t\t\t\"{#SMART_ENABLED}\":\"$smart_enabled\"\n";
    print "\t\t}";

}

print "\n\t]\n";
print "}\n";
