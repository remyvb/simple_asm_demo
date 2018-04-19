# Docs
# TODO: Write documentation
class profile::oradb::db_software(
  String $version,
  String $file_name,
  String $type,
)
{
  include profile
  include profile::oradb


  $dirs = [
    '/u01/app/oracle',
    '/u01/app/oracle/product',
  ]

  file{$dirs:
    ensure => directory,
    owner  => $profile::oradb::ora_user,
    group  => $profile::oradb::ora_group,
    mode   => '0744',
  } ->

  ora_install::installdb{$file_name:
    version                   => $version,
    file                      => $file_name,
    database_type             => $type,
    oracle_base               => $profile::oradb::ora_base,
    oracle_home               => $profile::oradb::ora_home,
    puppet_download_mnt_point => $profile::source_dir,
    ora_inventory_dir         => $profile::oradb::ora_inventory_dir,
  } ->

  file {"${::profile::oradb::ora_base}/admin":
    ensure => 'directory',
    owner  => $profile::oradb::ora_user,
    group  => $profile::oradb::ora_group,
    mode   => '0775',
  }

}
