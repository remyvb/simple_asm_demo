# Docs
# TODO: Write documentation
class profile::oradb::asm_diskgroup(
  Boolean $configure_afd = false,
  Hash    $disks         = {},
)
{
  include profile
  include profile::oradb
  $asm_version = $profile::oradb::asm_software::version

  if ( $configure_afd ) {
    $::profile::oradb::disk_devices.each |$device, $values| {
      exec { "add afd label ${values['afd_label']} to device /dev/${device}":
        command     => "${::profile::oradb::grid_home}/bin/asmcmd afd_label ${values['afd_label']} /dev/${device}",
        environment => ["ORACLE_HOME=${::profile::oradb::grid_home}"],
        user        => $profile::oradb::grid_user,
        path        => "/usr/local/sbin:/sbin:/bin:/usr/sbin:/usr/bin:${::profile::oradb::grid_home}/bin",
        unless      => "${::profile::oradb::grid_home}/bin/asmcmd afd_lslbl /dev/${device} | grep '^${values['afd_label']} .* /dev/${device}$'",
        before      => [
          Ora_asm_diskgroup['DATA@+ASM'],
          Ora_asm_diskgroup['RECO@+ASM']
        ]
      }
    }
  }

  $disks.each |$diskgroup, $devices| {
    ora_asm_diskgroup { "${diskgroup}@+ASM":
      ensure            => 'present',
      au_size           => '4',
      redundancy_type   => 'EXTERN',
      compat_asm        => $asm_version,
      compat_rdbms      => $asm_version,
      diskgroup_state   => 'MOUNTED',
      allow_disk_update => true,
      disks             => $devices,
    }
  }

}
