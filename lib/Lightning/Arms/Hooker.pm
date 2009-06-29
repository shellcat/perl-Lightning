package Lightning::Arms::Hooker;

use Plug::In;

use Carp;
use strict;
use warnings;

our $VERSION = '0.01';


# Props
my %Hooks = (
	'Prerun'	=> {},
	'Postrun'	=> {},
);

# Attributes
sub PreHook : ATTR(PreHook, CODE) {
	my ($pkg, $sym, $ref, $name, $args) = @_;
	
	# search hook
	my $hook = $args->[0] || return;
	my $code = search_hook($pkg, $hook) || return;
	
	# set hook
	$Hooks{'Prerun'}->{$ref} = $code;
}

sub PostHook : ATTR(PostHook, CODE) {
	my ($pkg, $sym, $ref, $name, $args) = @_;
	
	# search hook
	my $hook = $args->[0] || return;
	my $code = search_hook($pkg, $hook) || return;
	
	# set hook
	$Hooks{'Postrun'}->{$ref} = $code;
}

sub search_hook {
	my ($pkg, $hook) = @_;
	
	return unless $hook;
	
	my ($class, $method) = $hook =~ m|^(.+)::([^:]+)$|;
	
	unless (defined $class && defined $method) {
		($class) = $pkg;
		$method = $hook;
	}
	
	return unless $class->use();
	
	return $class->can($method);
}

	
# Plugins
sub prerun : Plugin(LT_PRERUN) {
	my ($c, $act, $i) = @_;
	
	my $conf = $c->config('hooker');
	my $hook = $Hooks{'Prerun'}->{$act->code()};
	
	my $source = '';
	
	if (!$hook && ref $conf eq 'HASH') {
		for my $src (keys %$conf) {
			next if length($src) < length($source);
			
			my $set = $conf->{$src};
			
			next unless (ref $set eq 'HASH' && exists $set->{prehook});
			
			my $h = search_hook($act->class(), $set->{prehook});
			if ($act->source() =~ m|^$src| && ref $h eq 'CODE') {
				$hook = $h;
				$source = $src;
			}
		}
	}
	
	return unless ref $hook eq 'CODE';
	
	$hook->($c, $act, $i);
}

sub postrun : Plugin(LT_POSTRUN) {
	my ($c, $act, $i) = @_;
	
	my $conf = $c->config('hooker');
	my $hook = $Hooks{'Postrun'}->{$act->code()};
	
	if (!$hook && ref $conf eq 'HASH') {
		for my $src (keys %$conf) {
			my $set = $conf->{$src};
			
			next unless (ref $set eq 'HASH' && exists $set->{posthook});
			
			my $h = search_hook($act->class(), $set->{posthook});
			if ($act->source() =~ m|^$src| && ref $h eq 'CODE') {
				$hook = $h;
				last;
			}
		}
	}
	
	return unless ref $hook eq 'CODE';
	
	$hook->($c, $act, $i);
}


=head1 NAME

Lightning::Arms::Hooker - Lightning Plugin for hooks

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

	this class is a Plugin for Lightning
	to use prehook and posthook which executed before/after Action.
	
	there are 2 usage.
	
	the first is the attribute named PreHook/PostHook.
	the attributed Action gets hooks.
	
	for example,
		sub hook1 { print 'prehook'; }
		sub hook2 { print 'posthook'; }
		
		sub action1 : PreHook(hook1) { print 'main'; }
		sub action2 : PreHook(hook1) PostHook(hook2) { print 'double hooked'; }
	
	if Action has PreHook attribute, it has prehook, and PostHook attribute behaves as posthook.
	
	the argument of the attribute should be the name of subroutine which defined as hook.
	and other class' subroutine can be assign as hook by doing,
	
		sub action3 : PreHook(SomeClass::hook3) {}
	
	the above is the 'Attribute Style'.
		
	and the another is 'Area Style'.
	
	this class accepts the config value which named 'hooker'.
	for example,
	
		Lightning->run(
			hooker	=> {
				'/Foo'	=> {
					prehook		=> 'App::prehook',
					posthook	=> 'App::posthook',
				},
				'/Fizz/Buzz'	=> {
					prehook		=> 'hook1',
				},
			},
		);
	
	the config value of 'hooker' must be a HASHref (unless that, it will be ignored).
	and the keys are the part of source which contained in Action object.
	the key will be used in the regex,
	
		$source =~ m|^$key|
	
	if it matches, set prehook and posthook.
	and if more than 2 keys matches, the value of the longer key overwrites.
	
	'Area Style' will be overwritten by 'Attribute Style'.
	
	
	the followings are the sample correspond table.
		
		* Sample (Path-Info type)
		hooker	=> {
			'/Foo/'	=> {
				prehook		=> 'App::prehook',
				posthook	=> 'App::posthook',
			},
			'/Fizz/Buzz/'	=> {
				prehook		=> 'hook1',
			},
		}
		
		sub Foo::buzz : PreHook(init) {}
		
	
	Source			PreHook				PostHook
	/			none				none
	
	/Foo			none				none
	/Foo/			App::prehook			App::posthook
	/Foo/bar		App::prehook			App::posthook
	/Foo/buzz		Foo::init			App::posthook
	
	/Fizz/			none				none
	/Fizz/Buzz		none				none
	/Fizz/Buzz/		Fizz::Buzz::hook1		none
	/Fizz/Buzz/foo		Fizz::Buzz::hook1		none

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
