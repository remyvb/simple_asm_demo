class profile::base::packages()
{
  $required_package = [
    'smartmontools',
  ]

  $required_package.each | $package | {
    unless ( defined(Package[$package]) ) {
      Package { $package:
        ensure => 'installed',
      }
    }
  }
}
