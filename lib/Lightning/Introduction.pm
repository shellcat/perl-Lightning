package Lightning::Introduction;

our $VERSION = '0.01';

=head1 NAME

Lightning::Introduction - the overview of Lightning

=head1 VERSION

Version 0.01

=head1 WHAT IS FRAMEWORK ?

	Framework is a kind of module family which serves the basic functions for applications.
	It keeps you away from bored coding (like parsing input, switching main routine, and so on).

	Using Framework, what you should do is only to make peculiarity part of the application.
	So it makes the development more efficient.

=head1 GLOSSARY

The followings are the featured words of Framework and Lightning.

=head2 Controller

	the role name of class.
	Controller class is in charge of parsing user input, determine main routine, and execute it.
	
	generally, Controller delegate the determination of main routine to the class called Dispatcher.

=head2 Dispatcher

	the role name of class.
	Dispatch is the process which determine what to do from input (like query parameter, or path info).

=head2 Action

	the alias of main routine.
	using Framework, developper needs only to make Action classes.
	
	generally, the names of class and method have some relation with Dispatch.

=head2 View

	the role name of class.
	View class takes charge of rendering outputs.

=head2 Plugin

	the mechanism which enables to extend the code from outside of the class.
	see Plug.pm for more about Plugins.

=head1 FEATURE

	Lightning is based on the unusual architecture.
	
	the core class Lightning does nothing but define the entire sequence of process.
	and it delegates the actual behavior on each steps to Plugins.
	(about Plugins, see Lightning::Plugin)
	
	for example, replacing the Plugin named 'LT_NOT_FOUND' enables to change the response when no Action is found by Dispatch.
	return 404, or redirect to another URL, or so on.
	
	
	there are ready-made Plugins in Lightning family.
	you can use them. and of course you can make new Plugins.
	
	Plugins have some rules about arguments and returning.
	see Lightning::Plugin for details.

=head1 NEXT STEP

see L<Lightning::CookBook|Lightning::CookBook> and try to use Lightning !

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
