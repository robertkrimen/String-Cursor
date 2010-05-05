#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
plan 'no_plan';

use String::Cursor;

my ( $s0, $v0, $p0 );

$s0 = String::Cursor->new( data => <<_END_ );

    abcdefghijklmnopqrstuvwxyz

qwerty

1 2 3 4 5 5 6 7 8 9     

    xyzzy

_END_

sub o0 () {
    diag $s0->head, " ", $s0->tail, ": ", $s0->islice( '@' );
}

$s0->skip_until( qr/rty/ );
is( $s0->read_until( qr/5 6/ ), <<_END_ );
qwerty

1 2 3 4 5 5 6 7 8 9     
_END_
