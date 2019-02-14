# This script populates a .WRV file with dose information.
# #
# # USE:   perl processWRV.pl [input WRV file] [ZPInfo file] [output filename]


open (WRVSRC, $ARGV[0]);
open (ZPINFO, $ARGV[1]);
open (OUTFILE, '>'.$ARGV[2]);

$doseMin = 0;
$doseMax = 0;
$Nmin = 100000;
$Nmax = 1;
$trapCt = 0;

# Parse ZP info file that is outputted by Henry's code
while (<ZPINFO>) {
    chomp;
    ~m/^(\w+)\s(\d+\.?\d*)\s(\d+\.?\d*)\s?(\d*\.?\d*)?/;
    if ($1 eq "Dose"){ # Then this is defining the dose.  This happens only once at the top of the file
        $doseMin = $2;
        $doseMax = $3;
    }else{ # Then this is a normal zone definition.  Store zone clock speeds and radii into arrays
        if ($2 < $Nmin){
            $Nmin = $2;
        }
        if ($2 > $Nmax){
            $Nmax = $2;
        }
        $clockTable[$2]     = $3;
        $radiusTable[$2]    = $4;
    }
}

print "Nmin = $Nmin, Nmax = $Nmax\n";
#for (my $k = $Nmin; $k <= $Nmax; $k+=2){
#    print "clocktable $k = $clockTable[$k]\n";
#    print "radiustable $k = $radiusTable[$k]\n";
#}

$blockX = 0;
$blockY = 0;
$blockUnit = 1;

