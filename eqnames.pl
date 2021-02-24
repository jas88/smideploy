#!/usr/bin/perl -w

use strict;

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
  print "rabbitmqadmin queue name=$_\n";
}
foreach (sort keys %e) {
  my $type=$_=~/control/i ? 'topic':'direct';
  print "rabbitmqadmin exchange declare name=$_ type=$type\n";
}