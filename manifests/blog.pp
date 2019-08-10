# Configures the omegaUp blog.
class omegaup::blog (
  $default_server = false,
  $hostname = 'localhost',
  $ssl = false,
  $wordpress_db_name = 'blog',
  $wordpress_db_password = undef,
  $wordpress_db_user = 'wordpress',
  $wordpress_user = 'wordpress',
) {
  user { [$wordpress_user]: ensure => present }

  $wp_root = "/var/www/${hostname}/"
  file { $wp_root:
    ensure  => directory,
    owner   => $wordpress_user,
    require => [File['/var/www'], User[$wordpress_user]],
  }

  class { '::omegaup::web':
    default_server => $default_server,
    hostname       => $hostname,
    ssl            => $ssl,
    try_files      => ['$uri', '$uri/', '/index.php?$args'],
    web_root       => $wp_root,
    require        => Class['::omegaup::apt_sources'],
  }
  class { 'wordpress':
    wp_owner       => $wordpress_user,
    wp_group       => $wordpress_user,
    db_user        => $wordpress_db_user,
    db_name        => $wordpress_db_name,
    db_password    => $wordpress_db_password,
    create_db      => false,
    create_db_user => false,
    install_dir    => $wp_root,
    version        => '4.9.1',
    require        => [File[$wp_root], Mysql::Db[$wordpress_db_name]],
  }
  mysql::db { $wordpress_db_name:
    user     => $wordpress_db_user,
    password => $wordpress_db_password,
    host     => 'localhost',
    grant    => ['CREATE', 'SELECT', 'INSERT', 'UPDATE', 'DELETE'],
  }
  file { "${wp_root}/wp-content/uploads":
    ensure  => directory,
    owner   => 'www-data',
    group   => 'www-data',
    require => [Class['wordpress'], User['www-data']],
  }

  $nginx_server = $ssl ? {
    true  => "${hostname}-ssl",
    false => $hostname,
  }
  nginx::resource::location { "${hostname}-wp-ban-php-uploads":
    ensure        => present,
    server        => $nginx_server,
    ssl           => $ssl,
    ssl_only      => $ssl,
    location      => '~* /(?:uploads|files)/.*\.php$',
    location_deny => ['all'],
    index_files   => [],
  }
}

# vim:expandtab ts=2 sw=2
