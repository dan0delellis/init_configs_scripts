#!/usr/bin/perl
use strict;
use Data::Dumper;

my $hagroup = "guys";

my $pve = "/etc/pve";
my $nodes = "$pve/nodes/";
my $ceph_storage = find_rbd();

my %TYPES = qw/lxc ct qemu-server vm/;
my %NAMES = qw/lxc hostname qemu-server name/;

my @conf = `find $nodes -name '*.conf'`;

my $H;
RESOURCE: for my $x(@conf) {
    chomp $x;
    if ($x =~ m%/etc/pve/nodes/([a-z0-9_-]+)/([a-z0-9_-]+)/([0-9]+).conf%i) {
        my ($node, $type, $id) = ($1, $2, $3);

        my $meta = parse_cfg($x);
        next RESOURCE if (is_valid($meta,"template"));

        KEYS: for my $m(keys %{$meta}) {
            my $t = identify_hardware($m);
            next KEYS unless (defined $t && $t=~ m/(disk|template)/);

            if ($t =~ m/locked/) {
                print Dumper "$x is locked by local hardare: '$m'";
                next RESOURCE;
            }

            #we are now for sure looking at a scsi/sata/virtio/ide device
            my $v = $meta->{$m};
            if ($v =~ m/^cdrom/) {
                print Dumper "$x has a host cdrom drive: '$m:$v'";
                next RESOURCE;
            }
            unless ($v =~ m/^(none,|$ceph_storage:)/) {
                print Dumper "$x has non-ceph storage: '$m:$v'";
                next RESOURCE;
            }
        }

        $H->{$id} = { type => $TYPES{$type}, comment=>$meta->{$NAMES{$type}} };
    }
}

for my $t (sort keys %{$H}) {
    my $r = $H->{$t};
    print "$r->{type}: $t\n\tcomment $r->{comment}\n\tgroup $hagroup\n\tstate started\n\n";
}

sub find_rbd {
    my $storage = "$pve/storage.cfg";

    my $RBD;
    my ($stype, $sname);
    my $D = read_to_str($storage);
    my @DEE = split(/\n\n+/, $D);

    foreach my $d(@DEE) {
        if ($d =~ m/(\S+):\s+(\S+)/) {
            ($stype, $sname) = ($1, $2);
        }
        if ($d =~ m/content\s(\S+)/) {
            my $stuff = $1;
            if ( $stuff =~ m/images/ && $stuff =~ m/rootdir/) {
                $RBD = $sname;
            }
        }
    }
    return $RBD;
}

sub parse_cfg {
    my ($p) = @_;
    my $D = read_to_str($p);
    my @L = split/\n/, $D;
    my $X;
    for my $l(@L) {
        if ($l =~ m/^(\S+):\s*(\S+)$/) {
            $X->{$1} = $2;
        }
    }
    return $X;
}

sub read_to_str {
    my ($p) =@_;

    my $D;
    open (my $RO, "<", $p);
    for (<$RO>) {
        $D .= $_;
    }
    close $RO;
    return $D;
}

sub identify_hardware {
    my ($k) = @_;
    if ( $k =~ m/(scsi|sata|virtio|ide|tpmstate|efidisk)[0-9]+/ ) {
        return "disk";
    }
    if ($k =~ m/(hostpci|usb)/) {
        return "locked";
    }
    return;
}
sub is_valid {
    my ($h, $k) = @_;
    if (exists $h->{$k} && defined $h->{$k} && $h->{$k} > 0) {
        return 1;
    }
    return;
}
