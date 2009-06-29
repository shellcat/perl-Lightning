package Lightning::Abstract::Context;

use Plug::In;

use Carp;
use strict;
use warnings;

our $VERSION = '0.10';
my %Header;
my %Subs;
my %Multi = (
	'Set-Cookie'	=> 1,
);

# simple utility
sub new { bless {}, shift; }

# common interface
sub header {
	my ($self, @args) = @_;
	
	return \%Header if scalar(@args) < 1;
	return $Header{$args[0]} if (defined $args[0] && scalar(@args) == 1);
	
	for (my $i = 0; $i < scalar(@args); $i += 2) {
		my ($key, $val) = @args[$i, $i + 1];
		
		if (exists $Multi{$key} &&
			exists $Header{$key} &&
			ref $Header{$key} eq 'ARRAY'
		) {
			push (@{$Header{$key}}, $val);
			
		} elsif (exists $Multi{$key} &&
				 exists $Header{$key}
		) {
			$Header{$key} = [$Header{$key}, $val];
		} else {
			$Header{$key} = $val;
		}
	}
}

sub extend {
	my ($pkg, $obj, $name) = @_;
	
	return unless $obj && $name;
	
	no strict 'refs';
	
	$Subs{$name} = $obj;
	
	*{__PACKAGE__ . "::" . $name} = sub { $Subs{$name}; };
}

# abstracts
sub config { croak qq{abstract method config() is not implemented.}; }
sub req { croak qq{abstract method req() is not implemented.}; }
sub env { croak qq{abstract method env() is not implemented.}; }

sub dispatch { croak qq{abstract method dispatch() is not implemented.}; }
sub view { croak qq{abstract method view() is not implemented.}; }


=head1 NAME

Lightning::Abstract::Context - the Interface of Context Class

=head1 VERSION

Version 0.10

=head1 SYNOPSIS

	the 'Context' is most important object.
	it holds the reference to Dispatch and View,
		and it is given to Action as the only argument.
	
	
	Context Class is recommended to implement the following Plugins.
		LT_MAKE_CONTEXT,
		LT_PARSE_INPUT,
		LT_BUNDLE
	
	See Lightning::Plugin for more information about Plugins.
	
	
	All of the Context Class must extend this Interface.
	This has some abstract methods used by Lightning CORE.
	
	See FUNCTIONS for the details of each method.

=head1 FUNCTIONS

=head2 new()

	the simple constructor.
	most of Context seems to be 'Singleton' or 'MonoState',
	so this method does only bless a HASHref to PACKAGE name.
	
	if you want, do override this.

=head2 header()

	the accessor to response headers.
	
	if no argument, return the HASHref of current headers.
	if 1 argument, return the current value defined by the argument.
	
	if more than 2 arguments (it have to HASH),
	set all values as header.

=head2 C<extend($obj, $name)>

	this method is to extend all of the Context class.
	
	the extention class should call this.
	then, you can use the method named $name on Context class.
	it returns $obj.
	
	the usage is like,
	
		Lightning::Context::Abstract->extend($obj, 'foo');
		
		$obj = $c->foo();

=head2 C<config($key) : abstract>

	Context has the responsivility to hold the config values
		which are given to Lightning::run().
	
	this method should return the value which assigned with $key.

=head2 C<req($key) : abstract>

	this method should return the request param which named $key.

=head2 C<env($key) : abstract>

	this method should return the value from $ENV{$key}.

=head2 C<dispatch() : abstract>

	Context must hold Dispatch object.
	and this method should return it.

=head2 C<view() : abstract>

	Context must hold View object.
	and this method should return it.

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
