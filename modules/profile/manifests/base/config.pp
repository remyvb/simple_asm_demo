class profile::base::config()
{
  class { 'timezone':
    region   => 'Europe',
    locality => 'Amsterdam',
  }
}
