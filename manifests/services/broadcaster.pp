# The omegaUp broadcaster service.
class omegaup::services::broadcaster (
  $services_ensure = running,
  $hostname = 'localhost',
  $frontend_host = 'http://localhost',
  $scoreboard_update_secret = 'secret',
  $keystore_password = 'omegaup',
) {
  include omegaup::users

  # Configuration
  file { '/etc/omegaup/broadcaster':
    ensure  => 'directory',
    require => File['/etc/omegaup'],
  }
  file { '/etc/omegaup/broadcaster/config.json':
    ensure  => 'file',
    owner   => 'omegaup',
    group   => 'omegaup',
    mode    => '600',
    content => template('omegaup/broadcaster/config.json.erb'),
    require => File['/etc/omegaup/broadcaster'],
  }
  omegaup::certmanager::cert { '/etc/omegaup/broadcaster/key.pem':
    hostname      => $hostname,
    password      => $keystore_password,
    owner         => 'omegaup',
    mode          => '600',
    separate_cert => '/etc/omegaup/broadcaster/certificate.pem',
    require       => [File['/etc/omegaup/broadcaster'], User['omegaup']],
  }

  # Runtime files
  file { ['/var/log/omegaup/broadcaster.log',
          '/var/log/omegaup/broadcaster.tracing.json']:
    ensure  => 'file',
    owner   => 'omegaup',
    group   => 'omegaup',
    require => File['/var/log/omegaup'],
  }

  # Service
  file { '/etc/systemd/system/omegaup-broadcaster.service':
    ensure => 'file',
    source => 'puppet:///modules/omegaup/omegaup-broadcaster.service',
    mode   => '644',
    owner  => 'root',
    group  => 'root',
    notify => Exec['systemctl daemon-reload'],
  }
  service { 'omegaup-broadcaster':
    ensure    => $services_ensure,
    enable    => true,
    provider  => 'systemd',
    subscribe => [
      File[
        '/usr/bin/omegaup-broadcaster',
        '/etc/omegaup/broadcaster/config.json'
      ],
      Exec['omegaup-backend'],
    ],
    require   => [
      File[
        '/etc/systemd/system/omegaup-broadcaster.service',
        '/usr/bin/omegaup-broadcaster',
        '/var/log/omegaup/broadcaster.log',
        '/var/log/omegaup/broadcaster.tracing.json',
        '/etc/omegaup/broadcaster/config.json'
      ],
      Omegaup::Certmanager::Cert['/etc/omegaup/broadcaster/key.pem'],
    ],
  }
}

# vim:expandtab ts=2 sw=2
