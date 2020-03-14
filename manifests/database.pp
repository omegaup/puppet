# Support for MySQL.
class omegaup::database (
  $root_password,
  $password,
  $development_environment = false,
  $service_provider = 'systemd',
) {
  class { '::mysql::server':
    root_password    => $root_password,
    service_provider => $service_provider,
    package_ensure   => $::lsbdistcodename ? {
      'focal' => 'present',
      default => '8.0.19-1ubuntu18.04',
    },
  }

  mysql::db { 'omegaup':
    user     => 'omegaup',
    password => $password,
    host     => 'localhost',
    grant    => ['SELECT', 'INSERT', 'UPDATE', 'DELETE'],
  }

  if $development_environment {
    mysql::db { 'omegaup-test':
      user     => 'omegaup',
      password => $password,
      host     => 'localhost',
      grant    => ['SELECT', 'INSERT', 'UPDATE', 'DELETE', 'DROP', 'ALTER'],
    }
  }
}

# vim:expandtab ts=2 sw=2
