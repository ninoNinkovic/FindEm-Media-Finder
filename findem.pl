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
use Mediainfo;

require "common_config.pl";

my $config = "$ENV{HOME}/.findem/config";
print colored ['blue'], "Welcome to the greatest script in the world!\n";
if (@ARGV == 0) {
	print colored ['red'], "\nUsage: ";
	print "./findem.pl <dirs> \n";
	print "\t<dirs> can be multiple space delimited directories\n\n";
	exit;
}
my $tagging_enabled = '1';
#######################################################################################
# READ IN CONFIG FILE FROM ~/.findem/config
#######################################################################################
if ( -e "$ENV{HOME}/.findem") {
	if ( -e "$config") {
		do "$ENV{HOME}/.findem/config";
	} else {
		findem_config( 1 );
		do "$ENV{HOME}/.findem/config";
	}
} else {
	findem_config( 1 );
	do "$ENV{HOME}/.findem/config";
}

#######################################################################################

#######################################################################################
# Check if Growl is enabled, if it is register it with Growl Host.
#######################################################################################
if ($g_enabled eq '1'){
		my $growl = Growl::GNTP->new(  AppName => $g_app,
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
}

#######################################################################################

#######################################################################################
# Find files to Convert
#######################################################################################
my @files = find(
	file =>
	name => [qw/ *.mkv *.avi *.mov *.ts *.mp4 *.iso / ],
	in => \@ARGV
	);

if (@files == 0) {
	print colored ['green'], "Found nothing to convert.\n";
	exit;
} else {

my $list = join("\n",@files," ");
print colored ['green'], "\nFound the following files to convert:\n\n$list\n";

#######################################################################################

#######################################################################################
# Loop through files found and convert to .m4v
#######################################################################################

foreach my $infile (@files) {
    print colored ['red'], $infile . "\n"; 
    my $infile_tmp = $infile;
    $infile_tmp =~ s/\'//g;
    #rmove($infile,$inflie_tmp);    
    my $outfile = $infile_tmp;
    $outfile =~ s/\.(?:mkv|avi|mov|ts|mp4|iso)\z/\.m4v/;
    mkpath($outfile);
    rmdir $outfile;
    move($infile,$infile_tmp);
	my $base_in = basename "$infile_tmp";
	my $base_out = basename "$outfile";

	## Figure out if audio is DTS or not
	my $file_info = new Mediainfo("filename" => "$infile_tmp");
	my $audio = $file_info->{audio_format};
	sleep (2);
	
	if ($audio eq dts) {		
		system "$handbrake -i '$infile_tmp' -o '$outfile' --preset=$preset";		
	} else {
		if ($infile =~ /\.(avi|iso)$/i) {
		system "$handbrake -i '$infile_tmp' -o '$outfile' --preset=$preset";
		} else {
		system "$subler -source '$infile_tmp' -dest '$outfile' -optimize";
    	}
	}
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
		print colored ['blue'], "Executing '$movietag' '$outfile' \n";
		sleep (2);
		system "'$movietag' '$outfile'";
		sleep (2);	
		print colored ['blue'], "Moving and Copying files around... \n\n";
		move ($outfile,$itunes) or die "Move to iTunes Failed: $!";
		move ($infile_tmp,$archive) or die "Move to archive failed: $!";
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
	}else{
		print colored ['blue'], "Executing '$tvtag' '$outfile' \n";
		sleep (2);
		system "'$tvtag' '$outfile'";
		sleep (2);	
		print colored ['blue'], "Moving and Copying files around... \n\n";
		move ($outfile,$itunes) or die "Move to iTunes Failed: $!";
		move ($infile_tmp,$archive) or die "Move to archive failed: $!";
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
		
	}	
	 #print Dumper(get_mp4info($outfile));
}
print colored ['bold blue'], "Thank you, please come again! \n\n";
#######################################################################################
}
