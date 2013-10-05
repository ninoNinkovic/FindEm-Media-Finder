#!/usr/bin/env perl
#######################################################################################
# tvtag-sickbeard.pl
#
# Usage: tvtag-sickbeard.pl <M4V file>
#
# Description:
#	Tvtag.pl is used to tag H.264 files with metadata for use in iTunes. Basically it
#	makes them pretty when imported into iTunes. It's very simple to use and should
#	automatically retrieve all relevant information to the TV show you are trying to 
#	tag from Sick-Beard.
#
#	Any questions can be directed to: tvtag@linuxjunk.org
#
#######################################################################################
use File::Basename;
use File::Path;
use Data::Dumper;
use DBI;
use Cwd;

if ($#ARGV != 0) {
	print "usage: tvtag.pl <movie file>\n";
	exit;
}
$location = dirname $0;
$config = "$ENV{HOME}/.tvtag/config";
#######################################################################################
# READ IN CONFIG FILE FROM ~/.tvtag/config
#######################################################################################
if ( -e "$ENV{HOME}/.tvtag") {
	if ( -e "$config") {
		do "$ENV{HOME}/.tvtag/config";
	} else {
		define_config();
	}
} else {
	define_config();
}


#######################################################################################
# Variable Declarations
#######################################################################################
my $file = $ARGV[0];
my $tvdb;
my ($filename, $directories) = fileparse("$file");
my @list = split(/ - /, $filename);
my $show = $list[0];
foreach my $ES (@list) {
	if ($ES =~ /[0-9]x[0-9]?\d+/) {
		my @list1 = split(/x/, $ES);
		$SeasonNumber = int $list1[0];
		$EpisodeNumber = int $list1[1];
	}
}


if ("$debug" == "2") {
	$show = "Supernatural";
	$SeasonNumber = "2";
	$EpisodeNumber = "4";
}

#######################################################################################
# Display which file is being tagged.
#######################################################################################
print "Tagging $filename\n";

#######################################################################################
# Verify that needed directories exist
#######################################################################################
if ( !-e "$cache") {
	mkpath("$cache");
}

#######################################################################################
# Initiate DB Connection
#######################################################################################
my $dbh = DBI->connect("dbi:SQLite:dbname=$sickbearddb","","",$dbargs);

my $TVShows_Query = "SELECT * from tv_shows where show_name like \"\%$show\%\"";
my $query_handle = $dbh->prepare($TVShows_Query);
$query_handle->execute();

$query_handle->bind_columns(\my($show_id,$filesystem_location,$show_name,$tvdb_id,$TVNetwork,$Genre,$a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k));
$query_handle->fetch();

$Episode_Query = "SELECT * FROM tv_episodes WHERE showid=\"$tvdb_id\" AND season=\"$SeasonNumber\" AND episode=\"$EpisodeNumber\"";
my $query_handle = $dbh->prepare($Episode_Query);
$query_handle->execute();

$query_handle->bind_columns(\my($Episode_ID,$SeriesID,$TVDBID,$EpisodeName,$null,$null,$Description,$AirDate1,$null,$null,$null,$null));
$query_handle->fetch();

$query_handle->finish;
undef($dbh);

if ("$debug" == "1") {	
	print "SHOW NAME: $show_name\n";
	print "SHOW: $show\n";
	print "SEASON #: $SeasonNumber\n";
	print "EP #: $EpisodeNumber\n";
}

#######################################################################################
# Populate Variables to be tagged.
#######################################################################################
my $Type = "TV Show";
my $HD = "yes";
@GenreList = split(/\|/, $Genre);
$Genre = $GenreList[1];
$Description =~ s/\;/./g;
#$Description =~ s/\'/\\\'/g;
$Description =~ s/\"/\\"/g;

#######################################################################################
# Season image retrieval
#######################################################################################

$imageexists = 0;
opendir (DIR, "$cache/seasons");
@ImageFiles = readdir(DIR);
closedir(DIR);

foreach my $x (@ImageFiles) {
	if ($x =~ /$SeriesID/) {
		push (@Images, "$x");
	} 
}

if (@Images) {
	foreach my $Image (@Images) {
		@ImageInfo = split(/-/, $Image);
		if ("$ImageInfo[1]" == "$SeasonNumber") {
			$imageexists = 1;
			$BannerImage = "$cache/seasons/$Image";
		}
	}
} 
if ($imageexists == "0" && -e "$sickbeard/cache/images/$SeriesID.poster.jpg") {
	$imageexists = 1;
	$BannerImage = "$sickbeard/cache/images/$SeriesID.poster.jpg";
}

########################################################################################
# Verbose Output
#######################################################################################
#=begin
if ("$verbose" eq "yes") {
	print "************************************\n";
	print "\n";
	print "FILENAME:\t$filename\n";
	print "DIRECTORY:\t$directories\n";
	print "SERIES ID:\t$SeriesID\n";
	print "TYPE:\t\t$Type\n";
	print "HD:\t\t$HD\n";
	#print "URL:\t\t$url\n";
	print "IMAGE:\t\t$BannerImage\n";
	print "SERIES NAME:\t$SeriesName\n";
	print "EPISODE NAME:\t$EpisodeName\n";
	print "AIR DATE:\t$AirDate\n";
	print "RATING:\t\t$Rating\n";
	print "GENRE:\t\t$Genre\n";
	print "SHORT DESC:\t$Description\n";
	print "DESC:\t\t$Description\n";
	print "TV NETWORK:\t$TVNetwork\n";
	print "SEASON:\t\t$SeasonNumber\n";
	print "EPISODE NUMBER:\t$EpisodeNumber\n";
	print "EPISODE ID:\t$ProductionCode\n";
	print "ACTORS:\t\t$Actors\n";
	print "GUEST ACTORS:\t$GuestStars\n";
	print "DIRECTOR:\t$Director\n";
	print "SCREENWRITER:\t$Writer\n";
	print "\n";
	print "************************************\n";
}

