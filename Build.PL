use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new
    ( module_name     => 'AAC::Pvoice',
      license         => 'perl',
      requires        => {
                          Wx            => 0.15,
                          Win32::API    => 0.41
                         }
    )->create_build_script;
