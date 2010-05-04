#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
plan 'no_plan';

use String::Cursor;

my ( $string );

$string = String::Cursor->new( data => join '', 'a' .. 'z' );

sub o0 () {
    diag $string->head, " ", $string->tail, ": ", $string->substring;
}


diag $string->data, "\n";
o0;

$string->find( qr/b/ );
o0;

$string->find( qr/b/ );
o0;

$string->reset->find( qr/b/ );
o0;

$string->find( qr/../ );
o0;

$string->shift( 3 );
o0;

$string->offset( +3 );
o0;

$string = String::Cursor->new( data => <<_END_ );

    abcdefghijklmnopqrstuvwxyz

qwerty

1 2 3 4 5 5 6 7 8 9     

    xyzzy

_END_

$string->find( qr/b/ );
o0;
diag scalar $string->slice;

$string->find( qr/2 3/ );
o0;
diag scalar $string->slice;

$string->reset->offset( 1 )->mark->find( qr/b/ );
o0;
diag scalar $string->slice;
diag scalar $string->substring;
