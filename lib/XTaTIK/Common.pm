package XTaTIK::Common;


require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(n_to_br);

use strict;
use warnings;
use HTML::Entities;

sub n_to_br {
    my $data = shift;
    return '' unless length $data;
    return encode_entities($data) =~ s/\n\r?|\r\n/<br>/gr;
}