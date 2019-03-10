# Wrapper for the omegaUp PHP frontend.
class omegaup::web(
  $web_root,
  $development_environment = false,
  $default_server = true,
  $hostname = 'localhost',
  $include_files = [],
  $php_version = $::lsbdistcodename ? {
    'bionic' => '7.2',
    default  => '7.0',
  },
  $php_max_children = 36,
  $php_max_requests = 500,
  $try_files = undef,
  $services_ensure = running,
  $ssl = false,
) {
  # nginx
  file { '/var/www':
    ensure => 'directory',
  }
  class { 'nginx':
    service_ensure       => $services_ensure,
    manage_repo          => false,
    worker_rlimit_nofile => 8192,
  }
  file { '/etc/nginx/conf.d/default.conf':
    ensure  => absent,
    require => Package['nginx'],
  }
  omegaup::web_host{ $hostname:
    default_server => $default_server,
    include_files  => $include_files,
    hostname       => $hostname,
    ssl            => $ssl,
    try_files      => $try_files,
    web_root       => $web_root,
  }

  # Make sure the old deprecated APCu package is not present.
  package { 'php-apcu':
    ensure => absent,
  }

  # PHP
  if $development_environment {
    $php_development_settings = {
      'PHP/error_reporting' => 'E_ALL',
      'PHP/display_errors'  => 'On',
      'PHP/display_startup_errors'  => 'On',
    }
  } else {
    $php_development_settings = {}
  }
  class { '::php':
    ensure       => latest,
    manage_repos => false,
    fpm          => true,
    settings     => merge({
      'PHP/post_max_size'       => '200M',
      'PHP/upload_max_filesize' => '200M',
    }, $php_development_settings),
    fpm_pools    => {
      'www'       => {
        'listen'          => "/run/php/php${php_version}-fpm.sock",
        'listen_owner'    => 'www-data',
        'listen_group'    => 'www-data',
        'pm_max_children' => $php_max_children,
        'pm_max_requests' => $php_max_requests,
      },
    },
    extensions   => {
      apcu     => {
        ensure   => 'latest',
        provider => 'pecl',
        settings => {
          'apc.enable_cli' => 1,
        },
        require  => Package['php-apcu'],
      },
      curl     => {
        provider   => 'apt',
      },
      mbstring => {
        provider   => 'apt',
      },
      mysql    => {
        provider => 'apt',
        so_name  => 'mysqli',
      },
      zip      => {
        provider   => 'apt',
      },
    },
  }
}

# vim:expandtab ts=2 sw=2
