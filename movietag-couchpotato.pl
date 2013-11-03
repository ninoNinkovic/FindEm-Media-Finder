#!/usr/bin/env perl
#######################################################################################
# movietag-couchpotato.pl
#
# Usage: movietag-couchpotato.pl <M4V file>
#
# Description:
#	movietag-couchpotato.pl is used to tag H.264 files with metadata for use in iTunes. 
#   Basically it makes them pretty when imported into iTunes. It's very simple to use 
#   and should automatically retrieve all relevant information to the Movie you are 
#   trying to tag from Couchpotato and imdb.
#
#
#######################################################################################
use File::Basename;
use File::Path;
use Data::Dumper;
use IMDB::Film;
use LWP::Simple;
use DBI;
use Cwd;
use Text::Trim;
use Mediainfo;

require "/Users/caleb/Documents/git/FindEm-Media-Finder/common_config.pl";

if ($#ARGV != 0) {
	print "usage: movietag-couchpotato.pl <movie file>\n";
	exit;
}
$location = dirname $0;
$config = "$ENV{HOME}/.movietag/config";
#######################################################################################
# READ IN CONFIG FILE FROM ~/.movietag/config
#######################################################################################
if ( -e "$ENV{HOME}/.movietag") {
	if ( -e "$config") {
		do "$ENV{HOME}/.movietag/config";
	} else {
		movie_config( 1 );
	}
} else {
	movie_config( 1 );
}


