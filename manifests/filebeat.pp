class omegaup::filebeat (
  $environment,
  $logstash_host,
  $template,
) {
  package { 'filebeat':
    require => Apt::Source['elastic-beats'],
  }
  file { '/etc/filebeat/filebeat.yml':
    ensure   => 'file',
    owner    => 'root',
    group    => 'root',
    mode     => '600',
    content  => template($template),
    require  => Package['filebeat'],
    notify   => Service['filebeat'],
  }
  service { 'filebeat':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    require    => File['/etc/filebeat/filebeat.yml'],
  }
}
# vim:expandtab ts=2 sw=2
