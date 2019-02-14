# This script populates a .WRV file with dose information.
# #
# # USE:   perl processWRV.pl [input WRV file] [ZPInfo file] [output filename]


open (WRVSRC, $ARGV[0]) or die "Can't open file";
open (OUTFILE, '>'.$ARGV[1]);

my @lines = ();
while (<WRVSRC>) {
    push(@lines, $_);
}

my $ct = 0;

for ($i = @lines; --$i; ) {
    $ct++;
    if ($ct % 50000 == 0){
        print "Processed $ct lines.\n";
    }

    
    my $j = int rand ($i+1);

    next if $i == $j;
    next if !(@lines[$j] =~ m/Trap/);
    next if !(@lines[$i] =~ m/Trap/);
    
    @lines[$i,$j] = @lines[$j,$i];
}

foreach (@lines) {
    print OUTFILE $_;
}

print "\nProcessed $ct lines\n";

