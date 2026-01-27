#!/usr/bin/perl

# This file is part of Koha.
#
# Copyright 2026 Koha Development team
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
use Test::More tests => 8;
use Test::Warn;
use t::lib::TestBuilder;
use t::lib::Mocks;

use File::Temp qw( tempfile );

use C4::Creators::PDF;
use Koha::Database;

use_ok('C4::Patroncards::Patroncard');

# Slurp whatever C4::Creators::PDF::End() prints to the currently selected
# filehandle, return it as a string. Centralises the tempfile/select/End
# dance so a future End() refactor only needs one edit, and so each subtest
# can make assertions against the actual emitted PDF content. Dies if End()
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

# Bug 41718: draw_guide_grid() uses a bare "Courier" font name and calls
# StrWidth without font/size args, which sends an unmapped/undef font
# name through C4::Creators::PDF's TTF lookup (PDF.pm:208-215) and
# produces these known warnings. Run a block, allow only those, and
# forward anything else to the previously installed handler
# (Test::NoWarnings) so new regressions still fail the suite.
# Forwarding must call the previous handler directly: perl disables
# __WARN__ handlers inside a __WARN__ handler, so a plain re-warn
# would bypass Test::NoWarnings entirely.
sub run_allowing_bug_41718_warnings {
    my ($code) = @_;
    my $prev = $SIG{__WARN__};
    local $SIG{__WARN__} = sub {
        my $w = shift;
        return
            if $w =~ /^ERROR in koha-conf\.xml -- missing <font type="(?:Courier)?">/
            || $w =~ /^Use of uninitialized value (?:\$fontName )?in .* at \S*C4\/Creators\/PDF\.pm/;
        ref $prev ? $prev->($w) : print STDERR $w;
    };
    return $code->();
}

my $schema = Koha::Database->new->schema;
$schema->storage->txn_begin;

my $builder = t::lib::TestBuilder->new;

# Build test data
my $branch   = $builder->build( { source => 'Branch' } );
my $category = $builder->build( { source => 'Category' } );
my $patron   = $builder->build_object(
    {
        class => 'Koha::Patrons',
        value => {
            firstname    => 'Testfirst',
            surname      => 'Testsurname',
            cardnumber   => 'CARD12345',
            branchcode   => $branch->{branchcode},
            categorycode => $category->{categorycode},
        }
    }
);

t::lib::Mocks::mock_userenv( { branchcode => $branch->{branchcode} } );

# ----------------------------------------
# Helper: build a Patroncard with given layout
# ----------------------------------------
sub build_patroncard {
    my (%overrides) = @_;
    my $layout = $overrides{layout} || {
        units => 'POINT',
        text  => [
            '<firstname> <surname>',
            { llx => 10, lly => 80, font => 'TR', font_size => 10, text_alignment => 'L' },
            '<cardnumber>',
            { llx => 10, lly => 60, font => 'TR', font_size => 8, text_alignment => 'C' },
        ],
        barcode => [
            {
                type         => $overrides{barcode_type} || 'CODE39',
                data         => $overrides{barcode_data} || 'CARD12345',
                llx          => 10,
                lly          => 10,
                height_scale => 0.01,
                width_scale  => 0.8,
                text_print   => '',
            }
        ],
        images => $overrides{images} || {},
    };
    return C4::Patroncards::Patroncard->new(
        batch_id        => 1,
        borrower_number => $patron->borrowernumber,
        llx             => 36,
        lly             => 36,
        height          => 200,
        width           => 300,
        layout          => $layout,
        text_wrap_cols  => 40,
    );
}

