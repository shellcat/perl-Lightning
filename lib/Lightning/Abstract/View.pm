package Lightning::Abstract::View;

use Plug::In;

use Carp;
use strict;
use warnings;

our $VERSION = '0.10';

# constructor
sub new { bless {}, shift; }

# abstracts
sub assign { croak qq{abstract method assign() is not implemented.}; }
sub file { croak qq{abstract method file() is not implemented.}; }


=head1 NAME

Lightning::Abstract::View - the Interface of View Class

=head1 VERSION

Version 0.10

=head1 SYNOPSIS

	'View' is in charge of output.
	usally View is concerned with some Template Engine like HTML::Template.
	
	View is NOT a Template Engine.
	only the adaptor in order to prevent the defference of interface of Template Engines.
	
	
	View is recommended to prepare the following Plugins.
		LT_MAKE_VIEW,
		LT_RENDER
	
	
	and See FUNCTIONS for abstract methods.

=head1 FUNCTIONS

=head2 new()

	simple constructor.
	you can override it.

=head2 C<assign() : abstract>

	set template parameters.

=head2 C<file() : abstract>

	set the template file name.

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