#######################################################################################
# Variable Declarations
#######################################################################################
$file = $ARGV[0];
($filename, $directories) = fileparse("$file");
@filelist = split(/\(/, $filename);
$movie = $filelist[0];
$movie =~ s/\s+$//;


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
my $dbh = DBI->connect("dbi:SQLite:dbname=$couchpotatodb","","",$dbargs);

my $movie_name = "SELECT * FROM librarytitle WHERE title = \"$movie\"";
my $query_handle = $dbh->prepare($movie_name);
$query_handle->execute();

$query_handle->bind_columns(\my($movie_id,$movie_title,$simple_title,$default,$libraries_id));
$query_handle->fetch();

$libraries_id_query = "select * from library_files__file_library where library_id = \"$libraries_id\"";
my $query_handle = $dbh->prepare($libraries_id_query);
$query_handle->execute();

$query_handle->bind_columns(\my($library_id,$file_id));
$query_handle->fetch();

$file_id_query = "select * from file where id = \"$file_id\"";
my $query_handle = $dbh->prepare($file_id_query);
$query_handle->execute();

$query_handle->bind_columns(\my($id1,$file_path,$null,$null,$null));
$query_handle->fetch();

$movie_info_query = "select * from library where id = \"$libraries_id\"";
my $query_handle = $dbh->prepare($movie_info_query);
$query_handle->execute();

$query_handle->bind_columns(\my($libraries_id1,$year,$identifier,$description,$tagline,$info,$null));
$query_handle->fetch();

$query_handle->finish;
undef($dbh);

$filename =~ s/\'//g;

if ($identifier) {
	print "IMDB ID is $identifier \n";
    $imdbObj = new IMDB::Film(crit => "$identifier");
} else {
	print "Looking by Title: $movie \n";
	$imdbObj = new IMDB::Film(crit => "$movie") || print "UNKNOWN ERROR\n" ; 
	}
	if($@) {
	                # Opsssss! We got an exception!
	                print "EXCEPTION: $@!";
	                next;
	        }
	
#if($imdbObj->status) {
#                print "Title: ".$imdbObj->title()."\n";
#                print "Year: ".$imdbObj->year()."\n";
#                print "Plot Symmary: ".$imdbObj->plot()."\n";
#                print "Rated: ".$imdbObj->mpaa_info()."\n";
#                print "Cover URL: ".$imdbObj->cover()."\n";
#        } else {
#                print "Something wrong: ".$imdbObj->error;
#        }
$title = $imdbObj->title();
$type = $imdbObj->kind();
$year = $imdbObj->year();
$companies = $imdbObj->company();
$coverurl = $imdbObj->cover();
@directors = @{ $imdbObj->directors() };
@writers = @{ $imdbObj->writers() };
@genres = @{ $imdbObj->genres() };
$tagline = $imdbObj->tagline();
$plot = $imdbObj->plot;
$storyline = $imdbObj->storyline();
$imdbrating = $imdbObj->rating();
@cast = @{ $imdbObj->cast() };
$duration = $imdbObj->duration();
$mpaa = $imdbObj->mpaa_info();
$full_plot = $imdbObj->full_plot();
@ratings = split /\ /, $mpaa;
$genre = $genres[0];
$rated = $ratings[1];

trim ( $title );
trim ( $type );
trim ( $year );
trim ( $genre );
trim ( $genres[0]);

$type = ucfirst($type);

if ($rated eq '') {
	$rated = 'Not Rated';
}

if ($type eq 'Video') {
	$type = 'Movie';
}

if ($genres[0] =~ /^ (?: Science Fiction | Sci-Fi | Fantasy ) $/x) {
	$genre = 'Sci-Fi & Fantasy';
}elsif ($genres[0] =~ /^ (?: Action | Adventure | War | Thriller | Crime ) $/x) {
	$genre = 'Action & Adventure';
}elsif ($genres[0] =~ /^ (?: Kids | Family | Animation ) $/x) {
	$genre = 'Kids & Family';
}else {
	$genre = $genres[0];
}

$file_info = new Mediainfo("filename" => "$file");
$height = $file_info->{height};
$width = $file_info->{width};

if ( $height < 720 ) {
	$hdvid = "0";
}
if ( $height > 719 ) {
	$hdvid = "1";
}
if ( $height > 1079 ) {
	$hdvid = "2";
}

if ($file_path eq '') {
	($cover, $directories) = fileparse("$coverurl");
	@coverlist = split(/\(/, $cover);
	$tmpfile = '/tmp/' . $coverlist[0];
	$tmpfile =~ s/\s+$//;
	
	getstore ($coverurl, $tmpfile);
	$file_path = $tmpfile;
}

$full_plot =~ s/\"/\\"/g;
$full_plot =~ s/\'/\\'/g;

#exit;
#######################################################################################
# Populate Variables to be tagged.
#######################################################################################
$Type = "Movie";


if ($rated eq 'R') {
	$crating = "Explicit";
} elsif ($rated eq 'Not Rated') {
	$crating = "None";
} else {
	$crating = "Clean";
}

$description =~ s/\;/./g;
$description =~ s/\"/\\"/g;

#######################################################################################
# Season image retrieval
#######################################################################################

$imageexists = 0;

if ( -e "$file_path" ) {
	$imageexists = 1;
	$BannerImage = "$file_path";
}

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
print "************************************\n";
use IMDB::Persons;

        #
        # Retrieve a person information by IMDB code
        #
        my $person = new IMDB::Persons(crit => '0868219');
        if($person->status) {
                print "Name: ".$person->name."\n";
                print "Birth Date: ".$person->date_of_birth."\n\n";
        }
use JSON;
use WebService::IMDBAPI;
use WebService::IMDBAPI::Result;

$imdbapi = WebService::IMDBAPI->new();
$results = $imdbapi->search_by_id('$identifier');
$result = $results[0];
#print $results->title;
#print $results->rated;
print "************************************\n\n";

}

#######################################################################################

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

if ($use eq "mp4v2") {
	system ("/usr/local/bin/mp4art -o -q -z --add \"$file_path\" \"$file\"");
	if ($tmpfile) {
	system ("rm $tmpfile");
	}
}
#######################################################################################
# Build actual tagging command
#######################################################################################
if ("$use" eq "MP4Tagger") {
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

} elsif ("$use" eq "mp4v2") {
	$command[0] = "$tagger";
	$command[1] = "-album \"$title\"";	
	$command[2] = "-type \"$type\"";	
	$command[3] = "-hdvideo $hdvid";	
	$command[4] = "-comment \"$mpaa\"";
	$command[5] = "-genre \"$genre\"";
	$command[6] = "-year \"$year\"";
	$command[7] = "-song \"$movie\"";
	$command[8] = "-rating \"$rated\"";
	$command[9] = "-crating \"$crating\"";	
	$command[10] = "-description \"$description\"";
	$command[11] = "-longdesc \"$description\"";	
	$command[12] = "-rannotation \"$mpaa\"";
	$command[13] = "\"$file\"";
}


open (STDOUT, "| tee -ai log.txt");
print "IMDB id: $identifier\n";
print "Title: $title\n";
print "Type: $type\n";
print "Year: $year\n";
print "Rated: $rated\n";
print "MPAA Rating: $mpaa\n";
print "Companies: $companies\n";
print "Cover URL: $coverurl\n";
print "Cover File: $file_path\n";
print "Directors: @directors\n";
print "Cast: $cast[0]\n";
print "Writers: $writers[0]\n";
print "Plot: $plot\n";
print "Full Plot: $full_plot\n";
print "Storyline: $storyline\n";
print "Duration: $duration\n";
print "Genres: $genres[0]\n";
print "Genre: $genre\n";
print "Temp File: $tmpfile\n";
print "\$use = $use\n\n";
print Dumper(@command);
close (STDOUT);

system("@command") == 0
	or die "system @command failed: $?";
