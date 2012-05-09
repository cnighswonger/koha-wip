#!/usr/bin/perl

use strict;
use warnings;

use WWW::Curl::Easy;
use WWW::Mechanize;
use Getopt::Long qw(:config no_ignore_case);
use Data::Dumper;


$|=1;

my $MARC = {};

my $mech = WWW::Mechanize->new(timeout => 30);

#open (CSV, ">>presidential_quotes.csv");
        $mech->get("http://www.loc.gov/marc/bibliographic/ecbdlist.html");
        my $HTML = $mech->content();
        my $pre_tag_flag = 0;
        my $main_category_flag = 0;
        open (FH, "<", \$HTML);
        LINE:
        while (<FH>) {
            next LINE if (m/^$/);
            $pre_tag_flag = 1 if (m/<pre>/g);
            $pre_tag_flag = 0 if (m/<\/pre>/g);
            $main_category_flag = 1 if (m/LEADER/g);
            $main_category_flag = 2 if (m/DIRECTORY/g);
            $main_category_flag = 3 if (m/Control Fields/gi);
            if ($pre_tag_flag) {
                s/^\s+//;
                push @{$MARC->{'leader'}}, $_ if $main_category_flag == 1;
                push @{$MARC->{'directory'}}, $_ if $main_category_flag == 2;
                push @{$MARC->{'control'}}, $_ if $main_category_flag == 3;
            }
            else {
                next LINE;
            }
        }
close FH;

#print Dumper($MARC);

## Parse leader structure

shift @{$MARC->{'leader'}};
shift @{$MARC->{'leader'}};

#die Dumper($MARC->{'control'});

#foreach (@{$MARC->{'leader'}}) {
foreach (@{$MARC->{'control'}}) {
    if (m/^(\d\d)\s-\s([A-Za-z\s]+)\n?/g) {
        print "\nFound tag: $1\n";
        print "Description: $2\n";
    }
    if (m/^([a-z0-9])\s-\s([A-Za-z\s]+)\n?/g) {
        print "Found subfield $1\n";
        print "Description: $2\n";
    }
    if (m/^(\d\d-\d\d)\s-\s([A-Za-z\s]+)\n?/g) {
        print "\nFound tag range $1\n";
        print "Description: $2\n";
    }
    if (m/\((NR|R)\)\n?/g) {
        print "Repeatability: $1\n" if $1;
    }
}

#                m/^(\s+)/;
#                my $count = ($1 ? split(//,$1) : 0);
#                if (m/leader/i) {
#                }
#                print "$count: $_";

#close CSV;
