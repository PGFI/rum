#!/usr/bin/perl

$|=1;

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../../lib";

use RUM::Sort qw(cmpChrs);

if(@ARGV < 4) {
    die "
Usage: sort_by_location.pl <in file> <out file> [options]

  Where:
     <in file> is a tab delimited file with either:
        one column giving locations in the format chr:start-end
        chr, start location and end location given in three different columns

  Options: 

      One of the following must be specified:

      -location_column n : n is the column that has the location (start counting at one)
                           in the case there is one column having the form chr:start-end 

      -location_columns c,s,e : c is the column that has the chromsome (start counting at one)
                                s is the column that has the start location (start counting at one)
                                e is the column that has the end location (start counting at one)
                                c,s,e must be separated by commas, without spaces

      -skip n : skip the first n lines (will preserve those lines at the top of the output).
";
}

my ($infile, $outfile) = @ARGV;

my $option_specified = "false";
my $location = "false";
my $locations = "false";
my $skip = 0;
my $location_column;
my $chr_column;
my $start_column;
my $end_column;

for(my $i=2; $i<@ARGV; $i++) {
    if($ARGV[$i] eq "-location_column") {
	$location_column = $ARGV[$i+1] - 1;
	if(!($location_column =~ /^\d+$/)) {
	    die "\nError: location_column must be a positive integer\n\n";
	} else {
	    if($ARGV[$i+1]  == 0) {
		die "\nError: location_column must be a positive integer\n\n";
	    }
	}
	$location = "true";
	$option_specified = "true";
	$i++;
    }
    if($ARGV[$i] eq "-location_columns") {
	if($ARGV[$i+1] =~ /(\d+),(\d+),(\d+)/) {
	    $chr_column = $1 - 1;
	    $start_column = $2 - 1;
	    $end_column = $3 - 1;
	} else {
	    die "\nError: location_columns must be three positive integers separated by commas, with no spaces.\n\n";
	    exit();
	}
	$locations = "true";
	$option_specified = "true";
	$i++;
    }
    if($ARGV[$i] eq "-skip") {
	$skip = $ARGV[$i+1];
	if(!($skip =~ /^\d+$/)) {
	    die "\nError: -skip must be a positive integer\n\n";
	} else {
	    if($ARGV[$i+1] == 0) {
		die "\nError: location_column must be a positive integer\n\n";
	    }
	}
    }
}
if($option_specified eq "false") {
    die "\nError: one of the two options must be specified.\n\n";
}



open my $in, "<", $infile;
open my $out, ">", $outfile;
for(my $i=0; $i<$skip; $i++) {
    my $line = <$in>;
    print $out $line;
}

my %hash;

while (defined(my $line = <$in>)) {
    chomp($line);
    my @a = split(/\t/,$line);
    my ($chr, $start, $end);
    if ($location eq "true") {
	my $loc = $a[$location_column];
	$loc =~ /^(.*):(\d+)-(\d+)/;
	$chr = $1;
	$start = $2;
	$end = $3;
    }
    if ($locations eq "true") {
	$chr = $a[$chr_column];
	$start = $a[$start_column];
	$end = $a[$end_column];
    }
    $hash{$chr}{$line}[0] = $start;
    $hash{$chr}{$line}[1] = $end;
}
close($in);

for my $chr (sort {cmpChrs($a,$b)} keys %hash) {
    for my $line (sort {
        $hash{$chr}{$a}[0]<=>$hash{$chr}{$b}[0] ||
        $hash{$chr}{$a}[1]<=>$hash{$chr}{$b}[1]
    } keys %{$hash{$chr}}) {
	chomp($line);
	if($line =~ /\S/) {
	    print $out "$line\n";
	}
    }
}

close($out);
