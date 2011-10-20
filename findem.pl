#!/usr/bin/env perl

#use strict;
use warnings;
use File::Find::Rule;
use File::Copy;
use MP4::Info;
use Data::Dumper;

my $handbrake = '/usr/local/bin/HandBrakeCLI';
my $preset = 'AppleTV';
my $itunes = '/Volumes/Media/iTunes/iTunes Media/Automatically Add to iTunes';
#my $tvtag = '$HOME/Documents/bin/tvtag-sickbeard.pl';
my $tvtag = '/Users/caleb/svn/FindEm-Movie-Finder/tvtag-sickbeard.pl';
my $archive = '/Users/caleb/Movies/archive';
my $mp4info = '/usr/local/bin/mp4info';
my $ripped = '/Users/caleb/Movies/Ripped';
#my $count = system "'$mp4info' '$outfile' | grep -c 'TV Season: 0'";

my @files = find(
	file =>
	name => [qw/ *.mkv *.avi / ],
	in => \@ARGV
	);


my $list = join("\n",@files," ");
print "\nFound the following files to convert:\n\n$list\n";


foreach my $infile (@files) {
    print $infile . "\n";
    # escape spaces
    # $infile =~ s[ ][\\ ]g;
    my $outfile = $infile;
    $outfile =~ s/\.(?:mkv|avi)\z/\.m4v/;
    system "$handbrake -i '$infile' -o '$outfile' --preset=$preset"; # without escaped spaces
    #system "$handbrake -i $infile' -o $outfile --preset=$preset"; # with escaped spaces
	#move ('$infile', '$archive');
	print "Executing '$tvtag' '$outfile' \n";
	sleep (5);
	system "'$tvtag' '$outfile'";
	sleep (2);
	#system ("mv '$infile' '$archive'");
	print $infile . "\n";
	print $outfile . "\n";
	print $archive . "\n";
	#print $count . "\n";
	
	my $info = get_mp4info($outfile) or die "No TAG info";
	$info->{TITLE};
	if (-e $info) {
		copy ($outfile,$itunes) or die "Copy failed: $!";
		sleep (2);
	} else {
		move ($outfile,$ripped) or die "Move failed: $!";
		sleep (5);
	}
	
	#print Dumper(get_mp4info($outfile));
	move ($infile,$archive) or die "Move failed: $!";
 ####   sleep (5);
 ####   if ($count == 0) {
 ####   	move ($outfile,$ripped) or die "Move failed: $!";
 ####   	sleep (5);
 ####   } else {
 ####   #system ("cp '$outfile' '$itunes'");
 ####   copy ($outfile,$itunes) or die "Copy failed: $!";
 ####   sleep (2);
 ####   }
}