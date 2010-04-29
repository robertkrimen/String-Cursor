package String::Cursor;
# ABSTRACT: Move and read through a string via position and regular expression

use strict;
use warnings;

use Any::Moose;

has data => qw/ is ro lazy_build 1 isa Str /;
sub _build_data { '' }

has [qw/ head tail /] => qw/ is rw required 1 lazy 1 isa Int default 0 /;

sub reset {
    my $self = shift;
    $self->head( 0 );
    $self->tail( 0 );
    return $self;
}

sub move {
    my $self = shift;
    my $move = shift;

    my $data = $self->data;

    if ( ref $move eq 'Regexp' ) {
        pos $data = $self->tail;
        return unless scalar $data =~ m/\G.*?($move)/;
        $self->head( $-[0] );
        $self->tail( $+[0] );
        return 1;
    }
    elsif ( $move =~ m/^[\-\+]?\d+$/ ) {
        my $position = $self->tail + $move;
        my $length = length $data;
        $position = $length if $position > $length;
        $self->head( $position );
        $self->tail( $position );
        return 1;
    }
    
    die "Not ready";
}

1;