# ========================================
# Subtest: draw_guide_box()
# ========================================
subtest 'draw_guide_box()' => sub {
    plan tests => 4;

    my $pdf = C4::Creators::PDF->new( InitVars => 0 );
    $pdf->Page();

    my $card   = build_patroncard();
    my $result = eval { $card->draw_guide_box($pdf); 1; };
    ok( $result, 'draw_guide_box($pdf) succeeds without error' ) or diag($@);

    # Without $pdf argument should return -1
    my $bad_result;
    warning_like { $bad_result = $card->draw_guide_box(); }
    qr/No pdf object passed in/,
        'draw_guide_box() without $pdf warns appropriately';
    is( $bad_result, -1, 'draw_guide_box() without $pdf returns -1' );

    # Slurp the PDF and confirm the guide-box rectangle landed in the
    # output stream (llx=36, lly=36, width=300, height=200 from build_patroncard).
    my $content = capture_pdf_end($pdf);
    like(
        $content, qr/36 36 300 200 re/,
        'PDF output contains guide-box rectangle at expected coordinates'
    );
};

# ========================================
# Subtest: draw_guide_grid()
# ========================================
subtest 'draw_guide_grid()' => sub {
    plan tests => 4;

    my $pdf = C4::Creators::PDF->new( InitVars => 0 );
    $pdf->Page();

    # draw_guide_grid() emits Bug 41718 warnings (hardcoded "Courier" font,
    # StrWidth without font/size); the helper allows only those and
    # re-emits anything else so new regressions still surface.
    my $card_point = build_patroncard();
    my $result     = run_allowing_bug_41718_warnings(
        sub {
            eval { $card_point->draw_guide_grid($pdf); 1 }
        }
    );
    ok( $result, 'draw_guide_grid() with POINT units succeeds' ) or diag($@);

    # Test with MM units
    my $card_mm = build_patroncard(
        layout => {
            units   => 'MM',
            text    => [],
            barcode => [
                {
                    type       => 'CODE39', data => 'X', llx => 0, lly => 0, height_scale => 0.01, width_scale => 0.8,
                    text_print => ''
                }
            ],
            images => {},
        }
    );
    $result = run_allowing_bug_41718_warnings(
        sub {
            eval { $card_mm->draw_guide_grid($pdf); 1 }
        }
    );
    ok( $result, 'draw_guide_grid() with MM units succeeds' ) or diag($@);

    # Without $pdf argument
    my $bad_result;
    warning_like { $bad_result = $card_point->draw_guide_grid(); }
    qr/No pdf object passed in/,
        'draw_guide_grid() without $pdf warns appropriately';
    is( $bad_result, -1, 'draw_guide_grid() without $pdf returns -1' );

    capture_pdf_end($pdf);
};

# ========================================
# Subtest: draw_text()
# ========================================
subtest 'draw_text()' => sub {
    plan tests => 4;

    my $pdf = C4::Creators::PDF->new( InitVars => 0 );
    $pdf->Page();

    my $card   = build_patroncard();
    my $result = eval { $card->draw_text($pdf); 1; };
    ok( $result, 'draw_text($pdf) succeeds without error' ) or diag($@);

    # Without $pdf argument
    my $bad_result;
    warning_like { $bad_result = $card->draw_text(); }
    qr/No pdf object passed in/,
        'draw_text() without $pdf warns appropriately';
    is( $bad_result, -1, 'draw_text() without $pdf returns -1' );

    # With empty text layout - should return undef gracefully
    my $card_no_text = build_patroncard(
        layout => {
            units   => 'POINT',
            text    => 'not_an_array',
            barcode => [
                {
                    type       => 'CODE39', data => 'X', llx => 0, lly => 0, height_scale => 0.01, width_scale => 0.8,
                    text_print => ''
                }
            ],
            images => {},
        }
    );
    my $no_text_result = eval { $card_no_text->draw_text($pdf); 1; };
    ok( $no_text_result, 'draw_text() with non-ARRAY text layout returns gracefully' ) or diag($@);

    capture_pdf_end($pdf);
};

