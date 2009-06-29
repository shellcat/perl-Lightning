#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Lightning' );
}

diag( "Testing Lightning $Lightning::VERSION, Perl $], $^X" );
