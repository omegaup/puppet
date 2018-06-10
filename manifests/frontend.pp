hiera_include('classes')

file { '/etc/omegaup': ensure => 'directory' }

host { 'localhost':
  ensure => present,
  name   => hiera('omegaup_hostname'),
  ip     => '127.0.0.1',
}

omegaup::certmanager::cert { '/etc/omegaup/frontend/certificate.pem':
  owner    => 'www-data',
  mode     => '0600',
  require  => [File['/etc/omegaup/frontend'], User['www-data']],
  hostname => hiera('omegaup_hostname'),
}
file { '/etc/omegaup/frontend':
  ensure  => 'directory',
  require => File['/etc/omegaup'],
}
class { '::omegaup::apt_sources':
  use_newrelic            => true,
  use_elastic_beats       => true,
  development_environment => false,
}

# Staging repository
file { '/opt/nvm':
  ensure => 'directory',
  owner  => $omegaup::user,
  group  => $omegaup::user,
}
github { '/opt/nvm':
  ensure  => latest,
  repo    => 'creationix/nvm',
  branch  => 'v0.33.2',
  owner   => $omegaup::user,
  group   => $omegaup::user,
  require => File['/opt/nvm'],
}
file { '/opt/omegaup-staging':
  ensure => 'directory',
  owner  => $omegaup::user,
  group  => $omegaup::user,
}
github { '/opt/omegaup-staging':
  ensure  => latest,
  repo    => $::omegaup::github_repo,
  branch  => $::omegaup::github_branch,
  owner   => $omegaup::user,
  group   => $omegaup::user,
  require => File['/opt/omegaup-staging'],
}
file { '/usr/local/bin/omegaup-uprev':
  ensure  => 'file',
  source  => 'puppet:///modules/omegaup/omegaup-uprev',
  mode    => 0755,
  owner   => 'root',
  group   => 'root',
}
exec { 'omegaup-uprev':
  command     => '/usr/local/bin/omegaup-uprev',
  subscribe   => [Github['/opt/omegaup-staging'],
                  File['/usr/local/bin/omegaup-uprev']],
  before      => Github[$::omegaup::root],
  require     => User['omegaup-www'],
  refreshonly => true,
}
exec { 'copy-vue':
  command     => '/usr/bin/rsync -a --delete /opt/omegaup-staging/frontend/www/js/dist/ /opt/omegaup/frontend/www/js/dist/',
  subscribe   => [Exec['omegaup-uprev'], Github[$::omegaup::root]],
  refreshonly => true,
}
exec { 'nginx-reload':
  command     => '/bin/systemctl reload nginx',
  subscribe   => Github[$::omegaup::root],
  refreshonly => true,
}
exec { 'delete-templates':
  command     => '/bin/rm -rf /var/tmp/*.php',
  subscribe   => Github[$::omegaup::root],
  refreshonly => true,
}

# New Relic
class { '::omegaup::new_relic': }

# Filebeat
class { '::omegaup::filebeat':
  template => 'omegaup/filebeat/frontend.yml.erb',
}

# vim:expandtab ts=2 sw=2
