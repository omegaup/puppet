# Support for libinteractive
class omegaup::libinteractive () {
  package { 'openjdk-8-jre-headless':
    ensure => installed,
  }
  remote_file { '/usr/share/java/libinteractive.jar':
    url      => 'https://github.com/omegaup/libinteractive/releases/download/v2.0.25/libinteractive.jar',
    sha1hash => '9c70b4cfe7a94843c3fa62e398da82029fd15724',
    mode     => '644',
    owner    => 'root',
    group    => 'root',
    require  => Package['openjdk-8-jre-headless'],
  }
}
