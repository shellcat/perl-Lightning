package Lightning;

use Plug::Out;

use Lightning::Context;
use Lightning::Dispatch::PathInfo;
use Lightning::View::Default;

use Lightning::Util::Error;
use Lightning::Util::Try qw(:all);

use Scalar::Util qw(blessed);
use Data::Dumper;
use Carp;
use strict;
use warnings;

our $VERSION = '0.10';

# boot method
sub run {
	shift if $_[0] eq __PACKAGE__;
	
	# prepare variables
	my @args = @_;
	my ($c, $v, $d);
	my ($post, $get);
	my ($buffer, $stdout);
	
	my %abstracts = (
		context		=> 'Lightning::Abstract::Context',
		dispatch	=> 'Lightning::Abstract::Dispatch',
		view		=> 'Lightning::Abstract::View',
		action		=> 'Lightning::Action',
	);
	
	# trap all exceptions
	try {
		# make context
		Plug::Out->accept(
			name	=> 'LT_MAKE_CONTEXT',
			type	=> Plug->TYPE_EXCLUSIVE,
			args	=> \@args,
			callback=> sub {
				$c = shift;
				
				unless (blessed($c) && $c->isa($abstracts{context})) {
					# invalid returning
					croak qq|Invalid Context object returned from LT_MAKE_CONTEXT.|;
				}
			},
			no_plug	=> sub { croak qq|No Plugin for LT_MAKE_CONTEXT.|; },
		)->energize();
		
		# filter input
		Plug::Out->accept(
			name	=> 'LT_FILTER_INPUT',
			type	=> Plug->TYPE_EXCLUSIVE,
			args	=> [$c],
			callback=> sub { ($post, $get) = @_; },
			no_plug	=> sub {
				read(STDIN, $post, (defined $ENV{'CONTENT_LENGTH'}) ? $ENV{'CONTENT_LENGTH'} : 0);
				$get = $ENV{'QUERY_STRING'} || '';
			},
		)->energize();
		
		# parse input
		Plug::Out->accept(
			name	=> 'LT_PARSE_INPUT',
			type	=> Plug->TYPE_EXCLUSIVE,
			args	=> [$c, $post, $get],
			callback=> sub { croak qq|Failed to Parse Input !| unless $_[0]; },
			no_plug	=> sub { croak qq|No Plugin for LT_PARSE_INPUT.|; },
		)->energize();
		
		# make dispatch
		Plug::Out->accept(
			name	=> 'LT_MAKE_DISPATCH',
			type	=> Plug->TYPE_EXCLUSIVE,
			args	=> [$c],
			callback=> sub {
				$d = shift;
				
				unless (blessed($d) && $d->isa($abstracts{dispatch})) {
					# invalid returning
					croak qq|Invalid Dispatch object returned from LT_MAKE_DISPATCH.|;
				}
			},
			no_plug	=> sub { croak qq|No Plugin for LT_MAKE_DISPATCH|; },
		)->energize();
		
		# make view
		Plug::Out->accept(
			name	=> 'LT_MAKE_VIEW',
			type	=> Plug->TYPE_EXCLUSIVE,
			args	=> [$c],
			callback=> sub {
				$v = shift;
				
				unless (blessed($v) && $v->isa($abstracts{view})) {
					# invalid returning
					croak qq|Invalid Dispatch object returned from LT_MAKE_VIEW.|;
				}
			},
			no_plug	=> sub { croak qq|No Plugin for LT_MAKE_VIEW|; },
		)->energize();
		
		# bundle
		Plug::Out->accept(
			name	=> 'LT_BUNDLE',
			type	=> Plug->TYPE_EXCLUSIVE,
			args	=> [$c, $d, $v],
			callback=> sub {
				$c = shift;
				
				unless (blessed($c) && $c->isa($abstracts{context})) {
					# invalid returning
					croak qq|Invalid Context object returned from LT_BUNDLE.|;
				}
			},
			no_plug	=> sub { croak qq|No Plugin for LT_BUNDLE.|; },
		)->energize();
		
		# other initialize
		Plug::Out->accept(
			name	=> 'LT_INIT',
			type	=> Plug->TYPE_SEQUENTIAL,
			args	=> [$c],
		)->energize();
		
		# prepare for dispatch
		Plug::Out->accept(
			name	=> 'LT_PREPARE_DISPATCH',
			type	=> Plug->TYPE_EXCLUSIVE,
			args	=> [$c],
			no_plug	=> sub { croak qq|No Plugin for LT_PREPARE_DISPATCH.|; },
		)->energize();
		
		# output buffering start
		my $buf;
		open($buffer, '>', \$buf) || croak qq|Failed to start buffering.|;
		$stdout = select($buffer);
		
		# Dispatch Loop start
		$c->header('Content-Type' => 'text/html');
		
		my $i = 0;
		while (1) {
			my $act;
			my $valid = 1;
			
			Plug::Out->accept(
				name	=> 'LT_DISPATCH',
				type	=> Plug->TYPE_EXCLUSIVE,
				args	=> [$c],
				callback=> sub {
					$act = shift || return;
					
					unless (blessed($act) && $act->isa($abstracts{action})) {
						croak qq|Invalid Action object returned from LT_DISPATCH.|;
					}
				},
				no_plug	=> sub { croak qq|No Plugin for LT_DISPATCH.|; },
			)->energize();
			
			# unless Action, finish !
			last unless $act;
			
			# verify Action
			Plug::Out->accept(
				name	=> 'LT_VERIFY_ACTION',
				type	=> Plug->TYPE_SEQUENTIAL,
				args	=> [$c, $act, $i],
				callback=> sub {
					return unless $valid;
					
					$valid = shift;
				},
			)->energize();
			
			# invalid, goto next
			next unless $valid;
			
			# prerun
			Plug::Out->accept(
				name	=> 'LT_PRERUN',
				type	=> Plug->TYPE_SEQUENTIAL,
				args	=> [$c, $act, $i],
			)->energize();
			
			# execute action
			$act->execute($c, $act, $i);
			
			# postrun
			Plug::Out->accept(
				name	=> 'LT_POSTRUN',
				type	=> Plug->TYPE_SEQUENTIAL,
				args	=> [$c, $act, $i],
			)->energize();
			
			# ok !
			$i++;
		}
		
		# if not found, handling it
		Plug::Out->accept(
			name	=> 'LT_NOT_FOUND',
			type	=> Plug->TYPE_SEQUENTIAL,
			args	=> [$c],
			no_plug	=> sub { $c->header("Status" => "404 Not Found"); },
		)->energize() if ($i == 0 && $c->header("Status") =~ m|^200|);
		
		# rendering
		Plug::Out->accept(
			name	=> 'LT_RENDER',
			type	=> Plug->TYPE_EXCLUSIVE,
			args	=> [$c],
			callback=> sub { croak qq|Failed to render.| unless shift; },
		)->energize();
		
		# output buffering end
		select($stdout);
		close($buffer);
		$buffer = undef;
		
		binmode($stdout);
		
		# output filtering
		Plug::Out->accept(
			name	=> 'LT_FILTER_OUTPUT',
			type	=> Plug->TYPE_SEQUENTIAL,
			args	=> [$c, \$buf],
		)->energize();
		
		# output
		$c->header('Content-Length' => (defined $buf) ? length($buf) : 0);
		
		my $header = $c->header();
		
		while (my ($key, $val) = each %$header) {
			next unless $val; # do not output blank header
			
			printf("%s: %s\n", $key, $val);
		}
		
		print "\n";
		print $buf if defined $buf;
	} catch {
		if (defined $buffer) { select($stdout); }
		
		Lightning::Util::Error->display(@_);
	};
}

		
=head1 NAME

