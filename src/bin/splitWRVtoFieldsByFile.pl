# This script splits a wrv file to fields
# #
# # USE:   perl splitWRVtoFieldsByFile.pl [input WRV file] [nBlockSide] [blockSize] [output filename]

use POSIX;
use List::Util qw[min max];

open (WRVSRC, $ARGV[0]);
open (OUTFILE, '>'.$ARGV[3]);

$nBlockSide = $ARGV[1];
$blockSize = $ARGV[2];

my $trapCt = 0;

my $blockExpandFactor = 1.25; # How much to expand blocksize to accommodate spillover at field boundaries

# Shift all shapes by this offset factor to accomodate for reduced block size
my $centerOffset = ($blockExpandFactor - 1)  * $blockSize/2 * $nBlockSide;
$centerOffset = 0;

print "Recentering WRV file by [$centerOffset, $centerOffset] dbUnits\n";

# Build 2D array for blocks_ref
my @files_ref = ();
for (my $kr = 0; $kr < $nBlockSide; $kr++){
    for (my $kc = 0; $kc < $nBlockSide; $kc++){
        my $subFileName = $ARGV[3]."_$kr"."_$kc";
        local *FILE;
        open (FILE, '>'.$subFileName);
        print "Generating temp subfield file $subFileName\n";
        push(@files_ref, *FILE);
    }
}

my $x1 = 0;
my $y1 = 0;

my $negCt = 0;
my $ct = 0;

while (<WRVSRC>) {

    if ($_ =~ m/patdef/){
        # Expand block size by 10%:
        $_ =~ m/^\s*\w+\s*(\d+)\s(\d+)\s(\d+)\s(\d+\.\d+)\s(\d+\.\d+)\s(\d+)\s(\d+)/;
        my $xExp = $2*$blockExpandFactor;
        my $yExp = $3*$blockExpandFactor;

        print OUTFILE "patdef $1 $xExp $yExp $4 $5 $6 $7\n";
    } elsif($_ =~ m/vepdef/ ){
        print OUTFILE $_;
    } elsif ($_ =~ m/Trap/){
        $trapCt++;
        $_ =~ m/^\s*(\w+)(\/\d+)?\s(\d+\.?\d*)\s(\d+)\s(\d+)\s?(\d+\.?\d*)?\s*(\d+\.?\d*)?\s?(\d*)\s?(\d*)\s?(\d*)\s?(\d*)\s?(\d*)\s?(\d*)/;
        $x1 = $3 + $centerOffset;
        $x2 = $5 + $centerOffset;
        $x3 = $7 + $centerOffset;
        $x4 = $8 + $centerOffset;
        $y1 = $4 + $centerOffset;
        $y2 = $6 + $centerOffset;

         

        $kc = floor(min($x1, $x2, $x3, $x4) / $blockSize);
        $kr = floor(min($y1, $y2) / $blockSize);

        $x1 -= $kc * $blockSize;
        $x2 -= $kc * $blockSize;
        $x3 -= $kc * $blockSize;
        $x4 -= $kc * $blockSize;
        $y1 -= $kr * $blockSize;
        $y2 -= $kr * $blockSize;

        if ($x1 < 0 or $x2 < 0 or $x3 < 0 or $x4 < 0 or $y1 < 0 or $y2 < 0){
            print "WARNING, negative value on line $.:\n";
            print " Original line: x1: $3, x2: $5, x3: $7, x4: $8, y1: $4, y2: $6; Blocksize: $blockSize\n";
            $negCt++;
        }

        # print "Accessing matrix index: [$kr,$kc], blocksize: $blockSize, [x,y] = [$x1, $x2]\n";

        
        my $offsetLine = "$1$2 $x1 $y1 $x2 $y2 $x3 $x4\n";

        if ($offsetLine =~ m/ 0 0 0 0 0 0/){
            print "WARNING: negative clock detected, skipping this shape;\n";
            next;
        }

        next if !($_ =~ m/Trap/);

        # Rebuild line using elements:
        my $fh = $files_ref[$kr * $nBlockSide + $kc];
        print $fh "$offsetLine";
    }
}

if ($negCt > 0){
    print "WARNING, $negCt negative values detected";
}


print "\nProcessing of WRV file @ARGV[0] complete.  Processed clock speeds on $trapCt shapes.\n\n";
