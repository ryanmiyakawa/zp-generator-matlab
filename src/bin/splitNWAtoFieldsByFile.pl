# This script splits a wrv file to fields
# #
# # USE:   perl splitWRVtoFieldsByFile.pl [input WRV file] [nBlockSide] [blockSize] [output filename]

use POSIX;
use List::Util qw[min max];
use Math::Trig;

open (NWASRC, $ARGV[0]);
open (OUTFILE, '>'.$ARGV[3]);

$nBlockSide = $ARGV[1];
$blockSize = $ARGV[2];

my $arcCt = 0;

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

my $r   = 0;
my $dr  = 0;
my $th  = 0;
my $dth = 0;
my $cx  = 0;
my $cy  = 0;
my $cOfX = 0;
my $cOfY = 0;
my $pD  = 0;
my $pS  = 0;
my $pT  = 0;

$cenCoord = $nBlockSide * $blockSize/2;

$isStitch = 0;


while (<NWASRC>) {
    if (!$isStitch and $_ =~ m/\[STITCH\]/){
        $isStitch = true;

        print OUTFILE $_;
        print OUTFILE "\012";
        print "stitch found";
    } elsif(!$isStitch){
        print OUTFILE $_;
    } elsif ($_ =~ m/ARC_S/){
        # print "arc";
        $arcCt++;
        $_ =~ m/^\s*ARC_S\s+(\d+\.?\d*)\s+(\d+\.?\d*)\s+(\d+\.?\d*)\s+(\d+\.?\d*)\s+(-?\d+\.?\d*)\s+(-?\d+\.?\d*)\s+(-?\d+\.?\d*)\s+(-?\d+\.?\d*)\s+(D\d+\.?\d*)\s+(S\d+\.?\d*)\s+(T-\d+\.?\d*)\s*/;
        
        # Set matched arc variables:
        $r      = $1;
        $th     = $2;
        $dr     = $3;
        $dth    = $4;
        $cx     = $5;
        $cy     = $6;
        $cOfX   = $7;
        $cOfY   = $8;
        $pD     = $9;
        $pS     = $10;
        $pT     = $11;

        #  print "Matches: $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11\n";

        # Find min x and min y:
        
        my $thDegL = deg2rad($th - $dth/2);
        my $thDegH = deg2rad($th + $dth/2);

        # print "th,dth: [$th, $dth], thL,H: [$thDegL, $thDegH]\n";
        my $minX = min($r*cos($thDegL), $r*cos($thDegH)) + $cenCoord;
        my $minY = min($r*sin($thDegL), $r*sin($thDegH)) + $cenCoord;

        # Need to shift each coordinate by half the total field:
        $kc = floor(($minX) / $blockSize);
        $kr = floor(($minY) / $blockSize);

        # print "xy: [$minX, $minY], RC: [$kr, $kc]\n";

        $cOfX -= -$cenCoord + $blockSize/2 + $kc * $blockSize;
        $cOfY -= -$cenCoord + $blockSize/2 + $kr * $blockSize;

        my $offsetLine = "ARC_S   $r   $th   $dr   $dth   $cx   $cy   $cOfX   $cOfY   $pD   $pS   $pT\012";

        # Rebuild line using elements:
        if (exists($files_ref[$kr * $nBlockSide + $kc])){
            my $fh = $files_ref[$kr * $nBlockSide + $kc];
            print $fh "$offsetLine";
        } else {
            print "WARNING: skipping arc out of bounds:\n$_"
        }
        
    } else {
        print "no cases";
    }
}



print "\nProcessing of NWA file @ARGV[0] complete.  Processed clock speeds on $arcCt arcs.\n\n";
