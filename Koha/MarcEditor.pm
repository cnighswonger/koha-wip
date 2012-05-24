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

use autouse 'Data::Dumper' => qw(Dumper);
use Carp;

use constant RECORD_TYPES   => qw(bib auth hold);

our $VERSION    = 0.01;

sub new {
    my ($invocant) = shift;
    my $type = ref($invocant) || $invocant;
    my $record_type = shift;
    if (!(grep /$record_type/, (RECORD_TYPES))) {
        croak "Invalid record type: $record_type.";
    }
    my $self = {
        record_type     => $record_type,
    };
    bless ($self, $type);
    return $self;
}

sub record_type {
    my $self = shift;
    return $self->{'record_type'};
}

1;
