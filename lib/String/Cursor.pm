package String::Cursor;
# ABSTRACT: Move and read through a string via position and regular expression

use strict;
use warnings;

use Any::Moose;

has data => qw/ is ro lazy_build 1 isa Str /;
sub _build_data { '' }

has state => qw/ is rw lazy_build 1 isa String::Cursor::State clearer clear_state /;
sub _build_state { shift->__state };

sub __state {
    my $self = shift;
    return String::Cursor::State->new( string => $self, position => 0, @_ );
}
sub _state {
    my $self = shift;
    $self->state( $self->__state( @_ ) );
}

sub reset {
    my $self = shift;
    $self->clear_state;
    return $self;
}

sub move {
    my $self = shift;
    return $self->state->move( @_ );
}

package String::Cursor::State;

use Any::Moose;

has string => qw/ is ro required 1 isa String::Cursor weak_ref 1 /, handles => [qw/ _state data /]; 
has position => qw/ is ro required 1 isa Int /;

sub move {
    my $self = shift;
    my $by = shift;

    my $data = $self->data;

    if ( ref $by eq 'Regexp' ) {
        pos $data = $self->position;
        return unless scalar $data =~ m/\G.*?($by)/;
        $position = $+[0];
        return $self->_state( position => $position );
    }
    elsif ( $by =~ m/^[\-\+]?\d+$/ ) {
        my $position = $self->position + $by;
        my $end = length $data;
        $position = $end if $position > $end;
        return $self->_state( position => $position );
    }
    
    die "Not ready";
}

1;
