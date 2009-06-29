package Lightning::Arms::Context::Cookie;

use Lightning::Abstract::Context;

use attributes;
use strict;

our $VERSION = '0.01';

my @Months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
my @Wdays = qw(Sun Mon Tue Wed Thu Fri Sat);

# extend Context
my $init = sub : Plugin(LT_INIT) {
	my ($c) = @_;
	
	Lightning::Abstract::Context->extend(__PACKAGE__->new($c), 'cookie');
};

# output prepared cookies
my $quit = sub : Plugin(LT_FILTER_OUTPUT) {
	my ($c, $buf) = @_;
	my $self = $c->cookie();
	
	$c->header("Set-Cookie" => $_) for values %{$self->{prepared}};
};


# methods
sub new {
	my ($pkg, $c) = @_;
	
	my $cookie = parse($c->env('HTTP_COOKIE'));
	
	bless {
		context		=> $c,
		received	=> $cookie,
		prepared	=> {},
	}, $pkg;
}

sub parse {
	my ($str) = @_;
	my %c;
	print $str;
	for my $node (split(/;\s*/, $str)) {
		my ($key, $val) = split(/=/, $node);
		
		merge(\%c, $key, $val);
	}
	
	return \%c;
}

sub merge {
	my ($ref, $key, $val) = @_;
	
	return unless ref $ref eq 'HASH';
	return unless $val;
	
	if (exists $ref->{$key} && ref $ref->{$key} eq 'ARRAY') {
		push (@{$ref->{$key}}, $val);
	} elsif (exists $ref->{$key}) {
		$ref->{$key} = [$ref->{$key}, $val];
	} else {
		$ref->{$key} = $val;
	}
	
	return 1;
}

sub set {
	my ($self, %args) = @_;
	my ($name, $val) = @args{qw(name val)};
	
	# check
	return unless $name;
	
	# make
	my $cookie = sprintf("%s=%s", $name, $val);
	
	for my $key (qw(expires domain path)) {
		$cookie .= sprintf("; %s=%s", $key, $args{$key}) if exists $args{$key};
	}
	
	$cookie .= "; secure" if (exists $args{secure} && $args{secure});
	
	# prepare
	$self->{prepared}->{$name} = $cookie;
}

sub get {
	my ($self, $name) = @_;
	
	$self->{received}->{$name};
}

sub make_expires {
	my ($self, $epoch) = @_;
	
	my ($sec, $min, $hour, $day, $mon, $year, $wday) = localtime($epoch);
	
	$year += 1900;
	
	my $m = $Months[$mon];
	my $w = $Wdays[$wday];
	
	return sprintf(
		"%s, %02d-%s-%04d %02d:%02d:%02d GMT",
		$w, $day, $m, $year, $hour, $min, $sec
	);
}


=head1 NAME

Lightning::Arms::Context::Cookie - The extention to get and set cookie.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

	This class is an extention for Context.
	After this class is loaded, you can use cookie() method on Context object.
	Its returning is the object of this class.
	
		$cookie = $c->cookie();
		
		print $cookie->get('foo');
		
		$cookie->set(
			name	=> 'fizz',
			val		=> 'oh it is the cookie !',
			expires	=> $cookie->make_expires(time() + 24 * 60 * 60),
		);
	
	You can get values from cookie with get() method.
	Also you can send cookie by set() method.
	
	See FUNCTIONS for more details of usage.

=head1 FUNCTIONS

=head2 new()

	the simple constructor.
	parse received cookies, and store the result.
	
	this method should be called automatically.
	so you only use this file !

=head2 get($name)

	get value glued with $name from received cookie.

=head2 set(%args)

	send cookie which defined %args.
	the elements of %args are the following.

	* $args{name} (required)
		the name of value.
	
	* $args{val} (required)
		the value to send.
	
	* $args{expires} (optional)
		the expired timestamp of this cookie.
		
		the value of this element must obey the format of cookie timestamp like "Thu, 1-Jan-2030 00:00:00 GMT".
		See make_expires() method also.
	
	* $args{domain} (optional)
		the domain which the cookie expects to be sent.
		by default, the current requested domain is used.
	
	* $args{path} (optional)
		the range which the cookie expects to be sent.
	
	* $args{secure} (optional)
		if the value of this element is true,
		the cookie will be sent at only https protocol.

=head2 make_expires($epoch)

	make the string which obey the format of cookie timestamp.
	you can use this returning as the value of expires element of set() method.

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
