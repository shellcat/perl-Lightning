package Lightning::Abstract::Dispatch;

use Lightning::Action;

use Plug::In;

use Carp;
use strict;
use warnings;

our $VERSION = '0.10';

# constructor
sub new { bless {}, shift; }

# abstracts

sub source { croak qq{abstract method source() is not implemented}; }

=head1 NAME

Lightning::Abstract::Dispatch - the Interface of Dispatch Class

=head1 VERSION

Version 0.10

=head1 SYNOPSIS

	the 'Dispatch' glues Request to Action by Path-Info, Query value, and so on.
	
	Dispatch should implement the Plugins,
		LT_MAKE_DISPATCH,
		LT_PREPARE_DISPATCH,
		LT_DISPATCH
	
	the simple purpose of Dispatch is to initialize Lightning::Action object.
	See FUNCTIONS and Lightning::Plugin to implement your Dispatch.

=head1 FUNCTIONS

=head2 new()

	simple constructor.
	of course you can override it.

=head2 source()

	this method is expected to return the source value of the last dispatch.

=head1 AUTHOR

ShellCat, C<< <shell@ateliershell.jp> >>

=head1 BUGS

Please report any bugs or feature requests to C<lightning@ateliershell.jp>.
I will be notified.

=head1 COPYRIGHT & LICENSE

Copyright 2009 AtelierShell, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Class
