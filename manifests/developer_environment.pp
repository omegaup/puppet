# Support for omegaUp in a VM.
class omegaup::developer_environment (
  $root,
  $user,
  $mysql_host,
  $mysql_user,
  $mysql_db,
  $mysql_password,
) {
  # Packages
  package { [ 'vim', 'openssh-client', 'gcc', 'g++', 'python-pip',
              'python3-six', 'python-six', 'silversearcher-ag', 'libgconf-2-4',
              'ca-certificates', 'meld', 'vim-gtk', 'yarn', 'nodejs',
              'docker.io']:
    ensure  => present,
  }
  package { ['python3-pep8', 'pylint3']:
    ensure => absent,
  }
  Anchor['php::begin'] -> exec { 'delete-older-phpunit':
    command => '/bin/rm -f /usr/bin/phpunit',
    unless  => '/usr/bin/test -f /usr/bin/phpunit && /usr/bin/phpunit --atleast-version 8.5.2',
  } -> class { '::php::phpunit':
    source      => 'https://phar.phpunit.de/phpunit-8.5.2.phar',
    auto_update => false,
    path        => '/usr/bin/phpunit',
  } -> Anchor['php::end']
  package { 'closure-linter':
    provider => pip,
  }
  package { 'pycodestyle':
    ensure   => '2.5.0',
    provider => pip3,
    require  => Package['python3-pip'],
  }
  package { 'yapf':
    ensure   => '0.25.0',
    provider => pip3,
    require  => Package['python3-pip'],
  }
  package { 'pyparsing':
    ensure   => '2.3.1',
    provider => pip3,
    require  => Package['python3-pip'],
  }
  package { 'jinja2':
    ensure   => '2.10',
    provider => pip3,
    require  => Package['python3-pip'],
  }
  exec { 'vagrant-docker-permissions':
    command => '/usr/sbin/usermod -aG docker vagrant',
    unless  => '/usr/bin/test -n "$(/usr/bin/groups vagrant | grep docker)"',
    require => Package['docker.io'],
  }

  # Test setup
  config_php { 'test settings':
    ensure   => present,
    settings => {
      'OMEGAUP_DB_USER'     => $mysql_user,
      'OMEGAUP_DB_HOST'     => $mysql_host,
      'OMEGAUP_DB_PASS'     => $mysql_password,
      'OMEGAUP_DB_NAME'     => 'omegaup-test',
      'OMEGAUP_SSLCERT_URL' => '/etc/omegaup/frontend/certificate.pem',
      'OMEGAUP_CACERT_URL'  => '/etc/omegaup/frontend/certificate.pem',
    },
    path     => "${root}/frontend/tests/test_config.php",
    owner    =>  $user,
    group    =>  $user,
  }
  config_php { 'developer settings':
    ensure   => present,
    settings => {
      'OMEGAUP_ENVIRONMENT' => 'development',
    },
    path     => "${root}/frontend/server/config.php",
    require  => Config_php['default settings'],
  }
  file { "${root}/frontend/tests/controllers/omegaup.log":
    ensure => 'file',
    owner  => $user,
    group  => $user,
  }
  file { ["${root}/frontend/tests/controllers/problems",
      "${root}/frontend/tests/controllers/submissions"]:
    ensure => 'directory',
    owner  => $user,
    group  => $user,
  }
  file { '/tmp/omegaup':
    ensure => 'directory',
    owner  => $user,
    group  => $user,
  } -> file { '/tmp/omegaup/problems.git':
    ensure => 'directory',
    owner  => $user,
    group  => $user,
  }

  # Selenium
  remote_file { '/var/lib/omegaup/chromedriver_linux64.zip':
    url      => 'https://chromedriver.storage.googleapis.com/80.0.3987.106/chromedriver_linux64.zip',
    sha1hash => '0e8848ebca11706768fd748dd0282672acad35ac',
    mode     => '644',
    owner    => 'root',
    group    => 'root',
    notify   => Exec['chromedriver'],
    require  => File['/var/lib/omegaup'],
  }
  exec { 'chromedriver':
    command     => '/usr/bin/unzip -o /var/lib/omegaup/chromedriver_linux64.zip chromedriver -d /usr/bin',
    user        => 'root',
    refreshonly => true,
  }
  package { [
    'google-chrome-stable', 'python3-pytest', 'python3-flaky', 'firefox',
  ]:
    ensure  => present,
    require => Apt::Source['google-chrome'],
  }
  package { 'python3-selenium':
    ensure => absent,
  }
  package { 'selenium':
    ensure   => present,
    provider => pip3,
    require  => Package['python3-pip'],
  }
  remote_file { '/var/lib/omegaup/geckodriver_linux64.tar.gz':
    url      => 'https://github.com/mozilla/geckodriver/releases/download/v0.19.1/geckodriver-v0.19.1-linux64.tar.gz',
    sha1hash => '9284c82e1a6814ea2a63841cd532d69b87eb0d6e',
    mode     => '644',
    owner    => 'root',
    group    => 'root',
    notify   => Exec['geckodriver'],
    require  => File['/var/lib/omegaup'],
  }
  exec { 'geckodriver':
    command     => '/bin/tar -xf /var/lib/omegaup/geckodriver_linux64.tar.gz --group=root --owner=root --directory=/usr/bin geckodriver',
    user        => 'root',
    refreshonly => true,
  }

  # phpminiadmin
  file { "${root}/frontend/www/phpminiadmin":
    ensure  => 'directory',
    owner   => $user,
    group   => $user,
    require => Github[$root],
  }
  remote_file { "${root}/frontend/www/phpminiadmin/index.php":
    url      => 'https://raw.githubusercontent.com/osalabs/phpminiadmin/f0a35497e8a29dea595a13987d82eabc1e830d0b/phpminiadmin.php',
    sha1hash => '22d69c7336977cf7b20413d373ede57507c0caaa',
    mode     => '644',
    owner    => $user,
    group    => $user,
    require  => File["${root}/frontend/www/phpminiadmin"],
  }
  file { "${root}/frontend/www/phpminiadmin/phpminiconfig.php":
    content => template('omegaup/developer_environment/phpminiconfig.php.erb'),
    mode    => '0644',
    owner   => $user,
    group   => $user,
    require => File["${root}/frontend/www/phpminiadmin"],
  }

  # composer
  exec { 'getcomposer':
    command => '/usr/bin/curl https://raw.githubusercontent.com/composer/getcomposer.org/76a7060ccb93902cd7576b67264ad91c8a2700e2/web/installer -o - -s | /usr/bin/php -- --quiet',
    user    => 'root',
    creates => '/usr/local/bin/composer',
    require => [Package['curl'], Class['::php']],
  }
  exec { 'composer install':
    command     => '/usr/local/bin/composer install',
    environment => ["HOME=/home/${user}"],
    user        => $user,
    cwd         => $root,
    require     => [Github[$root], Exec['getcomposer']],
  }

  # hook_tools
  docker::image { 'omegaup/hook_tools':
    image_tag => 'latest',
  }

  # MySQL
  file { '/etc/mysql/conf.d/mysql_password.cnf':
    content => template('omegaup/developer_environment/mysql_password.cnf.erb'),
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    require => [Class['::mysql::server']],
  }
}

# vim:expandtab ts=2 sw=2
