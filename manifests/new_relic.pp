class omegaup::new_relic (
  $license_key,
  $hostname = $::omegaup::hostname,
) {
  # New Relic infra
  file { '/etc/newrelic-infra.yml':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '644',
    content => template('omegaup/newrelic/newrelic-infra.yml.erb'),
    notify  => Service['newrelic-infra'],
  }
  package { 'newrelic-infra':
    require  => Apt::Source['newrelic-infra'],
  }
  service { 'newrelic-infra':
    ensure   => running,
    require  => Package['newrelic-infra'],
  }

  # New Relic sysmond
  package { 'newrelic-sysmond':
    require => Apt::Source['newrelic'],
  }
  service { 'newrelic-sysmond':
    ensure   => running,
    require  => Package['newrelic-sysmond'],
  }
  ini_setting { 'nrsysmond.cfg license':
    path    => '/etc/newrelic/nrsysmond.cfg',
    setting => 'license_key',
    value   => $license_key,
    require => Package['newrelic-sysmond'],
    notify  => Service['newrelic-sysmond'],
  }

  # New Relic PHP extension
  file { '/usr/lib/php/20170718/newrelic.so':
    ensure => link,
    target => '/usr/lib/newrelic-php5/agent/x64/newrelic-20170718.so',
    require  => [Package['newrelic-php5'], Package[$::php::fpm::package]],
  } -> php::extension { 'newrelic-php5':
    provider           => 'apt',
    package_prefix     => '',
    require            => Apt::Source['newrelic'],
    sapi               => 'fpm',
    so_name            => 'newrelic',
    settings_prefix    => 'newrelic/newrelic',
    settings           => {
      license                              => "\"${license_key}\"",
      appname                              => "\"${hostname}\"",
      'browser_monitoring.auto_instrument' => 'false',
    },
  }
}

# vim:expandtab ts=2 sw=2
