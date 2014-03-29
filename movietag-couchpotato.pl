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
use XML::Simple;
use JSON;


if ($#ARGV != 0) {
	print "usage: movietag-couchpotato.pl <movie file>\n";
	exit;
}
$location = dirname $0;
$config = "$ENV{HOME}/.movietag/config";

require "$location" . "/common_config.pl";
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
	                # Ooopsssss! We got an exception!
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
#$title = $imdbObj->title();
#$type = $imdbObj->kind();
#$year = $imdbObj->year();
#$companies = $imdbObj->company();
$coverurl = $imdbObj->cover();
#@directors = @{ $imdbObj->directors() };
#@writers = @{ $imdbObj->writers() };
#@genres = @{ $imdbObj->genres() };
#$tagline = $imdbObj->tagline();
#$plot = $imdbObj->plot;
#$storyline = $imdbObj->storyline();
#$imdbrating = $imdbObj->rating();
#@cast = @{ $imdbObj->cast() };
#$duration = $imdbObj->duration();
$mpaa = $imdbObj->mpaa_info();
##$full_plot = $imdbObj->full_plot();
#@ratings = split /\ /, $mpaa;
#$genre = $genres[0];
#$rated = $ratings[1];
#
#trim ( $title );
#trim ( $type );
#trim ( $year );
#trim ( $genre );
#trim ( $genres[0]);
#
#$type = ucfirst($type);

#print "size of hash: " . keys( %writers ) . ".\n";
#print "size of hash: " . keys( %directors ) . ".\n";
#push @{$hash{1}}, $2 while $info =~ m/(\w\W\d\D):(\w\W\d\D)
#$info =~ s/\"//g;
#$info =~ s/\[//g;
#$info =~ s/\]//g;

#%infohash = split /[:,]\s*/, $info;

#my $hash = from_json $info;
$movie =~ s/\ /\+/g;

if ($identifier) {
$tu = "http://www.omdbapi.com/?i=$identifier&r=XML&tomatoes=true";
} else {
$tu = "http://www.omdbapi.com/?t=$movie&r=XML&tomatoes=true";
}

if ($identifier) {
$url = "http://www.omdbapi.com/?i=$identifier&r=XML&tomatoes=true&plot=full";
} else {
$url = "http://www.omdbapi.com/?t=$movie&r=XML&tomatoes=true&plot=full";
}
#$url = "http://www.omdbapi.com/?i=$identifier&r=XML";

$omdb = get $url;
$to = get $tu;
$tx = new XML::Simple;
$td = $tx->XMLin("$to");
$splot = $td->{movie}->{plot};

$moviexml = new XML::Simple;
$moviedata = $moviexml->XMLin("$omdb");

$response = $moviedata->{response};
$year = $moviedata->{movie}->{year};
$imdbID = $moviedata->{movie}->{imdbID};
$genres = $moviedata->{movie}->{genre};
$director = $moviedata->{movie}->{director};
$writer = $moviedata->{movie}->{writer};
$plot = $moviedata->{movie}->{plot};
$title = $moviedata->{movie}->{title};
$type = $moviedata->{movie}->{type};
$actors = $moviedata->{movie}->{actors};
$rated = $moviedata->{movie}->{rated};
$poster = $moviedata->{movie}->{poster};
@genres = split /\,/, $genres;
$genre = @genres[0];
$production = $moviedata->{movie}->{Production};
$copy = chr(169);

trim ( $title );
trim ( $type );
trim ( $year );
trim ( $genre );
trim ( $genres[0]);

$type = ucfirst($type);


if ("$debug" == "1") {
	#print "$response \n";
	#print "$year \n";
	print Dumper $moviedata;
	#exit;
}


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

if ( $height < 699 ) {
	$hdvid = "0";
}
if ( $height > 700 ) {
	$hdvid = "1";
}
if ( $height > 999 ) {
	$hdvid = "2";
}

if ($file_path eq '') {
	($cover, $directories) = fileparse("$poster");
	@coverlist = split(/\(/, $cover);
	$tmpfile = '/tmp/' . $poster;
	$tmpfile =~ s/\s+$//;
	
	getstore ($coverurl, $tmpfile);
	$file_path = $tmpfile;
}
#	print $file_path;
#	exit 1;
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
	if ($identifier eq ''){
		$identifier = $imdbID;
	}
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
print "Poster: \t$poster\n";
print "Cover File: \t$file_path\n";
print "Directors: \t$director\n";
print "Cast: \t\t$actors\n";
print "Writers: \t$writer\n";
print "Plot: \t\t$plot\n";
print "Short Plot: \t$splot\n";
print "Full Plot: \t$full_plot\n";
print "Storyline: \t$storyline\n";
print "Duration: \t$duration\n";
print "Genre: \t\t$genre\n";
print "Temp File: \t$tmpfile\n\n";
print "************************************\n\n";

exit 0;
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
	system "/usr/local/bin/mp4art -o -q --add \"$file_path\" \"$file\"";
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
	$command[3] = "-hdvideo \"$hdvid\"";	
	$command[4] = "-comment \"$mpaa\"";
	$command[5] = "-genre \"$genre\"";
	$command[6] = "-year \"$year\"";
	$command[7] = "-song \"$title\"";
	$command[8] = "-rating \"$rated\"";
	$command[9] = "-crating \"$crating\"";	
	$command[10] = "-description \"$splot\"";
	$command[11] = "-longdesc \"$plot\"";	
	$command[12] = "-rannotation \"$mpaa\"";
	$command[13] = "-cast \"$actors\"";
	$command[14] = "-director \"$director\"";
	$command[15] = "-swriters \"$writer\"";
	$command[16] = "-studio \"$production\"";
	$command[17] = "-copyright \"$copy $production\"";
	$command[18] = "\"$file\"";
}


open (STDOUT, "| tee -ai log.txt");
print "IMDB id: $identifier\n";
print "Title: $title\n";
print "Type: $type\n";
print "Year: $year\n";
print "Rated: $rated\n";
print "MPAA Rating: $mpaa\n";
print "Companies: $production\n";
print "Cover URL: $poster\n";
print "Cover File: $file_path\n";
print "Directors: $director\n";
print "Cast: $actors\n";
print "Writers: $writer\n";
print "Plot: $splot\n";
print "Full Plot: $plot\n";
print "Storyline: $storyline\n";
print "Duration: $duration\n";
print "Genres: $genre\n";
print "Genre: $genre\n";
print "Temp File: $tmpfile\n";
print "\$use = $use\n\n";
print Dumper(@command);
print "===========================================\n\n\n";
close (STDOUT);

system("@command") == 0
	or die "system @command failed: $?";
exit 0;
