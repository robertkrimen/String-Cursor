package String::Cursor;
# ABSTRACT: Move and read through a string via position and regular expression

use strict;
use warnings;

use Any::Moose;

has data => qw/ is ro lazy_build 1 isa Str /;
sub _build_data { '' }

has length => qw/ is ro lazy_build 1 isa Int /;
sub _build_length { length shift->data }

has _cursor => qw/ is ro lazy_build 1 isa String::Cursor::Mark /, handles => [qw/ head tail /];
sub _build__cursor { String::Cursor::Mark->new };

has _mark => qw/ is ro lazy_build 1 isa HashRef /;
sub _build__mark { {} }

sub BUILD {
    my $self = shift;
    $self->mark;
}

sub reset {
    my $self = shift;
    $self->head( 0 );
    $self->tail( 0 );
    return $self;
}

sub cursor {
    my $self = shift;
    return $self->_cursor unless @_;
    $self->_cursor->set( @_ );
    return $self;
}

sub mark {
    my $self = shift;
    my $name;
    $name = shift if @_;
    $name = '_'  unless defined $name;
    $self->_mark->{$name} = $self->cursor->copy;
    return $self;
}

sub recall {
    my $self = shift;
    my $name;
    $name = shift if @_;
    $name = '_'  unless defined $name;
    return $self->_mark->{$name};
}

sub find {
    my $self = shift;
    my $target = shift;

    my $data = $self->data;
    return if $self->length <= ( my $from = 1 + $self->tail );
    pos $data = $from;
    return unless scalar $data =~ m/\G[[:ascii:]]*?($target)/;
    $self->cursor( $-[1], $+[1] - 1 );
    return 1;
}

sub offset {
    my $self = shift;
    my $offset = shift;

    return unless $offset;

    my ( $position );
    if ( $offset > 0 ) {
        $position = $self->tail + $offset;
        my $length = $self->length;
        $position = $length - 1 if $position > $length;
    }
    elsif ( $offset < 0 ) {
        $position = $self->head - $offset;
        $position = 0 if $position < 0;
    }
    $self->cursor( $position );
    return $self;
}

*shift = sub {
    my $self = shift;
    my $shift = shift;
    
    return unless $shift;

    my ( $head, $tail );
    if ( $shift > 0 ) {
        $head = $self->head + $shift;
        $tail = $self->tail + $shift;
        my $length = $self->length;
        if ( $head > $length ) {
            $head = $tail = $length - 1;
        }
        elsif ( $tail > $length ) {
            $tail = $length - 1;
        }
    }
    elsif ( $shift < 0 ) {
        $head = $self->head - $shift;
        $tail = $self->tail - $shift;
        if ( $tail < 0 ) {
            $head = $tail = 0;
        }
        elsif ( $head < 0 ) {
            $head = 0;
        }
    }
    $self->cursor( $head, $tail );
    return $self;
};
*shift = \&shift;

sub index {
    my $self = shift;
    my $target = shift;
    return $self->length if $self->length <= ( my $from = 1 + $self->tail );
    return index $self->data, $target, $from;
}

sub rindex {
    my $self = shift;
    my $target = shift;
    return $self->_rindex( $target, $self->head );
}

sub _rindex {
    my $self = shift;
    my $target = shift;
    my $from = shift;
    return 0 if 0 >= ( $from -= 1 );
    return rindex $self->data, $target, $from;
}

sub substring {
    my $self = shift;
    my ( $head, $tail ) = ( $self->head, $self->tail );
    return substr $self->data, $head, 1 + $tail - $head;
}

sub slice {
    my $self = shift;

    my $last = $self->recall;
    my $cursor = $self->cursor;

    my $data = $self->data;

    my ( $head, $tail );

    $head = $self->_rindex( "\n", $last->head );
    # TODO What if "\n" are head and tail, respectively?
    if ( "\n" eq substr $data, $last->head, 1 ) {
        # Original mark was "\n"
    }
    elsif ( $head == 0 && ( "\n" ne substr $data, 0, 1 ) ) {
        # Did not find "\n" before beginning of $data
    }
    else {
        $head += 1;
    }

    $tail = $self->index( "\n" );

    my $slice = substr $self->data, $head, $tail;

    return $slice;
}

sub up {
    my $self = shift;
    $self->tail( $self->head );
}

sub down {
    my $self = shift;
    $self->head( $self->tail );
}

package String::Cursor::Mark;

use Any::Moose;

has [qw/ head tail /] => qw/ is rw required 1 lazy 1 isa Int default 0 /;

sub set {
    my ( $self, $head, $tail ) = @_;
    $tail = defined $tail ? $tail : $head;
    $self->head( $head );
    $self->tail( $tail );
    return $self;
}

sub copy {
    my $self = shift;
    return (ref $self)->new( head => $self->head, tail => $self->tail );
}

1;