#=cut

#######################################################################################
# Build actual tagging command
#######################################################################################
if ("$use" eq "subler") {
	$sublercmd = "$subler -o \"$file\" -t ";
	$command[0] = "\"TV Show:$SeriesName\""; 
	$command[1] = "\"Media Kind:$Type\"";
	$command[2] = "\"Artwork:$BannerImage\"";
	$command[3] = "\"HD Video:$HD\"";
	$command[4] = "\"TV Episode ID:$ProductionCode\"";
	$command[5] = "\"TV Episode #:$EpisodeNumber\"";
	$command[6] = "\"TV Season:$SeasonNumber\"";
	$command[7] = "\"TV Network:$TVNetwork\"";
	$command[8] ="\"Name:$EpisodeName\"";
	$command[9] = "\"Genre:$Genre\"";
	$command[10] = "\"Release Date:$AirDate\""; 
	$command[11] = "\"Rating:$Rating\"";
	$command[12] = "\"Content Rating:Clean\"";
	$command[13] = "\"Cast:$Actors\"";
	$command[14] = "\"Director:$Director\"";
	$command[15] = "\"Screenwriters:$Writer\"";
	$command[16] = "\"Description:$Description\"";
	$command[17] = "\"Long Description:$Description\"";
	
	foreach my $x (@command) {
		`$sublercmd $x`;
	}
	
} elsif ("$use" eq "MP4Tagger") {
	$command[0] = "$mp4tagger";
	$command[1] = "-i \"$file\""; 
	$command[2] = "--tv_show \"$show\""; 
	$command[3] = "--media_kind \"$Type\"";
	if ($BannerImage) {
		$command[4] = "--artwork \"$BannerImage\"";
	} else {
		print "\n\n\tWARNING: THIS FILE WILL NOT CONTAIN ANY COVER ART, NO IMAGE FILE WAS FOUND!\n\n";
		$command[4] = "";
	}
	$command[5] = "--is_hd_video $HD";
	$command[6] = "--tv_episode_id \"$ProductionCode\"";
	$command[7] = "--tv_episode_n \"$EpisodeNumber\"";
	$command[8] = "--tv_season \"$SeasonNumber\"";
	$command[9] = "--tv_network \"$TVNetwork\"";
	$command[10] ="--name \"$EpisodeName\"";
	$command[11] = "--genre \"$Genre\"";
	$command[12] = "--release_date \"$AirDate\""; 
	$command[13] = "--rating \"$Rating\"";
	$command[14] = "--content_rating \"Clean\"";
	$command[15] = "--cast \"$Actors\"";
	$command[16] = "--director \"$Director\"";
	$command[17] = "--screenwriters \"$Writer\"";
	$command[18] = "--description \"$Description\"";
	$command[19] = "--long_description \"$Description\"";
	$command[20] = "--track_n \"$EpisodeNumber\"";
}


#print Dumper(@command);

system("@command") == 0
	or die "system @command failed: $?";


#######################################################################################
# Subroutines
#######################################################################################
sub trimlist {
	my $CommaDelimited;
	my @SplitArray;
	my $i;
	my $List;
	@SplitArray = split(/\|/, $_[0]);
	shift(@SplitArray);
	join(', ', @SplitArray);
}

sub define_config ($config) {
	system(clear);
	print "You don't appear to have a config file. Let's build one. (Hit enter to accept default)\n\n";
	sleep(1);
	if ( !-e "$ENV{HOME}/.tvtag") {
		mkpath("$ENV{HOME}/.tvtag");	
	}
	
	print "Do you want verbose tagging? [yes or no (default)] ";
	chomp ($verbose = <STDIN>);
	if ($verbose eq "") {
		$verbose = "no";
	}
	print "Define Tagger to use [MP4Tagger (default) or Subler]: ";
	chomp ($use = <STDIN>);
	if ($use eq "") {
		$use = "MP4Tagger";
	}

	do {
		print "Define Location of the Tagger binary: ";
		chomp ($mp4tagger = <STDIN>);
	} until "$mp4tagger" ne "";
		
	print "Define TVDB API Key (default is mine): ";
	chomp ($TVDBAPIKEY = <STDIN>);
	if ($TVDBAPIKEY eq "") {
		$TVDBAPIKEY = 'E5DC4EEFA8A7AA8D';
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
	print FILE "\$mp4tagger = \"$mp4tagger\"\;\n";
	print FILE "\$TVDBAPIKEY = \"$TVDBAPIKEY\"\;\n";
	print FILE "\$cache = \"$cache\"\;\n";
	print FILE "\$sickbeard = \"$sickbeard\"\;\n";
	print FILE "\$sickbearddb = \"$sickbeard/sickbeard.db\"\;\n";
	
	print "\n";
	print "Your config file should be built now. Let\'s run this script again.\n\n";	
}


