package Lightning::View::Default;

use base Lightning::Abstract::View;

use Lightning::Template;

use Carp;
use strict;
use warnings;

our $VERSION = '0.10';

# plugins
sub init : Plugin(LT_MAKE_VIEW) {
	__PACKAGE__->new(@_);
}

sub render : Plugin(LT_RENDER) {
	my ($c) = @_;
	my $self = $c->view();
	
	my $buf = '';
	$self->{engine}->render(\$buf) || return;
	
	print $buf;
}


# constructor
sub new {
	my ($pkg, $c) = @_;
	
	my $conf = $c->config('view');
	
	$conf = {} unless ref $conf eq 'HASH';
	
	my $self = bless {
		engine	=> Lightning::Template->new(
			path	=> $conf->{path},
			file	=> $conf->{file},
			cache	=> $conf->{cache},
			cached	=> $conf->{cached},
		),
	}, $pkg;
	
	return $self;
}

# abstracts
sub assign	{ shift->{engine}->assign(@_); }
sub file	{ shift->{engine}->file(@_); }

# optional
sub cache	{ shift->{engine}->cache(@_); }
sub cached	{ shift->{engine}->cached(@_); }
sub path	{ shift->{engine}->path(@_); }


=head1 NAME

Lightning::View::Default - the basic implement of View.

=head1 VERSION

Version 0.10

=head1 SYNOPSIS

	this is the adaptor for Lightning::Template.
	
	you can use this as an ordinary View in Action,
	and also take it as a sample of View implement.
	
	See Lightning::Abstract::View for the introduction of View.
	
	this accepts the config values for Template Engine.
	give arguments to Lightning::run() like following.
	
	view	=> {
		path	=> $template_search_paths,
		file	=> $default_template,
		cache	=> $use_cache_or_not,
		cached	=> $cache_files_dir,
	}
	
	all of the configs are optional.
	you can also set those values through the methods
		path(), file(), cache(), cached().
	
	See FUNCTIONS for more details.

=head1 FUNCTIONS

=head2 C<init($c) : LT_MAKE_VIEW>

	the implementation of Plugin LT_MAKE_VIEW.
	
	it only does call new().

=head2 C<render($c) : LT_RENDER>

	the implementation of Plugin LT_RENDER.
	
	call Lightning::Template::render(), and print its returning.

=head2 new($c)

	the constructor.
	
	create Lightning::Template object with given configs.

=head2 C<assign($key =E<gt> $value[, $key2 =E<gt> $value2...])>

	the implementation of the abstract.
	
	set the template values.

=head2 file($file)

	the implementation of the abstract.
	
	set the template file.

=head2 path(\@paths)

	add the search path for template file.
	the later the path is added, the bigger priority it will be given.

=head2 cache($flag)

	set flag about use cache or not.

=head2 cached($dir)

	set the directory path to make cache files.

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