# Parse the WRV file and create a new file that adds the clock times
while (<WRVSRC>){
       chomp;
    ~m/^\s*(\w+)(?:\/\d+)?\s(\d+\.?\d*)\s(\d+)\s(\d+)\s?(\d+\.?\d*)?\s*(\d+\.?\d*)?\s?(\d*)\s?(\d*)\s?(\d*)\s?(\d*)\s?(\d*)\s?(\d*)/;
    # ~m/^\s*(\w+)(?:\/\d+)?\s(\d+)\s(\d+)\s(\d+)\s?(\d*\.?\d*)\s?(\d*\.?\d*)\s?(\d*)\s?(\d*)\s?(\d*)\s?(\d*)\s?(\d*)\s?(\d*)/;

    # print "$1\n";
    if ($1 eq ""){
        next;
    }
    $trapCt++;
    if ($trapCt % 50000 == 0){
        print "Processed $trapCt shapes.\n";
    }

    if ($1 eq "patdef"){
        $blockUnit  = $2 ; # blockunit in microns 
        $blockX     = $3;
        $blockY     = $4;
        print OUTFILE "$1 $2 $3 $4 $doseMin $doseMax\n";
    }elsif ($1 eq "vepdef"){
        print OUTFILE $_."\n";
    }
    else{# shape is rect, trap, arect or atrap

        # Compute the clock time here:
        # First get the coordinate of the centroid, when the offset is removed.  Then compute radius of this centroid
        
        
        my ($xAv, $yAv, $radius); 
        my $xStep = 0;
        my $yStep = 0;
        my $nX = 1;
        my $nY = 1;
        my $route;
        my ($x1, $x2, $x3, $x4, $y1, $y2) = 0;

        if ($1 eq "atrap"){
            $route = "trap";
            $nX = $4;
            $nY = $5;
            $xStep = $2;
            $yStep = $3;
            $x1 = $6;
            $x2 = $8;
            $x3 = $10;
            $x4 = $11;
            $y1 = $7;
            $y2 = $9;
            # print "capture vars: $1 2 = $2 $3 $4 5 = $5, 6=$6, 7=$7 8 = $8, 9= $9 $10 $11 $12\n";
        }
        elsif ($1 eq "trap") {
            $route = "trap";
            $x1 = $2;
            $x2 = $4;
            $x3 = $6;
            $x4 = $7;
            $y1 = $3;
            $y2 = $5;
            # print "routing is trap\n";
        }elsif ($1 eq "arect"){
            $route = "rect";
            $xStep = $2;
            $yStep = $3;
            $nX = $4;
            $nY = $5;
            $x1 = $6;
            $x2 = $8;
            $y1 = $7;
            $y2 = $9;
            # print "routing is arect\n";
        }elsif ($1 eq "rect"){
            $route = "rect";
            $x1 = $2;
            $x2 = $4;
            $y1 = $3;
            $y2 = $5;
        }
        # print "got here?\n vars: nx = $nX, ny = $nY\n";
        $xOffset = 0;
        $yOffset = 0;
        my ($x1m, $x2m, $x3m, $x4m, $y1m, $y2m);
        my $n = 0;
        for (my $kx = 0; $kx < $nX; $kx++){
            for (my $ky = 0; $ky < $nY; $ky++){
                #   print "looping here \n";
                $xOffset = $kx * $xStep;
                $yOffset = $ky * $yStep;
                # print "offsets: xoffset = $xOffset, yOffset = $yOffset\n";

                if ($route eq "trap"){
                    $x1m = $x1 + $xOffset;
                    $x2m = $x2 + $xOffset;
                    $x3m = $x3 + $xOffset;
                    $x4m = $x4 + $xOffset;
                    $y1m = $y1 + $yOffset;
                    $y2m = $y2 + $yOffset;
                    # print "x: $x1m $x2m $x3m $x4m, y: $y1m $y2m\n";
                    $xAv         = ($x1m + $x2m + $x3m + $x4m)/4*$blockUnit - $blockX*$blockUnit/2;
                    $yAv         = ($y1m + $y2m)/2*$blockUnit - $blockY*$blockUnit/2;
                    $xAv /= 1000000;
                    $yAv /= 1000000;
                    $radius      = sqrt($xAv*$xAv + $yAv*$yAv); 
                } elsif($route eq "rect"){
                    $x1m = $x1 + $xOffset;
                    $x2m = $x2 + $xOffset;
                    $y1m = $y1 + $yOffset;
                    $y2m = $y2 + $yOffset;

                    $xAv         = ($x1m + $x2m)/2*$blockUnit - $blockX*$blockUnit/2;
                    $yAv         = ($y1m + $y2m)/2*$blockUnit - $blockY*$blockUnit/2;
                    $xAv /= 1000000;
                    $yAv /= 1000000;
                    $radius      = sqrt($xAv*$xAv + $yAv*$yAv); 
                }
                my $clockTime   = 0;
                
                # Now figure out which zone number corresponds to this radius.  
                # Once the zone number is found, use it to lookup the clock time
                if ($radius < $radiusTable[$Nmin]){
                    $clockTime = $clockTable[$Nmin];
                    $n = $Nmin; 
                }
                elsif ($radius > $radiusTable[$Nmax]){
                    $clockTime = $clockTable[$Nmax];
                    $n = $Nmax;
                }
                else {
                    for ($n = $Nmin + 2; $n <= $Nmax; $n+=2){
                        if ($radius < $radiusTable[$n]){
                            $clockTime = $clockTable[$n - 2];
                            last;
                        }
                    }
                }
                
                if ($route eq "trap"){
                    # print "writing x: $x1m $x2m $x3m $x4m, y: $y1m $y2m\n";

                    print OUTFILE "trap/$clockTime $x1m $y1m $x2m $y2m $x3m $x4m\n"; # zone = $n, radius = $radius, clocktime = $clockTime\n";
                } elsif ($route eq "rect"){
                    print OUTFILE "rect/$clockTime $x1m $y1m $x2m $y2m\n";# zone = $n, radius = $radius, clocktime = $clockTime\n";
                }
            } # End Y loop
        } # End X loop
        
    }


    
}
print "\nProcessing of WRV file @ARGV[0] complete.  Processed clock speeds on $trapCt shapes.\n\n";
