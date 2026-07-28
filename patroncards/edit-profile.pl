#!/usr/bin/perl
#
# Copyright 2006 Katipo Communications.
# Parts Copyright 2009 Foundations Bible College.
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

use CGI          qw ( -utf8 );
use Scalar::Util qw( blessed );
use URI;

use C4::Auth          qw( get_template_and_user );
use C4::Output        qw( output_html_with_http_headers );
use C4::Creators::Lib qw( get_all_templates get_unit_values );
use C4::Patroncards::Profile;

my $cgi = CGI->new;
my ( $template, $loggedinuser, $cookie ) = get_template_and_user(
    {
        template_name => "patroncards/edit-profile.tt",
        query         => $cgi,
        type          => "intranet",
        flagsrequired => { tools => 'label_creator' },
    }
);

my $op             = $cgi->param('op')         || '';
my $profile_id     = $cgi->param('profile_id') || $cgi->param('element_id');
my $profile        = undef;
my $template_list  = undef;
my @label_template = ();
my $error          = '';

my $units = get_unit_values();

if ( $op eq 'edit_form' ) {
    $profile       = C4::Patroncards::Profile->retrieve( profile_id => $profile_id );
    $template_list = get_all_templates( { fields => [qw( template_id template_code profile_id )] } );
} elsif ( $op eq 'cud-save' ) {
    my $printer_name = $cgi->param('printer_name') // '';
    my $paper_bin    = $cgi->param('paper_bin')    // '';
    s/^\s+|\s+$//g for ( $printer_name, $paper_bin );
    my @params = (
        printer_name => $printer_name,
        paper_bin    => $paper_bin,
        offset_horz  => scalar $cgi->param('offset_horz') || 0,
        offset_vert  => scalar $cgi->param('offset_vert') || 0,
        creep_horz   => scalar $cgi->param('creep_horz')  || 0,
        creep_vert   => scalar $cgi->param('creep_vert')  || 0,
        units        => scalar $cgi->param('units')       || 'POINT',
    );

    if ($profile_id) {    # if a profile_id was passed in, this is an update to an existing profile

        # retrieve() blesses whatever the query returned, so a profile deleted since the
        # form was opened yields an unusable object rather than an exception
        $profile = eval { C4::Patroncards::Profile->retrieve( profile_id => $profile_id ) };
        unless ( blessed($profile) ) {
            my $uri = URI->new("manage.pl");
            $uri->query_form( card_element => 'profile', element_id => $profile_id, error => 101 );
            print $cgi->redirect( $uri->as_string );
            exit;
        }
        $profile->set_attr(@params);
    } else {    # if no profile_id, this is a new profile so insert it
        $profile = C4::Patroncards::Profile->new(@params);
    }

    if ( $printer_name eq '' || $paper_bin eq '' ) {
        $error = 'missing_required';
    } else {

        # printers_profile has a UNIQUE key on (printer_name, template_id, paper_bin, creator)
        my $saved = eval { $profile->save() };
        if ( my $exception = $@ ) {
            die $exception
                unless blessed($exception) && $exception->isa('Koha::Exceptions::Object::DuplicateID');
            $error = 'duplicate';
        } elsif ( !defined $saved || $saved == -1 ) {

            # save() reports some database failures by return value rather than by throwing
            $error = 'save_failed';
        } else {
            print $cgi->redirect("manage.pl?card_element=profile");
            exit;
        }
    }
} else {    # if we get here, this is a new layout
    $profile = C4::Patroncards::Profile->new();
}

if ( $profile_id && $template_list ) {
    @label_template = grep {
               ( $_->{'profile_id'} == $profile->get_attr('profile_id') )
            && ( $_->{'template_id'} == $profile->get_attr('template_id') )
    } @$template_list;
}

foreach my $unit (@$units) {
    if ( $unit->{'type'} eq $profile->get_attr('units') ) {
        $unit->{'selected'} = 1;
    }
}

# if new layout, there will be no profile id, so shouldn't look for it
if ( $profile_id && $profile->get_attr('profile_id') > 0 ) {
    $template->param( profile_id => $profile->get_attr('profile_id') );
}

$template->param(
    label_template => $label_template[0]->{'template_code'} || '',
    printer_name   => $profile->get_attr('printer_name'),
    paper_bin      => $profile->get_attr('paper_bin'),
    offset_horz    => $profile->get_attr('offset_horz'),
    offset_vert    => $profile->get_attr('offset_vert'),
    creep_horz     => $profile->get_attr('creep_horz'),
    creep_vert     => $profile->get_attr('creep_vert'),
    units          => $units,
    op             => $op,
    error          => $error,
);

output_html_with_http_headers $cgi, $cookie, $template->output;
