# This script splits a NWA file to fields
# #
# # USE:   perl combinefiles.pl [input NWA file] [nBlockSide] [blockSize] [output filename]

use POSIX;

open (OUTFILE, '>>'.$ARGV[3]);

$nBlockSide = $ARGV[1];
$blockSize = $ARGV[2];

$arcCt = 0;

$cenCoord = $nBlockSide * $blockSize/2;

# Build stitch statements
for (my $kr = 0; $kr < $nBlockSide; $kr++){
    for (my $kc = 0; $kc < $nBlockSide; $kc++){
        my $xStitch = ($kc - ($nBlockSide - 1)/2) * $blockSize;
        my $yStitch = ($kr - ($nBlockSide - 1)/2) * $blockSize;
        print OUTFILE "$xStitch,   $yStitch\012";
    }
}
# Print one additional 0,0 stitch:
print OUTFILE "0,   0\012";

for (my $kr = 0; $kr < $nBlockSide; $kr++){
    for (my $kc = 0; $kc < $nBlockSide; $kc++){
        print OUTFILE "\012[DATA]\012\012";


        my $subFileName = $ARGV[0]."_$kr"."_$kc";
        local *FILE;
        open (FILE, $subFileName);

        # store lines into array, maybe this will help issue of file not being completely read
        my @lines = ();

        while (<FILE>){
            $arcCt++;
            if ($arcCt % 200000 == 0 && $arcCt > 0){
                print "Processed $arcCt lines.\n";
            }
            # push(@lines, $_);
            print OUTFILE "$_";
        }

        # # Delete the sub file:
        unlink($subFileName);

    }
}

# Print one final data line:
print OUTFILE "\012\012[DATA]\012\012";



print "\nProcessing of NWA file @ARGV[0] complete.  Processed clock speeds on $arcCt shapes.\n\n";
