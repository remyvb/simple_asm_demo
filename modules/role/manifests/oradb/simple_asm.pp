# Docs
class role::oradb::simple_asm()
{
  contain profile::base
  contain profile::oradb::os
  contain profile::oradb::nfs
  contain profile::oradb::asm_software
  contain profile::oradb::asm_diskgroup
  contain profile::oradb::db_software
  contain profile::oradb::database::db01

  Class['profile::base::hosts']
  -> Class['profile::oradb::os']
  -> Class['profile::oradb::nfs']
  -> Class['profile::oradb::asm_software']
  -> Class['profile::oradb::asm_diskgroup']
  -> Class['profile::oradb::db_software']
  -> Class['profile::oradb::database::db01']
}
