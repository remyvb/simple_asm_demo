# Docs
# TODO: Write documentation
define profile::oradb::generic::database(
  String $log_size,
  String $user_tablespace_size,
  String $system_tablespace_size,
  String $temporary_tablespace_size,
  String $undo_tablespace_size,
  String $sysaux_tablespace_size,
)
{
  require profile::oradb
  $oracle_base = $profile::oradb::ora_base
  $oracle_version = $profile::oradb::db_software::version

  #
  # All standard values fetched in data function
  #
  ora_database{$name:
    ensure                  => present,
    init_ora_content        => template("profile/init.ora.${oracle_version}.erb"),
    oracle_base             => $profile::oradb::ora_base,
    oracle_home             => $profile::oradb::ora_home,
    system_password         => $profile::oradb::ora_system_password,
    sys_password            => $profile::oradb::ora_sys_password,
    character_set           => 'AL32UTF8',
    national_character_set  => 'AL16UTF16',
    extent_management       => 'local',
    logfile_groups => [
        {group => 10, size => $log_size},
        {group => 10, size => $log_size},
        {group => 20, size => $log_size},
        {group => 20, size => $log_size},
      ],
    datafiles       => [
      {size => $system_tablespace_size, autoextend => {next => '10M', maxsize => 'unlimited'}},
    ],
    sysaux_datafiles => [
      {size => $sysaux_tablespace_size, autoextend => {next => '10M', maxsize => 'unlimited'}},
    ],
    default_temporary_tablespace => {
      name      => 'TEMP',
      tempfile  => {
        size       => $temporary_tablespace_size,
        autoextend => {
          next    => '5M',
          maxsize => 'unlimited',
        }
      },
    },
    undo_tablespace   => {
      name      => 'UNDOTBS1',
      datafile  => {
        size       => $undo_tablespace_size,
        autoextend => {next => '5M', maxsize => 'unlimited'}      }
    },
    default_tablespace => {
      name      => 'USERS',
      datafile  => {
        size       => $user_tablespace_size,
        autoextend => {next => '1M', maxsize => 'unlimited'}
      },
      extent_management => {
        'type'        => 'local',
        autoallocate  => true,
      }
    },
    timezone       => '+01:00',
  } ->

  ora_install::dbactions{ "start_${name}":
    oracle_home => $profile::oradb::ora_home,
    db_name     => $name,
  }

  ora_install::autostartdatabase{ "autostart ${name}":
    oracle_home => $profile::oradb::ora_home,
    db_name     => $name,
  }

}
