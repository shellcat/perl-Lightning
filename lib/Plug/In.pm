package Plug::In;

use base Attribute::Dynamic;

use Plug;

use attributes;
use Carp;
use strict;

our $VERSION = '0.10';

## Methods ------------------------
sub Plugin : ATTR(Plugin, CODE) {
	my ($pkg, $sym, $ref, $attr, $args) = @_;
	
	my $plugname = shift(@$args) || return;
	
	return Plug->entry($plugname, $ref);
}


=head1 NAME

Plug::In - the attribute definition for Plugin methods 

=head1 VERSION

Version 0.10

=head1 SYNOPSIS

	this class defines an attribute for method.
	the usage is,

	use Plug::In;
	
	sub foo : Plugin(plugname) {
		# do something...
	}

	the method with Plugin attribute is automatically stored as plugin method.
	its only argument is the name of plugin.

	the plugin methods will be executed by Plug::Out::energize().

	see Plug::Out for details of given arguments and returnings.


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

1;

