# APT source list.
class omegaup::apt_sources::internal (
  $development_environment,
  $use_newrelic,
) {
  # HHVM
  apt::source { 'hhvm':
    ensure => absent,
  }
  # Elastic beats
  apt::source { 'elastic-beats':
    ensure => absent,
  }

  if $::lsbdistcodename != 'focal' {
    # Nginx
    apt::source { 'nginx':
      location => 'https://nginx.org/packages/mainline/ubuntu',
      repos    => 'nginx',
      key      => '573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62',
    }

    # NPM/yarn
    apt::source { 'nodesource':
      location => 'https://deb.nodesource.com/node_11.x',
      include  => {
        src    => false,
      },
      key      => {
        key_location => 'https://deb.nodesource.com/gpgkey/nodesource.gpg.key',
        id           => '9FD3B784BC1C6FC31A8A0A1C1655A0AB68576280',
      },
    }

    # MySQL
    apt::source { 'mysql':
      location => 'http://repo.mysql.com/apt/ubuntu/',
      repos    => 'mysql-8.0 mysql-tools mysql-apt-config',
      key      => {
        id     => 'A4A9406876FCBD3C456770C88C718D3B5072E1F5',
        server => 'hkp://keyserver.ubuntu.com:80',
      },
      include => {
        src   => false,
        deb   => true,
      },
    }
  }
  apt::source { 'yarn':
    location => 'https://dl.yarnpkg.com/debian/',
    release  => 'stable',
    include  => {
      src    => false,
    },
    key      => {
      key_location => 'https://dl.yarnpkg.com/debian/pubkey.gpg',
      id           => '72ECF46A56B4AD39C907BBB71646B01B86E50310',
    },
  }

  # Development environment
  if ($development_environment) {
    apt::source { 'google-chrome':
      location     => 'http://dl.google.com/linux/chrome/deb/',
      release      => 'stable',
      architecture => 'amd64',
      include      => {
        src          => false,
      },
      key          => {
        key_location => 'https://dl.google.com/linux/linux_signing_key.pub',
        id           => 'EB4C1BFD4F042F6DDDCCEC917721F63BD38B4796'
      }
    }
  }

  # NewRelic
  if ($use_newrelic) {
    apt::source { 'newrelic-infra':
      location     => 'https://download.newrelic.com/infrastructure_agent/linux/apt',
      architecture => 'amd64',
      include      => {
        src          => false,
      },
      key          => {
        key_location => 'https://download.newrelic.com/infrastructure_agent/gpg/newrelic-infra.gpg',
        id           => 'A758B3FBCD43BE8D123A3476BB29EE038ECCE87C',
      },
    }
    apt::source { 'newrelic':
      location => 'http://apt.newrelic.com/debian/',
      release  => 'newrelic',
      repos    => 'non-free',
      include  => {
        src    => false,
      },
      key      => {
        key_location => 'https://download.newrelic.com/548C16BF.gpg',
        id           => 'B60A3EC9BC013B9C23790EC8B31B29E5548C16BF',
      },
    }
  }
}

# vim:expandtab ts=2 sw=2
