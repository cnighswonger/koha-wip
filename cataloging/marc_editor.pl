#!/usr/bin/perl

# Copyright 2012 Foundations Bible College Inc.
#
# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# Koha is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Koha; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

use Modern::Perl;

use CGI;
use autouse 'Data::Dumper' => qw(Dumper);

use C4::Auth;
use C4::Koha;
use C4::Context;
use C4::Output;
use C4::Biblio;

use Koha::MarcEditor;

my $cgi = new CGI;
my $params = $cgi->Vars;  # NOTE: Multivalue parameters NOT allowed here!!

my ( $template, $borrowernumber, $cookie ) = get_template_and_user(
    {
        template_name   => "cataloging/marc_editor.tt",
        query           => $cgi,
        type            => "intranet",
        authnotrequired => 1, #0,
        flagsrequired   => { editcatalogue => 'edit_catalogue' },
        debug           => 1,
    }
);

my $framework_code = 'TST';

my $framework_xslt =    C4::Context->config('intrahtdocs') .'/' .
                        C4::Context->preference("template") . '/' .
                        C4::Templates::_current_language() . '/' .
                        'xslt' . '/' .
                        C4::Context->preference('marcflavour') .
                        "marceditor$framework_code.xsl";

my $marc_xml = undef;

given ($params->{'record_type'}) {
    when (/bib/) {
        $marc_xml = GetXmlBiblio($params->{'record_id'});
    }
    when (/auth/) {
    }
    when (/hold/) {
    }
    when (/item/) {
    }
    default {
    }
}

my $marc_editor = Koha::MarcEditor->new(
    record_type     => $params->{'record_type'},
    record_id       => $params->{'record_id'},
    marc_xml        => $marc_xml,
    framework_xslt  => $framework_xslt,
);

$template->param(
    record_type     => $marc_editor->record_type,
    record_id       => $marc_editor->record_id,
    editor          => $marc_editor->output_editor,
);

output_html_with_http_headers $cgi, $cookie, $template->output;
