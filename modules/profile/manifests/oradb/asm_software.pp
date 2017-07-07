# Docs
# TODO: Write documentation
class profile::oradb::asm_software(
  $version,
  $file_name,
)
{
  include profile
  include profile::oradb


  $dirs = [
    '/u01',
    '/u01/app/grid',
    '/u01/app/grid/admin',
    '/u01/app/grid/product',
    "/u01/app/grid/product/${version}",
  ]

  file{$dirs:
    ensure => directory,
    owner  => $profile::oradb::grid_user,
    group  => $profile::oradb::grid_group,
    mode   => '0755',
  }

  file{'/u01/app':
    ensure => directory,
    owner  => $profile::oradb::grid_user,
    group  => $profile::oradb::grid_group,
    mode   => '0775',
  } ->

  ora_install::installasm{$file_name:
    version                   => $version,
    file                      => $file_name,
    grid_base                 => $profile::oradb::grid_base,
    grid_home                 => $profile::oradb::grid_home,
    puppet_download_mnt_point => $profile::source_dir,
    remote_file               => true,
    sys_asm_password          => $profile::oradb::asm_sys_password,
    asm_monitor_password      => $profile::oradb::asm_sys_password,
    ora_inventory_dir         => $profile::oradb::ora_inventory_dir,
    asm_diskgroup             => 'DATA',
    disk_discovery_string     => '/nfs_client/asm*',
    disks                     => '/nfs_client/asm_sda_nfs_b1,/nfs_client/asm_sda_nfs_b2',
    disk_redundancy           => 'EXTERNAL',
    user                      => $profile::oradb::grid_user,
  } ->

  ora_setting{'+ASM':
    default     => true,
    user        => 'sys',
    syspriv     => 'sysasm',
    oracle_home => $profile::oradb::grid_home,
    os_user     => $profile::oradb::grid_user,
  } ->

  file_line{'add_asm_to_oratab':
    path   => '/etc/oratab',
    line   => "+ASM:${profile::oradb::grid_home}:N",
  }

}
