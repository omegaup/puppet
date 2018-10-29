class omegaup::org_web (
  $hostname = 'omegaup.org',
  $default_server = true,
  $ssl = false,
) {
  $org_webroot = "/var/www/${hostname}"
  file { $org_webroot:
    ensure  => directory,
    owner   => 'omegaup-www',
    group   => 'omegaup-www',
    require => File['/var/www'],
  }
  github { $org_webroot:
    ensure  => latest,
    repo    => 'omegaup/nonprofit-web',
    owner   => 'omegaup-www',
    group   => 'omegaup-www',
    require => File[$org_webroot],
  }
  omegaup::web_host{ $hostname:
    default_server => $default_server,
    hostname       => $hostname,
    php            => false,
    ssl            => $ssl,
    web_root       => $org_webroot,
    rewrite_rules  => [
      '^/donate(/.*)?$ /#donate permanent',
    ],
  }
}

# vim:expandtab ts=2 sw=2
