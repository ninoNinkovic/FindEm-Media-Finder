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

my $config = "$ENV{HOME}/.findem/config";
print colored ['blue'], "Welcome to the greatest script in the world!\n";
if (@ARGV == 0) {
	print colored ['red'], "\nUsage: ";
	print "./findem.pl <dirs> \n";
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
		define_config();
	}
} else {
	define_config();
}

#######################################################################################

#######################################################################################
# Find files to Convert
#######################################################################################
my @files = find(
	file =>
	name => [qw/ *.mkv *.avi *.mov *.ts / ],
	in => \@ARGV
	);

if (@files == 0) {
	print colored ['green'], "Found nothing to convert.\n";
	exit;
} else {

my $list = join("\n",@files," ");
print colored ['green'], "\nFound the following files to convert:\n\n$list\n";

#######################################################################################
#$bc_email =~ s/@/\\@/;
#######################################################################################
# Loop through files found and convert to .m4v
#######################################################################################

foreach my $infile (@files) {
    print colored ['red'], $infile . "\n";
    # escape spaces
    #$infile =~ s[ ][\\ ]g;
	$infile =~ s/\'/\\'/g;
    my $outfile = $infile;
    $outfile =~ s/\.(?:mkv|avi|mov|ts)\z/\.m4v/;
	$outfile =~ s/\'/\\'/g;
	my $base_in = basename "$infile";
	my $base_out = basename "$outfile";
	sleep (2);
    system "$handbrake -i '$infile' -o '$outfile' --preset=$preset"; # without escaped spaces
    #system "$handbrake -i $infile' -o $outfile --preset=$preset"; # with escaped spaces
	if ($bc_enabled eq '1'){
		system "curl -d 'email=$bc_email' -d '&notification[from_screen_name]=Media+Procesor' -d '&notification[message]=$base_out has been Ripped.' http://boxcar.io/devices/providers/H04kjlc31sTQQE6vU7os/notifications";
	}

#######################################################################################

#######################################################################################
# Determine if it's a Movie or TV Show and handle appropriately
#######################################################################################

	if ($outfile =~ m/\(\d{4}\).m4v\z/){
		print colored ['blue'], "Moving and Copying files around... \n\n";
		sleep (2);
		move ($outfile,$ripped) or die "Move of Movie file failed: $!";
		move ($infile,$archive) or die "Move of Original Movie file failed: $!";
		if ($bc_enabled eq '1'){
			system "curl -d 'email=$bc_email' -d '&notification[from_screen_name]=Media+Procesor' -d '&notification[message]=$base_out has added to the Ripped Directory.' http://boxcar.io/devices/providers/H04kjlc31sTQQE6vU7os/notifications";
		}
	}else{
	print colored ['blue'], "Executing '$tvtag' '$outfile' \n";
	sleep (2);
	system "'$tvtag' '$outfile'";
	sleep (2);
	
	print colored ['blue'], "Moving and Copying files around... \n\n";
	copy ($outfile,$itunes_tmp) or die "Move Failed: $!";
	move ($infile,$archive) or die "Copy failed: $!";
	sleep (5);
	move ("$itunes_tmp/$base_out",$itunes) or die "Move failed: $!";
		if ($bc_enabled eq '1'){
			system "curl -d 'email=$bc_email' -d '&notification[from_screen_name]=Media+Procesor' -d '&notification[message]=$base_out has been added to iTunes.' http://boxcar.io/devices/providers/H04kjlc31sTQQE6vU7os/notifications";
		}
	}
	
 	#print Dumper(get_mp4info($outfile));
}
print colored ['bold blue'], "Thank you, please come again! \n\n";
#######################################################################################
}
#######################################################################################
# Define the Config file
#######################################################################################

