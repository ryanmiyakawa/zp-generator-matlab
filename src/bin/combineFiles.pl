# This script splits a wrv file to fields
# #
# # USE:   perl combinefiles.pl [input WRV file] [nBlockSide] [blockSize] [output filename]

use POSIX;

open (OUTFILE, '>>'.$ARGV[3]);

$nBlockSide = $ARGV[1];
$blockSize = $ARGV[2];

$trapCt = 0;

for (my $kr = 0; $kr < $nBlockSide; $kr++){
    for (my $kc = 0; $kc < $nBlockSide; $kc++){
        print OUTFILE "\n\nfield $kc $kr\n";


        my $subFileName = $ARGV[3]."_$kr"."_$kc";
        local *FILE;
        open (FILE, $subFileName);

        # store lines into array, maybe this will help issue of file not being completely read
        my @lines = ();

        while (<FILE>){
            $trapCt++;
            if ($trapCt % 200000 == 0 && $trapCt > 0){
                print "Processed $trapCt lines.\n";
            }
            # push(@lines, $_);
            print OUTFILE "$_";
        }

        # # Delete the sub file:
        unlink($subFileName);

    }
}



print "\nProcessing of WRV file @ARGV[0] complete.  Processed clock speeds on $trapCt shapes.\n\n";
