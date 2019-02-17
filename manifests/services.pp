# The omegaUp services.
class omegaup::services {
  remote_file { '/var/lib/omegaup/omegaup-backend.tar.xz':
    url      => 'https://github.com/omegaup/quark/releases/download/v1.1.6/omegaup-backend.tar.xz',
    sha1hash => 'c4b10bff84a93d4e0f2f887a7490103d3aab3cd4',
    mode     => '644',
    owner    => 'root',
    group    => 'root',
    notify   => Exec['unlink omegaup-backend'],
    require  => File['/var/lib/omegaup'],
  }

  exec { 'unlink omegaup-backend':
    command     => '/bin/rm -f /usr/bin/omegaup-grader /usr/bin/omegaup-runner /usr/bin/omegaup-broadcaster',
    user        => 'root',
    notify      => Exec['omegaup-backend'],
    refreshonly => true,
  }

  exec { 'omegaup-backend':
    command     => '/bin/tar -xf /var/lib/omegaup/omegaup-backend.tar.xz -C /',
    user        => 'root',
    notify      => File[
      '/usr/bin/omegaup-grader',
      '/usr/bin/omegaup-runner',
      '/usr/bin/omegaup-broadcaster'
    ],
    refreshonly => true,
  }

  file { ['/usr/bin/omegaup-grader', '/usr/bin/omegaup-runner',
          '/usr/bin/omegaup-broadcaster']:
    require => Exec['omegaup-backend'],
  }

  remote_file { '/usr/bin/omegaup-migrate-problem.xz':
    url      => 'https://github.com/omegaup/gitserver/releases/download/v1.2.0/omegaup-migrate-problem.xz',
    sha1hash => '3880e4dae6790d16bc9a0624fd501b48c4f21a2c',
    mode     => '644',
    owner    => 'root',
    group    => 'root',
    notify   => Exec['omegaup-migrate-problem'],
  }

  exec { 'omegaup-migrate-problem':
    command     => '/usr/bin/unxz --force --keep /usr/bin/omegaup-migrate-problem.xz && chmod 755 /usr/bin/omegaup-migrate-problem',
    user        => 'root',
    notify      => File['/usr/bin/omegaup-migrate-problem'],
    refreshonly => true,
  }

  file { '/usr/bin/omegaup-migrate-problem':
    require => Exec['omegaup-migrate-problem'],
  }

  remote_file { '/usr/bin/omegaup-update-problem.xz':
    url      => 'https://github.com/omegaup/gitserver/releases/download/v1.2.0/omegaup-update-problem.xz',
    sha1hash => 'fd98f3c1f66de2b4dee2af4065a526a0aa88a508',
    mode     => '644',
    owner    => 'root',
    group    => 'root',
    notify   => Exec['omegaup-update-problem'],
  }

  exec { 'omegaup-update-problem':
    command     => '/usr/bin/unxz --force --keep /usr/bin/omegaup-update-problem.xz && chmod 755 /usr/bin/omegaup-update-problem',
    user        => 'root',
    notify      => File['/usr/bin/omegaup-update-problem'],
    refreshonly => true,
  }

  file { '/usr/bin/omegaup-update-problem':
    require => Exec['omegaup-update-problem'],
  }

  remote_file { '/usr/bin/omegaup-gitserver.xz':
    url      => 'https://github.com/omegaup/gitserver/releases/download/v1.3.4/omegaup-gitserver.xz',
    sha1hash => 'bb044a56bdeab728503689eed78181984173d1c1',
    mode     => '644',
    owner    => 'root',
    group    => 'root',
    notify   => Exec['omegaup-gitserver'],
  }

  exec { 'omegaup-gitserver':
    command     => '/usr/bin/unxz --force --keep /usr/bin/omegaup-gitserver.xz && chmod 755 /usr/bin/omegaup-gitserver',
    user        => 'root',
    notify      => File['/usr/bin/omegaup-gitserver'],
    refreshonly => true,
  }

  file { '/usr/bin/omegaup-gitserver':
    require => Exec['omegaup-gitserver'],
  }
}

# vim:expandtab ts=2 sw=2
