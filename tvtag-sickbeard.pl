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
#	tag from Sickbeard.
#
#
#######################################################################################
use File::Basename;
use File::Path;
use Data::Dumper;
use DBI;
use Cwd;
use Mediainfo;
use Text::Trim;
use TVDB::API;
use XML::Simple;


if ($#ARGV != 0) {
	print "usage: tvtag.pl <movie file>\n";
	exit;
}
$location = dirname $0;
$config = "$ENV{HOME}/.tvtag/config";

require "$location" . "/common_config.pl";
#require "/Users/caleb/Documents/git/FindEm-Media-Finder/common_config.pl";
#######################################################################################
# READ IN CONFIG FILE FROM ~/.tvtag/config
#######################################################################################
if ( -e "$ENV{HOME}/.tvtag") {
	if ( -e "$config") {
		do "$ENV{HOME}/.tvtag/config";
	} else {
		tv_config( 1 );
	}
} else {
	tv_config( 1 );
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
#if ( !-e "$cache") {
#	mkpath("$cache");
#}
#
#######################################################################################
# Initiate DB Connection
#######################################################################################
#my $dbh = DBI->connect("dbi:SQLite:dbname=$sickbearddb","","",$dbargs);
#
#my $TVShows_Query = "SELECT * from tv_shows where show_name like \"\%$show\%\"";
#my $query_handle = $dbh->prepare($TVShows_Query);
#$query_handle->execute();
#
#$query_handle->bind_columns(\my($show_id,$filesystem_location,$show_name,$tvdb_id,$TVNetwork,$Genre,$a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k));
#$query_handle->fetch();
#
#$Episode_Query = "SELECT * FROM tv_episodes WHERE showid=\"$tvdb_id\" AND season=\"$SeasonNumber\" AND episode=\"$EpisodeNumber\"";
#my $query_handle = $dbh->prepare($Episode_Query);
#$query_handle->execute();
#
#$query_handle->bind_columns(\my($Episode_ID,$SeriesID,$TVDBID,$EpisodeName,$null,$null,$Description,$AirDate,$null,$null,$null,$null,$null,$null));
#$query_handle->fetch();
#
#$query_handle->finish;
#undef($dbh);

$basename = $filename;
$basename =~ s/\.(?:m4v)\z/\.xml/;

print "Episode: $basename \n";

$seriesxml = new XML::Simple;
$seriesdata = $seriesxml->XMLin("$directories" . "series.xml");

$episodexml = new XML::Simple;
$episodedata = $episodexml->XMLin("$directories" . "metadata\/" . "$basename");

if ("$debug" == "1") {
	print "Directory: $directories \n";
	print Dumper($episodedata);
	#exit;
}

$copy = chr(169);

## Episode Data
$director = $episodedata->{Director};
$writer = $episodedata->{Writer};
$airdate = $episodedata->{FirstAired};
$episodename = $episodedata->{EpisodeName};
$episodenumber = $episodedata->{EpisodeNumber};
$seasonnumber = $episodedata->{SeasonNumber};
$episodeid = $episodedata->{EpisodeID};
$seasonid = $episodedata->{seasonid};
$description = $episodedata->{Overview};

## Series Data
$rated = $seriesdata->{ContentRating};
$seriesid = $seriesdata->{SeriesID};
$tvnetwork = $seriesdata->{Network};
$seriesdesc = $seriesdata->{Overview};
@actors = split /\|/, $seriesdata->{Actors};
$show = $seriesdata->{SeriesName};
@genre = split /\|/, $seriesdata->{genre};

shift (@actors);
shift (@genre);
$genre = @genre[0];

if ("$debug" == "1") {	
	print "SHOW NAME: $show_name\n";
	print "SHOW: $show\n";
	print "SEASON #: $seasonnumber\n";
	print "EP #: $episodenumber\n";
}

#######################################################################################
# Populate Variables to be tagged.
#######################################################################################
my $type = "TV Show";

$file_info = new Mediainfo("filename" => "$file");
$height = $file_info->{height};
$width = $file_info->{width};

if ( $height < 700 ) {
	$hdvid = "0";
}
if ( $height > 699 ) {
	$hdvid = "1";
}
if ( $height > 999 ) {
	$hdvid = "2";
}

if ( $hdvid == "0" ) {
	$hd = "Standard Def";
}
if ( $hdvid == "1" ) {
	$hd = "720p";
}
if ( $hdvid == "2" ) {
	$hd = "1080p";
}

if ($rated =~ /^ (?: TV-MA | TV-14 ) $/x) {
	$crating = "Explicit";
} elsif ($rated =~ /^ (?: TV-PG | TV-G | TV-Y7 | TV-Y ) $/x) {
	$crating = "Clean";
} else {
	$crating = "None";
}


#@GenreList = split(/\|/, $genre);
#$genre = $GenreList[0];
$description =~ s/\;/./g;
$description =~ s/\"/\\"/g;
$director =~ s/\|/\ /g;
$writer =~ s/\|/\ /g;
trim ( $director );
trim ( $writer );

#######################################################################################
# Season image retrieval
#######################################################################################
#
#$imageexists = 0;
#opendir (DIR, "$cache/seasons");
#@ImageFiles = readdir(DIR);
#closedir(DIR);
#
#foreach my $x (@ImageFiles) {
#	if ($x =~ /$seriesid/) {
#		push (@Images, "$x");
#	} 
#}
#
#if (@Images) {
#	foreach my $Image (@Images) {
#		@ImageInfo = split(/-/, $Image);
#		if ("$ImageInfo[1]" == "$seasonnumber") {
#			$imageexists = 1;
#			$BannerImage = "$cache/seasons/$Image";
#		}
#	}
#} 
#if ($imageexists == "0" && -e "$sickbeard/cache/images/$seriesid.poster.jpg") {
#	$imageexists = 1;
#	$BannerImage = "$sickbeard/cache/images/$seriesid.poster.jpg";
#}
#
$image = "$directories" . "folder.jpg";
#
########################################################################################
# Debug Output
#######################################################################################

if ("$debug" == "1") {
print "************************************\n";
print "IMDB id: \t$identifier\n";
print "Title: \t\t$title\n";
print "Type: \t\t$type\n";
print "Year: \t\t$year\n";
print "Rated: \t\t$rated\n";
print "MPAA Rating: \t$mpaa\n";
print "Height is: \t$height\n";
print "Width is: \t$width\n";
print "HD Value is: \t$hdvid\n";
print "Companies: \tjoin(", ", @companies)\n";
print "Companies: \t$companies\n";
print "Cover URL: \t$coverurl\n";
print "Cover File: \t$file_path\n";
print "Directors: \t@directors\n";
print "Cast: \t\t$cast[0]\n";
print "Writers: \t$writers[0]\n";
print "Plot: \t\t$plot\n";
print "Full Plot: \t$full_plot\n";
print "Storyline: \t$storyline\n";
print "Duration: \t$duration\n";
print "Genre: \t\t$genre\n";
print "Temp File: \t$tmpfile\n\n";
print "************************************\n\n";

print "************************************\n";
print Dumper($directors);
print "Testing: $directors{'id'}\n";
print "************************************\n\n";

}

#######################################################################################

########################################################################################
# Verbose Output
#######################################################################################
if ("$verbose" eq "yes") {
	print "************************************\n";
	print "\n";
	print "FILENAME:\t$filename\n";
	print "DIRECTORY:\t$directories\n";
	print "SERIES ID:\t$seriesid\n";
	print "TYPE:\t\t$type\n";
	print "HD:\t\t$hd\n";
	print "TV RATING:\t$rated\n";
	print "CONTENT RATING:\t$crating\n";
	print "IMAGE:\t\t$image\n";
	print "SERIES NAME:\t$show\n";
	print "EPISODE NAME:\t$episodename\n";
	print "AIR DATE:\t$airdate\n";
	print "GENRE:\t\t$genre\n";
	print "SHORT DESC:\t$description\n";
	print "DESC:\t\t$description\n";
	print "TV NETWORK:\t$tvnetwork\n";
	print "SEASON:\t\t$SeasonNumber\n";
	print "EPISODE NUMBER:\t$EpisodeNumber\n";
	print "EPISODE ID:\t$ProductionCode\n";
	print "ACTORS:\t\t@actors\n";
	print "GUEST ACTORS:\t$GuestStars\n";
	print "DIRECTOR:\t$director\n";
	print "SCREENWRITER:\t$writer\n";
	print "COPYRIGHT:\t$copy Caleb\'s Own Work\n";
	print "\n";
	print "************************************\n";
}

#######################################################################################
# Build actual tagging command
#######################################################################################
if ("$use" eq "MP4Tagger") {
	$command[0] = "$tagger";
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
} elsif ("$use" eq "mp4v2") {
	$command[0] = "$tagger";
	$command[1] = "-show \"$show\"";
	$command[2] = "-type \"$type\"";
	$command[3] = "-hdvideo \"$hdvid\"";
	$command[4] = "-episodeid \"$episodenumber\"";
	$command[5] = "-episode \"$episodenumber\"";
	$command[6] = "-season \"$seasonnumber\"";
	$command[7] = "-network \"$tvnetwork\"";
	$command[8] ="-album \"$show\"";
	$command[9] = "-genre \"$genre\"";
	$command[10] = "-year \"$airdate\""; 
	$command[11] = "-song \"$episodename\"";
	$command[12] = "-rating \"$rated\"";
	$command[13] = "-crating \"$crating\"";
	$command[14] = "-description \"$description\"";
	$command[15] = "-longdesc \"$description\"";
	$command[16] = "-track \"$episodenumber\"";
	$command[17] = "-cast \"@actors\"";
	$command[18] = "-copywarning \"FBI ANTI-PIRACY WARNING: UNAUTHORIZED COPYING IS PUNISHABLE UNDER FEDERAL LAW.\"";
	$command[19] = "-director \"$director\"";
	$command[20] = "-artist \"@actors\"";
	$command[21] = "-writer \"$writer\"";
	$command[22] = "-swriter \"$writer\"";
	$command[23] = "-copyright \"$copy $tvnetwork\"";
	$command[24] = "\"$file\"";
}


#print Dumper(@command);
system ("/usr/local/bin/mp4art -o -q --add \"$image\" \"$file\"");
system("@command") == 0
	or die "system @command failed: $?";
