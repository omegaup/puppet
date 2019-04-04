# The omegaUp PHP frontend.
class omegaup::web_app(
  $additional_php_config_settings = $::omegaup::additional_php_config_settings,
  $development_environment = $::omegaup::development_environment,
  $frontend_proxy_websockets_v1_url = 'http://localhost:39613',
  $frontend_proxy_websockets_url = 'http://localhost:22291',
  $frontend_proxy_grader_url = 'http://localhost:36663',
  $github_ensure = $::omegaup::github_ensure,
  $github_branch = $::omegaup::github_branch,
  $github_repo = $::omegaup::github_repo,
  $github_remotes = $::omegaup::github_remotes,
  $gitserver_shared_token = $::omegaup::gitserver_shared_token,
  $grader_host = $::omegaup::grader_host,
  $hostname = $::omegaup::hostname,
  $mysql_host = $::omegaup::mysql_host,
  $mysql_password = $::omegaup::mysql_password,
  $mysql_user = $::omegaup::mysql_user,
  $php_max_children = $::omegaup::php_max_children,
  $php_max_requests = $::omegaup::php_max_requests,
  $root = $::omegaup::root,
  $services_ensure = $::omegaup::services_ensure,
  $ssl = $::omegaup::ssl,
  $user = $::omegaup::user,
) {
  # Repository
  file { $root:
    ensure => 'directory',
    owner  => $user,
    group  => $user,
  }
  github { $root:
    ensure  => $github_ensure,
    repo    => $github_repo,
    branch  => $github_branch,
    owner   => $user,
    group   => $user,
    remotes => $github_remotes,
    require => [File[$root], Package['git']],
  }
  file { "${root}/.git/hooks/pre-push":
    ensure  => 'link',
    target  => "${root}/stuff/git-hooks/pre-push",
    owner   => $user,
    group   => $user,
    require => Github[$root],
  }

  # Web application
  file { '/var/log/omegaup/omegaup.log':
    ensure  => 'file',
    owner   => 'www-data',
    group   => 'www-data',
    require => File['/var/log/omegaup'],
  }
  file { '/var/log/omegaup/csp.log':
    ensure  => 'file',
    owner   => 'www-data',
    group   => 'www-data',
    require => File['/var/log/omegaup'],
  }
  file { '/var/log/omegaup/jserror.log':
    ensure  => 'file',
    owner   => 'www-data',
    group   => 'www-data',
    require => File['/var/log/omegaup'],
  }
  file { '/var/www/omegaup.com':
    ensure  => 'link',
    target  => "${root}/frontend/www",
    require => [File['/var/www'], Github[$root]],
  }
  file { ["${root}/frontend/www/img",
          "${root}/frontend/www/templates"]:
    ensure  => 'directory',
    owner   => 'www-data',
    group   => 'www-data',
    require => Github[$root],
  }
  $omegaup_url = $ssl ? {
        true  => "https://${hostname}",
        false => "http://${hostname}",
  }
  $omegaup_gitserver_secret_token = $gitserver_shared_token ? {
        undef   => '',
        default => $gitserver_shared_token,
      }
  config_php { 'default settings':
    ensure   => present,
    settings => merge({
      'OMEGAUP_DB_USER'                => $mysql_user,
      'OMEGAUP_DB_HOST'                => $mysql_host,
      'OMEGAUP_DB_PASS'                => $mysql_password,
      'OMEGAUP_DB_NAME'                => 'omegaup',
      'OMEGAUP_URL'                    => $omegaup_url,
      'OMEGAUP_SSLCERT_URL'            => '/etc/omegaup/frontend/certificate.pem',
      'OMEGAUP_CACERT_URL'             => '/etc/omegaup/frontend/certificate.pem',
      'OMEGAUP_GRADER_URL'             => $grader_host,
      'OMEGAUP_GITSERVER_SECRET_TOKEN' => $omegaup_gitserver_secret_token,
    }, $additional_php_config_settings),
    path     => "${root}/frontend/server/config.php",
    owner    => $user,
    group    => $user,
    require  => Github[$root],
  }
  package { 'awscli':
    ensure   => 'latest',
    provider => pip3,
  }
  file { '/etc/nginx/sites-available/omegaup.com-nginx_rewrites.conf':
    content => template('omegaup/web_app/nginx.rewrites.erb'),
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
  }
  class { '::omegaup::web':
    development_environment => $development_environment,
    hostname                => $hostname,
    include_files           => ['/etc/nginx/sites-available/omegaup.com-nginx_rewrites.conf'],
    php_max_children        => $php_max_children,
    php_max_requests        => $php_max_requests,
    services_ensure         => $services_ensure,
    ssl                     => $ssl,
    web_root                => "${root}/frontend/www",
    require                 => File['/etc/nginx/sites-available/omegaup.com-nginx_rewrites.conf'],
  }

  # Documentation
  file { '/var/www/omegaup.com/docs':
    ensure  => 'directory',
    require => [
      File['/var/www/omegaup.com'],
    ],
  }
  remote_file { '/var/lib/omegaup/cppreference.tar.gz':
    url      => 'http://upload.cppreference.com/mwiki/images/3/37/html_book_20170409.tar.gz',
    sha1hash => '4708fb287544e8cfd9d6be56264384016976df94',
    mode     => '644',
    owner    => 'root',
    group    => 'root',
    notify   => Exec['extract-cppreference'],
    require  => File['/var/lib/omegaup'],
  }
  file { '/var/www/omegaup.com/docs/cpp':
    ensure  => 'directory',
    owner   => 'www-data',
    group   => 'www-data',
    require => [
      User['www-data'],
      File['/var/www/omegaup.com/docs'],
    ],
  }
  exec { 'extract-cppreference':
    command     => '/bin/tar -xf /var/lib/omegaup/cppreference.tar.gz --group=omegaup-www --owner=omegaup-www --strip-components=1 --directory=/var/www/omegaup.com/docs/cpp reference',
    user        => 'root',
    require     => [
      Remote_File['/var/lib/omegaup/cppreference.tar.gz'],
      File['/var/www/omegaup.com/docs/cpp'],
      User['www-data'],
    ],
    refreshonly => true,
  }
  remote_file { '/var/lib/omegaup/freepascal-doc.tar.gz':
    url      => 'ftp://ftp.hu.freepascal.org/pub/fpc/dist/3.0.2/docs/doc-html.tar.gz',
    sha1hash => 'b9b9dc3d624d3dd2699e008aa10bd0181d2bda77',
    mode     => '644',
    owner    => 'root',
    group    => 'root',
    notify   => Exec['extract-freepascal-doc'],
    require  => File['/var/lib/omegaup'],
  }
  file { '/var/www/omegaup.com/docs/pas':
    ensure  => 'directory',
    owner   => 'www-data',
    group   => 'www-data',
    require => [
      User['www-data'],
      File['/var/www/omegaup.com/docs'],
    ],
  }
  file { '/var/www/omegaup.com/docs/pas/en':
    ensure  => 'directory',
    owner   => 'www-data',
    group   => 'www-data',
    require => [
      User['www-data'],
      File['/var/www/omegaup.com/docs/pas'],
    ],
  }
  exec { 'extract-freepascal-doc':
    command     => '/bin/tar -xf /var/lib/omegaup/freepascal-doc.tar.gz --group=omegaup-www --owner=omegaup-www --strip-components=1 --directory=/var/www/omegaup.com/docs/pas/en doc',
    user        => 'root',
    require     => [
      Remote_File['/var/lib/omegaup/freepascal-doc.tar.gz'],
      File['/var/www/omegaup.com/docs/pas/en'],
      User['www-data'],
    ],
    refreshonly => true,
  }
  file { '/var/www/omegaup.com/docs/pas/en/index.html':
    ensure  => 'link',
    target  => 'fpctoc.html',
    require => Exec['extract-freepascal-doc'],
  }
}

# vim:expandtab ts=2 sw=2
