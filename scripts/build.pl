#!/usr/bin/perl

$BRANCH = main;

use Env qw(DEPOT_TOP);
use Env qw(BRANCH);

#use lib $DEPOT_TOP . "/$BRANCH/src/build_scripts/macosx";
#use buildcmds;
use File::Copy;
use Date::Format;

# require ($DEPOT_TOP . "/$BRANCH/src/build_scripts/version_info.pl");


# Find the most recent Change Number
system("p4 changes -m 1 -s submitted //recsched/*/$BRANCH/... > /tmp/rs_last_change");
open(LC, "/tmp/rs_last_change");
$change = <LC>;
($t, $lc, $o) = split(/ /, $change, 3);
print("Last change = $lc\n");
close(LC);

print("Synchronizing Tree\n");
system("p4 sync //recsched/*/$BRANCH/...@$lc");
print("Done Synchronization\n");

system("xcodebuild -target 'All recsched' -configuration Release BUNDLE_VERSION=$lc");
system("/Developer/usr/bin/packagemaker --doc iOnTV.pmdoc --version $lc --out iOnTV.pkg");

print("Build Complete\n");

exit 0;

