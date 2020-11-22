class { '::php::globals':
  php_version => '7.4',
  config_root => '/etc/php/7.4',
}

class { '::omegaup::apt_sources':
  development_environment => true,
}

class { '::omegaup::database':
  development_environment => true,
  root_password           => 'omegaup',
  password                => 'omegaup',
}

class { '::omegaup::certmanager': }

file { '/etc/omegaup/frontend':
  ensure  => 'directory',
  require => File['/etc/omegaup'],
} -> omegaup::certmanager::cert { '/etc/omegaup/frontend/key.pem':
  hostname => 'localhost',
  owner    => 'www-data',
  mode     => '600',
  require  => User['www-data'],
  separate_cert => '/etc/omegaup/frontend/certificate.pem',
}
class { '::omegaup':
  development_environment => true,
  local_database          => true,
  mysql_password          => 'omegaup',
  user                    => 'vagrant',
  gitserver_shared_token  => 'gitserversharedtoken',
  require                 => [Class['::omegaup::database']],
}
class { '::omegaup::web_app':
  http_port => 8001,
}

class { '::omegaup::cron':
  mysql_password => 'omegaup',
  require        => Class['::omegaup'],
}
class { '::omegaup::services': }

omegaup::certmanager::cert { '/etc/omegaup/grader/key.pem':
  hostname      => 'localhost',
  password      => 'omegaup',
  owner         => 'omegaup',
  mode          => '600',
  separate_cert => '/etc/omegaup/grader/certificate.pem',
  require       => [File['/etc/omegaup/grader'], User['omegaup']],
}
class { '::omegaup::services::grader':
  keystore_password => 'omegaup',
  mysql_password    => 'omegaup',
  user              => 'vagrant',
  local_database    => true,
  require           => [Omegaup::Certmanager::Cert['/etc/omegaup/grader/key.pem'],
                        Class['::omegaup::services']],
}
class { '::omegaup::services::gitserver':
  mysql_password    => 'omegaup',
  local_database    => true,
}
class { '::omegaup::services::runner':
  keystore_password => 'omegaup',
  require           => Class['::omegaup::services'],
}
omegaup::certmanager::cert { '/etc/omegaup/broadcaster/key.pem':
  hostname      => 'localhost',
  password      => 'omegaup',
  owner         => 'omegaup',
  mode          => '600',
  separate_cert => '/etc/omegaup/broadcaster/certificate.pem',
  require       => [File['/etc/omegaup/broadcaster'], User['omegaup']],
}
class { '::omegaup::services::broadcaster':
  keystore_password => 'omegaup',
  require           => [Omegaup::Certmanager::Cert['/etc/omegaup/broadcaster/key.pem'],
                        Class['::omegaup::services']],
}

# vim:expandtab ts=2 sw=2