# ========================================
# Subtest: draw_barcode()
# ========================================
subtest 'draw_barcode()' => sub {
    plan tests => 5;

    my $pdf = C4::Creators::PDF->new( InitVars => 0 );
    $pdf->Page();

    # Cover every barcode type _draw_barcode actually dispatches on
    # (Patroncard.pm:428-470). CODE39MOD and CODE39MOD10 invoke
    # Algorithm::CheckDigits and die with "Undefined subroutine" until
    # Bug 43095 adds the missing `use Algorithm::CheckDigits` import
    # (C4::Labels::Label has it; C4::Patroncards::Patroncard doesn't).
    # These two rows fail without that fix applied - see Bug 43095.
    my @types = (
        { type => 'CODE39',         data => 'CARD12345' },
        { type => 'CODE39MOD',      data => 'CARD12345' },
        { type => 'CODE39MOD10',    data => '12345' },       # numeric for modulo-10
        { type => 'COOP2OF5',       data => '12345' },
        { type => 'INDUSTRIAL2OF5', data => '12345' },
    );

    for my $t (@types) {
        my $card   = build_patroncard( barcode_type => $t->{type}, barcode_data => $t->{data} );
        my $result = eval { $card->draw_barcode($pdf); 1 };
        ok( $result, "draw_barcode() $t->{type} succeeds" ) or diag($@);
    }

    capture_pdf_end($pdf);
};

# ========================================
# Subtest: draw_image()
# ========================================
subtest 'draw_image()' => sub {
    plan tests => 3;

    my $pdf = C4::Creators::PDF->new( InitVars => 0 );
    $pdf->Page();

    # Create a minimal JPEG using GD
    my $jpeg_data;
    eval { require GD; };
    if ($@) {

        # Fallback: minimal JPEG binary
        $jpeg_data = pack(
            "H*",
            "ffd8ffe000104a46494600010100000100010000"
                . "ffdb004300080606070605080707070909080a0c14"
                . "0d0c0b0b0c1912130f141d1a1f1e1d1a1c1c2024"
                . "2e2720222c231c1c2837292c30313434341f27393d"
                . "38323c2e333432ffc0000b08000100010101011100"
                . "ffc4001f000001050101010101010000000000000000"
                . "0102030405060708090a0bffda00080101000003f1"
                . "00fb52800001ffd9"
        );
    } else {
        my $im    = GD::Image->new( 4, 4, 1 );
        my $white = $im->colorAllocate( 255, 255, 255 );
        my $red   = $im->colorAllocate( 255, 0,   0 );
        $im->filledRectangle( 0, 0, 3, 3, $white );
        $im->setPixel( 1, 1, $red );
        $jpeg_data = $im->jpeg(100);
    }

    my $images = {
        img1 => {
            data_source => [ { image_source => 'db' } ],
            data        => $jpeg_data,
            Tx          => 5,
            Ty          => 5,
            Sx          => 50,
            Sy          => 50,
            Ox          => 0,
            Oy          => 0,
            scale       => 1,
            alt         => { data => $jpeg_data, Sx => 50, Sy => 50 },
        },
    };

    my $card_img = build_patroncard( images => $images );

    # PDF::Reuse's prJpeg leaves $iColorType uninitialized for JPEGs
    # whose colour type it does not recognize (PDF/Reuse.pm sub prJpeg),
    # emitting one benign warning on small synthetic images. Filter
    # exactly that; forward anything else to the previous handler (see
    # run_allowing_bug_41718_warnings for why a plain re-warn would not
    # reach Test::NoWarnings).
    my $result;
    {
        my $prev = $SIG{__WARN__};
        local $SIG{__WARN__} = sub {
            my $w = shift;
            return if $w =~ /^Use of uninitialized value \$iColorType in pattern match \(m\/\/\) at \S*PDF\/Reuse\.pm/;
            ref $prev ? $prev->($w) : print STDERR $w;
        };
        $result = eval { $card_img->draw_image($pdf); 1 };
    }
    ok( $result, 'draw_image() with JPEG data succeeds' ) or diag($@);

    # Test with image_source => 'none' (should skip)
    my $images_none = {
        img1 => {
            data_source => [ { image_source => 'none' } ],
            data        => $jpeg_data,
            Tx          => 5,
            Ty          => 5,
            Sx          => 50,
            Sy          => 50,
            Ox          => 0,
            Oy          => 0,
            scale       => 1,
            alt         => { data => $jpeg_data, Sx => 50, Sy => 50 },
        },
    };
    my $card_no_img = build_patroncard( images => $images_none );
    $result = eval { $card_no_img->draw_image($pdf); 1; };
    ok( $result, 'draw_image() with image_source=none skips gracefully' ) or diag($@);

    # Without $pdf argument
    my $bad_result;
    warning_like { $bad_result = $card_img->draw_image(); }
    qr/No pdf object passed in/,
        'draw_image() without $pdf warns appropriately';

    capture_pdf_end($pdf);
};

