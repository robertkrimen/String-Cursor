package String::Cursor;
# ABSTRACT: Move and read through a string via position and regular expression

use strict;
use warnings;

use Any::Moose;

has data => qw/ is ro lazy_build 1 isa Str /;
sub _build_data { '' }

has length => qw/ is ro lazy_build 1 isa Int /;
sub _build_length { length shift->data }

has _mark => qw/ is ro lazy_build 1 isa HashRef /;
sub _build__mark { { '@' => String::Cursor::Mark->new } }

sub bang_mark { $_[0]->_mark->{'!'} }
sub at_mark { $_[0]->_mark->{'@'} }
sub head { shift->at_mark->head( @_ ) }
sub tail { shift->at_mark->tail( @_ ) }

sub BUILD {
    my $self = shift;
    $self->mark( '!' );
    $self->mark( '@' );
}

sub reset {
    my $self = shift;
    $self->head( 0 );
    $self->tail( 0 );
    return $self;
}

sub cursor {
    my $self = shift;
    return $self->_at_mark unless @_;
    $self->at_mark->set( @_ );
    return $self;
}

sub mark {
    my $self = shift;
    my $name;
    $name = shift if @_;
    $name = '!'  unless defined $name;
    $self->_mark->{$name} = $self->at_mark->copy;
    return $self;
}

sub recall {
    my $self = shift;
    my $name;
    $name = shift if @_;
    $name = '!'  unless defined $name;
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

#sub index {
#    my $self = shift;
#    my $target = shift;
#    return $self->length if $self->length <= ( my $from = 1 + $self->tail );
#    return index $self->data, $target, $from;
#}

#sub rindex {
#    my $self = shift;
#    my $target = shift;
#    return $self->_rindex( $target, $self->head );
#}

#sub _rindex {
#    my $self = shift;
#    my $target = shift;
#    my $from = shift;
#    return 0 if 0 >= ( $from -= 1 );
#    return rindex $self->data, $target, $from;
#}

sub substring {
    my $self = shift;
    my ( $head, $tail ) = ( $self->head, $self->tail );
    return substr $self->data, $head, 1 + $tail - $head;
}

sub _index ($$$) {
    my $index = index $$_[0], $_[1], $_[2];
    return -1 == $index ? length $$_[0] : $index;
}

sub _rindex ($$$) {
    my $index = rindex $$_[0], $_[1], $_[2];
    return -1 == $index ? 0 : $index;
}

sub _oslice_frame ($$$) {
    my ( $data, $head, $tail ) = @_;
    my $length = length $$data;

    my $left = _rindex $data, "\n", $head;
    my $right = _index $data, "\n", $tail;
    
    if ( "\n" eq substr $$data, $head, 1 ) {
        # Original mark was "\n"
    }
    elsif ( $left == 0 && ( "\n" ne substr $$data, 0, 1 ) ) {
        # Did not find "\n" before beginning of $data
    }
    else {
        $left += 1;
    }

    return ( $left, $right );
}

use Scalar::Util qw/ looks_like_number /;

sub normalize_position {
    my $self = $_[0];
    my $position = $_[1];

    return 0 unless $position;

    my $length = $self->length;
    $position = $length + $position if 0 > $position;
    return $position >= $length ? $length - 1 : $position;
}

sub mark2position {
    my $self = $_[0];
    my $mark = $_[1];
    my $lean = $_[2]; # < or >

    die "Missing mark" unless defined $mark;

    if ( blessed $mark ) {
    }
    elsif ( looks_like_number $mark ) {
        return $self->normalize_position( $mark );
    }
    elsif ( $mark =~ m/([!@]|\w+)[<>]?/ ) {
        $mark = $self->recall( $1 );
        $lean = $2 if defined $2;
    }
    else {
        die "Invalid mark ($mark)";
    }

    die "Missing lean" unless defined $lean;

    if      ( $lean eq '<' )    { return $mark->head }
    elsif   ( $lean eq '>' )    { return $mark->tail }
    else                        { die "Invalid lean ($lean)" }
}

sub frame2vector {
    my $self = $_[0];
    my $frame = $_[1];

    $frame = '' unless defined $frame && length $frame;
    
    my ( $left, $right );
    if ( blessed $frame ) { # Just a mark
        ( $left, $right ) = ( $frame, $frame );
    }
    elsif ( ref $frame eq 'ARRAY' ) {
        ( $left, $right ) = @$frame;
    }
    elsif ( $frame =~ m/([!@\w+<>]*)?(?:-([!@\w+<>]*))?/ ) {
        ( $left, $right ) = ( $1, $2 );
        $right = $left unless defined $right;
    }
    else {
        die "Invalid frame ($frame)";
    }
    
    $left = '!' unless defined $left;
    $right = '@' unless defined $right;

    my $v0 = $self->mark2position( $left, '<' );
    my $v1 = $self->mark2position( $right, '>' );

    return ( $v0, $v1 );
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
