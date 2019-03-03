# A certificate used to communicate between backend instances.
define omegaup::certmanager::cert (
  $hostname,
  $ensure = present,
  $country = $::omegaup::certmanager::country,
  $password = 'omegaup',
  $owner = undef,
  $group = undef,
  $mode = undef,
  $separate_cert = undef,
) {
  if $separate_cert != undef {
    $command = "/usr/bin/certmanager cert --root '${omegaup::certmanager::ssl_root}' --country '${country}' --hostname '${hostname}' --output '${title}' --cert-output '${separate_cert}' --password '${password}'"
    $creates = [$title, $separate_cert]
  } else {
    $command = "/usr/bin/certmanager cert --root '${omegaup::certmanager::ssl_root}' --country '${country}' --hostname '${hostname}' --output '${title}' --password '${password}'"
    $creates = [$title]
  }

  exec { "certmanager-${title}":
    command => $command,
    creates => $creates,
    require => Exec['certmanager-ca'],
  }

  file { $title:
    owner   => $owner,
    group   => $group,
    mode    => $mode,
    require => Exec["certmanager-${title}"],
  }

  if $separate_cert != undef {
    file { $separate_cert:
      owner   => $owner,
      group   => $group,
      require => Exec["certmanager-${title}"],
    }
  }
}

# vim:expandtab ts=2 sw=2
