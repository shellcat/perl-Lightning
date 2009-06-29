package Lightning::Template;

use IO::Handle;

use Carp;
use strict;
use warnings;

our $VERSION = '0.10';

# constructor
sub new {
	my ($pkg, %args) = @_;
	
	my ($file, $path, $cache, $cached) = @args{qw(file path cache cached)};
	
	# check
	$path ||= ['.'];
	$path = [$path] unless ref $path eq 'ARRAY';
	
	# make
	my $self = bless {
		file	=> $file,
		path	=> $path,
		cache	=> $cache,
		cached	=> $cached || '.',
		params	=> {},
	}, $pkg;
	
	return $self;
}

# accessor
sub file {
	my ($self, $file) = @_;
	
	$self->{file} = $file if defined $file;
	
	return $self->{file};
}

sub path {
	my ($self, $path) = @_;
	
	if (defined $path) {
		$path = [$path] unless ref $path eq 'ARRAY';
		unshift(@{$self->{path}}, @$path);
	}
	
	return $self->{path};
}

sub cache {
	my ($self, $cache) = @_;
	
	$self->{cache} = $cache if defined $cache;
	
	return $self->{cache};
}

sub cached {
	my ($self, $cached) = @_;
	
	$self->{cached} = $cached if defined $cached;
	
	return $self->{cached};
}

sub assign {
	my ($self, %params) = @_;
	
	%{$self->{params}} = (%{$self->{params}}, %params);
}

sub render {
	my ($self, $buf) = @_;
	
	return unless ref $buf eq 'SCALAR';
	return 1 unless $self->{file};
	
	# get compiled code
	my $code;
	
	unless ($self->read_cache(\$code) || $self->convert(\$code)) {
		$$buf = qq{Failed to find template or cache file !};
		return;
	}
	
	# make cache
	$self->write_cache(\$code);
	
	# ok execute
	{
		no warnings;
		
		local $@;
		$$buf = eval $code;
		
		if (length($@)) {
			$$buf = $@ . $code;
			return;
		}
	}
	
	return 1;
}


# private method
sub search_path {
	my ($self) = @_;
	
	return if ref $self->{file} eq 'SCALAR';
	
	my $file = $self->{file};
	for my $dir (@{$self->{path}}) {
		return $dir if -f $dir . '/' . $file;
	}
	
	return;
}

sub read_cache {
	my ($self, $buf) = @_;
	
	return unless ref $buf eq 'SCALAR';
	
	# check flag of cache
	return unless $self->{cache};
	
	# SCALARref template cannot use cache.
	return if ref $self->{file} eq 'SCALAR';
	
	# false if the template doesn't exist
	my $path = $self->search_path() || return;
	
	# check modified time
	my ($mtime) = (stat($path . '/' . $self->{file}))[9];
	my $cache = $self->{cached} . '/' . $self->{file} . $mtime;
	
	return unless -f $cache;
	
	# ok, found
	my ($size) = (stat($cache))[7];
	
	open (my $fh, '<', $cache) || return;
	flock($fh, 1);
	
	read($fh, $$buf, $size);
	
	close($fh);
	
	return 1;
}

sub write_cache {
	my ($self, $code) = @_;
	
	return unless ($self->{cache} && ref $self->{file} ne 'SCALAR' && ref $code eq 'SCALAR');
	
	# check cached is writable
	return unless -w $self->{cached};
	
	# get mtime
	my $path = $self->search_path();
	my ($mtime) = (stat($path . '/' . $self->{file}))[9];
	
	# dig directories
	my $dir = $self->{cached};
	$dir .= '/' unless $dir =~ m|/$|;
	
	my @dirs = split(m|/|, $self->{file});
	my $file = pop @dirs;
	
	while (my $d = shift @dirs) {
		$dir .= $d . '/';
		
		mkdir $dir unless -d $dir;
	}
	
	my $cache = $dir . $file . $mtime;
	
	# check
	return 1 if -f $cache;
	
	# make file
	open(my $fh, '>', $cache) || return;
	flock($fh, 2);
	
	print $fh $$code;
	
	close($fh);
	
	# ok !
	return 1;
}

