##About:

FindEm-Media-Finder is a perl script that will recursively look through directories passed to it for any .mkv, .avi, .mov, .ts, .mp4, or .iso files and rip them to be .m4v files.  It will then pass the resulting file to the tagging script based on if it's a TV Show or a Movie.  It determines the type based on the name.  TV Shows are assumed to be named `<ShowName> - <Season>x<Episode>.ext` (e.g. Homeland - 2x02.mkv).  Movies are assumed to be named `<Movie Name>(year).ext` (e.g. World War Z(2013).mkv).  Couchpotato, Sickbeard, and imdb are all used for tagging the metadata.

SublerCLI, HandbrakeCLI, MP4Tagger, Atomic Parsley, and mp4v2 (patched) are all used for various functions.  SublerCLI is used where possible to repackage the files in to an .m4v due to it's ability to do it very quickly.  However, there are a few known instances where it is unable to.  Right now, those are .avi files and .iso images.  Those are still being handled by Handbrake.

**findem.pl** - The main workhorse that will do the finding and/or converting of files then pass to one of the tagging scripts.  
**tvtag-sickbeard.pl** - Used to tag TV Shows using the Sickbeard database.  
**movietag-couchpotato.pl** - Used to tag Movies using the Couchpotato database as well as imdb.  
**tagger.pl** - Used to tag either file type, currently using for tagging one-offs.  
**runtime_wrapper** - A wrapper for findem.pl that will only allow one instance of the script to be running at a time.  

##Requirements:

###Perl Modules:
File::Basename  
File::Path  
Data::Dumper  
IMDB::Film  
LWP::Simple  
DBI  
Cwd  
Text::Trim  
File::Find::Rule  
File::Copy  
File::Path  
Email::Valid  
Term::ANSIScreen  
Growl::GNTP  

###Applications:
mp4v2 (patched)  
AtomicParsley  
MP4Tagger  
HandBrakeCLI  
SublerCLI  

##Usage:

	./findem.pl <directory> [<directory>]

##Setup:

On the first run of findem.pl, a config file will be built based on a few questions and stored at ~/.findem/config.  Those questions are:  
   1. Location of HandBrakeCLI? - This is the location of the HandbrakeCLI binary on your system.  
   2. Define HandBrake Preset to use - This can be set to any predefined preset in Handbrake.  
   3. Define Location of your iTunes Auto Add Directory - This is used to drop to finished files in to to be automatically picked up by iTunes.  This is located at [Your iTunes Library]/iTunes Media/Automatically Add to iTunes.  
   4. Location of SublerCLI? - This is the location of the SublerCLI binary on your system.  
   5. Define TV Tag script - This is the path to tvtag-sickbeard.pl.  
   6. Define Movie Tag script - This is the path to movietag-coupotato.pl.  
   7. Define archive directory - This is a directory where the original file will be copied to after it's been ripped.  Original files are never altered by this workflow.  
   8. Use Boxcar for mobile notifications? - If you use boxcar already, or would like to be notified on your mobile device when certains actions happen (file downloads, file finishes ripping, etc) then boxcar is an option.  
   9. Use Gowl for notifications? - Again, used for event notifications on your computer.  
	
Now that the config is built it will re-run, searching for media files in the directories you specified.  It will build a list of files it has found and begin to process those files one by one.  Processing those files consists of ripping to .m4v format, then passing the ripped file to the tagging script.  The first time each tagging script run, it will also build a config file located ~/.movietag/config or ~/.tvtag/config.  It will ask the following questions to build each tagging config file:  

**tvtag-sickbeard.pl:**  
   1. Do you want verbose tagging? - Spits out some extra tagging information, largely non-useful besides when troubleshooting tagging problems.  
   2. Define Tagger to use - Options are MP4Tagger, AtomicParsley, or mp4v2.  Right now, all work fine besides mp4v2, which is being added and expected to be functional shortly.  
   3. Define Location of the Tagger binary -  Location to the binary on your system of the tagger you are using.  
   4. Define Image cache location - Temporary location to write coverart files out to.  
   5. Define Sickbeard directory - This is the location of your Sickbeard install directory.  The location of your sickbeard.db is based off this directory.  
	
**movietag-couchpotato.pl**  
   1. Do you want verbose tagging? - Spits out some extra tagging information, largely non-useful besides when troubleshooting tagging problems.  
   2. Define Tagger to use - Options are MP4Tagger, AtomicParsley, or mp4v2.  Right now, only mp4v2 is currently working.  MP4Tagger is using tmdb 2.1 api which has been deprecated.  
   3. Define Location of the Tagger binary -  Location to the binary on your system of the tagger you are using.  
   4. Define Image cache location - Temporary location to write coverart files out to.  
   5. Define Couchpotato directory - This is the location of your Couchpotato install directory.  
   6. Define couchpotato.db location - This is the location of the couchpotato.db file on your system.  
	
##Optional Usage:

If you wanted to cron this to run every 20 mintues, for example, using the runtime_wrapper, a sample command would look something like the following:  

	*/20 * * * * <path to git checkout>/FindEm-Media-Finder/runtime_wrapper --cmd  
	"<path to git checkout>/FindEm-Media-Finder/findem.pl /Volumes/Media/TV /Volumes/Media/Movies"  
	2>&1 > /dev/null
	
This would search both the TV directory and the Movies directory.  Using the runtime_wrapper would prevent the script from running again until the previous run had completed.  I've found multiple running processes at the same time can cause lots of problems with audio sync and completeness of the finished file.  
	
##More information:

**mp4v2 (patched)** - The vanilla mp4v2 project does not yet include the ability to add mpaa ratings to movies (G, PG-13, R, etc).  So mp4v2 was recompiled using a user submitted patch and now that functionality is there.  I've included a copy of mp4v2 2.0.0 that's been patched.  All that's need is to compile this on your system.  

###Credits:  

HandBrake - [http://handbrake.fr](http://handbrake.fr)  
Subler - [http://code.google.com/p/subler/](http://code.google.com/p/subler/)  
mp4v2 - [https://code.google.com/p/mp4v2/](https://code.google.com/p/mp4v2/)  
AtomicParsley - [http://atomicparsley.sourceforge.net](http://atomicparsley.sourceforge.net)  
MP4Tagger - [https://github.com/ccjensen/MP4Tagger](https://github.com/ccjensen/MP4Tagger)  