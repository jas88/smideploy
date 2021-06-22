#!/usr/bin/perl -w

use strict;

open my $sh, '<', 'dockerbits.sh' or die "dockerbits.sh:$!\n";
my $l='';
while($l !~ /RABBITGOESHERE/) {
	print $l;
	$l=<$sh>;
}
$l=<$sh>;
my (%e,%q);
while(<>) {
  next unless /\s*(.+):\s*['"](.+)['"]/;
  my ($k,$v)=($1,$2);
  next unless $k=~/(exchange|queue)/i;
  if ($1=~/exchange/i) {
    $e{$v}++;
  } else {
    $q{$v}++;
  }
}

foreach (sort keys %q) {
  print "rabbitmqadmin declare queue name=$_\n";
}
foreach (sort keys %e) {
  my $type=$_=~/control/i ? 'topic':'direct';
  print "rabbitmqadmin declare exchange name=$_ type=$type\n";
}

while(defined $l) {
	print $l;
	$l=<$sh>;
}
