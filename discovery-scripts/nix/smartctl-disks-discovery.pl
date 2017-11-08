#!/usr/bin/perl
use warnings;
use strict;


#must be run as root
my $VERSION = 0.9;

#add path if needed into $smartctl_cmd
my $smartctl_cmd = "/usr/sbin/smartctl";
my @input_disks;
my @global_serials;
my @smart_disks;

if ( $^O eq 'darwin' ) {    # if MAC OSX

    while ( glob('/dev/disk*') ) {
        if ( $_ =~ /\/(disk+[0-9])$/ ) { push @input_disks, $1; }
    }
}
else {
    for (`$smartctl_cmd --scan-open`) {

        #my $testline = "# /dev/sdc -d usbjmicron # /dev/sdc [USB JMicron], ATA device open" ;
        #for ($testline) {
        #splitting lines like  "/dev/sda -d scsi # /dev/sda, SCSI device"
        #"/dev/sda [SAT] -d sat [ATA] (opened)" # in debian 6 and smartctl 5.4
        #"/dev/sda -d sat # /dev/sda [SAT], ATA device" # in debian 8 and smartctl 6.4
        #"/dev/bus/0 -d megaraid,01" for megaraid
        #"# /dev/sdc -d usbjmicron # /dev/sdc [USB JMicron], ATA device open "

        my ($disk_name) = $_ =~ /(\/(.+?))\s/;
        my ($disk_args) = $_ =~ /(-d [A-Za-z0-9,\+]+)/;

        if ( $disk_name and $disk_args ) {
            push @input_disks,
              {
                disk_name => $disk_name,
                disk_args => $disk_args,
                subdisk   => 0
              };
        }

    }
}

foreach my $disk (@input_disks) {

    my @output_arr;
    if ( @output_arr = get_smart_disks($disk) ) {
        push @smart_disks, @output_arr;
    }

}

json_discovery( \@smart_disks );

sub get_smart_disks {
    my $disk = shift;
    my @disks;

    $disk->{smart_enabled} = 0;

                my @cmd_label_ret = `ls -l /dev/disk/by-partlabel/ | awk '{ print substr(\$0, index(\$0,\$9)) }'`;
                my %partlabel_map;
                chomp @cmd_label_ret;
                foreach (@cmd_label_ret)
                {
                        (my $name = $_) =~ s/(\w+\-\w+).*/$1/;
                        (my $path = $_) =~ s/.*\///;    
                        $partlabel_map{"/dev/".$path} = $name;
                }
                $disk->{disk_partname} = $partlabel_map{$disk->{disk_name}."1"}; #fixme: hardcoded 1 to match the discname /dev/sda to the used partition /dev/sda1 

                my @cmd_path_ret = `ls -l /dev/disk/by-path/ | awk '{ print substr(\$0, index(\$0,\$9)) }'`;
                my %path_map;
                chomp @cmd_path_ret;
                foreach (@cmd_path_ret)
                {
                        (my $name = $_) =~ s/\s.*//g;
                        (my $path = $_) =~ s/.*\///;    
                        $path_map{"/dev/".$path} = $name;
                }
                $disk->{disk_path} = $path_map{$disk->{disk_name}."1"}; #fixme: hardcoded 1 to match the discname /dev/sda to the used partition /dev/sda1
                chomp( $disk->{disk_name} );
                chomp( $disk->{disk_args} );

    #my $testline = "open failed: Two devices connected, try '-d usbjmicron,[01]'";
    #my $testline = "open device: /dev/sdc [USB JMicron] failed: Two devices connected, try '-d usbjmicron,[01]'";
    #if ($disk->{subdisk} == 1) {
    #$testline = "/dev/sdb -d usbjmicron,$disk->{disk_args} # /dev/sdb [USB JMicron], ATA device";
    #}
    foreach my $line (`$smartctl_cmd -i $disk->{disk_name} $disk->{disk_args} 2>&1`) {
        #foreach my $line ($testline) {
        #print $line;
        #Some disks have "Number" and some "number", so
        if ( $line =~ /^Serial (N|n)umber: +(.+)$/ ) {

            #print "Serial number is ".$2."\n";
            if ( grep /$2/, @global_serials ) {

                #print "disk already exist skipping\n";
                return;
            }
            else {
                push @global_serials, $2;
            }
        }
        elsif ( $line =~ /Permission denied/ ) {

            warn $line;

        }
        elsif ( $disk->{subdisk} == 0 and $line =~ /failed: [A-zA-Z]+ devices connected, try '(-d [a-zA-Z0-9]+,)\[([0-9]+)\]'/) {
            #check for usbjmicron: "open failed: Two devices connected, try '-d usbjmicron,[01]'"
            # or "open device: /dev/sdc [USB JMicron] failed: Two devices connected, try '-d usbjmicron,[01]'"
            #not $disk->{subdisk} works as a guard against endless recursion

            foreach ( split //, $2 ) {    #splitting [01]

                push @disks,
                  get_smart_disks(
                    {
                        disk_name => $disk->{disk_name},
                        disk_args => $1 . $_,
                        subdisk   => 1
                    }
                  );

            }
            return @disks;

        }
        elsif ( $line =~ /^SMART.+?: +(.+)$/ ) {
            if ( $1 =~ /Enabled/ ) {
                $disk->{smart_enabled} = 1;
            }
            elsif ( $1 =~ /Unavailable/ ) {
                `$smartctl_cmd -i $disk->{disk_name} $disk->{disk_args} 2>&1`;
            }

            #if SMART is disabled then try to enable it (also offline tests etc)
            elsif ( $1 =~ /Disabled/ ) {
                foreach (`smartctl -s on -o on -S on $disk->{disk_name} $disk->{disk_args}`)
                {
                    if (/SMART Enabled/) { $disk->{smart_enabled} = 1; }
                }
            }

        }
    }
    push @disks, $disk;
    return @disks;

}

sub json_discovery {
    my $disks = shift;

    my $first = 1;
    print "{\n";
    print "\t\"data\":[\n\n";

    foreach my $disk ( @{$disks} ) {

        print ",\n" if not $first;
        $first = 0;
        print "\t\t{\n";
        print "\t\t\t\"{#DISKNAME}\":\"".$disk->{disk_name}.q{ }.$disk->{disk_args}."\",\n";
        #print "\t\t\t\"{#DISKCMD}\":\"".$disk->{disk_name}.q{ }.$disk->{disk_args}."\",\n";
        print "\t\t\t\"{#DISK_PARTNAME}\":\"".$disk->{disk_partname}."\",\n" if $disk->{disk_partname};
        print "\t\t\t\"{#DISK_PATH}\":\"".$disk->{disk_path}."\",\n" if $disk->{disk_path};
        print "\t\t\t\"{#SMART_ENABLED}\":\"".$disk->{smart_enabled}."\"\n";
        print "\t\t}";

    }
    print "\n\t]\n";
    print "}\n";

}
