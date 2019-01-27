class omegaup (
  $additional_php_config_settings = {},
  $broadcaster_host = 'http://localhost:39613',
  $development_environment = false,
  $github_ensure = present,
  $github_branch = 'master',
  $github_repo = 'omegaup/omegaup',
  $github_remotes = {},
  $gitserver_shared_token = undef,
  $grader_host = 'https://localhost:21680',
  $hostname = 'localhost',
  $local_database = false,
  $mysql_host = 'localhost',
  $mysql_password = undef,
  $mysql_user = 'omegaup',
  $php_max_children = 36,
  $php_max_requests = 500,
  $root = '/opt/omegaup',
  $services_ensure = running,
  $ssl = false,
  $user = undef,
) {
  include omegaup::users
  include omegaup::scripts
  include omegaup::directories

  # Packages
  package { ['git', 'curl', 'unzip', 'zip', 'sudo', 'python3-pip']:
    ensure  => installed,
    require => [Class['::omegaup::apt_sources']],
  }

  package { 'hhvm':
    ensure  => absent,
    require => [Class['::omegaup::apt_sources']],
  }

  # Common
  exec { 'submissions-directory':
    creates => '/var/lib/omegaup/submissions',
    command => '/usr/bin/mkhexdirs /var/lib/omegaup/submissions www-data www-data',
    require => [File['/var/lib/omegaup'], File['/usr/bin/mkhexdirs'],
                User['www-data']],
  }
  exec { 'systemctl daemon-reload':
    command     => '/bin/systemctl daemon-reload',
    refreshonly => true,
  }

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
  file { '/var/lib/omegaup/problems.git':
    ensure  => 'directory',
    owner   => 'www-data',
    group   => 'www-data',
    require => File['/var/lib/omegaup'],
  }
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
  config_php { 'default settings':
    ensure   => present,
    settings => merge({
      'OMEGAUP_DB_USER'                  => $mysql_user,
      'OMEGAUP_DB_HOST'                  => $mysql_host,
      'OMEGAUP_DB_PASS'                  => $mysql_password,
      'OMEGAUP_DB_NAME'                  => 'omegaup',
      'OMEGAUP_URL'                      => $ssl ? {
        true                             => "https://${hostname}",
        false                            => "http://${hostname}",
      },
      'OMEGAUP_SSLCERT_URL'              => '/etc/omegaup/frontend/certificate.pem',
      'OMEGAUP_CACERT_URL'               => '/etc/omegaup/frontend/certificate.pem',
      'OMEGAUP_GRADER_URL'               => "${grader_host}",
      'OMEGAUP_GITSERVER_SECRET_TOKEN'   => $gitserver_shared_token ? {
        undef                            => '',
        default                          => $gitserver_shared_token,
      },
    }, $additional_php_config_settings),
    path     => "${root}/frontend/server/config.php",
    owner    => $user,
    group    => $user,
    require  => Github[$root],
  }
  exec { 'awscli':
    command  => '/usr/bin/pip3 install --system --upgrade awscli',
    creates  => '/usr/local/bin/aws',
    require  => Package['python3-pip'],
  }
  class { '::omegaup::web':
    development_environment => $development_environment,
    hostname                => $hostname,
    include_files           => ["${root}/frontend/server/nginx.rewrites"],
    php_max_children        => $php_max_children,
    php_max_requests        => $php_max_requests,
    services_ensure         => $services_ensure,
    ssl                     => $ssl,
    web_root                => "${root}/frontend/www",
  }

  # Documentation
  file { '/var/www/omegaup.com/docs':
    ensure => 'directory',
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
    ensure => 'directory',
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
    ensure => 'directory',
    owner   => 'www-data',
    group   => 'www-data',
    require => [
      User['www-data'],
      File['/var/www/omegaup.com/docs'],
    ],
  }
  file { '/var/www/omegaup.com/docs/pas/en':
    ensure => 'directory',
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

  # Database
  if $local_database {
    dbmigrate { $root:
      ensure                  => latest,
      development_environment => $development_environment,
      subscribe               => [Github[$root], Mysql::Db['omegaup']],
    }

    Mysql::Db['omegaup'] -> Class['nginx']

    if $development_environment {
      Mysql::Db['omegaup-test'] ~> Dbmigrate[$root]
    }
  }

  # Development environment
  if $development_environment {
    class { '::omegaup::developer_environment':
      root           => $root,
      user           => $user,
      mysql_host     => $mysql_host,
      mysql_user     => $mysql_user,
      mysql_db       => 'omegaup',
      mysql_password => $mysql_password,
      require        => [Github[$root]],
    }
  }

  # Log management
  package { 'logrotate':
    ensure  => installed,
    require => [Class['::omegaup::apt_sources']],
  }
  file { '/etc/logrotate.d/omegaup':
    ensure  => 'file',
    source  => 'puppet:///modules/omegaup/omegaup.logrotate',
    mode    => '644',
    owner   => 'root',
    group   => 'root',
    require => Package['logrotate'],
  }
}

# vim:expandtab ts=2 sw=2
