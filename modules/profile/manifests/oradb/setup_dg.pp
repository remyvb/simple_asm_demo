# Docs
# TODO: Write documentation
class profile::oradb::setup_dg(
  Hash $dgconfig = {},
)
{
  include profile
  include profile::oradb

  $dbname = 'DB122'

  notice($dgconfig)

  $dirs = [
    "/u01/app/oracle/${dbname}",
    "/u01/app/oracle/${dbname}/adump",
  ]

  file{$dirs:
    ensure => directory,
    owner  => $profile::oradb::ora_user,
    group  => $profile::oradb::ora_group,
    mode   => '0750',
  }

  -> file{ "${profile::oradb::ora_home}/dbs/init_setup_dg.ora":
    ensure  => present,
    content => template("profile/init_setup_dg.ora.erb"),
    mode    => '0775',
    owner   => $profile::oradb::ora_user,
    group   => $profile::oradb::ora_group,
  }

  -> file{ '/install/duplicate.rman':
    ensure  => present,
    content => template("profile/duplicate.rman.erb"),
    mode    => '0775',
    owner   => $profile::oradb::ora_user,
    group   => $profile::oradb::ora_group,
  }

  -> file{ '/install/dgmgrl_config.dg':
    ensure  => present,
    content => template("profile/dgmgrl_config.dg.erb"),
    mode    => '0775',
    owner   => $profile::oradb::ora_user,
    group   => $profile::oradb::ora_group,
  }

  -> file_line{ "add_${dbname}_to_oratab":
    path => '/etc/oratab',
    line => "${dbname}:${profile::oradb::ora_home}:Y",
  }

  -> ora_setting{ $dbname:
    oracle_home    => $profile::oradb::ora_home,
    default        => true,
    user           => 'sys',
    os_user        => $profile::oradb::ora_user,
    syspriv        => 'sysdba',
    cdb            => false,
    connect_string => '',
    pluggable      => false,
    contained_by   => '',
  }

  -> exec{ 'get_password_file':
    command => "/bin/scp -q asm122.example.com:${profile::oradb::ora_home}/dbs/orapw${dbname} .",
    creates => "${profile::oradb::ora_home}/dbs/orapw${dbname}",
    cwd     => "${profile::oradb::ora_home}/dbs",
    user    => $profile::oradb::ora_user,
    group   => $profile::oradb::ora_group,
    notify  => Ora_exec['startup_nomount'],
  }

  -> ora_exec{ 'startup_nomount':
    statement   => "startup nomount pfile=${profile::oradb::ora_home}/dbs/init_setup_dg.ora",
    refreshonly => true,
    notify      => Exec['duplicate_db'],
  }

  -> exec{ 'duplicate_db':
    command     => 'rman cmdfile=duplicate.rman log=duplicate.log',
    cwd         => '/install',
    creates     => "${profile::oradb::ora_home}/dbs/spfile${dbname}.ora",
    user        => $profile::oradb::ora_user,
    group       => $profile::oradb::ora_group,
    path        => "/bin:/usr/local/bin:/usr/bin:/bin:${profile::oradb::ora_home}/bin",
    environment => ["ORACLE_HOME=${profile::oradb::ora_home}","ORACLE_SID=${dbname}"],
    refreshonly => true,
    logoutput   => true,
    timeout     => 600,
  }

  -> exec{ 'dataguard_broker_config':
    command     => 'dgmgrl @/install/dgmgrl_config.dg',
    cwd         => '/install',
    creates     => [
      "${profile::oradb::ora_home}/dbs/dr1${dbname}DG.dat",
      "${profile::oradb::ora_home}/dbs/dr2${dbname}DG.dat",
    ],
    user        => $profile::oradb::ora_user,
    group       => $profile::oradb::ora_group,
    path        => "/bin:/usr/local/bin:/usr/bin:/bin:${profile::oradb::ora_home}/bin",
    environment => ["ORACLE_HOME=${profile::oradb::ora_home}","ORACLE_SID=${dbname}"],
    logoutput   => true,
  }

}
