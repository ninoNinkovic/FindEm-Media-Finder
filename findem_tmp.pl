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
use Growl::GNTP;

my $config = "$ENV{HOME}/.findem/config";
print colored ['blue'], "Welcome to the greatest script in the world!\n";
if (@ARGV == 0) {
	print colored ['red'], "\nUsage: ";
	print "./findem.pl <dirs> \n";
	print "\t<dirs> can be multiple space delimited directories\n\n";
	exit;
}
my $tagging_enabled = '0';
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
# Create directories if they don't exist
#######################################################################################
if ( !-e "$ripped") {
	mkpath("$ripped");	
}
if ( !-e "$archive") {
	mkpath("$archive");	
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
    # $infile =~ s[ ][\\ ]g;
    my $outfile = $infile;
    $outfile =~ s/\.(?:mkv|avi|mov|ts)\z/\.m4v/;
	my $base_in = basename "$infile";
	my $base_out = basename "$outfile";
	sleep (2);
    system "$handbrake -i '$infile' -o '$outfile' --preset=$preset"; # without escaped spaces
    #system "$handbrake -i $infile' -o $outfile --preset=$preset"; # with escaped spaces
	if ($bc_enabled eq '1'){
		system "curl -d 'email=$bc_email' -d '&notification[from_screen_name]=Media+Procesor' -d '&notification[message]=$base_out has been Ripped.' http://boxcar.io/devices/providers/H04kjlc31sTQQE6vU7os/notifications";
	}
	if ($g_enabled eq '1'){
	  my $growl = Growl::GNTP->new(AppName => $g_app,
	                               PeerHost => $g_host,
	                               PeerPort => $g_port,
	                               Password => $g_password,
	                               AppIcon => $g_icon
	  );

	  $growl->register([
	      { Name => $g_app,
	        DisplayName => $g_app,	        
	        Icon => $g_icon, }
	  ]);

	  $growl->notify(
	      Event => $g_app,
	      Title => "$base_out Ripped",
	      Message => "$base_out has been Ripped.\n",
	      Icon => $g_icon
	  );
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
		if ($g_enabled eq '1'){
		  my $growl = Growl::GNTP->new(	AppName => $g_app,
			                               PeerHost => $g_host,
			                               PeerPort => $g_port,
			                               Password => $g_password,
			                               AppIcon => $g_icon
			  							);

		$growl->register([
		      { Name => $g_app,
		        DisplayName => $g_app,	        
		        Icon => $g_icon, }
			  ]);

		$growl->notify(
		      	Event => $g_app,
		      	Title => "$base_out Moved",
		      	Message => "$base_out has been added to the Ripped Diretory.\n",
		      	Icon => $g_icon
		  		);
		}		
	}elsif ($tagging_enabled eq '1'){
		print colored ['blue'], "Executing '$tvtag' '$outfile' \n";
		sleep (2);
		system "'$tvtag' '$outfile'";
		sleep (2);
	}
		print colored ['blue'], "Moving and Copying files around... \n\n";
		copy ($outfile,$itunes_tmp) or die "Move Failed: $!";
		move ($infile,$archive) or die "Copy failed: $!";
		sleep (5);
		move ("$itunes_tmp/$base_out",$itunes) or die "Move failed: $!";
			if ($bc_enabled eq '1'){
				system "curl -d 'email=$bc_email' -d '&notification[from_screen_name]=Media+Procesor' -d '&notification[message]=$base_out has been added to iTunes.' http://boxcar.io/devices/providers/H04kjlc31sTQQE6vU7os/notifications";
			}
			if ($g_enabled eq '1'){
			  my $growl = Growl::GNTP->new(	AppName => $g_app,
				                               PeerHost => $g_host,
				                               PeerPort => $g_port,
				                               Password => $g_password,
				                               AppIcon => $g_icon
				  );
	
				  $growl->register([
				      { Name => $g_app,
				        DisplayName => $g_app,	        
				        Icon => $g_icon, }
				  ]);
	
			  $growl->notify(
			      Event => $g_app,
			      Title => "$base_out Added to iTunes",
			      Message => "$base_out has been Added to your iTunes library.\n",
			      Icon => $g_icon
			  );
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

	print "Define TV Tag script: [$ENV{HOME}/svn/FindEm-Media-Finder/tvtag-sickbeard.pl (default)]: ";
	chomp ($tvtag = <STDIN>);
	if ($tvtag eq '') {
		$tvtag = '$ENV{HOME}/svn/FindEm-Media-Finder/tvtag-sickbeard.pl';
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
	
	print "Use Boxcar for mobile notifications?: [Yes (default)/No]: ";
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
	
	print "Use Gowl for notifications?: [Yes (default)/No]: ";
	chomp ($g_enabled = <STDIN>);
	if (lc($g_enabled) eq '') {
		$g_enabled = '1';
	} elsif (lc($g_enabled) eq 'yes') {
		$g_enabled = '1';
	} elsif (lc($g_enabled) eq 'no') {
		$g_enabled = '0';
	} else {
		print "I'll enable Growl Notifications for you since you can't decide.\n";
		$g_enabled = '1';
	}
	
	if ($g_enabled eq '1') {
		print "Your Growl Host Address Email: [localhost (default)]: ";
		chomp ($g_host = <STDIN>);
			if ($g_host eq '') {
				$g_host = 'localhost';
		 }
		
		print "Growl Port: [23053 (default)]: ";
		chomp ($g_port = <STDIN>);
		 	if ($g_port eq '') {
		 		$g_port = '23053';
			}
			
		print "Growl Password: [(Required)]: ";
		chomp ($g_password = <STDIN>);
		 	if ($g_password eq '') {
		 		print "A password is require, try again.\n";
				chomp ($g_password = <STDIN>);
				if ($g_password eq '') {
			 		print "A password is require, Growl notification will be disabled.\n";
					$g_enabled = '0';
				}		
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
 	print FILE "\$itunes = \"$itunes\"\;\n";
	print FILE "\$itunes_tmp = \"$itunes_tmp\"\;\n";
	print FILE "\$tvtag = \"$tvtag\"\;\n";
	print FILE "\$archive = \"$archive\"\;\n";
	print FILE "\$ripped = \"$ripped\"\;\n";
	print FILE "\$bc_enabled = \"$bc_enabled\"\;\n";
	if ($bc_enabled eq '1'){
	print FILE "\$bc_email = \"$bc_email\"\;\n";
	}
	print FILE "\$g_enabled = \"$g_enabled\"\;\n";
	if ($g_enabled eq '1'){
	print FILE "\$g_host = \"$g_host\"\;\n";
	print FILE "\$g_port = \"$g_port\"\;\n";
	print FILE "\$g_password = \"$g_password\"\;\n";
	print FILE "\$g_app = \"Media\\ Processor\"\;\n";
	print FILE "\$g_icon = \"http://www.macjunk.net/images/icon.png\"\;\n";
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
