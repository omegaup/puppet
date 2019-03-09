# The omegaUp webhook service.
class omegaup::services::webhook (
  $github_oauth_token = undef,
  $github_webhook_secret = undef,
  $github_branch = defined('$::omegaup::github_branch') ? {
    true  => $::omegaup::github_branch,
    false => 'master',
  },
  $force_database_migration = false,
  $hostname = undef,
  $ssl = undef,
  $manifest_name = 'frontend',
  $services_ensure = running,
  $slack_webhook_url = undef,
) {
  include omegaup::users

  if $force_database_migration {
    if defined('$::omegaup::development_environment') and $::omegaup::development_environment {
      $force_database_migration_args = ['--development-environment']
    } else {
      $force_database_migration_args = ['--databases', 'omegaup']
    }
  } else {
    $force_database_migration_args = []
  }

  # Configuration
  file { '/etc/omegaup/webhook':
    ensure  => 'directory',
  } -> file { '/etc/omegaup/webhook/config.json':
    ensure  => 'file',
    owner   => 'omegaup-deploy',
    group   => 'omegaup-deploy',
    mode    => '0640',
    content => template('omegaup/webhook/config.json.erb'),
    require => User['omegaup-deploy'],
  }
  file { '/etc/sudoers.d/omegaup-deploy':
    ensure  => 'file',
    source  => 'puppet:///modules/omegaup/sudoers-omegaup-deploy',
    owner   => 'root',
    group   => 'root',
    mode    => '0440',
    require => [User['omegaup-deploy'], Package['sudo']],
  }
  file { '/usr/bin/omegaup-webhook':
    ensure => 'file',
    source => 'puppet:///modules/omegaup/omegaup-webhook',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
  file { '/usr/bin/omegaup-deploy-latest':
    ensure  => 'file',
    content => template('omegaup/webhook/omegaup-deploy-latest.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }
  file { '/var/lib/omegaup/webhook':
    ensure  => 'directory',
    owner   => 'omegaup-deploy',
    group   => 'omegaup-deploy',
    mode    => '0750',
    require => [User['omegaup-deploy'], File['/var/lib/omegaup']],
  }

  # Service
  file { '/etc/systemd/system/omegaup-webhook.service':
    ensure  => 'file',
    source  => 'puppet:///modules/omegaup/omegaup-webhook.service',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    require => File['/usr/bin/omegaup-webhook'],
    notify  => Exec['systemctl daemon-reload'],
  }
  service { 'omegaup-webhook':
    ensure     => $services_ensure,
    enable     => true,
    provider   => 'systemd',
    hasrestart => true,
    restart    => '/bin/systemctl reload omegaup-webhook',
    subscribe  => File[
      '/usr/bin/omegaup-webhook',
      '/etc/omegaup/webhook/config.json',
      '/etc/systemd/system/omegaup-webhook.service',
    ],
    require    => File[
      '/etc/systemd/system/omegaup-webhook.service',
      '/usr/bin/omegaup-webhook',
      '/usr/bin/omegaup-deploy-latest',
      '/etc/sudoers.d/omegaup-deploy',
      '/etc/omegaup/webhook/config.json',
      '/var/lib/omegaup/webhook',
    ],
  }

  # Webhook endpoint
  if $hostname != undef and $ssl != undef {
    $server_name = $ssl ? {
        true  => "${hostname}-ssl",
        false => $hostname,
      }
    nginx::resource::location { 'omegaup-org-webhook':
      ensure                => present,
      server                => $server_name,
      ssl                   => $ssl,
      ssl_only              => $ssl,
      location              => '/webhook',
      proxy                 => 'http://localhost:58517',
      proxy_read_timeout    => '90',
      proxy_connect_timeout => '90',
      proxy_set_header      => [
        'Host $host',
        'X-Real-IP $remote_addr',
        'X-Forwarded-For $proxy_add_x_forwarded_for',
        'Proxy ""',
      ],
      rewrite_rules         => [
        '^/webhook/(.*)$ /$1 break',
      ],
    }
  }
}

# vim:expandtab ts=2 sw=2
