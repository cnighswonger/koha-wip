#!/usr/bin/perl

# This file is part of Koha.
#
# Copyright 2020, 2026 Koha Development team
# Copyright (C) 2017  Mark Tompsett
#
# Koha is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# Koha is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Koha; if not, see <https://www.gnu.org/licenses>.

use Modern::Perl;

BEGIN {
    eval { require PDF::Reuse; PDF::Reuse->VERSION(0.43) };
    if ($@) {
        require Test::More;
        Test::More::plan( skip_all => 'PDF::Reuse >= 0.43 required (see Bug 41717)' );
    }
}

use Test::NoWarnings;
use Test::More tests => 11;
use Test::Warn;
use t::lib::TestBuilder;
use t::lib::Mocks;

use MARC::Record;
use MARC::Field;
use Data::Dumper;
use File::Temp qw( tempfile );

use C4::Items;
use C4::Biblio;
use C4::Labels::Layout;
use C4::Creators::PDF;

use Koha::Database;

use_ok('C4::Labels::Label');

# Slurp whatever C4::Creators::PDF::End() prints to the currently selected
# filehandle, return it as a string. Centralises the tempfile/select/End
# dance so a future End() refactor only needs one edit. Dies if End()
# dies (after restoring the selected filehandle) so cleanup-only callers
# cannot silently pass through an End() regression.
sub capture_pdf_end {
    my ($pdf) = @_;
    my ( $fh, $path ) = tempfile( SUFFIX => '.pdf', UNLINK => 1 );
    open( my $out, '>', $path ) or die "Cannot open $path for write: $!";
    my $orig = select $out;
    eval { $pdf->End() };
    my $end_err = $@;
    select $orig;
    close $out;
    die "pdf End() failed: $end_err" if $end_err;
    open( my $in, '<', $path ) or die "Cannot open $path for read: $!";
    local $/;
    my $content = <$in>;
    close $in;
    return $content;
}

my $schema = Koha::Database->new->schema;
$schema->storage->txn_begin;

my $batch_id;
my ( $llx, $lly ) = ( 0, 0 );
my $frameworkcode = q{};

## Setup Test
my $builder = t::lib::TestBuilder->new;

# Add branch
my $branch_1 = $builder->build( { source => 'Branch' } )->{branchcode};

# Add categories
my $category_1 = $builder->build( { source => 'Category' } )->{categorycode};

# Add an item type
my $itemtype = $builder->build( { source => 'Itemtype', value => { notforloan => 0 } } )->{itemtype};

t::lib::Mocks::mock_userenv( { branchcode => $branch_1 } );

my $bibnum = $builder->build_sample_biblio( { frameworkcode => $frameworkcode } )->biblionumber;

# Create a helper item instance for testing
my $item = $builder->build_sample_item(
    {
        library      => $branch_1,
        itype        => $itemtype,
        biblionumber => $bibnum,
        enumchron    => "enum",
        copynumber   => "copynum"
    }
);
my $itemnumber = $item->itemnumber;

# Modify item; setting barcode.
my $testbarcode = '97531';
$item->barcode($testbarcode)->store;

my $layout = C4::Labels::Layout->new( layout_name => 'TEST' );

my $dummy_template_values = {
    creator          => 'Labels',
    profile_id       => 0,
    template_code    => 'Avery 5160 | 1 x 2-5/8',
    template_desc    => '3 columns, 10 rows of labels',
    page_width       => 8.5,
    page_height      => 11,
    label_width      => 2.63,
    label_height     => 1,
    top_text_margin  => 0.139,
    left_text_margin => 0.0417,
    top_margin       => 0.35,
    left_margin      => 0.23,
    cols             => 3,
    rows             => 10,
    col_gap          => 0.13,
    row_gap          => 0,
    units            => 'INCH',
    template_stat    => 1,
    barcode_width    => 0.8,
    barcode_height   => 0.01
};

