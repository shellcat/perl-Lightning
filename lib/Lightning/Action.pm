package Lightning::Action;

use attributes;
use Carp;
use strict;

our $VERSION = '0.10';

my %Types = (
	action	=> 'CODE',
	prehook	=> 'CODE',
	posthook=> 'CODE',
);

sub new {
	my ($pkg, %args) = @_;
	
	return unless (ref $args{code} eq 'CODE' && $args{class} && $args{method});
	
	bless {
		code	=> $args{code},
		class	=> $args{class},
		method	=> $args{method},
		source	=> $args{source},
	}, $pkg;
}

sub execute {
	my $self = shift;
	
	return unless ref $self->{code} eq 'CODE';
	
	$self->{code}->(@_);
}

our $AUTOLOAD;
sub AUTOLOAD : lvalue {
	my ($self) = @_;
	my ($method) = $AUTOLOAD =~ m|::([^:]+)$|;
	
	croak qq|no such method $method.| unless defined $self->{$method};
	
	{
		no strict 'refs';
		
		if (exists $Types{$method}) {
			*{$AUTOLOAD} = sub : lvalue {
				return if ($_[1] && ref $_[1] ne $Types{$method});
				
				$_[0]->{$method};
			};
		} else {
			*{$AUTOLOAD} = sub : lvalue { $_[0]->{$method}; };
		}
	}
	
	$self->$method();
}

sub DESTROY {}


=head1 NAME

Lightning::Action - The basic implementation of Action Class

=head1 VERSION

Version 0.10

=head1 SYNOPSIS

	Action contains the executable code and the value which used at Dispatch.
	Concretely, Main Action, sources, and so on.
	All of the properties have accessor.
	See FUNCTIONS for them.
	
	
	If you are to write Action classes for application,
	see class(), method(), source() for use these values in your Action.
	
	If you are to implement your Dispatch or some Plugins,
	see new(), and action() for the detail of interfaces.

=head1 FUNCTIONS

=head2 new(%args)

	the simple constructor of this class.
	the valid arguments are following.
	
	* $args{code} : required
		CODEref which works as the Main Action.
		this code will run at execute() with 1 argument of Lightning::Context object.
	
	* $args{class} : required
		the class name which dispatch source defines.
	
	* $args{method} : required
		the method name which dispatch source defines.
		
	* $args{source} : recommended
		this expects the value which used at Dispatch.
		like Path_Info, Query, and so on.

=head2 execute(@args)

	run Main Action.
	
	originally, this method is to execute the code as Action of Lightning
		with 1 argument (Lightning::Abstract::Context object).
	but in order to make it more flexible, all arguments are passed to the codes.

=head2 accessors

	the following accessors are available.
	they have the attribute 'lvalue'.
	
	class()
	method()
	source()
	code()
	
	Be sure that code() accepts only CODEref.

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