sub read_template {
	my ($self, $buf) = @_;
	
	return unless ref $buf eq 'SCALAR';
	
	# only copy if template is SCALARref
	if (ref $self->{file} eq 'SCALAR') {
		$$buf = ${$self->{file}};
		return 1;
	}
	
	# else, read from file
	my $path = $self->search_path();
	my ($size) = (stat($path . '/' . $self->{file}))[7];
	
	open (my $fh, '<', $path . '/' . $self->{file}) || return;
	flock($fh, 1);
	
	read($fh, $$buf, $size);
	
	close($fh);
	
	return 1;
}

sub convert {
	my ($self, $buf) = @_;
	
	return unless ref $buf eq 'SCALAR';
	
	# get template
	my $template;
	
	$self->read_template(\$template) || return;
	
	# prepare for parse
	my ($l, $r);
	
	$self->{closer} = [];
	
	# remove comment
	$template =~ s|{\*.*?\*}||sg;
	
	# start buffering
	my $fh = IO::Handle->new();
	open($fh, '>', $buf) || return;
	my $stdout = select($fh);
	
	# parse loop
	$self->print_code({}, 'start');
	
	while (1) {
		my $tag = $self->next_tag(\$template) || last;
		
		# output static part
		$self->print_code($tag, 'static');
		
		# no more tag ? finish !
		last unless $tag->{type};
		
		# each tags
		$self->print_code($tag);
	}
	
	$self->print_code({}, 'finish');
	
	# end buffering
	select($stdout);
	close($fh);
	
	# return
	return 1;
}

sub next_tag {
	my ($self, $template) = @_;
	
	return unless ref $template eq 'SCALAR';
	
	my %tag = (
		type	=> '',
		static	=> '',
		prop	=> '',
	);
	
	# search
	my ($tag) = $$template =~ m|(\{[^{]*?\})|;
	
	# cut static part
	my $static = ($tag) ? substr($$template, 0, index($$template, $tag))
						: $$template;
	my $space = (defined $tag) ? length($tag) : 0;
	
	substr($$template, 0, length($static) + $space) = '';
	
	$tag{static} = escape($static);
	
	# no tag ? return !
	return \%tag unless $tag;
	
	# parse tag type
	$tag =~ s|\{\s*(.*)\s*\}|$1|;
	
	my ($symbol) = $tag =~ m|^(\S+)|;
	
	$tag{type} = ($self->can('print_'.lc($symbol).'_code')) ? lc($symbol) :
				# (lc($symbol) eq 'if') ? "if" :
				# (lc($symbol) eq 'else') ? "else" :
				# (lc($symbol) eq 'elseif') ? "elseif" :
				# (lc($symbol) eq 'unless') ? "unless" :
				# (lc($symbol) eq 'foreach') ? "foreach" :
				# (lc($symbol) eq 'hidden') ? "hidden" :
				 (lc($symbol) =~ /^\/[if|unless|foreach]/) ? "end" : "var";
	
	my $prop = ($tag{type} eq 'var') ? $symbol : substr($tag, length($symbol));
	$prop =~ s|^\s*(.*)\s*$|$1|;
	
	$tag{prop} = $prop;
	
	# ok
	return \%tag;
}

sub escape {
	my ($str) = @_;
	
	$str =~ s|\\|\\\\|g;
	$str =~ s|"|\\"|g;
	$str =~ s|\$|\\\$|g;
	$str =~ s|\@|\\\@|g;
	$str =~ s|\%|\\\%|g;
	$str =~ s|\r||g;
	$str =~ s|\n|\\n|g;
	
	return $str;
}

sub extract {
	my ($str) = @_;
	
	return $str unless $str =~ m|\$|;
	
	$str =~ s|\.\((.+)?\)|{$1}|g;
	$str =~ s|(\$[\w_\.\->]+)|to_code($1)|ego;
	
	return $str;
}

sub to_code {
	my ($str) = @_;
	
	$str =~ s|\->|}->|g;
	$str =~ s|^\$|\$param_of->{|;
	$str =~ s|\.$|}->|;
	$str =~ s|\.|}->{|g;
	
	my @l = $str =~ m|{|g;
	my @r = $str =~ m|}|g;
	
	$str .= '}' if (scalar(@l) != scalar(@r));
	
	return $str;
}

