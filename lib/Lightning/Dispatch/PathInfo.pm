package Lightning::Dispatch::PathInfo;

use base Lightning::Abstract::Dispatch;

use Lightning::Util::require;

use Carp;
use strict;
use warnings;

our $VERSION = '0.10';

my $Default_Class = 'Root';

# Plugins for Lightning
sub init : Plugin(LT_MAKE_DISPATCH) {
	__PACKAGE__->new(@_);
}

sub prepare : Plugin(LT_PREPARE_DISPATCH) {
	my ($c) = @_;
	
	$c->dispatch()->chain($c->env('PATH_INFO') || '/');
}

sub discode : Plugin(LT_DISPATCH) {
	my ($c) = @_;
	my $self = $c->dispatch();
	
	# prepare
	my $prefix = $self->{prefix};
	my $source = $self->{sources}->[$self->{idx}] || return;
	(my $s = $source) =~ s|^/||;
	
	my @s = split(m|/|, $s);
	
	unshift(@s, $prefix) if length($prefix);
	
	# get original destination
	my $method = ($source =~ m|/$|) ? 'index' : pop @s;
	my @source;
	for (@s) {
		if ($_ eq '..') {
			pop(@source);
			next;
		}
		
		push (@source, $_);
	}
	
	my $class = join('::', @source);
	
	$class ||= 'Root';
	
	# load target
	$class->use() || return;
	
	my $code = $class->can($method) || $class->can('default') || return;
	
	return unless ref $code eq 'CODE';
	
	# make Action
	my $action = Lightning::Action->new(
		code	=> $code,
		class	=> $class,
		method	=> $method,
		source	=> $source,
	) || croak qq{failed to initialize Action object !};
	
	# increment index
	$self->{idx}++;
	
	# done !
	return $action;
};


# implements
sub new {
	my ($pkg, $c) = @_;
	
	my $prefix = (ref $c->config('dispatch') eq 'HASH') ? $c->config('dispatch')->{prefix} : '';
	
	bless {
		prefix	=> $prefix,
		sources	=> [],
		idx		=> 0,
	}, $pkg;
}

sub source {
	my ($self) = @_;
	
	return if $self->{idx} <= 0;
	
	return $self->{sources}->[$self->{idx} - 1];
}

sub chain {
	my ($self, $source) = @_;
	
	return unless $source;
	
	my $priv = ($source =~ m|^/|) ? '' : $self->source();
	
	$priv =~ s|[^/]*$||;
	
	push (@{$self->{sources}}, $priv . $source);
}


=head1 NAME

Lightning::Dispatch::PathInfo - The basic Dispatch Class with Path-Info

=head1 VERSION

Version 0.10

=head1 SYNOPSIS

	This is an implementation of Dispatch.
	the source of dispatch is $ENV{'PATH_INFO'} as same as the ordinary WAFs.
	
	The Dispatch-Rules are the following.
	
	Path-Info		Target Class		Target Method
	undef			Root			index()
	/			Root			index()
	/foo			Root			foo()
	/Foo			Root			Foo()
	/Foo/			Foo			index()
	/Foo/bar		Foo			bar()
	/Foo/Bar/		Foo::Bar		index()
	/Foo/Bar/buzz		Foo::Bar		buzz()
	
	And the configuration of 'Action Prefix' is available.
	if 'Action Prefix' is defined as 'App::Action',
	the Dispatch-Rules become the following.
	
	Path-Info		Target Class		Target Method
	undef			App::Action		index()
	/			App::Action		index()
	/foo			App::Action		foo()
	/Foo			App::Action		Foo()
	/Foo/			App::Action::Foo	index()
	/Foo/bar		App::Action::Foo	bar()
	/Foo/Bar/		App::Action::Foo::Bar	index()
	/Foo/Bar/buzz		App::Action::Foo::Bar	buzz()
	
	The way to define 'Action Prefix' is to give the config value like
		dispatch	=> { prefix => 'App::Action' }
	to Lightning.
	
	See Lightning::run() for the details about config values.
	
	
	If the Target Symbol is undefined,
	then check the default() method in the Target Class.

=head1 FUNCTIONS

=head2 C<init($c) : LT_MAKE_DISPATCH>

	the implementation of the Plugin LT_MAKE_DISPATCH.
	but it does only calling new().
	
	See new() for initialize code.

=head2 C<prepare($c) : LT_PREPARE_DISPATCH>

	the implementation of the Plugin LT_PREPARE_DISPATCH.
	
	it stores Path Info from Context.

=head2 C<discode($c) : LT_DISPATCH>

	the implementation of the Plugin LT_DISPATCH.
	
	it make Lightning::Action object obey to Dispatch Rule.
	See SYNOPSIS for the Dispatch Rules.

=head2 new($c)

	the constructor.
	
	it makes some properties from Config value.
	See SYNOPSIS for the available values.

=head2 has_next()

	the implementation of the abstract method.
	
	if the object has undispatched soruce, returns ture.
	unless, returns false.

=head2 source()

	the implementation of the abstract method.
	
	returns the last dispatched source.

=head2 chain($source)

	this is the method to reserve the next Action.
	
	$source should be a Path Info like value.
	
	and it also can be relative.
	in other words, you can use URI like '../foo'.
	if the first letter of $source is not '/', this method take $source as relative.
	
	for example,
		the first source is '/App/Bar/foo'
		and App::Bar::foo() calls this method like
		
		$c->dispatch()->chain('../Fizz/buzz');
		
		the next source will be '/App/Fizz/buzz'
			and Action will be App::Fizz::buzz().
	
	if you don't want relative,
	be sure that the head of $source is '/'.

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
