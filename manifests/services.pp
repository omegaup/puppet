# The omegaUp services.
class omegaup::services {
  remote_file { '/var/lib/omegaup/omegaup-backend.tar.xz':
    url      => 'https://github.com/omegaup/quark/releases/download/v1.1.34/omegaup-backend.tar.xz',
    sha1hash => '8dc43c5288aef06a846ac42cd70cc7731ce85be7',
    mode     => '644',
    owner    => 'root',
    group    => 'root',
    notify   => Exec['unlink omegaup-backend'],
    require  => File['/var/lib/omegaup'],
  }

  exec { 'unlink omegaup-backend':
    command     => '/bin/rm -f /usr/bin/omegaup-grader /usr/bin/omegaup-broadcaster',
    user        => 'root',
    notify      => Exec['omegaup-backend'],
    refreshonly => true,
  }

  exec { 'omegaup-backend':
    command     => '/bin/tar -xf /var/lib/omegaup/omegaup-backend.tar.xz -C /',
    user        => 'root',
    notify      => File[
      '/usr/bin/omegaup-grader',
      '/usr/bin/omegaup-broadcaster'
    ],
    refreshonly => true,
  }

  file { ['/usr/bin/omegaup-grader', '/usr/bin/omegaup-broadcaster']:
    require => Exec['omegaup-backend'],
  }

  remote_file { '/var/lib/omegaup/omegaup-gitserver.tar.xz':
    url      => 'https://github.com/omegaup/gitserver/releases/download/v1.4.12/omegaup-gitserver.tar.xz',
    mode     => '644',
    owner    => 'root',
    group    => 'root',
    notify   => Exec['omegaup-gitserver'],
  }

  exec { 'unlink omegaup-gitserver':
    command     => '/bin/rm -f /usr/bin/omegaup-gitserver',
    user        => 'root',
    notify      => Exec['omegaup-gitserver'],
    refreshonly => true,
  }

  exec { 'omegaup-gitserver':
    command     => '/bin/tar -xf /var/lib/omegaup/omegaup-gitserver.tar.xz -C /',
    user        => 'root',
    notify      => File['/usr/bin/omegaup-gitserver'],
    refreshonly => true,
  }

  file { '/usr/bin/omegaup-gitserver':
    require => Exec['omegaup-gitserver'],
  }
}

# vim:expandtab ts=2 sw=2
