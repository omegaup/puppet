lookup('classes', {merge => unique}).include

# A few entries to avoid taking a dependency on ::omegaup.
package { 'sudo':
  ensure => present,
}
exec { 'systemctl daemon-reload':
  command     => '/bin/systemctl daemon-reload',
  refreshonly => true,
}

class { '::omegaup::apt_sources':
  use_newrelic            => true,
  development_environment => false,
}
class { '::omegaup::web_app': }
class { '::omegaup::users': }
class { '::omegaup::blog':
  require => Class['::omegaup::web'],
}
class { '::omegaup::org_web':
  require => Class['::omegaup::apt_sources'],
}
class { '::omegaup::database':
  require => Class['::omegaup::apt_sources'],
}

class { '::omegaup::filebeat': }
class { '::omegaup::services::webhook':
  manifest_name => 'frontend_org',
  require       => Class['::omegaup::apt_sources'],
}
