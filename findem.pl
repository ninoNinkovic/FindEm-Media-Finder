#!/usr/bin/env perl

use strict;
use warnings;
use File::Find::Rule;
use File::Copy;
use Data::Dumper;

my $handbrake = '/usr/local/bin/HandBrakeCLI';
my $preset = 'AppleTV';
my $itunes = '"/Volumes/Media/iTunes/iTunes Media/Automatically Add to iTunes/"';
my $tvtag = '/Users/caleb/Documents/bin/tvtag-sickbeard.pl';
my $archive = '/Users/caleb/Movies/archive';

my @files = find(
	file =>
	name => [qw/ *.mkv *.avi / ],
	in => @ARGV
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
	system "$tvtag $outfile";
	move ($infile, $archive); 
	sleep (2);
	copy ($outfile, $itunes);
	sleep (2);
}