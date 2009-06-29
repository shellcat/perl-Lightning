package Lightning::Plugin;

our $VERSION = '0.01';

=head1 NAME

Lightning::Plugin - the detailed document about Plugins

=head1 VERSION

Version 0.01

=head1 ABSTRACT

	Lightning uses Plug.pm in lib directory.
	first of all, see its document for usage of Plugin.
	
	the purposes of using Plugins are,
	  1. replacing core functions easily.
	  2. adding procedures flexibly.
	
	therefore, some plugs need more than 1 plugin methods, and others are not necessary.
	
	each plugin methods receives arguments defined by accepted plug.
	and, some of plugs have the rule about the returning from plugin methods.
	
	all of plugs defined at Lightning core is in PLUGS section.

=head1 PREPARED PLUGINS

	this section introduces the list of Plugins attached with Lightning itself.
	for details, see the document of each Plugin.

=head2 L<Lightning::Context|Lightning::Context>

	the default Context class.
	it is an implementation of Lightning::Abstract::Context.

=head2 L<Lightning::Dispatch::PathInfo|Lightning::Dispatch::PathInfo>

	the default Dispatcher class.
	it is an implementation of Lightning::Abstract::Dispatch.

=head2 L<Lightning::View::Default|Lightning::View::Default>

	the default View class.
	it is an implementation of Lightning::Abstract::View.
	
	this is the wrapper of Lightning::Template.

=head2 L<Lightning::Arms::Hooker|Lightning::Arms::Hooker>

	hook is the method runs before/after Action.
	this extention serves the attributes and functions for making hooks easily.

=head2 L<Lightning::Arms::Verify::Accessibility|Lightning::Arms::Verify::Accessibility>

	this provides the attributes which add accessibility as Action to methods.

=head2 L<Lightning::Arms::Context::Stash|Lightning::Arms::Context::Stash>

	add the function of temporary storage to Context object.

=head2 L<Lightning::Arms::Context::Cookie|Lightning::Arms::Context::Cookie>

	make using Cookie easily.

=head2 L<Lightning::Arms::Context::Session|Lightning::Arms::Context::Session>

	make using Session easily.

=head1 HOW TO USE PLUGINS

	Prepared Plugins get ready as soon as loaded.
	so you need only to use() the class after loading Lightning.
	for example,
	
	use Lightning;
	use Lightning::Arms::Hooker;
		
	it is quite important that how order the classes are loaded.
	because some part of Plugin are TYPE_EXCLUSIVE.
	only the method compiled last is used.
	
	Lightning loads the default Plugins by itself.
	so if you want to replace the procedures, you must load classes after Lightning.

=head1 HOW TO MAKE PLUGINS

	Plugins must be based on Plug::In.
	first, see Attribute::Dynamic and Plug::In for general usage of Plug::In.

	then see the list of Plug rules in PLUGS section
	and implement the method obey to the rules of arguments and returnings.

=head1 PLUGS

	Plugs have some properties.
	the following is the format to explain the detail of each Plug.

=head2 Format

	Purpose 	: the purpose of this plug.
	Type		: TYPE_EXCLUSIVE or TYPE_SEQUENTIAL
	Arguments	: the list of arguments given to plugin methods.
	Returning	: the rule of returning which the plugin methods must obey.
	Necessity	: if at least 1 plugin method required, 'Required'.
					otherwise, 'Optional'.
	
	
	there is the defined Plugs by Lightning core.
	

=head2 LT_MAKE_CONTEXT

	Purpose		: initialize Context Object (see Lightning::Abstract::Context about Context)
	Type		: TYPE_EXCLUSIVE
	Arguments	: all of the arguments (without classname string) which Lightning::run() receives.
	Returning	: an instance of Lightning::Abstract::Context or its subclass.
	Necessity	: Required.

=head2 LT_FILTER_INPUT

	Purpose		: filter input contents (GET and POST)
	Type		: TYPE_EXCLUSIVE
	Arguments	: returning of LT_MAKE_CONTEXT
	Returning	: filtered POST string, filtered GET string
	Necessity	: Optional.

