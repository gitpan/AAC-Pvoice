use ExtUtils::MakeMaker;

my $pdrv;

if ($^O eq 'MSWin32')
{
    $pdrv = Device::ParallelPort::drv::win32;
}
else
{
    $pdrv = Device::ParallelPort::drv::parport;
}

WriteMakefile(
    NAME         => 'AAC::Pvoice',
    VERSION_FROM => 'lib/AAC/Pvoice.pm', # finds $VERSION
    AUTHOR       => 'Jouke Visser <jouke@cpan.org>',
    ABSTRACT_FROM=> 'lib/AAC/Pvoice.pm',
    PREREQ_PM    => {   Wx                      => 0.15,
                        Device::ParallelPort    => 0,
                        $pdrv                   => 0,
                        }
);
