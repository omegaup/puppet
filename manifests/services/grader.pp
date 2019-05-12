# The omegaUp grader service.
class omegaup::services::grader (
  $user = undef,
  $hostname = 'localhost',
  $embedded_runner = true,
  $broadcaster_host = 'https://localhost:32672',
  $frontend_host = 'http://localhost',
  $gitserver_shared_token = $::omegaup::gitserver_shared_token,
  $keystore_password = 'omegaup',
  $local_database = true,
  $mysql_db = 'omegaup',
  $mysql_host = 'localhost',
  $mysql_password = undef,
  $mysql_user = 'omegaup',
  $root = '/opt/omegaup',
  $services_ensure = running,
) {
  include omegaup::users
  include omegaup::scripts
  include omegaup::directories

  # libinteractive
  package { 'openjdk-8-jre-headless':
    ensure => installed,
  }
  remote_file { '/usr/share/java/libinteractive.jar':
    url      => 'https://github.com/omegaup/libinteractive/releases/download/v2.0.24/libinteractive.jar',
    sha1hash => 'a6345604d5d61168658660abbf1ade07fb22983a',
    mode     => '644',
    owner    => 'root',
    group    => 'root',
    require  => Package['openjdk-8-jre-headless'],
  }

  # Configuration
  file { '/etc/omegaup/grader/config.json':
    ensure  => 'file',
    owner   => 'omegaup',
    group   => 'omegaup',
    mode    => '0600',
    content => template('omegaup/grader/config.json.erb'),
    require => File['/etc/omegaup/grader'],
  }

  # Runtime files
  file { ['/var/log/omegaup/service.log', '/var/log/omegaup/tracing.json']:
    ensure  => 'file',
    owner   => 'omegaup',
    group   => 'omegaup',
    require => File['/var/log/omegaup'],
  }
  file { ['/var/lib/omegaup/input', '/var/lib/omegaup/cache',
          '/var/lib/omegaup/grade', '/var/lib/omegaup/ephemeral']:
    ensure  => 'directory',
    owner   => 'omegaup',
    group   => 'omegaup',
    require => File['/var/lib/omegaup'],
  }
  exec { 'submissions-directory':
    creates => '/var/lib/omegaup/submissions',
    command => '/usr/bin/mkhexdirs /var/lib/omegaup/submissions www-data omegaup 775',
    require => [File['/var/lib/omegaup'], File['/usr/bin/mkhexdirs'],
                User['www-data']],
  }
  exec { 'submissions-directory-amend':
    command => '/bin/chown omegaup:omegaup /var/lib/omegaup/submissions/* && /bin/chmod 755 /var/lib/omegaup/submissions/*',
    unless  => '/usr/bin/test "$(/usr/bin/stat -c "%U:%G %a" /var/lib/omegaup/submissions/00)" = "omegaup:omegaup 755"',
    require => [Exec['submissions-directory'], User['omegaup']],
  }
  file { '/var/lib/omegaup/problems.git':
    ensure  => 'directory',
    owner   => 'omegaup',
    group   => 'omegaup',
    require => File['/var/lib/omegaup'],
  }
  exec { 'problems.git-directory-amend':
    command => '/bin/chown omegaup:omegaup /var/lib/omegaup/problems.git/* && /bin/chmod 755 /var/lib/omegaup/problems.git/*',
    unless  => [
      '/usr/bin/test -z "$(/bin/ls -A /var/lib/omegaup/problems.git/)"',
      '/usr/bin/test "$(for problem in /var/lib/omegaup/problems.git/*/; do /usr/bin/stat -c "%U:%G %a" "${problem}"; break; done)" = "omegaup:omegaup 755"',
    ],
    require => [File['/var/lib/omegaup/problems.git'], User['omegaup']],
  }

  # Service
  file { '/etc/systemd/system/omegaup-grader.service':
    ensure  => 'file',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('omegaup/grader/omegaup-grader.service.erb'),
    notify  => Exec['systemctl daemon-reload'],
  }
  service { 'omegaup-grader':
    ensure    => $services_ensure,
    enable    => true,
    provider  => 'systemd',
    subscribe => [
      File[
        '/etc/omegaup/grader/config.json',
        '/etc/systemd/system/omegaup-grader.service',
        '/usr/bin/omegaup-grader',
      ],
      Exec['omegaup-backend'],
    ],
    require   => [
      File[
        '/etc/systemd/system/omegaup-grader.service',
        '/var/lib/omegaup/input', '/var/lib/omegaup/cache',
        '/var/lib/omegaup/grade', '/var/log/omegaup/service.log',
        '/usr/bin/omegaup-grader',
        '/var/log/omegaup/tracing.json',
        '/etc/omegaup/grader/config.json',
      ],
      Remote_File['/usr/share/java/libinteractive.jar'],
    ],
  }

  # Git service
  file { '/var/log/omegaup/gitserver.log':
    ensure  => 'file',
    owner   => 'omegaup',
    group   => 'omegaup',
    require => File['/var/log/omegaup'],
  }
  file { '/etc/systemd/system/omegaup-gitserver.service':
    ensure  => 'file',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('omegaup/grader/omegaup-gitserver.service.erb'),
    notify  => Exec['systemctl daemon-reload'],
  }
  service { 'omegaup-gitserver':
    ensure    => $services_ensure,
    enable    => true,
    provider  => 'systemd',
    subscribe => [
      File[
        '/etc/systemd/system/omegaup-gitserver.service',
        '/usr/bin/omegaup-gitserver',
      ],
      Exec['omegaup-gitserver'],
    ],
    require   => [
      File[
        '/etc/systemd/system/omegaup-gitserver.service',
        '/var/log/omegaup/gitserver.log',
        '/var/lib/omegaup/problems.git',
      ],
    ],
  }
}

# vim:expandtab ts=2 sw=2
