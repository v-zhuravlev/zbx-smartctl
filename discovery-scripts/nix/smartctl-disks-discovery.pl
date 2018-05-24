#!/usr/bin/perl
use warnings;
use strict;

#must be run as root
my $VERSION = 0.11;

#add path if needed into $smartctl_cmd
my $smartctl_cmd = "smartctl";
my @input_disks;
my @global_serials;
my @smart_disks;

if ( $^O eq 'darwin' ) {    # if MAC OSX (limited support, consider to use smartctl --scan-open)

    while ( glob('/dev/disk*') ) {
        if ( $_ =~ /\/(disk+[0-9])$/ ) { 
            push @input_disks,
              {
                disk_name => $1,
                disk_args => '',#stub
                disk_sn => '', #stub
                disk_model => '', #stub
                disk_type => 1, #wild guess :)
                subdisk   => 0
              };
        }
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

    chomp( $disk->{disk_name} );
    chomp( $disk->{disk_args} );

    #my $testline = "open failed: Two devices connected, try '-d usbjmicron,[01]'";
    #my $testline = "open device: /dev/sdc [USB JMicron] failed: Two devices connected, try '-d usbjmicron,[01]'";
    #if ($disk->{subdisk} == 1) {
    #$testline = "/dev/sdb -d usbjmicron,$disk->{disk_args} # /dev/sdb [USB JMicron], ATA device";
    #}
    my @smartctl_output = `$smartctl_cmd -i $disk->{disk_name} $disk->{disk_args} 2>&1`;
    foreach my $line (@smartctl_output) {
        #foreach my $line ($testline) {
        #print $line;
        if ( $line =~ /^SMART.+?: +(.+)$/ ) {

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
    
    foreach my $line (@smartctl_output) {
        
        if ( $line =~ /^serial number: +(.+)$/i ) {

            #print "Serial number is ".$2."\n";
            if ( grep /$1/, @global_serials ) {

                #print "disk already exists skipping\n";
                return;
            }
            else {
                $disk->{disk_sn} = $1;
                if ($disk->{smart_enabled} eq 1){
                    push @global_serials, $1;
                }
            }
        }
        elsif ( $line =~ /^Device Model: +(.+)$/ ) {
                $disk->{disk_model} = $1;
        }
        
        if ( $line =~ /Rotation Rate: (.+)/ ) {

            if ( $1 =~ /Solid State Device/ ) {
                $disk->{disk_type} = 1;
            }
            elsif( $1 =~ /rpm/ ) {
                $disk->{disk_type} = 0;
            }
        }
        if ( !exists($disk->{disk_type})) {

                $disk->{disk_type} = 2;
                foreach my $extended_line (`$smartctl_cmd -a $disk->{disk_name} $disk->{disk_args} 2>&1`){

                    #search for Spin_Up_Time or Spin_Retry_Count
                    if ($extended_line  =~ /Spin_/){
                        $disk->{disk_type} = 0;
                        last;
                    }
                    #search for SSD in uppercase
                    elsif ($extended_line  =~ / SSD /){
                        $disk->{disk_type} = 1;
                        last;
                    }
                }
        }

        if ( $line =~ /Permission denied/ ) {

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
        print "\t\t\t\"{#DISKMODEL}\":\"".$disk->{disk_model}."\",\n";
        print "\t\t\t\"{#DISKSN}\":\"".$disk->{disk_sn}."\",\n";
        print "\t\t\t\"{#DISKNAME}\":\"".$disk->{disk_name}."\",\n";
        print "\t\t\t\"{#DISKCMD}\":\"".$disk->{disk_name}.q{ }.$disk->{disk_args}."\",\n";
        print "\t\t\t\"{#SMART_ENABLED}\":\"".$disk->{smart_enabled}."\",\n";
        print "\t\t\t\"{#DISKTYPE}\":\"".$disk->{disk_type}."\"\n";
        print "\t\t}";

    }
    print "\n\t]\n";
    print "}\n";

}
