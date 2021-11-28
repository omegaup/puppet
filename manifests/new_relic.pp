# Support for the New Relic PHP plugin.
class omegaup::new_relic (
  $license_key,
  $hostname = $::omegaup::hostname,
) {
  # New Relic infra
  file { '/etc/newrelic-infra.yml':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('omegaup/newrelic/newrelic-infra.yml.erb'),
    notify  => Service['newrelic-infra'],
  }
  package { 'newrelic-infra':
    require  => Apt::Source['newrelic-infra'],
  }
  service { 'newrelic-infra':
    ensure  => running,
    require => Package['newrelic-infra'],
  }

  # New Relic sysmond
  package { 'newrelic-sysmond':
    require => Apt::Source['newrelic'],
  }
  service { 'newrelic-sysmond':
    ensure  => running,
    require => Package['newrelic-sysmond'],
  }
  ini_setting { 'nrsysmond.cfg license':
    path    => '/etc/newrelic/nrsysmond.cfg',
    setting => 'license_key',
    value   => $license_key,
    require => Package['newrelic-sysmond'],
    notify  => Service['newrelic-sysmond'],
  }

  # New Relic PHP extension
  php::extension { 'newrelic-php5':
    provider        => 'apt',
    package_prefix  => '',
    require         => Apt::Source['newrelic'],
    sapi            => 'fpm',
    so_name         => 'newrelic',
    settings_prefix => 'newrelic/newrelic',
    settings        => {
      license                                       => "\"${license_key}\"",
      appname                                       => "\"${hostname}\"",
      'browser_monitoring.auto_instrument'          => false,
      'distributed_tracing_enabled'                 => true,
      'distributed_tracing_exclude_newrelic_header' => 1,
      'span_events_enabled'                         => true,
      'transaction_tracer.enabled'                  => true,
      'transaction_tracer.threshold'                => 0,
    },
  } -> file { '/usr/lib/php/20190902/newrelic.so':
    ensure => link,
    target => '/usr/lib/newrelic-php5/agent/x64/newrelic-20190902.so',
  }
}

# vim:expandtab ts=2 sw=2
