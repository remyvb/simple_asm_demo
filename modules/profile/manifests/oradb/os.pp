# Docs
# TODO: Write documentation
class profile::oradb::os
{
  contain profile
  contain profile::oradb

  case ($::os['release']['major']) {
    '4','5','6': { $firewall_service = 'iptables'}
    '7': { $firewall_service = 'firewalld' }
    default: { fail 'unsupported OS version when checking firewall service'}
  }

  service { $firewall_service:
      enable    => false,
      ensure    => false,
      hasstatus => true,
  }

  $ora_groups = ['oinstall','dba','asmdba']
  $asm_groups = ['asmadmin','asmoper']
  $groups     = $ora_groups + $asm_groups

  group {$groups:
    ensure => 'present',
  }

  user { $::profile::oradb::ora_user :
    ensure      => present,
    uid         => 54321,
    gid         => $::profile::oradb::ora_group,
    groups      => $ora_groups,
    shell       => '/bin/bash',
    password    => '$1$DSJ51vh6$4XzzwyIOk6Bi/54kglGk3.',
    home        => '/home/oracle',
    comment     => 'Database software owner created by Puppet',
    require     => Group[$ora_groups],
    managehome  => true,
  }

  user { $::profile::oradb::grid_user :
    ensure      => present,
    uid         => 54322,
    gid         => $::profile::oradb::grid_group,
    groups      => $groups,
    shell       => '/bin/bash',
    password    => '$1$DSJ51vh6$4XzzwyIOk6Bi/54kglGk3.',
    home        => '/home/grid',
    comment     => 'GridInfra software owner created by Puppet',
    require     => Group[$groups],
    managehome  => true,
  }

  $packages = [ 'binutils.x86_64', 'compat-libcap1.x86_64', 'compat-libstdc++-33.i686',
                'compat-libstdc++-33.x86_64', 'gcc.x86_64', 'gcc-c++.x86_64', 'glibc.i686', 'glibc.x86_64', 'glibc-devel.i686',
                'glibc-devel.x86_64', 'ksh', 'libaio.i686', 'libaio.x86_64', 'libaio-devel.i686', 'libaio-devel.x86_64', 'libgcc.i686',
                'libgcc.x86_64', 'libstdc++.i686', 'libstdc++.x86_64', 'libstdc++-devel.i686', 'libstdc++-devel.x86_64',
                'libXi.i686', 'libXi.x86_64', 'libXtst.i686', 'libXtst.x86_64', 'make.x86_64', 'sysstat.x86_64']

  package { $packages:
    ensure  => present,
  }

  class { 'limits':
     config => {
                #'*'       => { 'nofile'  => { soft => '2048' , hard => '8192', },},
                # $::profile::oradb::ora_user  => { 'nofile' => { soft => '65536' , hard => '65536', },
                #                                   'nproc'  => { soft => '2048'  , hard => '16384', },
                #                                   'stack'  => { soft => '10240' , hard => '32768', },},
                $::profile::oradb::grid_user => { 'nofile' => { soft => '65536' , hard => '65536', },
                                                  'nproc'  => { soft => '2048'  , hard => '16384', },
                                                  'stack'  => { soft => '10240' , hard => '32768', },},
                },
     use_hiera => false,
  }
  contain limits

  sysctl { 'kernel.msgmnb':                 ensure => 'present', permanent => 'yes', value => '65536',}
  sysctl { 'kernel.msgmax':                 ensure => 'present', permanent => 'yes', value => '65536',}
  sysctl { 'kernel.shmmax':                 ensure => 'present', permanent => 'yes', value => '4398046511104',}
  sysctl { 'kernel.shmall':                 ensure => 'present', permanent => 'yes', value => '4294967296',}
  sysctl { 'fs.file-max':                   ensure => 'present', permanent => 'yes', value => '6815744',}
  sysctl { 'kernel.shmmni':                 ensure => 'present', permanent => 'yes', value => '4096', }
  sysctl { 'fs.aio-max-nr':                 ensure => 'present', permanent => 'yes', value => '1048576',}
  sysctl { 'kernel.sem':                    ensure => 'present', permanent => 'yes', value => '250 32000 100 128',}
  sysctl { 'net.ipv4.ip_local_port_range':  ensure => 'present', permanent => 'yes', value => '9000 65500',}
  sysctl { 'net.core.rmem_default':         ensure => 'present', permanent => 'yes', value => '262144',}
  sysctl { 'net.core.rmem_max':             ensure => 'present', permanent => 'yes', value => '4194304', }
  sysctl { 'net.core.wmem_default':         ensure => 'present', permanent => 'yes', value => '262144',}
  sysctl { 'net.core.wmem_max':             ensure => 'present', permanent => 'yes', value => '1048576',}
  sysctl { 'kernel.panic_on_oops':          ensure => 'present', permanent => 'yes', value => '1',}

  # In RHEL7.2 defaults RemoveIPC to true, which will cause the database and ASM to crash
  file_line { 'Do not remove ipc':
    path   => '/etc/systemd/logind.conf',
    line   => 'RemoveIPC=no',
    match  => "^#RemoveIPC.*$",
    notify => Exec['systemctl daemon-reload'],
  } ->
  exec { 'systemctl daemon-reload':
    command     => '/bin/systemctl daemon-reload',
    refreshonly => true,
    require     => File_line['Do not remove ipc'],
    notify      => Service['systemd-logind'],
  } ->
  service { 'systemd-logind':
    provider   => 'systemd',
    hasrestart => true,
    subscribe  => Exec['systemctl daemon-reload'],
  }
}
