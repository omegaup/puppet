# omegaUp.
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
  $database_migration_args = [],
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
  exec { 'systemctl daemon-reload':
    command     => '/bin/systemctl daemon-reload',
    refreshonly => true,
  }

  # Database
  if $local_database {
    dbmigrate { $root:
      ensure                  => latest,
      development_environment => $development_environment,
      database_migration_args => $database_migration_args,
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
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    require => Package['logrotate'],
  }
}

# vim:expandtab ts=2 sw=2
