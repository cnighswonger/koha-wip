#!/usr/bin/perl
#
# Copyright 2026 Chris Nighswonger
#
# This file is part of Koha.
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

use Test::More tests => 4;
use Test::NoWarnings;
use File::Temp qw( tempfile );

BEGIN {
    eval { require PDF::Reuse::Barcode; PDF::Reuse::Barcode->VERSION('0.11'); 1 }
        or plan skip_all => 'PDF::Reuse::Barcode 0.11 or later is required for textsize support';
}

use C4::Labels::Label;
use C4::Creators::PDF;

# The size of the text under a barcode is set by PDF::Reuse::Barcode, not by
# Koha, so the only way to assert it is to read the Tf operator back out of
# the rendered content stream.
sub render_barcode_text_sizes {
    my (%params) = @_;

    my ( undef, $path ) = tempfile( SUFFIX => '.pdf', UNLINK => 1 );
    my $pdf = C4::Creators::PDF->new( InitVars => 0, file => $path );

    my $label = C4::Labels::Label->new(
        batch_id          => 1,
        item_number       => 1,
        width             => 200,
        height            => 100,
        top_text_margin   => 10,
        left_text_margin  => 10,
        barcode_type      => $params{barcode_type},
        printing_type     => 'BAR',
        guidebox          => 0,
        oblique_title     => 0,
        font              => 'TR',
        font_size         => $params{font_size},
        barcode_font_size => $params{barcode_font_size},
        callnum_split     => 0,
        justify           => 'L',
        format_string     => 'barcode',
        text_wrap_cols    => 10,
        scale_width       => 0.8,
        scale_height      => 0.01,
    );

    $label->barcode(
        llx            => 10,
        lly            => 10,
        width          => 150,
        y_scale_factor => 10,
        barcode_data   => '123456',
        barcode_type   => $params{barcode_type},
    );

    open( my $out, '>', $path ) or die "Cannot write $path: $!";
    my $previous = select $out;
    eval { $pdf->End() };
    select $previous;
    close $out;

    open( my $in, '<', $path ) or die "Cannot read $path: $!";
    local $/;
    my $content = <$in>;
    close $in;

    return [ $content =~ m{/\S+ \s+ ([\d.]+) \s+ Tf}gx ];
}

subtest 'barcode_font_size sets the size of the text under the barcode' => sub {
    plan tests => 3;

    is(
        render_barcode_text_sizes( barcode_type => 'CODE39', font_size => 3, barcode_font_size => 6 )->[0],
        6,
        'A barcode_font_size of 6 renders the barcode text at 6'
    );

    is(
        render_barcode_text_sizes( barcode_type => 'CODE39', font_size => 3, barcode_font_size => 20 )->[0],
        20,
        'A barcode_font_size of 20 renders the barcode text at 20'
    );

    is(
        render_barcode_text_sizes( barcode_type => 'CODE39', font_size => 20, barcode_font_size => 6 )->[0],
        6,
        'The layout font_size does not affect the barcode text'
    );
};

subtest 'the default leaves existing layouts rendering as before' => sub {
    plan tests => 1;

    # Layouts created before bug 30819 are backfilled to 10, which is the size
    # PDF::Reuse::Barcode used unconditionally until then. A layout carrying
    # the old default font_size of 3 must not shrink its barcode text.
    is(
        render_barcode_text_sizes( barcode_type => 'CODE39', font_size => 3, barcode_font_size => 10 )->[0],
        10,
        'A layout with font_size 3 and the backfilled barcode_font_size renders at 10'
    );
};

subtest 'EAN13 places its text at a size fixed by the symbology' => sub {
    plan tests => 1;

    my $sizes = render_barcode_text_sizes( barcode_type => 'EAN13', font_size => 3, barcode_font_size => 20 );

    is_deeply(
        [ grep { $_ != 10 } @$sizes ],
        [],
        'barcode_font_size does not change EAN13 text, which stays at 10'
    );
};