=head2 LT_PARSE_INPUT

	Purpose		: parse input contents
	Type		: TYPE_EXCLUSIVE
	Arguments	: returning of LT_MAKE_CONTEXT, filtered POST string, filtered GET string
	Returning	: boolean value if succeed or not.
	Necessity	: Required.

=head2 LT_MAKE_DISPATCH

	Purpose		: initialize Dispatcher object
	Type		: TYPE_EXCLUSIVE
	Arguments	: returning of LT_MAKE_CONTEXT
	Returning	: an instance of Lightning::Abstract::Dispatch or its subclass.
	Necessity	: Required.

=head2 LT_MAKE_VIEW

	Purpose		: initialize View object
	Type		: TYPE_EXCLUSIVE
	Arguments	: returning of LT_MAKE_CONTEXT
	Returning	: an instance of Lightning::Abstract::View or its subclass.
	Necessity	: Required.

=head2 LT_BUNDLE

	Purpose		: make relation between Context, Dispatcher, View objects
	Type		: TYPE_EXCLUSIVE
	Arguments	: returning of LT_MAKE_CONTEXT, LT_MAKE_DISPATCH, LT_MAKE_VIEW
	Returning	: an instance of Lightning::Abstract::Context or its subclass.
	Necessity	: Required.

=head2 LT_INIT

	Purpose		: various initialization.
	Type		: TYPE_SEQUENTIAL
	Arguments	: returning of LT_BUNDLE
	Returning	: nothing required
	Necessity	: Optional.

=head2 LT_PREPARE_DISPATCH

	Purpose		: prepare for first Dispatch (for example, get string from path-info).
	Type		: TYPE_EXCLUSIVE
	Arguments	: returning of LT_BUNDLE
	Returning	: nothing required
	Necessity	: Required.

=head2 LT_DISPATCH

	Purpose		: Dispatching
	Type		: TYPE_EXCLUSIVE
	Arguments	: returning of LT_BUNDLE
	Returning	: if there is Dispatch source which has been yet used,
					an instance of Lightning::Action or its subclass.
					otherwise undef.
	Necessity	: Required.

=head2 LT_VERIFY_ACTION

	Purpose		: validate the result of Dispatching
	Type		: TYPE_SEQUENTIAL
	Arguments	: returning of LT_BUNDLE, returning of LT_DISPATCH, the number of executed Actions
	Returning	: if Action is valid, the instance of Lightning::Action or its subclass.
					otherwise undef.
	Necessity	: Optional.

=head2 LT_PRERUN

	Purpose		: hook before execute Action
	Type		: TYPE_SEQUENTIAL
	Arguments	: returning of LT_BUNDLE, returning of LT_VERIFY_ACTION, the number of executed Actions
	Returning	: nothing required
	Necessity	: Optional.

=head2 LT_POSTRUN

	Purpose		: hook after execute Action
	Type		: TYPE_SEQUENTIAL
	Arguments	: returning of LT_BUNDLE, returning of LT_VERIFY_ACTION, the number of executed Actions
	Returning	: nothing required
	Necessity	: Optional.

=head2 LT_NOT_FOUND

	Purpose		: decide response when no valid Action is found
	Type		: TYPE_SEQUENTIAL
	Arguments	: returning of LT_BUNDLE
	Returning	: nothing required
	Necessity	: Optional.

=head2 LT_RENDER

	Purpose		: render the response body
	Type		: TYPE_EXCLUSIVE
	Arguments	: returning of LT_BUNDLE
	Returning	: the response body
	Necessity	: Required.

=head2 LT_FILTER_OUTPUT

	Purpose		: filter outputs
	Type		: TYPE_SEQUENTIAL
	Arguments	: returning of LT_BUNDLE, returning of LT_VERIFY_RENDER
	Returning	: filtered contents
	Necessity	: Optional.

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
