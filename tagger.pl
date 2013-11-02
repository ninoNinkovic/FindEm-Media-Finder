#!/usr/bin/env perl

use File::Find::Rule;
use File::Copy;
use File::Path;
#use MP4::Info;
use Data::Dumper;
use File::Basename;
use Cwd;
use Email::Valid;
use Term::ANSIScreen qw/:color /;

require "/Users/caleb/Documents/git/FindEm-Media-Finder/common_config.pl";

my $config = "$ENV{HOME}/.findem/config";
print colored ['blue'], "Welcome to the greatest script in the world!\n";
if (@ARGV == 0) {
	print colored ['red'], "\nUsage: ";
	print "./tagger.pl <dirs> \n";
	print "\t<dirs> can be multiple space delimited directories\n\n";
	exit;
}

#######################################################################################
# READ IN CONFIG FILE FROM ~/.findem/config
#######################################################################################
if ( -e "$ENV{HOME}/.findem") {
	if ( -e "$config") {
		do "$ENV{HOME}/.findem/config";
	} else {
		findem_config( 1 );
	}
} else {
	findem_config( 1 );
	require $config;
}

#######################################################################################

#######################################################################################
# Find files to Convert
#######################################################################################
my @files = find(
	file =>
	name => [qw/ *.m4v *.mp4 / ],
	in => \@ARGV
	);

if (@files == 0) {
	print colored ['green'], "Found nothing to tag.\n";
	exit;
} else {

my $list = join("\n",@files," ");
print colored ['green'], "\nFound the following files to tag:\n\n$list\n";

#######################################################################################
#$bc_email =~ s/@/\\@/;
#######################################################################################
# Loop through files found
#######################################################################################

foreach my $infile (@files) {
$infile =~ s/\'//g;
print $infile;
#######################################################################################

#######################################################################################
# Determine if it's a Movie or TV Show and handle appropriately
#######################################################################################
   #
   if ($infile =~ m/\(\d{4}\).m4v\z/){
   	print colored ['red'], "Executing '$movietag' '$infile' \n";
	system "'$movietag' '$infile'";
   }else{
	print colored ['blue'], "Executing '$tvtag' '$infile' \n";
	system "'$tvtag' '$infile'";
    } 
 	#print Dumper(get_mp4info($outfile));
}
print colored ['bold blue'], "Thank you, please come again! \n\n";
#######################################################################################
}