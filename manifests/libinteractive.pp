# Support for libinteractive
class omegaup::libinteractive () {
  package { 'openjdk-8-jre-headless':
    ensure => installed,
  }
  remote_file { '/usr/share/java/libinteractive.jar':
    url      => 'https://github.com/omegaup/libinteractive/releases/download/v2.0.27/libinteractive.jar',
    mode     => '644',
    owner    => 'root',
    group    => 'root',
    require  => Package['openjdk-8-jre-headless'],
  }
}
