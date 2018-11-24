# The omegaUp cronjobs.
class omegaup::cron (
  $mysql_password = undef,
  $mysql_user = 'omegaup',
  $mysql_host = 'localhost',
  $root = '/opt/omegaup',
) {
  include cron

  user { ['omegaup-cron']: ensure => present }
  file { '/home/omegaup-cron':
    ensure => 'directory',
    owner   => 'omegaup-cron',
    group   => 'omegaup-cron',
    mode    => '600',
    require => User['omegaup-cron'],
  }
  file { '/home/omegaup-cron/.my.cnf':
    ensure  => 'file',
    owner   => 'omegaup-cron',
    group   => 'omegaup-cron',
    mode    => '600',
    content => template('omegaup/cron/my.cnf.template'),
    require => [File['/home/omegaup-cron'], User['omegaup-cron']],
  }
  file { '/var/log/omegaup/cron.log':
    ensure  => 'file',
    owner   => 'omegaup-cron',
    group   => 'omegaup-cron',
    mode    => '644',
    require => [File['/var/log/omegaup'], User['omegaup-cron']],
  }

  package { ['python3', 'python3-mysqldb']:
    ensure  => present,
  }

  cron::daily { 'aggregate_user_feedback':
    command => "${root}/stuff/cron/aggregate_user_feedback.py",
    ensure  => absent,
  }
  cron::daily { 'aggregate_feedback':
    command => "${root}/stuff/cron/aggregate_feedback.py --logfile=/var/log/omegaup/cron.log",
    minute  => 18,
    hour    => 10,
    user    => 'omegaup-cron',
    require => [Github[$root], User['omegaup-cron']],
  }
  cron::hourly { 'update_user_rank':
    command => "${root}/stuff/cron/update_user_rank.py --logfile=/var/log/omegaup/cron.log",
    minute  => 19,
    user    => 'omegaup-cron',
    require => [Github[$root], User['omegaup-cron']],
  }
}

# vim:expandtab ts=2 sw=2
