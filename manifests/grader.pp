hiera_include('classes')

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
