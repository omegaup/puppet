# The omegaUp broadcaster service.
class omegaup::services::broadcaster (
  $services_ensure = running,
  $hostname = 'localhost',
  $frontend_host = 'http://localhost',
  $scoreboard_update_secret = 'secret',
  $keystore_password = 'omegaup',
) {
  include omegaup::users
  include omegaup::directories

  # Configuration
  file { '/etc/omegaup/broadcaster/config.json':
    ensure  => 'file',
    owner   => 'omegaup',
    group   => 'omegaup',
    mode    => '0600',
    content => template('omegaup/broadcaster/config.json.erb'),
    require => File['/etc/omegaup/broadcaster'],
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
    mode   => '0644',
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
        '/etc/omegaup/broadcaster/config.json'
        '/etc/systemd/system/omegaup-broadcaster.service',
        '/usr/bin/omegaup-broadcaster',
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
    ],
  }
}

# vim:expandtab ts=2 sw=2
