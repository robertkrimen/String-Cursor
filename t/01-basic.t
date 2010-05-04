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
