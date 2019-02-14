# This script populates a .WRV file with dose information.
# #
# # USE:   perl processWRV.pl [input WRV file] [nBlockSide] [blockSize] [output filename]

use POSIX;
use Fcntl;

open (WRVSRC, $ARGV[0]);
open (OUTFILE, '>'.$ARGV[3]);

$nBlockSide = $ARGV[1];
$blockSize = $ARGV[2];

my $trapCt = 0;

my $blockExpandFactor = 1.25; # How much to expand blocksize to accommodate spillover at field boundaries

# Build 2D array for blocks_ref
my @files_ref = ();
for (my $kr = 0; $kr < $nBlockSide; $kr++){
    for (my $kc = 0; $kc < $nBlockSide; $kc++){
        my $subFileName = $ARGV[3]."_$kr"."_$kc";
        local *FILE;
        open (FILE, '>'.$subFileName);
        push(@files_ref, *FILE);
    }
}

my $x1 = 0;
my $y1 = 0;

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
        $_ =~ m/^\s*(\w+)(\/\d+)?\s(\d+\.?\d*)\s(\d+)\s(\d+)\s?(\d+\.?\d*)?\s*(\d+\.?\d*)?\s?(\d*)\s?(\d*)\s?(\d*)\s?(\d*)\s?(\d*)\s?(\d*)/;
        $x1 = $3;
        $x2 = $5;
        $x3 = $7;
        $x4 = $8;
        $y1 = $4;
        $y2 = $6;

        $kc = floor($x1 / $blockSize);
        $kr = floor($y1 / $blockSize);

        $x1 -= $kc * $blockSize;
        $x2 -= $kc * $blockSize;
        $x3 -= $kc * $blockSize;
        $x4 -= $kc * $blockSize;
        $y1 -= $kr * $blockSize;
        $y2 -= $kr * $blockSize;

        # print "Accessing matrix index: [$kr,$kc], blocksize: $blockSize, [x,y] = [$x1, $x2]\n";

        my $offsetLine = "$1$2 $x1 $y1 $x2 $y2 $x3 $x4\n";
        next if !($_ =~ m/Trap/);

        # Rebuild line using elements:
        my $fh = $files_ref[$kr * $nBlockSide + $kc];
        print $fh "$offsetLine";
    }
}

# for (my $kr = 0; $kr < $nBlockSide; $kr++){
#     for (my $kc = 0; $kc < $nBlockSide; $kc++){
#         close ($files_ref[$kr * $nBlockSide + $kc]);
#     }
# }





for (my $kr = 0; $kr < $nBlockSide; $kr++){
    for (my $kc = 0; $kc < $nBlockSide; $kc++){
        print OUTFILE "\nfield $kc $kr\n";


        my $subFileName = $ARGV[3]."_$kr"."_$kc";
        local *FILE;
        open (FILE, $subFileName);

        while (<FILE>){
            $trapCt++;
            print OUTFILE "$_\n";
            if ($trapCt % 50000 == 0){
                print "Processed $trapCt lines.\n";
            }
        }

        # Delete the sub file:

        unlink($subFileName);

    }
}



print "\nProcessing of WRV file @ARGV[0] complete.  Processed clock speeds on $trapCt shapes.\n\n";
