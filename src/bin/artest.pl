

my @ar_ref = ();

my @ar = (1, 2);
$ar_ref[0] = \@ar;
my @ar = (3, 4);
$ar_ref[1] = \@ar;

# @{$ar_ref[0]}[0] = 1;
# @{$ar_ref[0]}[1] = 2;

# @{$ar_ref[1]}[0] = 3;
# @{$ar_ref[1]}[1] = 4;

foreach (@{$ar_ref[0]}){
    print "$_\n";
}

foreach (@{$ar_ref[1]}){
    print "$_\n";
}