#!/usr/bin/perl
use Data::Dumper;
use File::stat;
use List::Util qw/shuffle/;

my $mnt_ip = '10.1.0.5';
my $src_dir="/mnt/media/Music/.playlists";
my $outfile="/etc/default/vlc-radio/playlist.m3u8";
my $current_stat = stat($outfile);
my $mtime= 9;

my $LAST;
$LAST->{file} = $outfile;
$LAST->{mtime} = $current_stat->[$mtime];

my @flist = get_files($src_dir);
foreach my $h (@flist) {
    print Dumper "checking $h->{file}; age: $h->{mtime}";
    if ($h->{mtime} > $LAST->{mtime}) {
        print Dumper "\tfound newer file: $h->{file}";
        $LAST = $h;
    }
}

#whatever the newest file is, resuffle it weekly
my $D = read_file($LAST->{file});

dump_file($outfile,$D);

sub dump_file {
    my ($p,$d) = @_;
    open (my $FH, ">", $p) or die "cant write to file '$f':$!";
    print $FH @{$d};
    close $FH;
}

sub get_files {
    my ($d) = @_;
    opendir my $DH, $d or die "Cannot open directory '$d': $!";
    my @files = readdir $DH;
    closedir $DH;

    my @F;

    foreach my $f(@files) {
        my $temp;
        my $realpath = "$d/$f";
        next unless ( -f $realpath );
        $temp->{file} = $realpath;

        my $X = stat($temp->{file});
        $temp->{mtime} = $X->[$mtime];
        push @F, $temp;
    }
    return @F;
}

sub read_file {
    my ($p) = @_;
    open (my $RO, "<", $p) or die "Unable to read file '$p':$!";
    my @D;
    while (my $l=<$RO>) {
        chomp $l;
        $l =~ s/\\/\//g;
        $l =~ s/\/\//\//;
        $l =~ s/$mnt_ip/mnt/;
        $l =~ s/^\s+//g;
        $l =~ s/\s+$/\n/g;
        push @D, $l;
    }
    close $RO;
    @D = shuffle @D;
    return \@D;
}
