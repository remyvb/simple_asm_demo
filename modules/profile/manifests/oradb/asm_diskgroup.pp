# Docs
# TODO: Write documentation
class profile::oradb::asm_diskgroup(
)
{
  include profile
  include profile::oradb
  $asm_version = $profile::oradb::asm_software::version

  ora_asm_diskgroup { 'DATA@+ASM':
    ensure          => 'present',
    au_size         => '1',
    redundancy_type => 'EXTERN',
    compat_asm      => $asm_version,
    compat_rdbms    => $asm_version,
    diskgroup_state => 'MOUNTED',
    disks           => [
      {'diskname' => 'DATA_0000',
       'path'     => '/nfs_client/asm_sda_nfs_b1'},
      {'diskname' => 'DATA_0001',
       'path'     => '/nfs_client/asm_sda_nfs_b2'}
    ],
  }

  ora_asm_diskgroup {'RECO@+ASM':
    ensure          => 'present',
    au_size         => '1',
    redundancy_type => 'EXTERNAL',
    compat_asm      => $asm_version,
    compat_rdbms    => $asm_version,
    disks           => [
      {'diskname' => 'RECO_0000',
       'path'     => '/nfs_client/asm_sda_nfs_b3'},
      {'diskname' => 'RECO_0001',
       'path'     => '/nfs_client/asm_sda_nfs_b4'},
    ]
  }

}
