# Docs
# TODO: Write documentation
class profile::oradb::asm_diskgroup(
)
{
  include profile
  include profile::oradb

  ora_asm_diskgroup { 'DATA@+ASM':
    ensure          => 'present',
    au_size         => '1',
    redundancy_type => 'EXTERN',
    compat_asm      => '12.2.0.1.0',
    compat_rdbms    => '12.2.0.0.0',
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
    compat_asm      => '12.2.0.0.0',
    compat_rdbms    => '12.2.0.0.0',
    disks           => [
      {'diskname' => 'RECO_0000',
       'path'     => '/nfs_client/asm_sda_nfs_b3'},
      {'diskname' => 'RECO_0001',
       'path'     => '/nfs_client/asm_sda_nfs_b4'},
    ]
  }

}
