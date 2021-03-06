#!/usr/bin/perl -w

use strict;

# Convert files given in lst-file created by findFiles.pl to CoNNL using DTAG

my $sessionID = $ARGV[0];
my $language = $ARGV[1];

# Use tag-feauture in conll-output instead of msd-feature
my $useTag = 0;
if ($ARGV[2] eq "tag") {
    $useTag = 1;
}



# Get location of dtag
open(DTAG, "pathToDTAG.conf");
my $dtag = <DTAG>;
chomp $dtag;
close(DTAG);

# $sessionID = 0;
# $language = "it";


my $dtagCommand = "$dtag -e '";
if ($useTag) {
    $dtagCommand = $dtagCommand."option conll_postag=tag;;option conll_cpostag=tag;;";
} else {
$dtagCommand = $dtagCommand."option conll_postag=msd;;option conll_cpostag=msd;;";
}

open (TRFILES, "$sessionID-$language.trainingFiles.lst");
while (my $line = <TRFILES>) {

    chomp $line;
    
    # get 'local' filename
    $line =~ /.*\/(.*)/;
    my $lFilename = $1;
    
    # SLOW concatanation - fix this if necessary
    $dtagCommand = "$dtagCommand"."load $line;;save -conll $sessionID-$language.$lFilename.conll;;";
}
close (TRFILES);


$dtagCommand = "$dtagCommand"."exit'";


system("$dtagCommand");


$dtagCommand = "$dtag -e '";

open (TPFILES, "$sessionID-$language.toParseFiles.lst");
while (my $line = <TPFILES>) {

    chomp $line;
    
    # get 'local' filename
    $line =~ /.*\/(.*)/;
    my $lFilename = $1;
    
    # SLOW concatanation - fix this if necessary
    $dtagCommand = "$dtagCommand"."load $line;;save -conll $sessionID-$language.$lFilename.conll;;";
}
close (TPFILES);

$dtagCommand = "$dtagCommand"."exit'";

system("$dtagCommand");




