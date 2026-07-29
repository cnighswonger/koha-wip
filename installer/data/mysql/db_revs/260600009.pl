use Modern::Perl;
use Koha::Installer::Output qw(say_success);

return {
    bug_number  => "30819",
    description => "Add a separate font size for the text under a barcode",
    up          => sub {
        my ($args) = @_;
        my ( $dbh, $out ) = @$args{qw(dbh out)};

        unless ( column_exists( 'creator_layouts', 'barcode_font_size' ) ) {
            $dbh->do(
                q{
                ALTER TABLE creator_layouts ADD COLUMN `barcode_font_size` int(4) NOT NULL DEFAULT 10
                COMMENT 'font size in points for the human-readable text under a barcode'
                AFTER `font_size`
                }
            );

            say_success( $out, "Added column 'creator_layouts.barcode_font_size'" );
        }
    },
};
