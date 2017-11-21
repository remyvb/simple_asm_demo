# Docs
# TODO: Write documentation
class profile::oradb::setup_user_equivalence(
  Array  $nodes = [],
  String $private_key = '',
)
{
  include profile
  include profile::oradb

  profile::oradb::user_equivalence{ $profile::oradb::ora_user:
    nodes       => $nodes,
    private_key => $private_key,
  }

  -> ora_install::tnsnames{ 'DB122':
    oracle_home          => '/u01/app/oracle/product/12.2.0.1/db_home1',
    server               => {myserver1 => { host => 'asm122.example.com', port => 1521, protocol => 'TCP' }},
    connect_service_name => 'DB122.domain.local',
    entry_type           => 'tnsname',
  }

  -> ora_install::tnsnames{ 'DB122DG':
    oracle_home          => '/u01/app/oracle/product/12.2.0.1/db_home1',
    server               => {myserver1 => { host => 'asm123.example.com', port => 1521, protocol => 'TCP' }},
    connect_service_name => 'DB122',
    entry_type           => 'tnsname',
  }

}
