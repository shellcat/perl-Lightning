use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Lightning',
    AUTHOR              => 'shellcat <shell@ateliershell.jp>',
    VERSION_FROM        => 'lib/Lightning.pm',
    ABSTRACT_FROM       => 'lib/Lightning.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Lightning-*' },
);
