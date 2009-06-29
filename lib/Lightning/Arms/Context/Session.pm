package Lightning::Arms::Context::Session;

use Lightning::Abstract::Context;
use Lightning::Arms::Context::Cookie;

use Data::Dumper;
use IO::Handle;
use attributes;
use strict;

our $VERSION = '0.01';

my $Seed = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
my $Count = length($Seed);

# extend Context
my $init = sub : Plugin(LT_INIT) {
	my ($c) = @_;
	
	Lightning::Abstract::Context->extend(__PACKAGE__->new($c), 'session');
};


# methods
sub new {
	my ($pkg, $c) = @_;
	
	# get directory to store from config
	my $dir = $c->config('session') || '.';
	return unless -d $dir && -r $dir && -w $dir;
	
	# construct
	my $self = bless {
		context	=> $c,
		dir		=> $dir,
	}, $pkg;
	
	# continue session if sid exists
	my $sid = $c->cookie()->get('sid');
	my $data = load_data($dir, $sid);
	
	if (ref $data eq 'HASH' && defined $data->{expires} && ref $data->{store} eq 'HASH') { # data exists
		$self->{sid} = $sid;
		$self->{data} = $data;
	}
	if ($data->{expires} <= time()) { # expired
		$self->end();
	}
	
	# ok
	return $self;
}

sub load_data {
	my ($dir, $sid) = @_;
	my $path = sprintf("%s/%s", $dir, $sid);
	my $data;
	
	return unless $sid =~ m|^\w+$|;
	return unless -f -r -w $path;
	
	open (my $fh, '<', $path) || return;
	flock ($fh, 1);
	
	{
		no strict;
		$data = eval join("", $fh->getlines());
	}
	
	$fh->close();
	
	return $data;
}

sub make_sid {
	my ($digit) = @_;
	
	$digit ||= 16;
	
	my $sid = '';
	while (length($sid) < $digit) {
		$sid .= substr($Seed, int(rand($Count)), 1);
	}
	
	return $sid;
}

sub validate_new_sid {
	my ($dir, $sid) = @_;
	
	# check format
	return unless $sid =~ m|^\w+$|;
	
	# check collision
	my $data = load_data($dir, $sid) || return 1;
	
	return if $data->{expires} > time();
	
	# clear expired data
	unlink sprintf("%s/%s", $dir, $sid);
}


# instance methods
sub is_valid {
	my ($self) = @_;
	my $data = $self->{data};
	
	return unless ref $data eq 'HASH';
	return unless (defined $data->{expires} && $data->{expires} > time());
	return unless ref $data->{store} eq 'HASH';
	
	return 1;
}

sub start {
	my ($self, $ttl) = @_;
	
	$ttl ||= 2 * 60 * 60; # default 2 hours
	
	return unless $ttl > 0;
	
	# make sid : try less than 5 times
	my $sid;
	for (0..4) {
		my $s = make_sid();
		
		if ($self->validate_new_sid($s)) {
			$sid = $s;
			last;
		}
	}
	
	return unless $sid;
	
	# make data file
	my %data = (
		expires	=> time() + $ttl,
		store	=> {},
	);
	
	open (my $fh, '>', sprintf("%s/%s", $self->{dir}, $sid)) || return;
	flock ($fh, 2);
	
	$fh->print(Dumper(\%data));
	
	close($fh);
	
	# hold sid and data
	$self->{sid} = $sid;
	$self->{data} = \%data;
	
	# send cookie
	$self->{context}->cookie()->set(
		name	=> 'sid',
		val		=> $sid,
		expires	=> $self->{context}->cookie()->make_expires(time() + $ttl),
	);
	
	# done
	return $sid;
}

sub regenerate {
	my ($self) = @_;
	
	return unless $self->is_valid();
	
	my $sid;
	my $dir = $self->{dir};
	my $path = sprintf("%s/%s", $dir, $self->{sid});
	my $cookie = $self->{context}->cookie();
	
	for (0..4) {
		my $s = make_sid();
		
		# validate
		next unless validate_new_sid($dir, $s);
		
		# move stored file
		next unless rename($path, sprintf("%s/%s", $dir, $s));
		
		$cookie->set(
			name	=> 'sid',
			val		=> $s,
			expires	=> $cookie->make_expires($self->{data}->{expires}),
		);
		
		return $self->{sid} = $s;
	}
	
	return;
}

sub end {
	my ($self) = @_;
	
	return unless $self->is_valid();
	
	my $path = sprintf("%s/%s", $self->{dir}, $self->{sid});
	
	return if (-f $path && !unlink($path));
	
	delete $self->{sid};
	delete $self->{data};
	
	return 1;
}

sub sid { shift->{sid}; }

sub param {
	my ($self, @args) = @_;
	
	return unless $self->is_valid();
	
	my $store = $self->{data}->{store};
	
	return unless scalar(@args);
	return $store->{$args[0]} if scalar(@args) == 1;
	
	%$store = (%$store, @args);
	
	return 1;
}

sub DESTROY {
	my ($self) = @_;
	
	return unless $self->is_valid();
	
	my $path = sprintf("%s/%s", $self->{dir}, $self->{sid});
	
	open (my $fh, '>', $path) || return;
	flock ($fh, 2);
	
	$fh->print(Dumper($self->{data}));
	
	$fh->close();
}


=head1 NAME

Lightning::Arms::Context::Session - The extention of session implementation.

=head1 VERSION

Version 0.01

=head1 PREREQUISITE

	This class excepts the client which accepts Cookie.
	For some browsers (like mobile phone), the session does not work.
	
	The session values are stored in file.
	So this is useless for applications working on redundant servers.
	And of course, the directory is readable/writable for the executive user.

=head1 SYNOPSIS

	This class is an extention for Context.
	After this class is loaded, you can use session() method on Context object.
	Its returning is the object of this class.
	
		$session = $c->session();
		
		$session->start() unless $session->is_valid();
		$session->param('foo' => 'bar');
		
		# in after access...
		$session = $c->session();
		
		print $session->param('foo');
		
		# and if it is no longer needed...
		$session->end();
	
	Once the session started, session id is made.
	
	Then you can store values as session value with param() method.
	The session values can be alive after script ends.
	
	When the same client accesses, it sends session id through Cookie.
	The session object loads the saved values automatically.
	They can be read by param() method.
	
	The session ends at the following situations.
		* Session is expired
		* Client does not send session id
		* script calls end() method
	
	And, this extension requires the config value named 'session'.
	The value should be the directory path to store the session files.
	for example,
	
		Lightning->run(
			'session'	=> './session',
		);
	
	Default is current directory.
	
	If the directory is not readable or writable, initialization fails.

=head1 FUNCTIONS

=head2 new()

	the simple constructor.
	if valid session id is sent, load the saved values.
	
	this method should be called automatically.
	so you only use this file !

=head2 is_valid()

	returns the boolean value if the valid session is started or not.

=head2 start([$ttl])

	start new session.
	$ttl should be the number of seconds until expires.
	the default is 2 hours.
	
	returning is the created session id if succeed.

=head2 end()

	end the current session.

=head2 sid()

	get current session id.

=head2 param($name)

	get session value named $name.

=head2 C<param($name, $value)>

	set session value named $name to $value.

=head2 param(%args)

	all elements in %args are set as session value.

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
