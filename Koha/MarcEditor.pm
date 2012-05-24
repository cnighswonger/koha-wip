package Koha::MarcEditor;

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

use Carp;
use XML::LibXML;
use XML::LibXSLT;
use autouse 'Data::Dumper' => qw(Dumper);

use vars qw($AUTOLOAD);

use constant REQUIRED_PARAMS    => qw(record_type record_id marc_xml framework_xslt);
use constant RECORD_TYPES       => qw(bib auth hold);

our $VERSION = 0.01;

sub new {
    my $invocant = shift;
    my $type = ref($invocant) || $invocant;
    my %params = @_;
    if (my @missing_params = (grep {$params{$_} eq undef} (REQUIRED_PARAMS))) {
        croak "Missing required parameter(s): " . join (', ', @missing_params);
    }
    if (!(grep /$params{'record_type'}/, (RECORD_TYPES))) {
        croak "Invalid record type: $params{'record_type'}.";
    }
    my $self = {
        record_type     => $params{'record_type'},
        record_id       => $params{'record_id'},
        marc_xml        => $params{'marc_xml'},
        framework_xslt  => $params{'framework_xslt'},
    };
    bless ($self, $type);
    return $self;
}

sub output_editor {
    my $self = shift;

    my $xml_parser = XML::LibXML->new(recover => 0);
    my $xslt_parser = XML::LibXSLT->new();

    my $xml_source = $xml_parser->parse_string($self->{'marc_xml'});
    my $xslt_stylesheet = $xslt_parser->parse_stylesheet($xml_parser->parse_file($self->{'framework_xslt'}));
    my $parsed_results = $xslt_stylesheet->transform($xml_source);
    return $xslt_stylesheet->output_string($parsed_results);
}

## AUTOLOAD method taken from http://www.perlmonks.org/?node_id=444212

sub AUTOLOAD {
    my ($self, $value)= @_ ;

    return if $AUTOLOAD =~ /::DESTROY$/ ;

    my $attname = $AUTOLOAD;
    $attname =~ s/.*::// ;

    if(! exists $self->{$attname}){
        croak("Attribute $attname does not exists in $self");
    }

    my $pkg = ref($self ) ;
    my $code = qq{
                   package $pkg ;
                   sub $attname {
                           my \$self = shift ;
                           \@_ ? \$self->{$attname} = shift :
                           \$self->{$attname} ;
                   }
       };

    eval $code ;
    if( $@ ){
        croak("Failed to create method $AUTOLOAD : $@");
    }
    goto &$AUTOLOAD ;
}


1;
