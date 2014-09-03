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

$location = dirname $0;
require "$location" . "/common_config.pl";
# require "/Users/caleb/Documents/git/FindEm-Media-Finder/common_config.pl";

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
	name => [qw/ *.mkv *.avi *.mov *.wmv *.ts *.mp4 *.iso / ],
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

foreach $infile (@files) {
    print colored ['red'], $infile . "\n"; 
	$infile_tmp =  $infile;
    $infile_tmp =~ s/\'/\\'/g;
	# $infile_tmp =~ s/\ /\\ /g;
	# $infile_tmp =~ s/\(/\\(/g;
	# $infile_tmp =~ s/\)/\\)/g;
	# move ($infile,$infile_tmp);
	$infile = $infile_tmp;
	#$infile =~ s/\(/\\(/g;
    #$infile =~ s/\)/\\)/g;
    $outfile = $infile;
    $outfile =~ s/\.(?:mkv|avi|wmv|mov|ts|mp4|iso)\z/\.m4v/;
    mkpath($outfile);
    rmdir $outfile;

	my $base_in = basename "$infile";
	my $base_out = basename "$outfile";
	print "Base In: $base_in\n";
	print "Base Out: $base_out\n";
	#print "tmp file: $infile_tmp\n";
	#system "/usr/local/bin/mkvdts2ac3 -w /Volumes/purple/Media/mkvdts2ac3_tmp/ -n -d -i -f '$infile'";
#	exit;

	## Get some info about the file
	$file_info = new Mediainfo("filename" => "$infile");
	$audio = $file_info->{audio_format};

if ("$debug" == "1") {
	print $file_info->{filename}, "\n";
	print $file_info->{filesize}, "\n";
	print $file_info->{container}, "\n";
	print $file_info->{length}, "\n";
	print $file_info->{bitrate}, "\n";
	print $file_info->{video_codec}, "\n";
	print $file_info->{video_format}, "\n";
	print $file_info->{video_length}, "\n";
	print $file_info->{video_bitrate}, "\n";
	print $file_info->{width}, "\n";
	print $file_info->{height}, "\n";
	print $file_info->{fps}, "\n";
	print $file_info->{fps_mode}, "\n";
	print $file_info->{dar}, "\n";
	print $file_info->{frame_count}, "\n";
	print $file_info->{audio_codec}, "\n";
	print $file_info->{audio_format}, "\n";
	print $file_info->{audio_length}, "\n";
	print $file_info->{audio_bitrate}, "\n";
	print $file_info->{audio_rate}, "\n";
	print $file_info->{audio_language}, "\n";
	print $file_info->{have_video}, "\n";
	print $file_info->{have_audio}, "\n";
	print $file_info->{rotation}, "\n";
	print $file_info->{video_codec_profile}, "\n";
	print $file_info->{video_format_profile}, "\n";
}
	sleep (5);
	
	# if ($audio eq dts) {
# 		system "/usr/local/bin/mkvdts2ac3 -w /Volumes/purple/Media/mkvdts2ac3_tmp/ -n -d -i -f '$infile'";
# 		#`/usr/local/bin/mkvdts2ac3 -w /Volumes/purple/Media/mkvdts2ac3_tmp/ -n -d -i -f --new '$infile'`;
# 		sleep (5);
# 	}
	if ($infile =~ /\.(iso)$/i) {
		system "$handbrake -i '$infile' -o '$outfile' --preset=$preset";	
	} elsif ($infile =~ /\.(wmv)$/i) {
		system "$ffmpeg -i '$infile' -map 0:0 -c:v libx264 -crf 23 -profile:v high -r 30 -metadata:s:v language=eng -metadata:s:v title='Video Track' -map 0:1 -c:a:0 ac3 -ab:a:0 448k -ac:a:0 6 -ar:a:0 48000 -metadata:s:a:0 language=eng -metadata:s:a:0 title='Audio Track' -movflags faststart -f mp4 -y '$outfile'";
	} else {
		system "$ffmpeg -i '$infile' -map 0:0 -vcodec copy -metadata:s:v language=eng -metadata:s:v title='Video Track' -map 0:1 -codec:a:0 ac3 -ab:a:0 448k -ac:a:0 6 -ar:a:0 48000 -metadata:s:a:0 language=eng -metadata:s:a:0 title='Audio Track' -movflags faststart -f mp4 -y '$outfile'";
	# system "$subler -itunesfriendly -64bitchunk -language English -source '$infile' -dest '$outfile'";
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
		move ($infile,$archive) or die "Move to archive failed: $!";		
		#move ($infile_tmp,$archive) or die "Move to archive failed: $!";
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
		move ($infile,$archive) or die "Move to archive failed: $!";
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