my $label_info = {
    batch_id         => $batch_id,
    item_number      => $item->itemnumber,
    llx              => $llx,
    lly              => $lly,
    width            => $dummy_template_values->{'label_width'},
    height           => $dummy_template_values->{'label_height'},
    top_text_margin  => $dummy_template_values->{'top_text_margin'},
    left_text_margin => $dummy_template_values->{'left_text_margin'},
    barcode_type     => $layout->get_attr('barcode_type'),
    printing_type    => 'BIB',
    guidebox         => $layout->get_attr('guidebox'),
    oblique_title    => $layout->get_attr('oblique_title'),
    font             => $layout->get_attr('font'),
    font_size        => $layout->get_attr('font_size'),
    callnum_split    => $layout->get_attr('callnum_split'),
    justify          => $layout->get_attr('text_justify'),
    text_wrap_cols   => $layout->get_text_wrap_cols(
        label_width      => $dummy_template_values->{'label_width'},
        left_text_margin => $dummy_template_values->{'left_text_margin'}
    ),
    scale_width  => $dummy_template_values->{barcode_width},
    scale_height => $dummy_template_values->{barcode_height},
};

my $format_string  = '100a 245a';
my $barcode_width  = $label_info->{scale_width} * $label_info->{width};
my $barcode_height = $label_info->{scale_height} * $label_info->{height};
my $label          = C4::Labels::Label->new( %$label_info, format_string => $format_string );
my $label_text     = $label->create_label();
ok( defined $label_text, 'Label Text Value defined.' );
my $label_csv_data = $label->csv_data();
is_deeply(
    $label_csv_data,
    [ sprintf( "%s %s", $item->biblio->author, $item->biblio->title ) ]
);

$format_string  = '100a 245a,enumchron copynumber';
$label          = C4::Labels::Label->new( %$label_info, format_string => $format_string );
$label_csv_data = $label->csv_data();
is_deeply(
    $label_csv_data,
    [
        sprintf( "%s %s", $item->biblio->author, $item->biblio->title ),
        sprintf( "%s %s", $item->enumchron,      $item->copynumber )
    ]
);
is( $barcode_width,  '2.104', );
is( $barcode_height, '0.01', );

# ========================================
# Subtest: draw_label_text() deep assertions
# ========================================
subtest 'draw_label_text() returns correct text structure' => sub {
    plan tests => 6;

    # Local fixture: deterministic two-field format so this subtest does
    # not depend on whatever was last assigned to the top-level $format_string.
    my $local_format = '100a 245a,enumchron copynumber';

    my $label_bib = C4::Labels::Label->new(
        %$label_info,
        format_string => $local_format,
        printing_type => 'BIB',
        justify       => 'L',
    );
    my $text_result = $label_bib->create_label();

    ok( defined $text_result, 'create_label(BIB) returns defined value' );
    is( ref $text_result, 'ARRAY', 'Return value is an arrayref' );
    cmp_ok( scalar @$text_result, '>=', 2, 'Two-field format yields at least two text lines' );

    my $first_line       = $text_result->[0];
    my $expected_llx     = $label_info->{llx} + $label_info->{left_text_margin};
    my $expected_first_y = $label_info->{lly} + $label_info->{height} - $label_info->{top_text_margin};

    is(
        $first_line->{text_llx}, $expected_llx,
        'First line text_llx = llx + left_text_margin (justify L)'
    );
    is(
        $first_line->{text_lly}, $expected_first_y,
        'First line text_lly = lly + height - top_text_margin (per _BIB)'
    );
    cmp_ok(
        $text_result->[1]{text_lly}, '<', $first_line->{text_lly},
        'Second line text_lly is less than first (text flows downward)'
    );
};

# ========================================
# Subtest: draw_guide_box()
# ========================================
subtest 'draw_guide_box() returns PDF stream when enabled' => sub {
    plan tests => 3;

    my $label_with_box = C4::Labels::Label->new(
        %$label_info,
        format_string => $format_string,
        guidebox      => 1,
        llx           => 10,
        lly           => 20,
        width         => 100,
        height        => 50,
    );
    my $box_stream = $label_with_box->draw_guide_box();
    ok( $box_stream, 'draw_guide_box returns truthy when guidebox enabled' );
    like( $box_stream, qr/10 20 100 50 re/, 'PDF stream contains expected rectangle coordinates' );

    my $label_no_box = C4::Labels::Label->new(
        %$label_info,
        format_string => $format_string,
        guidebox      => 0,
    );
    ok( !$label_no_box->draw_guide_box(), 'draw_guide_box returns falsy when guidebox disabled' );
};

