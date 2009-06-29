package Lightning::Arms::Context::Stash;

use Lightning::Abstract::Context;
use Plug::In;

use strict;

our $VERSION = '0.01';

# extend Context
my $init = sub : Plugin(LT_INIT) {
	my ($c) = @_;
	
	Lightning::Abstract::Context->extend(__PACKAGE__->new($c), 'stash');
};

# methods
sub new {
	my ($pkg, $c) = @_;
	
	bless {
		c		=> $c,
		stash	=> {},
	}, $pkg;
}

sub disclose {
	my ($self) = @_;
	
	my %data = %{$self->{stash}};
	
	return \%data;
}

our $AUTOLOAD;
sub AUTOLOAD : lvalue {
	my ($self, @args) = @_;
	my ($class, $method) = $AUTOLOAD =~ m|(.+)::([^:]+)$|;
	
	return if $self->can($method);
	
	{
		no strict 'refs';
		
		*{$AUTOLOAD} = sub : lvalue {
			my ($self) = @_;
			
			$self->{stash}->{$method};
		};
	}
	
	$self->$method();
}

sub DESTROY {}

=head1 NAME

Lightning::Arms::Context::Stash - Simple Stash for storing data.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

	This class is an extention for Context.
	After this class is loaded, you can use stash() method on Context object.
	and its returning can store various data like,
	
		$stash = $c->stash();
		
		$stash->foo() = 'fizz';
		
		print $stash->foo();
	
	You can call any method name except new, disclose, AUTOLOAD, and DESTROY on a instance.
	then the data space created automatically.
	
	the data space is readable/writable.
	and also used as lvalue, so you can use it as if it is a ordinary variable !

=head1 FUNCTIONS

=head2 new()

	the simple constructor.
	only bless, and returns the instance.
	
	this method should be called automatically.
	so you only use this file !

=head2 disclose()

	get HASHref contains all elements in the stash.

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
