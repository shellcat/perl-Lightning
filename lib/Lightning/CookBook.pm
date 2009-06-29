package Lightning::CookBook;

our $VERSION = '0.01';

=head1 NAME

Lightning::CookBook - the start-up document of Lightning

=head1 VERSION

Version 0.01

=head1 NOTICE

	the contents of this document assumes using Lightning with default Plugins.
	if you use the optional Plugins, be sure to read their document too.

=head1 QUICK START

	the application by Lightning requires an executive file (cgi file) and Action classes.
	first of all, the content of cgi file is
	
	#!/usr/bin/perl
	
	use Lightning;
	
	Lightning->run();
	
	exit;
	
	that's all.
	and the root of Action classes (Root.pm, in include-path) is
	
	package Root;
	
	sub index { print 'Welcome to Lightning family !'; }
	sub foo { print 'foo !'; }
	
	1;
	
	then the base of the application is prepared !
	put the cgi file as %{DocumentRoot}/app/index.cgi and access by browser to

	http://yourhost/app/index.cgi
	
	you can see the message 'Welcome to Lightning family !'.
	and,

	http://yourhost/app/index.cgi/foo
	
	it shows the message 'foo !'.

=head1 URL RULES

	path-info determines which Action to use.
	for example,

	path-info		Action
	/				Root::index()
	/foo			Root::foo()
	/Foo/			Foo::index()
	/Foo/bar		Foo::bar()
	/Foo/Bar/		Foo::Bar::index()
	
	the above means that the string after the last slash (/) determines the method name
	and other part of the string defines the class name.
	
	the default class is Root, and the default method is index().
	if the class is found but method not, default() method will be used.

=head1 ACTION METHODS

	Action methods receives the following arguments.
		
	* an instance of Lightning::Abstract::Context or its subclass
	* an instance of Lightning::Action or its subclass
	* integer value how many Actions are done
	
	so the ordinary Action methods are like
	
	sub foo {
		my ($c, $act, $i) = @_;
		# do something
	}
	
	see Lightning::Context and Lightning::Action about $c and $act.

=head1 USE QUERY PARAMS

	the instance of Lightning::Context contains parsed input parameters.
	for example,
	
	print $c->req('bar');
	
	req($key) method returns the query param named $key.
	it does not mind GET and POST context.
	and if more than 2 values are given with the same key,
	req($key) returns ARRAYref which contains all of them.

=head1 USE VIEW

	$c contains a View object.
	it is wrapper of Template Engine.
	
	the usage is
		
	$c->view()->assign('msg', 'Welcome !');
	$c->view()->file('top.html');
		
	$c->view() returns the View object.
	and you can call assign(), file(), and other method on it.
	see Lightning::Abstract::View or Lightning::View::Default.

=head1 USE PLUGINS

	there are some Plugin modules to extend Lightning.
	for example, Lightning::Arms::Context::Cookie.
	
	in index.cgi,
	
	use Lightning;
	use Lightning::Arms::Context::Cookie;
		
	then, in Action class, you can use Cookie so easily.
		
	$c->cookie()->get('foo');
	
	almost Plugins initializes itself automatically.
	so what you should do is only use() them !
	
	see Lightning/Arms directory for all of prepared Plugins.

=head1 NEXT STEP

see L<Lightning::Plugin|Lightning::Plugin> for more understanding.

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
