# The omegaUp runner service.
class omegaup::services::runner (
  $services_ensure = running,
  $hostname = 'localhost',
  $grader_host = 'https://localhost:11302',
  $keystore_password = 'omegaup',
  $runner_flags = '',
) {
  include omegaup::users
  include omegaup::directories

  remote_file { '/var/lib/omegaup/omegaup-runner.tar.xz':
    url      => 'https://github.com/omegaup/quark/releases/download/v1.1.24/omegaup-runner.tar.xz',
    sha1hash => 'ba32950989d3f5fce4fd24ae543fc3f9b77e7702',
    mode     => '644',
    owner    => 'root',
    group    => 'root',
    notify   => Exec['unlink omegaup-runner'],
    require  => File['/var/lib/omegaup'],
  }

  exec { 'unlink omegaup-runner':
    command     => '/bin/rm -f /usr/bin/omegaup-runner',
    user        => 'root',
    notify      => Exec['omegaup-runner'],
    refreshonly => true,
  }

  exec { 'omegaup-runner':
    command     => '/bin/tar -xf /var/lib/omegaup/omegaup-runner.tar.xz -C /',
    user        => 'root',
    notify      => File['/usr/bin/omegaup-runner'],
    refreshonly => true,
  }

  file { '/usr/bin/omegaup-runner':
    require => Exec['omegaup-runner'],
  }

  file { '/var/lib/omegaup/omegajail-xenial-distrib-x86_64.tar.bz2':
    ensure => absent,
  }
  remote_file { '/var/lib/omegaup/omegajail-bionic-distrib-x86_64.tar.xz':
    url      => 'https://omegaup-omegajail.s3.amazonaws.com/omegajail-bionic-distrib-x86_64.tar.xz',
    sha1hash => '39ac682218883cb40a7ac70101d162b5383d79c5',
    mode     => '644',
    owner    => 'root',
    group    => 'root',
    require  => File['/var/lib/omegaup'],
  }
  remote_file { '/var/lib/omegaup/omegajail-bionic-rootfs-x86_64.tar.xz':
    url      => 'https://omegaup-omegajail.s3.amazonaws.com/omegajail-bionic-rootfs-x86_64.tar.xz',
    sha1hash => '490b126d5248e6601d5c12a3b437e26a7191516c',
    mode     => '644',
    owner    => 'root',
    group    => 'root',
    require  => File['/var/lib/omegaup'],
  }
  exec { 'omegajail-distrib':
    command     => '/bin/rm -rf /var/lib/omegajail && /bin/tar -xf /var/lib/omegaup/omegajail-bionic-rootfs-x86_64.tar.xz -C / && /bin/tar -xf /var/lib/omegaup/omegajail-bionic-distrib-x86_64.tar.xz -C /',
    user        => 'root',
    notify      => File['/var/lib/omegajail/bin/omegajail'],
    subscribe   => [
      Remote_File['/var/lib/omegaup/omegajail-bionic-rootfs-x86_64.tar.xz'],
      Remote_File['/var/lib/omegaup/omegajail-bionic-distrib-x86_64.tar.xz'],
    ],
    refreshonly => true,
  }
  file { '/var/lib/omegajail/bin/omegajail':
    require => Exec['omegajail-distrib'],
  }

  # Configuration
  file { '/etc/omegaup/runner':
    ensure  => 'directory',
    require => File['/etc/omegaup'],
  } -> omegaup::certmanager::cert { '/etc/omegaup/runner/key.pem':
    hostname      => $hostname,
    password      => $keystore_password,
    owner         => 'omegaup',
    mode          => '600',
    separate_cert => '/etc/omegaup/runner/certificate.pem',
    require       => User['omegaup'],
  } -> file { '/etc/omegaup/runner/config.json':
    ensure  => 'file',
    owner   => 'omegaup',
    group   => 'omegaup',
    mode    => '0644',
    content => template('omegaup/runner/config.json.erb'),
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
    notify  => Exec['systemctl daemon-reload'],
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
      Exec['omegaup-runner'],
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
