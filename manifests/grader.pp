lookup('classes', {merge => unique}).include

host { 'localhost':
  ensure => present,
  name   => hiera('omegaup_hostname'),
  ip     => '127.0.0.1',
}

class { '::omegaup::apt_sources':
  use_newrelic            => false,
  development_environment => false,
}

# Filebeat
class { '::omegaup::filebeat': }

# vim:expandtab ts=2 sw=2
