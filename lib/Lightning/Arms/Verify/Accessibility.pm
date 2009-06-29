package Lightning::Arms::Verify::Accessibility;

use Plug::In;

use Carp;
use strict;
use warnings;

our $VERSION = '0.01';

# Props
my %Codes = (
	'Protected'	=> {},
	'Private'	=> {},
);

# Attributes
sub Public : ATTR(Public, CODE) {}

sub Protected : ATTR(Protected, CODE) {
	my ($pkg, $sym, $ref) = @_;
	
	$Codes{'Protected'}->{$ref} = 1;
}

sub Private : ATTR(Private, CODE) {
	my ($pkg, $sym, $ref) = @_;
	
	$Codes{'Private'}->{$ref} = 1;
}

# Plugins
sub verify : Plugin(LT_VERIFY_ACTION) {
	my ($c, $act, $i) = @_;
	
	# check private and protected
	if (defined $Codes{'Private'}->{$act->code()} ||
		(defined $Codes{'Protected'}->{$act->code()} && $i == 0)
	) { # search default Action
		my $class = $act->class();
		my $ref = $class->can('default') || return;
		
		$act->code() = $ref;
	}
	
	# done
	return $act;
}


=head1 NAME

Lightning::Arms::Verify::Accessibility - Lightning Plugin for make accessibility of Action.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

	this class is a Plugin for Lightning for set accessibility of Action.
	
	In the standard, all of methods in Action class can be executed as Action.
	But some methods like common utility, may not assume that case.
	
	So, this Arms enables you to hide those methods from Dispatcher.
	
	
	the usage is only to add a attribute to method.
	
		sub act1 : Public {}
		sub act2 : Protected {}
		sub act3 : Private {}
	
	there are 3 accessibility.
	If the Action is invalid, the 'default' method will be searched.

=head2 Public

	public accessible.
	actually, this attribute does nothing.

=head2 Protected

	the attributed method cannot be executed as first Action.
	in other words, the method will be executed only when redirected from other Action.

=head2 Private

	the attributed method cannot be executed as Action at all.

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