# ========================================
# Subtest: End-to-end PDF output
# ========================================
# This subtest is the load-bearing "are we testing Koha code, not just
# PDF::Reuse?" assertion. PDF::Reuse::prEnd() will happily emit a valid
# %PDF- header for an empty document, so file size + header alone are
# tautologies that pass even if every Koha draw method died. We capture
# the rendered PDF and assert on content the Koha code is responsible for:
# the borrower-field substitution from draw_text and the guide-box
# rectangle from draw_guide_box.
subtest 'End-to-end PDF output exercises Koha rendering' => sub {
    plan tests => 6;

    my $pdf = C4::Creators::PDF->new( InitVars => 0 );
    $pdf->Page();

    my $card = build_patroncard();

    # Each draw step must succeed individually; a bare `eval {}` that
    # swallows the result silently masks Koha-side failures.
    ok( eval { $card->draw_guide_box($pdf); 1 }, 'draw_guide_box did not die' )
        or diag($@);
    ok( eval { $card->draw_text($pdf); 1 }, 'draw_text did not die' )
        or diag($@);
    ok( eval { $card->draw_barcode($pdf); 1 }, 'draw_barcode did not die' )
        or diag($@);

    my $content = capture_pdf_end($pdf);

    # draw_text runs each layout line through get_borrower_attributes
    # substitution and ultimately calls $pdf->Text(Tx, Ty, $line), which
    # emits a PDF "BT ... <hex> Tj ET" text block. With PDF::Reuse's
    # TTFont path the rendered glyphs are CID-encoded (not literal ASCII),
    # so we can't grep for "Testsurname" directly. Instead, pin two
    # observable contracts of the draw_text -> Koha layout -> prText chain:
    #
    # (a) the document contains at least one BT/ET text-block with a Tj
    #     (i.e. draw_text actually rendered SOME text); and
    # (b) one of those blocks lands at the deterministic Y coordinate
    #     produced by the layout math: the '<firstname> <surname>' line
    #     has lly=80 and the card has lly=36, so origin_lly = 36 + 80 = 116.
    #
    # Substitution that silently produced empty strings would still emit
    # a Tj (with empty content) - but the Ty=116 placement only happens
    # if the layout line actually reached prText with non-degenerate state,
    # which is the load-bearing assertion against the first-draft failure
    # mode of "tests pass when Koha code does nothing".
    like(
        $content, qr/BT\s+\/\S+\s+\d+\s+Tf.*?Tj\s+ET/s,
        'PDF contains a BT/Tj/ET text block (draw_text emitted text)'
    );
    like(
        $content, qr/\b\d+(?:\.\d+)?\s+116\s+Td\b/,
        'A text block lands at Ty=116 (layout origin_lly = card lly 36 + text attr lly 80)'
    );

    # draw_guide_box emits a rectangle at llx,lly,width,height; pin the
    # actual coordinates so a future regression that shifts the geometry
    # or skips the draw fails here, not just at "file is non-empty".
    like(
        $content, qr/36 36 300 200 re/,
        'PDF contains guide-box rectangle at expected coordinates'
    );
};

$schema->storage->txn_rollback();

1;