sub print_code {
	my ($self, $tag, $type) = @_;
	
	return unless ref $tag eq 'HASH';
	
	$type ||= $tag->{type};
	
	return unless $type;
	
	if ($type eq 'start')		{ print qq|my \$o = '';\nmy \$param_of = \$self->{params};\n|; }
	elsif ($type eq 'finish')	{ print qq|return \$o;\n|; }
	elsif ($type eq 'static')	{ print qq|\$o .= "| . $tag->{static} . qq|";\n|; }
	else {
		my $method = sprintf("print_%s_code", $type);
		my $code = $self->can($method) || return;
		
		$code->($self, $tag);
	}
	
	return 1;
}

sub print_var_code {
	my ($self, $tag) = @_;
	
	print qq|\$o .= | . extract($tag->{prop}) . qq|;\n|;
}

sub print_hidden_code {
	my ($self, $tag) = @_;
	
	print extract($tag->{prop}) . qq|;\n|;
}

sub print_if_code {
	my ($self, $tag) = @_;
	
	my @op;
	
	for my $op (split(/\s+/, $tag->{prop})) {
		if ($op =~ /^[eq|ne|==|!=|>|<|>=|<=|\|\||&&|and|or]$/) { # logical operand
			push (@op, $op);
			next;
		}
		
		my ($pre, $post, $deny) = ('') x 3;
		if ($op =~ s|^(\(+)||) { $pre = $1; }
		if ($op =~ s|(\)+)||) { $post = $1; }
		if ($op =~ s|^!||) { $deny = '!'; }
		
		push (@op, sprintf("%s%s%s%s", $pre, $deny, extract($op), $post));
	}
	
	print qq|if (| . join(' ', @op) . qq|) {\n|;
	
	push (@{$self->{closer}}, '');
}

sub print_unless_code {
	my ($self, $tag) = @_;
	
	my @op;
	
	for my $op (split(/\s+/, $tag->{prop})) {
		if ($op =~ /^[eq|ne|==|!=|>|<|>=|<=|\|\||&&|and|or]$/) { # logical operand
			push (@op, $op);
			next;
		}
		
		my ($pre, $post, $deny) = ('') x 3;
		if ($op =~ s|^(\(+)||) { $pre = $1; }
		if ($op =~ s|(\)+)||) { $post = $1; }
		if ($op =~ s|^!||) { $deny = '!'; }
		
		push (@op, sprintf("%s%s%s%s", $pre, $deny, extract($op), $post));
	}
	
	print qq|unless (| . join(' ', @op) . qq|) {\n|;
	
	push (@{$self->{closer}}, '');
}

sub print_elseif_code {
	my ($self, $tag) = @_;
	
	my @op;
	
	for my $op (split(/\s+/, $tag->{prop})) {
		if ($op =~ /^[eq|ne|==|!=|>|<|>=|<=|\|\||&&|and|or]$/) { # logical operand
			push (@op, $op);
			next;
		}
		
		my ($pre, $post, $deny) = ('') x 3;
		if ($op =~ s|^(\(+)||) { $pre = $1; }
		if ($op =~ s|(\)+)||) { $post = $1; }
		if ($op =~ s|^!||) { $deny = '!'; }
		
		push (@op, sprintf("%s%s%s%s", $pre, $deny, extract($op), $post));
	}
	
	print qq|} elsif (| . join(' ', @op) . qq|) {\n|;
}

sub print_else_code {
	my ($self, $tag) = @_;
	
	print qq|} else {\n|;
}

sub print_foreach_code {
	my ($self, $tag) = @_;
	
	my %state;
	for (split(/\s+/, $tag->{prop})) {
		my ($key, $val) = split(/=/);
		
		$state{$key} = extract($val);
	}
	
	print qq|my \$tar = $state{from};\n|;
	print qq|my \%tmp = \%\$param_of;\n|;
	
	my $closer;
	if (exists $state{key} && exists $state{item}) {
		# each for HASH
		print qq|while (my (\$k, \$v) = each \%\$tar) {\n|
				. qq|my \$param_of = \\\%tmp;\n|
				. qq|\@{\$param_of}{qw(| . $state{key} . qq| | . $state{item} . qq|)} = (\$k, \$v);\n|;
		
		$closer = qq|\$tmp{| . $state{key} . qq|} = \$param_of->{| . $state{key} . qq|};\n|
					.qq|\$tmp{| . $state{item} . qq|} = \$param_of->{| . $state{item} . qq|};\n|
					.qq|\%\$param_of = \%tmp;\n|;
		
	} elsif (exists $state{key}) {
		# keys for HASH
		print qq|foreach (sort keys \%\$tar) {\n|
				. qq|my \$param_of = \\\%tmp;\n|
				. qq|\$param_of->{| . $state{key} . qq|} = \$_;\n|;
				
		$closer = qq|\$tmp{| . $state{key} . qq|} = \$param_of->{| . $state{key} . qq|};\n|
				. qq|\%\$param_of = \%tmp;\n|;
		
	} elsif (exists $state{item}) {
		# ARRAY
		print qq|foreach my \$tmp (\@\$tar) {\n|
			. qq|my \$param_of = \\\%tmp;\n|
			. qq|\$param_of->{| . $state{item} . qq|} = \$tmp;\n|;
			
		$closer = qq|\$tmp{| . $state{item} . qq|} = \$param_of->{| . $state{item} . qq|};\n|
				. qq|\%\$param_of = \%tmp;\n|;
	}
	
	push (@{$self->{closer}}, $closer) if $closer;
}
		
sub print_end_code {
	my ($self, $tag) = @_;
	
	print qq|}\n|;
	print pop @{$self->{closer}};
}








=head1 NAME

Lightning::Template - Basic Template Engine of Lightning

=head1 VERSION

Version 0.10

=head1 SYNOPSIS

	This is the Template Engine with simple interface and template syntax.
	
	The most simple usage is the following.
	
	[in code]	
	my $t = Lightning::Template->new(file => $template_file);
	
	$t->assign('foo', 'fizz buzz');
	
	print $t->render();
	
	[in template]
	foo value is {$foo}.
	
	[the result]
	foo value is fizz buzz.
	
	See TEMPLATES for the syntax and functions of template.
	See FUNCTIONS for the methods of the object.

=head1 TEMPLATES

There are some kinds of functions for template.

=head2 VARIABLES

	template can use the assigned values.
	
	the way to assign is use assign() method in Perl code.
		
		$t->assign('foo', 1);
		
	then, the variable $foo can be used in template file.
	
		{$foo}
		
	it will be replaced to its value 1.
	
	be careful that the syntax of variable is case sensitive.
	so the followings are different.
		
		{$foo}
		{$Foo}

=head2 KEYWORDS

	there are some keywords for template.
	the keywords enables you to make loop, condition branches, and so on.
	
	most of the keywords is similar to Perl keyword.
	but template keyword is case insensitive.

=head2 SCALAR

	you can show the scalar value as {$foo}.
	then it is replaced to the value which assigned as $t->assign('foo', $some_value).

=head2 ARRAY

	ARRAY value is available.
	
	if you assign $t->assign('bar', [qw(1 2 3)]),
	in template, they are random accessable like
		
		{$bar[0]}, {$bar[1]}, {$bar[2]}
		
	they will be replaced to each value.
	
	be sure that ARRAY value must be assigned as an ARRAYref.

=head2 HASH

	HASH value is also available.
	
	if you assign $t->assign('fizz', { a => 1, b => 2 }),
	in template, you can access with certain key.
		
		{$fizz.a}, {$fizz.b}
	
	don't forget to connect assigned name and its key with a dot (.).
	it is not {$fizz->{a}} !
	
	and HASH value must be assigned as a HASHref too.

=head2 OBJECT

	all of object can be assigned.
	the way to assign is the same as SCALAR value.
	
	and in template, object method can be called like,
		
		{$obj->some_method()}
		
	then the returning of the method will be displayed.
	
	you can give arguments to the method.
		
		{$obj->another_method(5)}
		{$obj->other_method($foo)}
		
	so, even template variables can be passed to the methods !

=head2 CALCULATION

	the basic calculations are supported.
	
		{$foo + 1}
		{$bar - 1}
		{$fizz * 2}
		{$buzz / 2}
		{$joe % 2}
	
	the above displays the result of calc.
	
	the calculations in {if}, {unless}, {elseif} (in the following) are
		also available.

=head2 IF, UNLESS, ELSEIF, ELSE

	they are the KEYWORD for template.
	
	they are the condition branching tag as same as Perl CORE.
	
		{if $foo > 0}a{else}b{/if}
		{unless $bar}blank !{elseif $bar < 5}fewer !{/unless}
		
	usage is like above.
	
	the syntax is the same as that of Perl.
	but be careful that elsif is {elseif} in template.
	and end bracket tag ({/if}, {/unless}) is required.

=head2 FOREACH

	this is the KEYWORD for template.
	
	the iteration of ARRAY or HASH is made by {foreach} tag.
	the usage is,
	
	* for ARRAY (assigned as $array)
		{foreach from=$array item=a}
			{$a}
		{/foreach}
		
	* for HASH (assigned as $hash)
		{foreach from=$hash key=k item=i}
			{$k} : {$i}
		{/foreach}
		
		this is the emulation of 'each' loop of Perl.
		
	what different between ARRAY and HASH is the KEYWORD 'key'.
	if it doesn't exist, the 'from' value is cared as ARRAY.
	otherwise, it is as HASH.
	
	in other words,
	be sure to put 'key' for HASH,
	and be sure NOT to put 'key' for ARRAY.
	
	
	{foreach} tag needs to be closed by {/foreach} tag.

=head2 HIDDEN, ASSIGNMENT

	this is the KEYWORD for template.
	
	this is not for display, but for calculate or assign something.
	for example,
	
		{hidden $a = $b}
		{hidden $c += 2}
		{hidden $d = $obj->some_method()}
		
	these tags executes the code, but don't display anything.
	if these code are in the ordinary SCALAR tag,
	
		{$a = $b} # shows the value of $b
		{$c += 2} # shows the result of calculation
		{$d = $obj->some_method()} # shows the returning of the method
		
	as the comment, they shows the result of execution.

=head1 FUNCTIONS

=head2 new(%args)

	the constructor of this class.
	the available options are the following.
	
	* $args{file}
		path to template file.
		default is undef.
		
		the file should exist in the 'search path'.
		see $args{path} about 'search path'.
		
		and this can be SCALARref also.
		if it is so, the value of reference will be used as template.
		
		this param can be set by file() method.
		
	* $args{path}
		the list of 'search path'.
		it is the list of directory name which the engine searches template.
		
		default is only current directory.
		
		the priority of searching is LIFO.
		it means the later the path added, the faster it is searched.
		
		this argument should be a SCALAR or ARRAYref of paths.
		
		search path can be added by path() method too.
		
	* $args{cache}
		the flag of using cache.
		if this is true, use cache. otherwise, not.
		default is false.
		
		if using cache, template is compiled only once until it is modified.
		so if you want to re-compile, remove the cache file or touch the template file.
		
		this flag can be set by cache() method.
		
	* $args{cached}
		the directory path for storing cache files.
		default is current directory.
		
		you can change it by cached() method.

=head2 file([$file])

	set template file to $file.
	and return the current template.

=head2 path([$path])

	add search path.
	then return ARRAYref of the list of search path.
	
	$path has to be SCALAR or ARRAYref.
	if ARRAYref is given, add the path obey to the order of ARRAY.
	for example,
		before order : .
			$t->path(['../', './template']);
		after order : ../ ./template .
	
	the returning is sorted for the reverse priority.

=head2 cache([$flag])

	set cache flag to $flag.
	then return the current flag.

=head2 cached([$dir])

	set cache directory to $dir.
	then return the current directory.

=head2 C<assign($key1 =E<gt> $value1[, $key2 =E<gt> $value2...])>

	give params to template.
	the key is the variable name which can be used in template.
	
	if the same key is already assigned, it will be overwritten.

=head2 render(\$buf)

	compile template, and execute it.
	then, set the result to $buf and return true.
	
	if some error occurs, set the error message to $buf and return false.

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
