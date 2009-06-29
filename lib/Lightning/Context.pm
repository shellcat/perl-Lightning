package Lightning::Context;

use base Lightning::Abstract::Context;

use Carp;
use strict;
use warnings;

our $VERSION = '0.10';

my %Statics = (
	Obj			=> undef,
	Config		=> {},
	
	Parsed		=> 0,
	Req			=> {},
	Env			=> {},
	Dispatch	=> undef,
	View		=> undef,
	Action		=> [],
);

# plugins for Lightning
sub init : Plugin(LT_MAKE_CONTEXT) {
	return __PACKAGE__->new(@_);
}

sub parse : Plugin(LT_PARSE_INPUT) {
	my ($self, $raw_post, $raw_get) = @_;
	
	# prepare
	my $merge = sub {
		my ($dist, $key, $val) = @_;
		
		return unless ref $dist eq 'HASH';
		
		if (exists $dist->{$key} && ref $dist->{$key} eq 'ARRAY') {
			push (@{$dist->{$key}}, $val);
		} elsif (exists $dist->{$key}) {
			$dist->{$key} = [$dist->{$key}, $val];
		} else {
			$dist->{$key} = $val;
		}
		
		return 1;
	};
	
	#my ($get, $post) = @Statics{qw(Get Post)};
	my $req = $Statics{Req};
	
	# ENV context
	%{$Statics{Env}} = %ENV;
	
	# GET context
	for (split(/&/, $raw_get)) {
		my ($key, $val) = split(/=/);
		
		$val =~ tr/+/ /;
		$val =~ s/%([0-9a-fA-F]{2})/pack('C', hex($1))/eg;
		
		$merge->($req, $key, $val);
	}
	
	# POST context
	if (defined $ENV{'CONTENT_TYPE'} && $ENV{'CONTENT_TYPE'} =~ m|^multipart/form\-data|) {
		# multipart data
		my $boundary = $ENV{'CONTENT_TYPE'} =~ m|boundary=\"?([^\";.,]+)\"?|;
		for (split(/$boundary/, $raw_post)) {
			my $key = $_ =~ m|\s*name=\"?([^\"]+)\"?|;
			
			next unless $key;
			
			my $val = substr($_, index($_, "\r\n\r\n") + length("\r\n\r\n"));
			$val =~ s|[\r\n]*$||g;
			
			my $mime = $_ =~ m|Content-Type: (\S+)|;
			
			$val = ($mime) ? { mime => $mime, cont => $val } : $val;
			
			$merge->($req, $key, $val);
		}
	} else {
		# ordinary data
		for (split(/&/, $raw_post)) {
			my ($key, $val) = split(/=/);
			
			$val =~ tr/+/ /;
			$val =~ s/%([0-9a-fA-F]{2})/pack('C', hex($1))/eg;
			
			$merge->($req, $key, $val);
		}
	}
	
	# done !
	1;
}

sub bundle : Plugin(LT_BUNDLE) {
	my ($c, $dispatch, $view) = @_;
	
	return unless $c eq $Statics{Obj};
	
	$Statics{Dispatch} = $dispatch;
	$Statics{View} = $view;
	
	return $c;
}

# constructor
sub new {
	my ($pkg, %config) = @_;
	
	# merge configure
	%{$Statics{Config}} = (%{$Statics{Config}}, %config);
	
	# construct if not yet
	$Statics{Obj} ||= bless {}, $pkg;
}

# implements
sub config			{ $Statics{Config}->{$_[1]}; }
sub req				{ $Statics{Req}->{$_[1]}; }
sub req_all			{ $Statics{Req}; }
sub env				{ $Statics{Env}->{$_[1]}; }

sub dispatch		{ $Statics{Dispatch}; }
sub view			{ $Statics{View}; }


=head1 NAME

Lightning::Context - The most simple Context Class

=head1 VERSION

Version 0.10

=head1 SYNOPSIS

	This is the simple implementation of Context.
	There is no method without recommended Plugins, or abstract methods.
	
	See FUNCTIONS for what and how the class can do.

=head1 FUNCTIONS

=head2 C<init() : Plugin(LT_MAKE_CONTEXT)>

	this method does only calling new().
	this is called automatically at the step of the Plug named LT_MAKE_CONTEXT.

=head2 C<parse($raw_post, $raw_get) : Plugin(LT_PARSE_INPUT)>

	parse the request context.
	it is the implementation of the Plugin LT_PARSE_INPUT.
	
	See req() for how to get the parsed value.

=head2 C<bundle($c, $dispatch, $view) : Plugin(LT_BUNDLE)>

	this is the Plugin for LT_BUNDLE.
	
	only bundle the 3 arguments.
	but returns false if $c is not equal to the object which made by init().

=head2 new()

	constructor of the class.
	this class implements the 'Singleton Pattern'
		because Request Context is MonoState.

=head2 req($key)

	accessor to request context value.
	this doesn't mind GET or POST.
	
	$key should be a key of parameter.
	
	if the key defined more than twice in the request,
	the returning is ARRAYref.
	
	and if the value is uploaded file,
	the returning is a HASHref like following.
		
		{
			mime	=> $mime_type,
			cont	=> $file_content,
		}

=head2 env($key)

	this is the accessor for %ENV values.

=head2 dispatch()

	accessor for Dispatcher object which given at bundle().
	
	see Lightning::Abstract::Dispatch about Dispatcher.

=head2 view()

	accessor for View object which given at bundle().
	
	see Lightning::Abstract::View about View.

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
