# domain: the domain under which this repo will be avaiable
# projectroot: where the git repos are listened
# projects_list: which repos to export
#
# logmode:
#   - default: Do normal logging including ips
#   - anonym: Don't log ips
define git::web::repo(
  $ensure = 'present',
  $projectroot = 'absent',
  $projects_list = 'absent',
  $logmode = 'default',
  $sitename = 'absent'
){
  if ($ensure == 'present') and (($projects_list == 'absent') or ($projectroot == 'absent')){
    fail("You have to pass \$project_list and \$projectroot for ${name} if it should be present!")
  }
  if $ensure == 'present' { include git::web }
  $gitweb_url = $name
  case $gitweb_sitename {
    'absent': { $gitweb_sitename = "${name} git repository" }
    default: { $gitweb_sitename = $sitename }
  }
  $gitweb_config = "/etc/gitweb.d/${name}.conf"
  file{$gitweb_config: }
  if $ensure == 'present' {
    File[$gitweb_config]{
      content => template('git/web/config.erb')
    }
  } else {
    File[$gitweb_config]{
      ensure => absent,
    }
  }
  case lookup('gitweb_webserver', { default_value => 'none' }) {
    'lighttpd': {
      git::web::repo::lighttpd{$name:
        ensure        => $ensure,
        logmode       => $logmode,
        gitweb_url    => $gitweb_url,
        gitweb_config => $gitweb_config,
      }
    }
    'apache': {
      apache::vhost::gitweb{$gitweb_url:
        ensure  => $ensure,
        logmode => $logmode,
      }
    }
    default: {
      if ($ensure == 'present') {
        fail("no supported gitweb_webserver defined on ${::fqdn}, so can't do git::web::repo: ${name}")
      }
    }
  }
}
