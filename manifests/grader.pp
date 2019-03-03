hiera_include('classes')

file { '/etc/omegaup': ensure => 'directory' }
file { '/etc/omegaup/broadcaster':
  ensure  => 'directory',
  require => File['/etc/omegaup'],
}
file { '/etc/omegaup/grader':
  ensure  => 'directory',
  require => File['/etc/omegaup'],
}

host { 'localhost':
  ensure => present,
  name   => hiera('omegaup_hostname'),
  ip     => '127.0.0.1',
}

class { '::omegaup::apt_sources':
  use_newrelic            => false,
  use_elastic_beats       => true,
  development_environment => false,
}

# Filebeat
class { '::omegaup::filebeat':
  template => 'omegaup/filebeat/frontend.yml.erb',
}

# vim:expandtab ts=2 sw=2
