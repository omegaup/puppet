# Creates users needed at runtime.
class omegaup::users {
  user { ['omegaup', 'www-data', 'omegaup-deploy']: ensure => present }
  user { 'omegaup-www':
    ensure => present,
    managehome => true,
  }
}

# vim:expandtab ts=2 sw=2
