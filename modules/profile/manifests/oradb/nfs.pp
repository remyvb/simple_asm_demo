class profile::oradb::nfs {

  $nfs_files = ['/home/nfs_server_data/asm_sda_nfs_b1',
                '/home/nfs_server_data/asm_sda_nfs_b2',
                '/home/nfs_server_data/asm_sda_nfs_b3',
                '/home/nfs_server_data/asm_sda_nfs_b4']

  file { '/home/nfs_server_data':
    ensure  => directory,
    recurse => false,
    replace => false,
    mode    => '0775',
    owner   => 'grid',
    group   => 'asmdba',
  } ->

  exec { '/bin/dd if=/dev/zero of=/home/nfs_server_data/asm_sda_nfs_b1 bs=1 count=0 seek=7520M':
    user      => 'grid',
    group     => 'asmdba',
    logoutput => true,
    unless    => '/usr/bin/test -f /home/nfs_server_data/asm_sda_nfs_b1',
  } ->

  exec { '/bin/dd if=/dev/zero of=/home/nfs_server_data/asm_sda_nfs_b2 bs=1 count=0 seek=7520M':
    user      => 'grid',
    group     => 'asmdba',
    logoutput => true,
    unless    => '/usr/bin/test -f /home/nfs_server_data/asm_sda_nfs_b2',
  } ->

  exec { '/bin/dd if=/dev/zero of=/home/nfs_server_data/asm_sda_nfs_b3 bs=1 count=0 seek=7520M':
    user      => 'grid',
    group     => 'asmdba',
    logoutput => true,
    unless    => '/usr/bin/test -f /home/nfs_server_data/asm_sda_nfs_b3',
  } ->

  exec { '/bin/dd if=/dev/zero of=/home/nfs_server_data/asm_sda_nfs_b4 bs=1 count=0 seek=7520M':
    user      => 'grid',
    group     => 'asmadmin',
    logoutput => true,
    unless    => '/usr/bin/test -f /home/nfs_server_data/asm_sda_nfs_b4',
  } ->

  file { $nfs_files:
    ensure  => present,
    owner   => 'grid',
    group   => 'asmdba',
    mode    => '0664',
  } ->

  class { '::nfs':
    server_enabled => true,
    client_enabled => true,
    nfs_v4         => false,
    nfs_v4_client  => false,
  } ->

  # Workaround for getting rpcbind.service enabled in systemd
  exec { 'systemctl add-wants multi-user.target rpcbind':
    command     => '/bin/systemctl add-wants multi-user.target rpcbind',
    unless      => '/bin/systemctl is-enabled rpcbind.service|egrep -q "enabled|indirect"',
  } ->

  nfs::server::export{ '/home/nfs_server_data':
    ensure      => 'mounted',
    options_nfs => 'rw sync no_wdelay insecure_locks no_root_squash',
    clients     => '192.168.253.0/24(rw,insecure,async,no_root_squash) localhost(rw)',
  } ->

  file { '/nfs_client':
    ensure  => directory,
    recurse => false,
    replace => false,
    mode    => '0775',
    owner   => 'grid',
    group   => 'asmdba',
  } ->

  nfs::client::mount { '/nfs_client':
    server        => 'localhost',
    share         => '/home/nfs_server_data',
    remounts      => true,
    atboot        => true,
    options_nfs   => '_netdev,rw,bg,hard,nointr,rsize=65536,wsize=65536,tcp,timeo=600,noatime',
  }

}
