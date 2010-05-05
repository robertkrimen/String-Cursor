#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
plan 'no_plan';

use String::Cursor;

my ( $s0, $v0, $p0 );

$s0 = String::Cursor->new( data => join '', 'a' .. 'z' );

sub o0 () {
    diag $s0->head, " ", $s0->tail, ": ", $s0->islice( '@' );
}

diag $s0->data, "\n";
o0;

$s0->find( qr/b/ );
o0;

$s0->find( qr/b/ );
o0;

$s0->reset->find( qr/b/ );
o0;

$s0->find( qr/..../ );
o0;

$v0 = [ $s0->frame2vector( [qw/ ! @ /] ) ];
cmp_deeply( $v0, [qw/ 0 5 /] );

$v0 = [ $s0->frame2vector( '@' ) ];
cmp_deeply( $v0, [qw/ 2 5 /] );

$v0 = [ $s0->frame2vector( '!' ) ];
cmp_deeply( $v0, [qw/ 0 0 /] );

$v0 = [ $s0->frame2vector( '@<-@>' ) ];
cmp_deeply( $v0, [qw/ 2 5 /] );

$s0->shift( 3 );
o0;

$s0->offset( +3 );
o0;

$v0 = [ $s0->frame2vector( [qw/ ! @ /] ) ];
cmp_deeply( $v0, [qw/ 0 11 /] );

$s0 = String::Cursor->new( data => <<_END_ );

    abcdefghijklmnopqrstuvwxyz

qwerty

1 2 3 4 5 5 6 7 8 9     

    xyzzy

_END_

$s0->find( qr/b/ );
o0;

$v0 = [ $s0->frame2vector( [qw/ ! @ /] ) ];
cmp_deeply( $v0, [qw/ 0 6 /] );

diag scalar $s0->oslice;

$s0->find( qr/2 3/ );
o0;
diag scalar $s0->oslice;

$s0->reset->offset( 1 )->mark->find( qr/b/ );
o0;
diag scalar $s0->oslice;
diag scalar $s0->islice;
