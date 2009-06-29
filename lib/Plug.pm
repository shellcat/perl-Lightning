package Plug;

use Plug::In;
use Plug::Out;

use Carp;
use strict;

our $VERSION = '0.10';

## Props ----------------------------
use constant {
	TYPE_EXCLUSIVE	=> 'exclusive',
	TYPE_SEQUENTIAL	=> 'sequential',
};

my %Statics = (
	Entry	=> {},
);


## Methods ------------------------
sub entry {
	my ($pkg, $plugname, $ref) = @_;
	
	my $codes = $Statics{Entry};
	
	$codes->{$plugname} ||= [];
	
	return push (@{$codes->{$plugname}}, $ref);
}

sub retrieve {
	my ($pkg, $plugname, $type) = @_;
	
	my $codes = $Statics{Entry}->{$plugname} || [];
	
	return ($type eq TYPE_EXCLUSIVE) ? [$codes->[$#$codes]] : $codes;
}


=head1 NAME

Plug - module family for easy, dynamic Plugin

=head1 VERSION

Version 0.10

=head1 SYNOPSIS

	Plugin is the mechanism for extending function from outside.
	the usage is like,

	package Foo;
	
	use Plug::In;
	
	sub foo : Plugin(entry_test) {
		my ($i) = @_;
		
		return $i + 1;
	}
	
	
	package Bar;
	
	use Plug::Out;
	
	my $t = 1;
	
	Plug::Out->accept(
		name	=> 'entry_test',
		type	=> Plug->TYPE_EXCLUSIVE,
		args	=> [$t],
		callback=> sub { print shift; },
		no_plug	=> sub { die; },
	)->energize(); # shows '2'


	to say in short,
	make method with attribute Plugin(),
	and call Plug::Out::accept() and Plug::Out::energize().

	be careful that, the class which makes method with Plugin() attribute must use Plug::In.

	see Plug::In for making plugin methods.
	and see Plug::Out for using them.


=head1 TYPES

there are 2 types of Plug.

=head2 TYPE_EXCLUSIVE

	it is exclusive plug.
	when more than 2 plugin methods are defined,
	only last method will be used.

	it is suitable for switching procedure with dynamic loading.

=head2 TYPE_SEQUENTIAL

	it is sequential plug.
	when more than 2 plugin methods are defined,
	all methods will be executed by the order of definition.

	in other words, the sooner the method is defined, the sooner it is executed.

	it is suitable for extending a kind of procedure.

=head1 FUNCTIONS

=head2 entry($name, $ref)

	this method is called by Plug::In automatically
	
=head2 retrieve($name, $type)

	this method is called by Plug::Out automatically

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

