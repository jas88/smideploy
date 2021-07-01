#!/usr/bin/perl -w
#
# Quick hack so CTPAnonymiser doesn't blow up immediately due to missing
# SRanon script

use strict;
use YAML::Tiny;

my $yaml=YAML::Tiny->read($ARGV[0]) || die "Bad YAML:$!\n";

$yaml->[0]->{CTPAnonymiserOptions}->{SRAnonTool}='/smi/dummy.sh';

$yaml->write($ARGV[0]);

