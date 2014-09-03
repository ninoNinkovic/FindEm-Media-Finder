#!/usr/bin/env perl
	
#######################################################################################
# Subroutines
#######################################################################################

	
sub findem_config($) {
	my $config = "$ENV{HOME}/.findem/config";
	my $handbrake;
	my $preset;
	my $itunes;
	my $subler;
	my $tvtag;
	my $movietag;
	
	my $archive;
	my $bc_enabled;
	my $bc_email;
	my $g_enabled;
	my $g_host;
	my $g_port;
	my $g_password;

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
	print "Define HandBrake Preset to use [AppleTV 3 (default)]: ";
	chomp ($preset = <STDIN>);
	if ($preset eq '') {
		$preset = 'AppleTV 3';
	}
	
	print "Location of SublerCLI? [/usr/local/bin/SublerCLI (default)]: ";
	chomp ($subler = <STDIN>);
	if ($subler eq '') {
		$subler = '/usr/local/bin/SublerCLI';
	}	

	print "Define Location of your iTunes Auto Add Directory [/Volumes/Media/iTunes/iTunes Media/Automatically Add to iTunes (default)]: ";
	chomp ($itunes = <STDIN>);
	if ($itunes eq '') {
		$itunes = '/Volumes/Media/iTunes/iTunes Media/Automatically Add to iTunes';
	}
	
	print "Define TV Tag script: [$ENV{HOME}/svn/FindEm-Media-Finder/tvtag-sickbeard.pl (default)]: ";
	chomp ($tvtag = <STDIN>);
	if ($tvtag eq '') {
		$tvtag = '$ENV{HOME}/svn/FindEm-Media-Finder/tvtag-sickbeard.pl';
	}

	print "Define Movie Tag script: [$ENV{HOME}/svn/FindEm-Media-Finder/movietag-couchpotato.pl (default)]: ";
	chomp ($movietag = <STDIN>);
	if ($movietag eq '') {
		$movietag = '$ENV{HOME}/svn/FindEm-Media-Finder/movietag-couchpotato.pl';
	}

	print "Define archive directory: [$ENV{HOME}/Movies/archive (default)]: ";
	chomp ($archive = <STDIN>);
	if ($archive eq '') {
		$archive = '$ENV{HOME}/Movies/archive';
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
$preset =~ s/\ /\\ /g;
	open (FILE, ">>$config");
	print FILE "\$handbrake = \'$handbrake\'\;\n";
	print FILE "\$preset = \'$preset\'\;\n";
	print FILE "\$subler = \'$subler\'\;\n";
	print FILE "\$itunes = \"$itunes\/\"\;\n";
	#print FILE "\$itunes_tmp = \'$itunes_tmp\'\;\n";
	print FILE "\$tvtag = \"$tvtag\"\;\n";
	print FILE "\$tvpvr = \"$tvpvr\"\;\n";
	print FILE "\$movietag = \"$movietag\"\;\n";
	print FILE "\$archive = \"$archive\"\;\n";
	#print FILE "\$ripped = \"$ripped\"\;\n";
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
		
	print "\n";
	print "Your config file should be built now. Let's run this script again.\n\n";
	sleep (3);
	do "$ENV{HOME}/.findem/config";
	#exit;
}

sub movie_config($) {
	my $config = "$ENV{HOME}/.movietag/config";
	my $verbose = '';
	my $use = '';
	my $tagger = '';
	my $cache = '';
	my $couchpotato = '';
	my $couchpotatodb = '';
	
	system(clear);
	print "You don't appear to have a config file. Let's build one. (Hit enter to accept default)\n\n";
	sleep(1);
	if ( !-e "$ENV{HOME}/.movietag") {
		mkpath("$ENV{HOME}/.movietag");	
	}
	
	print "Do you want verbose tagging? [yes or no (default)] ";
	chomp ($verbose = <STDIN>);
	if ($verbose eq "") {
		$verbose = "no";
	}
	print "Define Tagger to use [MP4Tagger, or AtomicParsley, or mp4v2 (default)]: ";
	chomp ($use = <STDIN>);
	if ($use eq "AtomicParsley") {
		$use = "ATOMIC";
	}
	if ($use eq "") {
		$use = "mp4v2";
	}

	do {
		print "Define Location of the Tagger binary: ";
		chomp ($tagger = <STDIN>);
	} until "$tagger" ne "";

	print "Define Image cache location: [$ENV{HOME}/.cache] ";
	chomp ($cache = <STDIN>);
	if ($cache eq "") {
		$cache = "$ENV{HOME}/.cache";
	}
	
	do {
		print "Define Couchpotato directory: ";
		chomp ($couchpotato = <STDIN>);
		$couchpotato =~ s/^~/$ENV{HOME}/g;
	} until "$couchpotato" ne "";	
	
	do {
		print "Define couchpotato.db location: ";
		chomp ($couchpotatodb = <STDIN>);
		$couchpotatodb =~ s/^~/$ENV{HOME}/g;
	} until "$couchpotatodb" ne "";	
	
	open (FILE, ">>$config");
	print FILE "\$verbose = \"$verbose\"\;\n";
	print FILE "\$debug = \"0\"\;\n";
 	print FILE "\$use = \"$use\"\;\n";
	print FILE "\$tagger = \"$tagger\"\;\n";
	print FILE "\$cache = \"$cache\"\;\n";
	print FILE "\$couchpotato = \"$couchpotato\"\;\n";
	print FILE "\$couchpotatodb = \"$couchpotatodb\"\;\n";
	
	print "\n";
	print "Your config file should be built now. Let\'s run this script again.\n\n";	
}

sub tv_config($) {
	my $config = "$ENV{HOME}/.tvtag/config";
	my $verbose = '';
	my $use = '';
	my $tagger = '';
	my $tvpvr = '';
	my $cache = '';
	my $sickbeard = '';
	
	system(clear);
	print "You don't appear to have a config file. Let's build one. (Hit enter to accept default)\n\n";
	sleep(1);
	if ( !-e "$ENV{HOME}/.tvtag") {
		mkpath("$ENV{HOME}/.tvtag");	
	}
	
	print "Do you want verbose tagging? [yes or no (default)]: ";
	chomp ($verbose = <STDIN>);
	if ($verbose eq "") {
		$verbose = "no";
	}
	print "Define Tagger to use [MP4Tagger, AtomicParsley, or mp4v2 (default)]: ";
	chomp ($use = <STDIN>);
	if ($use eq "AtomicParsley") {
		$use = "ATOMIC";
	}elsif ($use eq "") {
		$use = "mp4v2";
	}

	do {
		print "Define Location of the Tagger binary: ";
		chomp ($tagger = <STDIN>);
	} until "$tagger" ne "";
		
	#print "Define TVDB API Key (default is mine): ";
	#chomp ($TVDBAPIKEY = <STDIN>);
	#if ($TVDBAPIKEY eq "") {
	#	$TVDBAPIKEY = 'F3EE3AE655C54A95';
	#}
	
	print "Define TV PVR (Sickbeard or NZBDrone)[NZBDrone (default)]: ";
	chomp ($tvpvr = <STDIN>);
	if ($tvpvr eq '') {
		$tvpvr = 'NZBDrone';
	}

	print "Define Image cache location: [$ENV{HOME}/.cache] ";
	chomp ($cache = <STDIN>);
	if ($cache eq "") {
		$cache = "$ENV{HOME}/.cache";
	}
	
	do {
		print "Define Sickbeard directory: ";
		chomp ($sickbeard = <STDIN>);
		$sickbeard =~ s/^~/$ENV{HOME}/g;
	} until "$sickbeard" ne "";	
	
	open (FILE, ">>$config");
	print FILE "\$verbose = \"$verbose\"\;\n";
	print FILE "\$debug = \"0\"\;\n";
 	print FILE "\$use = \"$use\"\;\n";
	print FILE "\$tagger = \"$tagger\"\;\n";
	#print FILE "\$TVDBAPIKEY = \"$TVDBAPIKEY\"\;\n";
	print FILE "\$cache = \"$cache\"\;\n";
	print FILE "\$sickbeard = \"$sickbeard\"\;\n";
	print FILE "\$sickbearddb = \"$sickbeard/sickbeard.db\"\;\n";
	
	print "\n";
	print "Your config file should be built now. Let\'s run this script again.\n\n";	
}

sub trimlist {
	my $CommaDelimited;
	my @SplitArray;
	my $i;
	my $List;
	@SplitArray = split(/\|/, $_[0]);
	shift(@SplitArray);
	join(', ', @SplitArray);
}

1;