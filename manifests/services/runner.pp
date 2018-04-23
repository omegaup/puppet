# The omegaUp runner service.
class omegaup::services::runner (
  $services_ensure = running,
  $hostname = 'localhost',
  $grader_host = 'https://localhost:11302',
  $keystore_password = 'omegaup',
  $runner_flags = '',
) {
  include omegaup::users

  remote_file { '/var/lib/omegaup/omegajail-xenial-distrib-x86_64.tar.bz2':
    url      => 'https://omegaup-omegajail.s3.amazonaws.com/omegajail-xenial-distrib-x86_64.tar.bz2',
    sha1hash => '8716bf0c7f6df071bc6ae876078560cc909a4764',
    mode     => 644,
    owner    => 'root',
    group    => 'root',
    require  => File['/var/lib/omegaup'],
  }
  exec { 'omegajail-distrib':
    command     => '/bin/tar -xf /var/lib/omegaup/omegajail-xenial-distrib-x86_64.tar.bz2 -C /',
    user        => 'root',
    notify      => File['/var/lib/omegajail/bin/omegajail'],
    subscribe   => Remote_File['/var/lib/omegaup/omegajail-xenial-distrib-x86_64.tar.bz2'],
    refreshonly => true,
  }
  file { '/var/lib/omegajail/bin/omegajail':
    require => Exec['omegajail-distrib'],
  }

  # Configuration
  file { '/etc/omegaup/runner':
    ensure  => 'directory',
    require => File['/etc/omegaup'],
  }
  file { '/etc/omegaup/runner/config.json':
    ensure  => 'file',
    owner   => 'omegaup',
    group   => 'omegaup',
    mode    => '0644',
    content => template('omegaup/runner/config.json.erb'),
    require => File['/etc/omegaup/runner'],
  }
  omegaup::certmanager::cert { '/etc/omegaup/runner/key.pem':
    hostname      => $hostname,
    password      => $keystore_password,
    owner         => 'omegaup',
    mode          => '0600',
    separate_cert => '/etc/omegaup/runner/certificate.pem',
    require       => [File['/etc/omegaup/runner'], User['omegaup']],
  }

  # Runtime files
  file { '/var/lib/omegaup/runner':
    ensure  => 'directory',
    owner   => 'omegaup',
    group   => 'omegaup',
    require => File['/var/lib/omegaup'],
  }
  file { ['/var/log/omegaup/runner.log',
          '/var/log/omegaup/runner.tracing.json']:
    ensure  => 'file',
    owner   => 'omegaup',
    group   => 'omegaup',
    require => File['/var/log/omegaup'],
  }

  # Service
  file { '/etc/systemd/system/omegaup-runner.service':
    ensure  => 'file',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('omegaup/runner/omegaup-runner.service.erb'),
  }
  service { 'omegaup-runner':
    ensure    => $services_ensure,
    enable    => true,
    provider  => 'systemd',
    subscribe => [
      File[
        '/usr/bin/omegaup-runner',
        '/etc/omegaup/runner/config.json'
      ],
      Exec['omegaup-backend'],
    ],
    require   => [
      File[
        '/etc/systemd/system/omegaup-runner.service', '/usr/bin/omegaup-runner',
        '/var/lib/omegaup/runner', '/var/log/omegaup/runner.log',
        '/var/log/omegaup/runner.tracing.json', '/etc/omegaup/runner/config.json',
        '/var/lib/omegajail/bin/omegajail'
      ],
      Omegaup::Certmanager::Cert['/etc/omegaup/runner/key.pem'],
    ],
  }
}

# vim:expandtab ts=2 sw=2