sub define_config ($config) {
	system("clear");
	print "You don't appear to have a config file. Let's build one. (Hit enter to accept default)\n\n";
	sleep(1);
	if ( !-e "$ENV{HOME}/.findem") {
		mkpath("$ENV{HOME}/.findem");	
	}
	
	print "Location of HandBrakeCLI? [/usr/local/bin/HandBrakeCLI (default)]: ";
	chomp ($handbrake = <STDIN>);
	if ($handbrake eq '') {
		$handbrake = '/usr/local/bin/HandBrakeCLI';
	}
	print "Define HandBrake Preset to use [AppleTV (default)]: ";
	chomp ($preset = <STDIN>);
	if ($preset eq '') {
		$preset = 'AppleTV';
	}

   ### do {
   ### 	print "Define Location of your iTunes Auto Add Directory: ";
   ### 	chomp ($mp4tagger = <STDIN>);
   ### } until "$mp4tagger" ne "";
		
	print "Define Location of your iTunes Auto Add Directory [/Volumes/Media/iTunes/iTunes Media/Automatically Add to iTunes (default)]: ";
	chomp ($itunes = <STDIN>);
	if ($itunes eq '') {
		$itunes = '/Volumes/Media/iTunes/iTunes Media/Automatically Add to iTunes';
	}
	
	print "Define Location of your iTunes Temp Directory [/Volumes/Media/iTunes/iTunes Media (default)]: ";
	chomp ($itunes_tmp = <STDIN>);
	if ($itunes_tmp eq '') {
		$itunes_tmp = '/Volumes/Media/iTunes/iTunes Media';
	}

	print "Define TV Tag script: [$ENV{HOME}/svn/FindEm-Movie-Finder/tvtag-sickbeard.pl (default)]: ";
	chomp ($tvtag = <STDIN>);
	if ($tvtag eq '') {
		$tvtag = '$ENV{HOME}/svn/FindEm-Movie-Finder/tvtag-sickbeard.pl';
	}
	
	print "Define archive directory: [$ENV{HOME}/Movies/archive (default)]: ";
	chomp ($archive = <STDIN>);
	if ($archive eq '') {
		$archive = '$ENV{HOME}/Movies/archive';
	}
	
	print "Define Ripped Movies directory: [$ENV{HOME}/Movies/Ripped (default)]: ";
	chomp ($ripped = <STDIN>);
	if ($ripped eq '') {
		$ripped = '$ENV{HOME}/Movies/Ripped';
	}
	
	print "Use Boxcar for notifications?: [Yes (default)/No]: ";
	chomp ($bc_enabled = <STDIN>);
	if (lc($bc_enabled) eq '') {
		$bc_enabled = '1';
	} elsif (lc($bc_enabled) eq 'yes') {
		$bc_enabled = '1';
	} elsif (lc($bc_enabled) eq 'no') {
		$bc_enabled = '0';
	} else {
		print "I'll enable Boxcar for you since you can't decide.\n";
		$bc_enabled = '1';
	}
	
	if ($bc_enabled eq '1') {
		print "Your Boxcar Email: []: ";
		chomp ($bc_email = <STDIN>);
		if (Email::Valid->address(-address => $bc_email,
								  -tldcheck => 1,
								  -mxcheck => 1)) {
			$bc_email =~ s/@/\\@/;
			} else {
				print "Boxcar will be disabled.\n";
				$bc_enabled = '0';
			}
	}
	
   #####do {
   #####	print "Define Sickbeard directory: ";
   #####	chomp ($sickbeard = <STDIN>);
   #####	$sickbeard =~ s/^~/$ENV{HOME}/g;
   #####} until "$sickbeard" ne "";	
	
	open (FILE, ">>$config");
	print FILE "\$handbrake = \'$handbrake\'\;\n";
	print FILE "\$preset = \'$preset\'\;\n";
 	print FILE "\$itunes = \'$itunes\'\;\n";
	print FILE "\$itunes_tmp = \'$itunes_tmp\'\;\n";
	print FILE "\$tvtag = \"$tvtag\"\;\n";
	print FILE "\$archive = \"$archive\"\;\n";
	print FILE "\$ripped = \"$ripped\"\;\n";
	print FILE "\$bc_enabled = \"$bc_enabled\"\;\n";
	if ($bc_enabled eq '1'){
	print FILE "\$bc_email = \"$bc_email\"\;\n";
	}
	###print FILE "\$sickbeard = \"$sickbeard\"\;\n";
	###print FILE "\$sickbearddb = \"$sickbeard/sickbeard.db\"\;\n";
	
	print "\n";
	print "Your config file should be built now. Let's run this script again.\n\n";
	sleep (3);
	#exit;
}

sub box_car () {
	
}
#######################################################################################
