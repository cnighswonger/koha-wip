#!/usr/bin/perl
#
# This is to test C4/Koha
# It requires a working Koha database with the sample data

use strict;
use warnings;
use C4::Context;

use Test::More tests => 4;
use DateTime::Format::MySQL;

eval {use Test::Deep;};

BEGIN {
    use_ok('C4::Koha', qw( :DEFAULT GetDailyQuote ));
    use_ok('C4::Members');
}

my $dbh = C4::Context->dbh;

subtest 'Authorized Values Tests' => sub {
    plan tests => 6;

    my $data = {
        category            => 'CATEGORY',
        authorised_value    => 'AUTHORISED_VALUE',
        lib                 => 'LIB',
        lib_opac            => 'LIBOPAC',
        imageurl            => 'IMAGEURL'
    };


# Insert an entry into authorised_value table
    my $query = "INSERT INTO authorised_values (category, authorised_value, lib, lib_opac, imageurl) VALUES (?,?,?,?,?);";
    my $sth = $dbh->prepare($query);
    my $insert_success = $sth->execute($data->{category}, $data->{authorised_value}, $data->{lib}, $data->{lib_opac}, $data->{imageurl});
    ok($insert_success, "Insert data in database");


# Tests
    SKIP: {
        skip "INSERT failed", 5 unless $insert_success;

        is ( GetAuthorisedValueByCode($data->{category}, $data->{authorised_value}), $data->{lib}, "GetAuthorisedValueByCode" );
        is ( GetKohaImageurlFromAuthorisedValues($data->{category}, $data->{lib}), $data->{imageurl}, "GetKohaImageurlFromAuthorisedValues" );

        my $sortdet=C4::Members::GetSortDetails("lost", "3");
        is ($sortdet, "Lost and Paid For", "lost and paid works");

        my $sortdet2=C4::Members::GetSortDetails("loc", "child");
        is ($sortdet2, "Children's Area", "Child area works");

        my $sortdet3=C4::Members::GetSortDetails("withdrawn", "1");
        is ($sortdet3, "Withdrawn", "Withdrawn works");
    }

# Clean up
    if($insert_success){
        $query = "DELETE FROM authorised_values WHERE category=? AND authorised_value=? AND lib=? AND lib_opac=? AND imageurl=?;";
        $sth = $dbh->prepare($query);
        $sth->execute($data->{category}, $data->{authorised_value}, $data->{lib}, $data->{lib_opac}, $data->{imageurl});
    }
};
### test for C4::Koha->GetDailyQuote()
SKIP:
    {
        skip "Test::Deep required to run the GetDailyQuote tests.", 1 if $@;

        subtest 'Daily Quotes Test' => sub {
            plan tests => 4;

            SKIP: {

                skip "C4::Koha can't \'GetDailyQuote\'!", 3 unless can_ok('C4::Koha','GetDailyQuote');

                my $expected_quote = {
                    id          => 3,
                    source      => 'Abraham Lincoln',
                    text        => 'Four score and seven years ago our fathers brought forth on this continent, a new nation, conceived in Liberty, and dedicated to the proposition that all men are created equal.',
                    timestamp   => re('\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2}'),   #'0000-00-00 00:00:00',
                };

# test quote retrieval based on id

                my $quote = GetDailyQuote('id'=>3);
                cmp_deeply ($quote, $expected_quote, "Got a quote based on id.") or
                    diag('Be sure to run this test on a clean install of sample data.');

# test random quote retrieval

                $quote = GetDailyQuote('random'=>1);
                ok ($quote, "Got a random quote.");

# test quote retrieval based on today's date

                my $query = 'UPDATE quotes SET timestamp = ? WHERE id = ?';
                my $sth = C4::Context->dbh->prepare($query);
                $sth->execute(DateTime::Format::MySQL->format_datetime(DateTime->now), $expected_quote->{'id'});

                DateTime::Format::MySQL->format_datetime(DateTime->now) =~ m/(\d{4}-\d{2}-\d{2})/;
                $expected_quote->{'timestamp'} = re("^$1");

#        $expected_quote->{'timestamp'} = DateTime::Format::MySQL->format_datetime(DateTime->now);   # update the timestamp of expected quote data

                $quote = GetDailyQuote(); # this is the "default" mode of selection
                cmp_deeply ($quote, $expected_quote, "Got a quote based on today's date.") or
                    diag('Be sure to run this test on a clean install of sample data.');
            }
        };
}
