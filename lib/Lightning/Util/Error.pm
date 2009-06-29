package Lightning::Util::Error;

use Lightning::Template;
use strict;

our $VERSION = '0.01';

sub display {
	shift if (defined $_[0] && $_[0] eq __PACKAGE__);
	
	my ($msg, $stack) = @_;
	
	# load target files
	my $n = 1;
	for my $s (@$stack) {
		open (my $fh, '<', $s->{file}) || exit;
		flock($fh, 1);
		
		my $i = 0;
		my @l = ();
		while (my $l = <$fh>) {
			$i++;
			
			next if $i < $s->{line} - 3;
			last if $i > $s->{line} + 3;
			
			push (@l, {
				line	=> $i,
				cont	=> $l,
			});
		}
		
		close ($fh);
		
		$s->{num} = $n;
		$s->{site} = \@l;
		
		$n++;
	}
	
	# create view
	my $t = Lightning::Template->new();
	
	$t->assign(
		msg		=> $msg,
		stack	=> $stack,
	);
	
	my $tmpl =<<'EOM';
<html>
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
	<title>Lightning - Web Application Framework</title>
</head>

<body bgcolor="#FFFFFF" text="#000000">

<b>Exception Occured !</b><br>
<br>
Exception : {$msg}<br>
<br>
<br>
Stack Trace<br>
{foreach from=$stack item=s}
	{$s.num}. {$s.pkg}, {$s.file}, line {$s.line}<br>
	<div style="background-color: #FFFFCC">
		{foreach from=$s.site item=site}
		{if $site.line == $s.line}
		<span style="background-color: #FFFF99">{$site.line} : {$site.cont}</span>
		{else}
		{$site.line} : {$site.cont}
		{/if}
		<br>
		{/foreach}
	</div>
	<br>
{/foreach}

</body>
</html>
EOM
	
	$t->file(\$tmpl);
	
	my $buf = '';
	$t->render(\$buf);
	
	# display
	select(STDOUT);
	
	print "Content-Type: text/html\n";
	print "Content-Length: " . length($buf) . "\n";
	print "\n";
	
	print $buf;
}


=head1 NAME

Lightning::Error - Default Error Handler for Lightning

=head1 VERSION

Version 0.10

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
