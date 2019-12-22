# The omegaUp grader cronjobs.
class omegaup::grader_cron (
  $aws_username,
  $aws_secret_access_key,
  $aws_access_key_id,
) {
  include omegaup::directories
  include cron

  file { '/etc/omegaup/grader/aws_credentials',
    ensure  => 'file',
    owner   => 'omegaup',
    group   => 'omegaup',
    mode    => '0600',
    content => template('omegaup/grader/aws_credentials.erb'),
    require => [
      User['omegaup'],
      File['/etc/omegaup/grader'],
    ],
  }

  file { '/var/lib/aws_results_upload/':
    ensure  => 'directory',
  } -> file { '/var/lib/aws_results_upload/s3put.py':
    ensure => 'file',
    source => 'puppet:///modules/omegaup/s3put.py',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  } -> file { '/var/lib/aws_results_upload/aws_results_upload.py':
    ensure => 'file',
    source => 'puppet:///modules/omegaup/aws_results_upload.py',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  } -> cron::daily { 'aws_results_upload':
    command => '/var/lib/aws_results_upload/aws_results_upload.py --logfile=/var/log/omegaup/cron.log',
    minute  => 14,
    hour    => 1,
    user    => 'omegaup',
    require => [
      User['omegaup'],
      File['/etc/omegaup/grader/aws_credentials'],
    ],
  }
}

# vim:expandtab ts=2 sw=2
