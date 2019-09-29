# The omegaUp grader service.
class omegaup::services::gitserver (
  $hostname = 'localhost',
  $frontend_host = 'http://localhost',
  $gitserver_shared_token = $::omegaup::gitserver_shared_token,
  $mysql_db = 'omegaup',
  $mysql_host = 'localhost',
  $mysql_password = undef,
  $mysql_user = 'omegaup',
  $root = '/opt/omegaup',
  $services_ensure = running,
) {
  include omegaup::directories
  include omegaup::libinteractive
  include omegaup::scripts
  include omegaup::users

  # Configuration
  file { '/etc/omegaup/gitserver/config.json':
    ensure  => 'file',
    owner   => 'omegaup',
    group   => 'omegaup',
    mode    => '0600',
    content => template('omegaup/gitserver/config.json.erb'),
    require => File['/etc/omegaup/gitserver'],
  }

  # Runtime files
  file { '/var/lib/omegaup/problems.git':
    ensure  => 'directory',
    owner   => 'omegaup',
    group   => 'omegaup',
    require => File['/var/lib/omegaup'],
  }

  # Service
  file { '/var/log/omegaup/gitserver.log':
    ensure  => 'file',
    owner   => 'omegaup',
    group   => 'omegaup',
    require => File['/var/log/omegaup'],
  }
  file { '/etc/systemd/system/omegaup-gitserver.service':
    ensure  => 'file',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('omegaup/gitserver/omegaup-gitserver.service.erb'),
    notify  => Exec['systemctl daemon-reload'],
  }
  service { 'omegaup-gitserver':
    ensure    => $services_ensure,
    enable    => true,
    provider  => 'systemd',
    subscribe => [
      File[
        '/etc/systemd/system/omegaup-gitserver.service',
        '/usr/bin/omegaup-gitserver',
      ],
      Exec['omegaup-gitserver'],
    ],
    require   => [
      File[
        '/etc/systemd/system/omegaup-gitserver.service',
        '/usr/bin/omegaup-gitserver',
        '/var/log/omegaup/gitserver.log',
        '/var/lib/omegaup/problems.git',
      ],
    ],
  }
}

# vim:expandtab ts=2 sw=2
