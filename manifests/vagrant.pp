class { '::omegaup::apt_sources':
  development_environment => true,
}

class { '::omegaup::database':
  development_environment => true,
  root_password           => 'omegaup',
  password                => 'omegaup',
}

class { '::omegaup::certmanager': }
file { '/etc/omegaup': ensure => 'directory' }

omegaup::certmanager::cert { '/etc/omegaup/frontend/certificate.pem':
  hostname => 'localhost',
  owner    => 'www-data',
  mode     => '600',
  require  => [File['/etc/omegaup/frontend'], User['www-data']],
}
file { '/etc/omegaup/frontend':
  ensure  => 'directory',
  require => File['/etc/omegaup'],
}
class { '::omegaup':
  development_environment => true,
  local_database          => true,
  mysql_password          => 'omegaup',
  user                    => 'vagrant',
  gitserver_shared_token  => 'gitserversharedtoken',
  require                 => [Class['::omegaup::database']],
}
class { '::omegaup::web_app': }

class { '::omegaup::cron':
  mysql_password => 'omegaup',
  require        => Class['::omegaup'],
}
class { '::omegaup::services': }

file { '/etc/omegaup/grader':
  ensure  => 'directory',
  require => File['/etc/omegaup'],
} -> omegaup::certmanager::cert { '/etc/omegaup/grader/key.pem':
  hostname      => $hostname,
  password      => 'omegaup',
  owner         => 'omegaup',
  mode          => '600',
  separate_cert => '/etc/omegaup/grader/certificate.pem',
  require       => User['omegaup'],
} -> class { '::omegaup::services::grader':
  keystore_password => 'omegaup',
  mysql_password    => 'omegaup',
  user              => 'vagrant',
  require           => Class['::omegaup::services'],
}
class { '::omegaup::services::runner':
  keystore_password => 'omegaup',
  require           => Class['::omegaup::services'],
}
file { '/etc/omegaup/broadcaster':
  ensure  => 'directory',
  require => File['/etc/omegaup'],
} -> omegaup::certmanager::cert { '/etc/omegaup/broadcaster/key.pem':
  hostname      => $hostname,
  password      => 'omegaup',
  owner         => 'omegaup',
  mode          => '600',
  separate_cert => '/etc/omegaup/broadcaster/certificate.pem',
  require       => User['omegaup'],
} -> class { '::omegaup::services::broadcaster':
  keystore_password => 'omegaup',
  require           => Class['::omegaup::services'],
}

# vim:expandtab ts=2 sw=2
