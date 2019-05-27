# Support for Filebeat to upload logs.
class omegaup::filebeat () {
  package { 'filebeat':
    ensure => absent,
  }
  file { '/etc/filebeat/filebeat.yml':
    ensure => absent,
  }
  service { 'filebeat':
    ensure => stopped,
  }
}
# vim:expandtab ts=2 sw=2
