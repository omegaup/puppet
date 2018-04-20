define omegaup::web_host(
  $hostname = 'localhost',
  $default_server = true,
  $include_files = [],
  $try_files = undef,
  $ssl = false,
  $php = true,
  $web_root,
) {
  $nginx_server = $ssl ? {
    true  => "${hostname}-ssl",
    false => $hostname,
  }
  $listen_options = $default_server ? {
    true  => ' default_server',
    false => '',
  }
  $index_files = $php ? {
    true  => ['index.php', 'index.html'],
    false => ['index.html'],
  }
  $gzip_types = 'application/javascript application/json text/html text/css image/x-icon'
  if $ssl {
    exec { "${hostname}.dhparam":
      command => "/usr/bin/openssl dhparam -out /etc/ssl/private/${hostname}.dhparam 2048",
      user    => 'root',
      creates => "/etc/ssl/private/${hostname}.dhparam",
    }
    nginx::resource::server { $hostname:
      ensure            => present,
      index_files       => [],
      listen_port       => 80,
      rewrite_rules     => ["^ https://${hostname}\$request_uri permanent"],
      server_name       => [$hostname],
      require           => File['/etc/nginx/conf.d/default.conf'],
    }
    nginx::resource::server { "${hostname}-ssl":
      ensure               => present,
      listen_port          => 443,
      listen_options       => "http2${listen_options}",
      server_name          => [$hostname],
      ssl                  => true,
      ssl_cert             => "/etc/letsencrypt/live/${hostname}/fullchain.pem",
      ssl_key              => "/etc/letsencrypt/live/${hostname}/privkey.pem",
      ssl_ciphers          => 'EECDH+AESGCM:EDH+AESGCM:ECDHE-RSA-AES128-GCM-SHA256:AES256+EECDH:DHE-RSA-AES128-GCM-SHA256:AES256+EDH:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA:AES256-GCM-SHA384:AES128-GCM-SHA256:AES256-SHA256:AES128-SHA256:AES256-SHA:AES128-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!3DES:!MD5:!PSK:!RC4',
      ssl_protocols        => 'TLSv1.2 TLSv1.1 TLSv1',
      ssl_dhparam          => "/etc/ssl/private/${hostname}.dhparam",
      index_files          => $index_files,
      include_files        => $include_files,
      gzip_types           => $gzip_types,
      error_pages          => {
        404 => '/404.html',
      },
      client_max_body_size => '100m',
      server_cfg_prepend   => {
        resolver                => '208.67.222.222 208.67.220.220 valid=300s',
        resolver_timeout        => '5s',
        root                    => $web_root,
        ssl_stapling            => 'on',
        ssl_stapling_verify     => 'on',
        gzip                    => 'on',
        expires                 => '7d',
        ssl_trusted_certificate => "/etc/letsencrypt/live/${hostname}/fullchain.pem",
      },
      try_files            => $try_files,
      require              => [File['/etc/nginx/conf.d/default.conf'],
                               Exec["${hostname}.dhparam"]],
    }
  } else {
    nginx::resource::server { $hostname:
      ensure               => present,
      server_name          => [$hostname],
      listen_port          => 80,
      listen_options       => $listen_options,
      index_files          => $index_files,
      include_files        => $include_files,
      error_pages          => {
        404 => '/404.html',
      },
      client_max_body_size => '100m',
      server_cfg_prepend   => {
        root => $web_root,
        gzip => 'on'
      },
      try_files            => $try_files,
      require              => File['/etc/nginx/conf.d/default.conf'],
      gzip_types           => $gzip_types,
    }
    nginx::resource::server { "${hostname}-ssl":
      ensure            => absent,
    }
  }
  if $php {
    nginx::resource::location { "${hostname}-php":
      ensure               => present,
      server               => $nginx_server,
      ssl                  => $ssl,
      ssl_only             => $ssl,
      location             => '~ \.php$',
      fastcgi              => 'unix:/run/php/php7.0-fpm.sock',
      proxy                => undef,
      fastcgi_script       => undef,
      location_cfg_prepend => {
        expires            => '-1',
        fastcgi_param      => 'SCRIPT_FILENAME $document_root$fastcgi_script_name',
        fastcgi_index      => 'index.php',
        fastcgi_keep_conn  => 'on',
      },
    }
  }
}

# vim:expandtab ts=2 sw=2
