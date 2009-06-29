package Lightning::Util::Try;

use Carp;
use strict;

our $VERSION = '0.01';

sub import {
	my ($pkg, @tags) = @_;
	
	my $class = caller();
	my %exports;
	
	for my $tag (@tags) {
		if ($tag eq ':all') {
			@exports{qw(try catch finally)} = (1) x 3;
		} elsif ($pkg->can($tag)) {
			$exports{$tag} = 1;
		}
	}
	
	{
		no strict 'refs';
		
		for my $method (keys %exports) {
			*{$class.'::'.$method} = $pkg->can($method);
		}
	}
	
	return 1;
}

sub try(&;$) {
	my ($code, $traps) = @_;
	
	$traps = {} unless ref $traps eq 'HASH';
	
	my ($res, $err, @result, @stack);
	{
		local $@ = undef;
		local $SIG{__DIE__} = sub {
			#return if $^S;
			
			my ($e) = @_;
			
			my $i = 0;
			while (1) {
				my ($pkg, $file, $line) = caller($i);
				$i++;
				
				last unless $pkg;
				next if $pkg eq __PACKAGE__;
				
				push (@stack, {
					pkg		=> $pkg,
					file	=> $file,
					line	=> $line,
				});
			}
			
			die $e;
		};
		
		$res = eval {
			@result = $code->();
			1;
		};
		
		$err = $@;
	}
	
	if (!$res && ref $traps->{catch} eq 'CODE') { # exception occured
		$res = eval {
			$traps->{catch}->($err, \@stack);
			@stack = ();
			1;
		};
	}
	
	if (ref $traps->{finally} eq 'CODE') {
		$traps->{finally}->();
	}
	
	if (scalar(@stack)) {
		croak qq{Uncaught Exception $err};
	}
	
	return (wantarray) ? @result : \@result;
}


sub catch(&;$) {
	my ($code, $traps) = @_;
	
	$traps = {} unless ref $traps eq 'HASH';
	$traps->{catch} = $code;
	
	return $traps;
}

sub finally(&) {
	my ($code) = @_;
	
	my $traps = { finally => $code };
	
	return $traps;
}

=head1 NAME

Lightning::Util::Try - Exception trapper like Java

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

	only use with :all tag.
	then you can use Java like try ~ catch ~ finally syntax !
	
	use Lightning::Util::Try qw(:all);
	
	try {
		# some trying ...
	} catch {
		my @e = @_; # exception stacks
		# some exception handling ...
	} finally {
		# some finishments ...
	}

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


1; # End of Test
