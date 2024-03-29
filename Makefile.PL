use 5.008003;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Acme::Tpyo',
    VERSION_FROM      => 'lib/Acme/Tpyo.pm', # finds $VERSION
    PREREQ_PM         => {POSIX => 0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Acme/Tpyo.pm', # retrieve abstract from module
       AUTHOR         => 'Ryan J. Voots <simcop@cpan.org>') : ()),
);
