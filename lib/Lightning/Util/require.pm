package Lightning::Util::require;

use Lightning::Util::Try qw(:all);
use Data::Dumper;
use strict;
use warnings;

our $VERSION = '0.01';

sub import {
	my ($pkg) = @_;
	
	push (@UNIVERSAL::ISA, $pkg);
}

sub require {
	my ($pkg) = @_;
	my $file = $pkg;
	
	$file =~ s|::|/|g;
	$file .= '.pm';
	
	return 1 if $INC{$file};
	
	my $res = try { CORE::require($file) } catch { $@ = shift };
	
	return $res;
}

sub use {
	my ($pkg, @args) = @_;
	
	$pkg->require() || return;
	
	return $pkg->import(@args) if $pkg->can('import');
	return 1;
}


=head1 NAME

Lightning::Util::require - Dynamic require functions for UNIVERSAL.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS
	
	use Lightning::Util::require;
	
	$class= 'Foo';
	
	$class->use();

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
