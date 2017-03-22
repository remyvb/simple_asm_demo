# Docs
# TODO: Write documentation
class profile::oradb::db_software(
  $version,
  $file_name,
  $type,
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
    remote_file               => true,
  } ->

  file {"${::profile::oradb::ora_base}/admin":
    ensure => 'directory',
    owner  => $profile::oradb::ora_user,
    group  => $profile::oradb::ora_group,
    mode   => '0775',
  }


}
