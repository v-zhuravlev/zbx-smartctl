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
        for (`$smartctl_cmd --scan-open`) {
            #splitting lines like  "/dev/sda -d scsi # /dev/sda, SCSI device"
                                  #"/dev/sda [SAT] -d sat [ATA] (opened)" # in debian 6 and smartctl 5.4
                                  #"/dev/sda -d sat # /dev/sda [SAT], ATA device" # in debian 8 and smartctl 6.4
                                  #"/dev/bus/0 -d megaraid,01" for megaraid
            my $disk_name = (split / /, $_)[0];
            my ($disk_args) = $_ =~ /(-d [A-Za-z0-9,]+)/;
                push @disks,$disk_name.q{ }.$disk_args;

        }
}

#print "Disks are @disks";
print "{\n";
print "\t\"data\":[\n\n";

@serials;
DISKLOOP:foreach my $disk (@disks) {
    #DISK LOOP
    $smart_enabled      = 0;

    chomp($disk);
    #SMART STATUS LOOP
    foreach $line (`$smartctl_cmd -i $disk`) {
        #Some disks have "Number" and some "number", so
        if ($line =~ /^Serial (N|n)umber: +(.+)$/) {
            #print "Serial number is ".$2."\n";
            if (grep /$2/,@serials) {
                #print "disk already exist skipping\n";
                next DISKLOOP;
            }
            else {
                push @serials,$2;
            }
        } elsif ($line =~ /^SMART.+?: +(.+)$/)  {
            #print "$1\n";

            if ( $1 =~ /Enabled/ ) {
                $smart_enabled = 1;
            }
            #if SMART is disabled then try to enable it (also offline tests etc)
            elsif ( $1 =~ /Disabled/ ) {
                foreach (`smartctl -s on -o on -S on $disk`) {
                    if (/SMART Enabled/) {  $smart_enabled = 1; }
                }
            }
        }
    }

    print ",\n" if not $first;
    $first = 0;
    print "\t\t{\n";
    print "\t\t\t\"{#DISKNAME}\":\"$disk\",\n";
    print "\t\t\t\"{#SMART_ENABLED}\":\"$smart_enabled\"\n";
    print "\t\t}";

}

print "\n\t]\n";
print "}\n";
