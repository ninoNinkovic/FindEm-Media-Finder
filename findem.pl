#!/usr/bin/env perl

use File::Find::Rule;
use Data::Dumper;

my $handbrake = '/usr/local/bin/HandBrakeCLI';
my $preset = 'AppleTV';
my $itunes = '/Volumes/Media/iTunes/iTunes Media/Automatically Add to iTunes/';
my $tvtag = '/usr/local/bin/tvtag-sickbeard.pl';

my @files = find(
	file =>
	name => [qw/ *.mkv *.avi / ],
	in => @ARGV
	);


$list = join("\n",@files," ");
print "\nFound the following files to convert:\n\n$list\n";



foreach $file (@files) {
	print $file . "\n";
	system "$handbrake -i '$file' -o test\.m4v --preset=$preset";
	#system "$tvtag test.m4v"
}
