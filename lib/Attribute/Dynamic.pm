package Attribute::Dynamic;

use attributes;
use Data::Dumper;
use Carp;
use strict;
use warnings;

## Props ----------------------------
our $VERSION = '0.01';

my %Statics = (
	Attrs	=> {},
	Codes	=> {},
	Symbols	=> {},
);

{
	no strict 'refs';
	no warnings;
	
	*{UNIVERSAL::MODIFY_CODE_ATTRIBUTES} = \&MODIFY_CODE_ATTRIBUTES;
	*{UNIVERSAL::import} = \&import;
}

## Methods ------------------------
sub MODIFY_CODE_ATTRIBUTES {
	my ($pkg, $ref, @attrs) = @_;
	
	my $defs = $Statics{Attrs};
	my $codes = $Statics{Codes};
	
	$codes->{$pkg} ||= [];
	
	# parse attributes
	for my $attr (@attrs) {
		my ($name, $args) = $attr =~ m|^([^\(\)]+)(\(.+\))?$|;
		
		$args = '' unless defined $args;
		$args =~ s|\((.+)\)|$1|;
		
		my @args = map { s|^['"](.*)['"]$|$1|; $_ } split(/\s*,\s*/, $args);
		
		if ($name eq 'ATTR') { # user make attribute
			my ($alias) = @args;
			$defs->{$alias} = $ref;
			
		} elsif (exists $defs->{$name}) { # defined attribute
			push (@{$codes->{$pkg}}, [$name, $ref, \@args]);
			
		}
	}
	
	return;
}

sub import {
	no strict 'refs';
	
	my ($pkg, @args) = @_;
	my $switch = shift(@args);
	
	# prepare
	my $defs = $Statics{Attrs};
	my $codes = $Statics{Codes}->{$pkg} || return 1;
	
	# make reverse symbol table
	my $rev = {};
	for my $sym (values %{$pkg.'::'}) {
		my $name = *{$sym}{NAME};
		my $code = *{$sym}{CODE};
		
		next unless ref $code eq 'CODE';
		
		$rev->{$code} = *{$pkg.'::'.$name};
	}
	
	# execute attributes
	for (@$codes) {
		my ($name, $ref, $args) = @$_;
		
		my $attr = $defs->{$name};
		my $sym = $rev->{$ref};
		
		$attr->($pkg, $sym, $ref, $name, $args);
	}
	
	return 1;
}


=head1 NAME

Attribute::Dynamic - The helper to make attributes

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

	This class is the only helper to make CODE attributes.
	the usage is,
	
	package Foo;
	
	use Attribute::Dynamic;
	
	sub test : ATTR(test) {
		my ($pkg, $sym, $ref, $name, $args) = @_;
		# do something...
	}
	
	# and in another file ...
	package Bar;
	
	use UNIVERSAL::require;
	Foo->use();
	
	sub method : test {
		# do anything...
	}
	
	in the class uses Attribute::Dynamic, the CODE attribute named 'ATTR' is available.
	it requires 1 argument which means the name of newly attribute.

	then you can add the created attribute to every CODE.

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

