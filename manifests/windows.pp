# See http://superuser.com/a/1066433
file { '/usr/sbin/policy-rc.d':
  ensure  => present
  content => "#!/bin/sh\ncase \"${1}\" in\n  udev|systemd-logind) exit 101;;\nesac\n",
  mode    => '0755',
}
# Ubuntu on Windows does not support Upstart. Fall back to 'init' for services.
Service {
  provider => init,
}
# Nginx does not start in Windows otherwise.
class { 'nginx::config':
  nginx_cfg_prepend => { 'master_process' => 'off' },
}
# Connecting to MySQL through a UNIX socket does not work on Windows.
# Use the localhost IP to force it to go through TCP.
$mysql_host = '127.0.0.1'

class { '::omegaup::apt_sources':
  require => File['/usr/sbin/policy-rc.d'],
}

class { '::omegaup::database':
  development_environment => true,
  root_password           => $mysql_password,
  password                => $mysql_password,
  service_provider        => 'init'
}

class { '::omegaup::certmanager': }
file { '/etc/omegaup': ensure => 'directory' }
file { ['/etc/omegaup/frontend', '/etc/omegaup/grader']:
  ensure  => 'directory',
  require => File['/etc/omegaup'],
}
omegaup::certmanager::cert { '/etc/omegaup/frontend/certificate.pem':
  hostname => 'localhost',
  mode     => '600',
  owner    => 'www-data',
  require  => [File['/etc/omegaup/frontend'], User['www-data']],
}

class { '::omegaup':
  development_environment => true,
  user                    => $user,
  mysql_host              => $mysql_host,
  mysql_password          => $mysql_password,
  require                 => [Class['::omegaup::database']],
}

# vim:expandtab ts=2 sw=2
