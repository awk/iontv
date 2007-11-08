#!/usr/bin/perl

$BRANCH = main;

use Env qw(DEPOT_TOP);
use Env qw(BRANCH);

use File::Copy;
use Date::Format;


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

printf("Removing build output folder, old packages and old zip archive\n");
system("rm -rf build");
system("rm -f iOnTV_*.zip");
system("rm -f iOnTV.pkg");

printf("Creating Source Archive source-$lc\n");
system("cd ..; tar -cf iOnTV-src-$lc.tar --exclude '*build*' ./");
system("cd ..;gzip iOnTV-src-$lc.tar");
printf("Source Archive created\n");

system("xcodebuild -target 'All recsched' -configuration Release BUNDLE_VERSION=$lc");
print("Build Complete\n");

printf("Creating Package\n");
system("/Developer/usr/bin/packagemaker --doc iOnTV.pmdoc --version $lc --out iOnTV.pkg");

printf("Creating zip archive for sparkle\n");
system("cd build/Release; zip ../../iOnTV_$lc -r9q ./iOnTV.app");

exit 0;