Lightning - the flexible Web Application Framework

=head1 VERSION

Version 0.10

=head1 ABSTRACT

	Lightning is a Framework for helping to develop Web Application.
	
	the feature of Lightning is its architecture.
	this Framework does only execute some Plugins.
	
	parse input, dispatch, and execute action...
	Plugins are in charge of what it does on each steps.
	
	of course there are default Plugins in Lightning family.
	first of all, you'd better to try to use Lightning with the defaults.
	
	then, when you get used to using Lightning,
	let's try to make your Plugins !
	
	
	Make your development Lightning !
	Welcome to the Lightning World !

=head1 INDEX

	There are some documents about Lightning.
	you'd better to choose what to read according to your purpose.

=head2 L<Lightning::Introduction|Lightning::Introduction>

	the general introduction of Web Application Framework and Lightning.
	if you aren't accustomed to Framework, see this.

=head2 L<Lightning::CookBook|Lightning::CookBook>

	the start-up document of this Framework.
	this explains only usage.
	if you use Lightning at the first time, see this.

=head2 L<Lightning::Plugin|Lightning::Plugin>

	more detailed description of the usage and architecture of Lightning.
	what Plugins are prepared,
	how to extend Lightning,
	and how to develop your own Plugins.
	
	for more heavy use, see this.

=head1 FUNCTIONS

=head2 run([%config])

	the only method in this class.
	
	%config elements are used by Plugins.
	and of course, applications can use them too.
	
	See Lightning::CookBook about how to use the config elements.

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
