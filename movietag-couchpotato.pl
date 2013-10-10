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
use IMDB::Film;
use LWP::Simple;
use DBI;
use Cwd;
use Text::Trim;

if ($#ARGV != 0) {
	print "usage: movietag-couchpotato.pl <movie file>\n";
	exit;
}
$location = dirname $0;
$config = "$ENV{HOME}/.movietag/config";
#######################################################################################
# READ IN CONFIG FILE FROM ~/.tvtag/config
#######################################################################################
if ( -e "$ENV{HOME}/.movietag") {
	if ( -e "$config") {
		do "$ENV{HOME}/.movietag/config";
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
my ($filename, $directories) = fileparse("$file");
@filelist = split(/\(/, $filename);
my $movie = $filelist[0];
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

my $imdbObj = new IMDB::Film(crit => "$identifier");
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
$rating = $ratings[1];

trim ( $title );
trim ( $type );
trim ( $year );
trim ( $genre );

$type = ucfirst($type);

if ($rating eq '') {
	$rating = 'Not Rated';
}

if ($genre eq 'Action') {
	$genre = 'Action & Adventure';
}
if ($genre eq 'Adventure') {
	$genre = 'Action & Adventure';
}
if ($genre eq 'Kids') {
	$genre = 'Kids & Family';
}
if ($genre eq 'Family') {
	$genre = 'Kids & Family';
}
if ($genre eq 'Science Fiction') {
	$genre = 'Sci-Fi & Fantasy';
}
if ($genre eq 'Sci-Fi') {
	$genre = 'Sci-Fi & Fantasy';
}
if ($genre eq 'Fantasy') {
	$genre = 'Sci-Fi & Fantasy';
}

if ($file_path eq '') {
	($cover, $directories) = fileparse("$coverurl");
	@coverlist = split(/\(/, $cover);
	$tmpfile = '/tmp/' . $coverlist[0];
	$tmpfile =~ s/\s+$//;
	
	getstore ($coverurl, $tmpfile);
	$file_path = $tmpfile;
}

if ("$debug" == "1") {
print "Title: $title\n";
print "Type: $type\n";
print "Year: $year\n";
print "Rating: $rating\n";
print "MPAA Rating: $mpaa\n";
print "Companies: join(", ", @companies)\n";
print "Companies: $companies\n";
print "Cover URL: $coverurl\n";
print "Cover File: $file_path\n";
print "Directors: @directors\n";
print "Plot: $plot\n";
print "Full Plot: $full_plot\n";
print "Storyline: $storyline\n";
print "Duration: $duration\n";
print "Genre: $genre\n";
print "Temp File: $tmpfile\n";
}
$full_plot =~ s/\"/\\"/g;
$full_plot =~ s/\'/\\'/g;



#system ("rm -f \"$cover->file\"");
#exit;
#######################################################################################
# Populate Variables to be tagged.
#######################################################################################
my $Type = "Movie";
my $HD = "yes";
if ($HD eq "yes") {
	$hdvid = "1";
}

if ($rating eq 'R') {
	$crating = "Explicit";
} elsif ($rating eq 'Not Rated') {
	$crating = "None";
} else {
	$crating = "Clean";
}

#@GenreList = split(/\|/, $Genre);
#$Genre = $GenreList[1];
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

} elsif ("$use" eq "ATOMIC") {
	$command[0] = "$tagger";
	$command[1] = "\"$file\""; 
	$command[2] = "--title \"$movie_title\""; 
	$command[3] = "--stik \"$Type\"";
	if ($BannerImage) {
		$command[4] = "--artwork \"$BannerImage\"";
	} else {
		print "\n\n\tWARNING: THIS FILE WILL NOT CONTAIN ANY COVER ART, NO IMAGE FILE WAS FOUND!\n\n";
		$command[4] = "";
	}
	#$command[5] = "--is_hd_video $HD";
	#$command[6] = "--TVEpisode \"$ProductionCode\"";
	#$command[7] = "--TVEpisodeNum \"$EpisodeNumber\"";
	#$command[8] = "--TVSeasonNum \"$SeasonNumber\"";
	#$command[9] = "--TVNetwork \"$TVNetwork\"";
	#$command[10] ="--title \"$EpisodeName\"";
	#$command[11] = "--genre \"$Genre\"";
	$command[12] = "--year \"$year\""; 
	#$command[13] = "--contentRating \"$Rating\"";
	#$command[14] = "--advisory \"us-tv|TV-PG|400|\"";
	#$command[15] = "--artist \"$Actors\"";
	#$command[16] = "--director \"$Director\"";
	#$command[17] = "--screenwriters \"$Writer\"";
	$command[18] = "--description \"$description\"";
	#$command[19] = "--long_description \"$Description\"";
	#$command[20] = "--tracknum \"$EpisodeNumber\"";
	$command[21] = "--overWrite";

} elsif ("$use" eq "mp4v2") {
	$command[0] = "$tagger";
	#$command[1] = "\"$file\""; 
	$command[2] = "-album \"$title\"";
	#if ($Type eq "TV Show") {
	#	$Type = "tvshow";
	#} elsif ($Type eq "Movie") {
	#	$Type = "movie";
	#}
	$command[3] = "-type \"$type\"";
	#if ($BannerImage) {
	#	$command[4] = "-artwork \"$BannerImage\"";
	#} else {
	#	print "\n\n\tWARNING: THIS FILE WILL NOT CONTAIN ANY COVER ART, NO IMAGE FILE WAS FOUND!\n\n";
	#	$command[4] = "";
	#}
	$command[5] = "-hdvideo $hdvid";
	#$command[6] = "-episodeid \"$EpisodeNumber\"";
	#$command[7] = "-episode \"$EpisodeNumber\"";
	#$command[8] = "-season \"$SeasonNumber\"";
	#$command[9] = "-network \"$TVNetwork\"";
	$command[10] ="-comment \"$mpaa\"";
	$command[11] = "-genre \"$genre\"";
	$command[12] = "-year \"$year\"";
	$command[13] = "-song \"$movie\"";
	$command[14] = "-rating \"$rating\"";
	$command[15] = "-crating \"$crating\"";
	#$command[16] = "-cast \"$Actors\"";
	#$command[17] = "-director \"$Director\"";
	#$command[18] = "-swriters \"$Writer\"";
	$command[19] = "-description \"$description\"";
	$command[20] = "-longdesc \"$description\"";
	#$command[21] = "-track \"$EpisodeNumber\"";
	$command[22] = "-rannotation \"$mpaa\"";
	#$command[23] = "-show \"$title\"";
	#$command[24] = "--name \"$title\"";
	$command[25] = "\"$file\"";
}


#print Dumper(@command);
if ("$use" eq "mp4v2") {
	system ("mp4art -o -q --add \"$file_path\" \"$file\"");
	if ($tmpfile) {
	system ("rm $tmpfile");
	}
}
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