# ========================================
# Subtest: barcode() with all supported types
# ========================================
subtest 'barcode() generates all supported barcode types' => sub {
    plan tests => 7;

    # Local fixture; do not inherit top-level $format_string state.
    my $local_format = '100a 245a';

    my $pdf = C4::Creators::PDF->new( InitVars => 1 );
    $pdf->Page();

    # C4::Labels::Label::barcode() converts every PDF::Reuse::Barcode::*
    # failure to a warn (Label.pm:556,573,590,609), so a per-type test that
    # only checks "did it die" cannot distinguish success from a silent
    # barcode-generation failure. We therefore assert no barcode-generation
    # warning fires for each type, which is the actual breakage signal.
    # CODE39MOD10 (modulo-10 / 'siret') needs numeric data; alpha input
    # yields an empty checksum and silently degenerates.
    my @barcode_tests = (
        { type => 'CODE39',         barcode => 'TEST97531',     desc => 'CODE39' },
        { type => 'CODE39MOD',      barcode => 'TEST97531',     desc => 'CODE39MOD (modulo43 checksum)' },
        { type => 'CODE39MOD10',    barcode => '97531',         desc => 'CODE39MOD10 (modulo10 checksum)' },
        { type => 'COOP2OF5',       barcode => '97531',         desc => 'COOP2OF5 (numeric)' },
        { type => 'INDUSTRIAL2OF5', barcode => '97531',         desc => 'INDUSTRIAL2OF5 (numeric)' },
        { type => 'EAN13',          barcode => '5901234123457', desc => 'EAN13 (13-digit)' },
    );

    for my $bc_test (@barcode_tests) {
        my $bc_label = C4::Labels::Label->new(
            %$label_info,
            format_string => $local_format,
            printing_type => 'BAR',
            barcode_type  => $bc_test->{type},
            barcode       => $bc_test->{barcode},
        );
        warnings_are { $bc_label->create_label() } [],
            "barcode() $bc_test->{desc} emits no barcode-generation warning";
    }

    # Slurp the PDF and assert it contains at least one barcode graphic
    # stroke (Code39 / 2-of-5 / EAN13 all emit rectangle 're' operators),
    # so the per-type checks above can't all pass against an empty document.
    my $content = capture_pdf_end($pdf);
    like( $content, qr/\bre\b/, 'PDF contains barcode rectangle operators' );
};

# ========================================
# Subtest: create_label() printing type orchestration
# ========================================
subtest 'create_label() printing type orchestration' => sub {
    plan tests => 5;

    my $local_format = '100a 245a';

    my $pdf = C4::Creators::PDF->new( InitVars => 1 );
    $pdf->Page();

    # BIB - returns label_text (text only)
    my $label_bib = C4::Labels::Label->new(
        %$label_info,
        format_string => $local_format,
        printing_type => 'BIB',
    );
    my $bib_result = $label_bib->create_label();
    ok( defined $bib_result, 'BIB printing type returns label text' );

    # BAR - returns undef (barcode only)
    my $label_bar = C4::Labels::Label->new(
        %$label_info,
        format_string => $local_format,
        printing_type => 'BAR',
        barcode_type  => 'CODE39',
        barcode       => 'ORCHTEST1',
    );
    my $bar_result = $label_bar->create_label();
    ok( !defined $bar_result, 'BAR printing type returns undef (barcode only)' );

    # BIBBAR - text-above-barcode geometry (text near top of label)
    my $label_bibbar = C4::Labels::Label->new(
        %$label_info,
        format_string => $local_format,
        printing_type => 'BIBBAR',
        barcode_type  => 'CODE39',
        barcode       => 'ORCHTEST2',
    );
    my $bibbar_result = $label_bibbar->create_label();
    ok( defined $bibbar_result, 'BIBBAR printing type returns label text' );

    # BARBIB - barcode-above-text geometry (text shifted downward)
    my $label_barbib = C4::Labels::Label->new(
        %$label_info,
        format_string => $local_format,
        printing_type => 'BARBIB',
        barcode_type  => 'CODE39',
        barcode       => 'ORCHTEST3',
    );
    my $barbib_result = $label_barbib->create_label();
    ok( defined $barbib_result, 'BARBIB printing type returns label text' );

    # If _BIBBAR and _BARBIB were swapped, both return arrays with defined
    # entries and the four checks above would still pass. Pin the geometric
    # contract: BIBBAR puts text above BARBIB's text.
    cmp_ok(
        $bibbar_result->[0]{text_lly}, '>', $barbib_result->[0]{text_lly},
        'BIBBAR places first text line above BARBIB (text_lly higher)'
    );

    capture_pdf_end($pdf);
};

$schema->storage->txn_rollback();

1;
