# Docs
# TODO: Write documentation
class profile::oradb::asm_software(
  String $version,
  String $file_name,
)
{
  include profile
  include profile::oradb

  $configure_afd = lookup({name => 'profile::oradb::asm_diskgroup::configure_afd', default_value => false})

  if ( $configure_afd ) {
    # add udev rules for devices
    if ( $::profile::oradb::disk_devices ) {
      file { '/etc/udev/rules.d/99-oracle-afddevices.rules':
        ensure  => present,
        content => template("profile/99-oracle-afddevices.rules.erb"),
        require => User[$::profile::oradb::grid_user],
        notify  => Exec['apply_udev_rules'],
      }
      exec { 'apply_udev_rules':
        command     => '/sbin/udevadm control --reload-rules && /sbin/udevadm trigger',
        refreshonly => true,
      }
    }
  }

  $dirs = [
    '/u01',
    '/u01/app/grid',
    '/u01/app/grid/admin',
    '/u01/app/grid/product',
    "/u01/app/grid/product/${version}",
  ]

  file{ $dirs:
    ensure => directory,
    owner  => $profile::oradb::grid_user,
    group  => $profile::oradb::grid_group,
    mode   => '0755',
  }

  file{ '/u01/app':
    ensure => directory,
    owner  => $profile::oradb::grid_user,
    group  => $profile::oradb::grid_group,
    mode   => '0775',
  }

  -> ora_install::installasm{ $file_name:
    version                   => $version,
    file                      => $file_name,
    grid_base                 => $profile::oradb::grid_base,
    grid_home                 => $profile::oradb::grid_home,
    puppet_download_mnt_point => $profile::source_dir,
    sys_asm_password          => $profile::oradb::asm_sys_password,
    asm_monitor_password      => $profile::oradb::asm_sys_password,
    ora_inventory_dir         => $profile::oradb::ora_inventory_dir,
    asm_diskgroup             => 'DATA',
    disk_discovery_string     => case $configure_afd {
      true:  { '/dev/data*,/dev/reco*' }
      false: { '/nfs_client/asm*' }
    },
    disks                     => case $configure_afd {
      true:  { '/dev/data01' }
      false: { '/nfs_client/asm_sda_nfs_b1,/nfs_client/asm_sda_nfs_b2' }
    },
    disks_failgroup_names     => case $configure_afd {
      true:  { '/dev/data01,' }
      false: { '/nfs_client/asm_sda_nfs_b1,' }
    },
    disk_redundancy           => 'EXTERNAL',
    disk_au_size              => '4',
    configure_afd             => $configure_afd,
    user                      => $profile::oradb::grid_user,
  }

  -> ora_setting{ '+ASM':
    default     => false,
    user        => 'sys',
    syspriv     => 'sysasm',
    oracle_home => $profile::oradb::grid_home,
    os_user     => $profile::oradb::grid_user,
  }

  -> file_line{ 'add_asm_to_oratab':
    path   => '/etc/oratab',
    line   => "+ASM:${profile::oradb::grid_home}:N",
  }

}
