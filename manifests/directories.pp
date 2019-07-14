# Creates directories needed at runtime.
class omegaup::directories {
  file { ['/var/lib/omegaup', '/var/log/omegaup', '/etc/omegaup']:
    ensure => 'directory',
  } -> file { ['/etc/omegaup/grader', '/etc/omegaup/gitserver', '/etc/omegaup/broadcaster']:
    ensure => 'directory',
  }
}

# vim:expandtab ts=2 sw=2
