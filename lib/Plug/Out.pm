package Plug::Out;

use Plug;

use Carp;
use strict;

our $VERSION = '0.10';

## Props ----------------------------
my %Props = (
	name		=> '',
	codes		=> [],
	callback	=> sub {},
	no_plug		=> sub {},
	args		=> [],
);


## Methods ------------------------
sub new {
	my ($pkg, $plugname, $codes, $callback, $no_plug, $args) = @_;
	
	my $self = bless {
		%Props,
		name		=> $plugname,
		codes		=> [@$codes],
		callback	=> $callback,
		no_plug		=> $no_plug,
		args		=> [@$args],
	}, $pkg;
	
	return $self;
}

sub accept {
	my ($pkg, %option) = @_;
	
	my ($plugname, $args, $cb, $np, $type) = @option{qw(name args callback no_plug type)};
	
	$type ||= Plug->TYPE_SEQUENTIAL;
	
	return unless $plugname;
	return unless ($type eq Plug->TYPE_EXCLUSIVE || $type eq Plug->TYPE_SEQUENTIAL);
	
	my $class = caller();
	my $callback = (ref $cb eq 'CODE') ? $cb :
					($class->can($cb)) ? $class->can($cb) : undef;
	my $no_plug = (ref $np eq 'CODE') ? $np :
				 ($class->can($np)) ? $class->can($np) : sub {};
	
	return unless ref $args eq 'ARRAY';
	
	my $self = $pkg->new(
		$plugname,
		Plug->retrieve($plugname, $type),
		$callback,
		$no_plug,
		$args,
	) || return;
	
	return $self;
}

sub energize {
	my ($self) = @_;
	
	my $codes = $self->{codes};
	my $args = $self->{args};
	my $callback = $self->{callback} || sub {};
	my $no_plug = $self->{no_plug} || sub{};
	
	return unless (
		ref $codes eq 'ARRAY' &&
		ref $args eq 'ARRAY' &&
		ref $callback eq 'CODE' &&
		ref $no_plug eq 'CODE'
	);
	
	# execute plugins
	my $i = 0;
	for my $c (@$codes) {
		next unless ref $c eq 'CODE';
		
		my @res = $c->(@$args);
		
		$callback->(@res);
		
		$i++;
	}
	
	$no_plug->() unless $i;
	
	return 1;
}


=head1 NAME

Plug::Out - the interface to use Plugins

=head1 VERSION

Version 0.10

=head1 SYNOPSIS

	this class is the interface for the classes which calls plugin methods.
	first, accept() method should be called.

	use Plug::Out;
	
	my $plug = Plug::Out->accept(
		name	=> 'plugname',
		type	=> Plug->TYPE_EXCLUSIVE,
		args	=> [1],
		callback=> sub {},
		no_plug	=> sub {},
	);

	it makes Plug::Out object.
	then,

	$plug->energize();

	in energize() method, stored plugin methods are executed.

	this class has only 2 methods,
	so the following style of coding is recommended.

	use Plug::Out;
	
	Plug::Out->accept(
		name	=> 'plugname',
		type	=> Plug->TYPE_EXCLUSIVE,
		args	=> [1],
		callback=> sub {},
		no_plug	=> sub {},
	)->energize();


	see FUNCTIONS for more details.

=head1 FUNCTIONS

=head2 accept(%options)

	fetch the stored plugin methods, and define the behavior of the plug.
	the returning is the object of this class.
	
	the arguments must be HASH, and required elements are following.

=head3 $options{name} : required

	the name of plugin.
	plugin methods which marked with the same name will be executed.

=head3 $options{type} : optional

	the type which decides the behavior.
	see Plug::TYPES document for details.
	
	the default is TYPE_SEQUENTIAL.

=head3 $options{args} : optional

	ARRAYref contains the arguments which will be given to plugin methods.

=head3 $options{callback} : optional

	CODEref which receives the returning of plugin methods.
	the code is executed for each plugin returns.

=head3 $options{no_plug} : optional

	this element must be a CODEref.
	this code will be used if no plugin is executed.

=head2 energize()

	execute prepared plug.
	if no error occurs, returns true.


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

