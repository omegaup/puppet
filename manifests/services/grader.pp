# The omegaUp grader service.
class omegaup::services::grader (
  $user = undef,
  $hostname = 'localhost',
  $embedded_runner = true,
  $broadcaster_host = 'https://localhost:32672',
  $frontend_host = 'http://localhost',
  $gitserver_shared_token = $::omegaup::gitserver_shared_token,
  $keystore_password = 'omegaup',
  $local_database = true,
  $mysql_db = 'omegaup',
  $mysql_host = 'localhost',
  $mysql_password = undef,
  $mysql_user = 'omegaup',
  $root = '/opt/omegaup',
  $services_ensure = running,
) {
  include omegaup::users
  include omegaup::scripts
  include omegaup::directories

  # libinteractive
  package { 'openjdk-8-jre-headless':
    ensure => installed,
  }
  remote_file { '/usr/share/java/libinteractive.jar':
    url      => 'https://github.com/omegaup/libinteractive/releases/download/v2.0.23/libinteractive.jar',
    sha1hash => '38313bcb9f01e52d7188dba1e12af15f8482040f',
    mode     => '644',
    owner    => 'root',
    group    => 'root',
    notify   => Exec['refresh-libinteractive'],
    require  => Package['openjdk-8-jre-headless'],
  }
  exec { 'refresh-libinteractive':
    command     => "${root}/stuff/refresh_libinteractive.py",
    require     => [Github[$root]],
    refreshonly => true,
  }

  # Configuration
  file { '/etc/omegaup/grader':
    ensure  => 'directory',
    require => File['/etc/omegaup'],
  }
  file { '/etc/omegaup/grader/config.json':
    ensure  => 'file',
    owner   => 'omegaup',
    group   => 'omegaup',
    mode    => '600',
    content => template('omegaup/grader/config.json.erb'),
    require => File['/etc/omegaup/grader'],
  }
  omegaup::certmanager::cert { '/etc/omegaup/grader/key.pem':
    hostname      => $hostname,
    password      => $keystore_password,
    owner         => 'omegaup',
    mode          => '600',
    separate_cert => '/etc/omegaup/grader/certificate.pem',
    require       => [File['/etc/omegaup/grader'], User['omegaup']],
  }

  # Runtime files
  package { ['libhttp-parser2.1', 'libssh2-1']:
    ensure => installed,
  }
  file { ['/var/log/omegaup/service.log', '/var/log/omegaup/tracing.json']:
    ensure  => 'file',
    owner   => 'omegaup',
    group   => 'omegaup',
    require => File['/var/log/omegaup'],
  }
  file { ['/var/lib/omegaup/input', '/var/lib/omegaup/cache',
          '/var/lib/omegaup/grade', '/var/lib/omegaup/ephemeral']:
    ensure  => 'directory',
    owner   => 'omegaup',
    group   => 'omegaup',
    require => File['/var/lib/omegaup'],
  }

  # Service
  file { '/etc/systemd/system/omegaup-grader.service':
    ensure  => 'file',
    mode    => '644',
    owner   => 'root',
    group   => 'root',
    content => template('omegaup/grader/omegaup-grader.service.erb'),
    notify  => Exec['systemctl daemon-reload'],
  }
  service { 'omegaup-grader':
    ensure    => $services_ensure,
    enable    => true,
    provider  => 'systemd',
    subscribe => [
      File[
        '/usr/bin/omegaup-grader',
        '/etc/omegaup/grader/config.json'
      ],
      Exec['omegaup-backend'],
    ],
    require   => [
      File[
        '/etc/systemd/system/omegaup-grader.service',
        '/var/lib/omegaup/input', '/var/lib/omegaup/cache',
        '/var/lib/omegaup/grade', '/var/log/omegaup/service.log',
        '/usr/bin/omegaup-grader',
        '/var/log/omegaup/tracing.json',
        '/etc/omegaup/grader/config.json'
      ],
      Remote_File['/usr/share/java/libinteractive.jar'],
      Omegaup::Certmanager::Cert['/etc/omegaup/grader/key.pem'],
      Package['libhttp-parser2.1', 'libssh2-1'],
    ],
  }

  # Git service
  file { '/var/log/omegaup/gitserver.log':
    ensure  => 'file',
    owner   => 'omegaup',
    group   => 'omegaup',
    require => File['/var/log/omegaup'],
  }
  file { '/etc/systemd/system/omegaup-gitserver.service':
    ensure  => 'file',
    mode    => '644',
    owner   => 'root',
    group   => 'root',
    content => template('omegaup/grader/omegaup-gitserver.service.erb'),
    notify  => Exec['systemctl daemon-reload'],
  }
  service { 'omegaup-gitserver':
    ensure    => $services_ensure,
    enable    => true,
    provider  => 'systemd',
    subscribe => [
      File[
        '/usr/bin/omegaup-gitserver', '/var/log/omegaup/gitserver.log',
        '/etc/systemd/system/omegaup-gitserver.service'
      ],
    ],
    require   => [
      File[
        '/etc/systemd/system/omegaup-gitserver.service',
        '/var/lib/omegaup/problems.git'
      ],
    ],
  }
}

# vim:expandtab ts=2 sw=2
