# gitweb
class git::web {
  include ::git
  package{'gitweb':
    ensure  => present,
    require => Package['git'],
  }

  file{
    '/etc/gitweb.d':
      ensure => directory,
      owner  => root,
      group  => 0,
      mode   => '0755';
    '/etc/gitweb.conf':
      source => [ "puppet:///modules/site_git/web/${::fqdn}/gitweb.conf",
                  "puppet:///modules/site_git/web/gitweb.conf",
                  "puppet:///modules/git/web/gitweb.conf" ],
      require => Package['gitweb'],
      owner   => root,
      group   => 0,
      mode    => '0644';
    "/var/www/git/robots.txt":
      source => [ "puppet:///modules/site_git/web/${::fqdn}/robots.txt",
                  "puppet:///modules/site_git/web/robots.txt",
                  "puppet:///modules/git/web/robots.txt" ],
      require => Package['gitweb'],
      owner   => root,
      group   => 0,
      mode    => '0644';
  }
}
