# Generates certificates needed for frontend-backend communication.
class omegaup::certmanager (
  $ssl_root = '/etc/certmanager',
  $ca_name = 'omegaUp Testing Certificate Authority',
  $country = 'MX',
) {
  file { '/usr/bin/certmanager':
    ensure => 'file',
    source => 'puppet:///modules/omegaup/certmanager',
    owner  => 'root',
    group  => 'root',
    mode   => '700',
  }
  file { $ssl_root:
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
  }
  exec { 'certmanager-ca':
    command => "/usr/bin/certmanager init --root '${::omegaup::certmanager::ssl_root}' --ca-name '${ca_name}' --country '${country}'",
    creates => "${::omegaup::certmanager::ssl_root}/ca.crt",
    require => [File['/usr/bin/certmanager'],
                File[$::omegaup::certmanager::ssl_root]],
  }
}

# vim:expandtab ts=2 sw=2
