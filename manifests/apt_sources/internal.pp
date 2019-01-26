class omegaup::apt_sources::internal (
  $development_environment,
  $use_elastic_beats,
  $use_newrelic,
) {
  # HHVM
  apt::source { 'hhvm':
    ensure => absent,
  }

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
      location       => 'http://dl.google.com/linux/chrome/deb/',
      release        => 'stable',
      architecture   => 'amd64',
      include        => {
        src          => false,
      },
      key            => {
        key_location => 'https://dl.google.com/linux/linux_signing_key.pub',
        id           => 'EB4C1BFD4F042F6DDDCCEC917721F63BD38B4796'
      }
    }
  }

  # NewRelic
  if ($use_newrelic) {
    apt::source { 'newrelic-infra':
      location       => 'https://download.newrelic.com/infrastructure_agent/linux/apt',
      architecture   => 'amd64',
      include        => {
        src          => false,
      },
      key            => {
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

  # Elastic beats
  if ($use_elastic_beats) {
    apt::source { 'elastic-beats':
      location => 'http://packages.elastic.co/beats/apt',
      release  => 'stable',
      include  => {
        src    => false,
      },
      key      => {
        key_location => 'https://packages.elastic.co/GPG-KEY-elasticsearch',
        id           => '46095ACC8548582C1A2699A9D27D666CD88E42B4',
      }
    }
  }
}

# vim:expandtab ts=2 sw=2
