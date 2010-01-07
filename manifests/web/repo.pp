# domain: the domain under which this repo will be avaiable
# projectroot: where the git repos are listened
# projects_list: which repos to export
define git::web::repo(
  $ensure = 'present',
  $projectroot,
  $projects_list,
  $sitename = 'absent'
){
  include git::web
  $gitweb_url = $name
  case $gitweb_sitename {
    'absent': { $gitweb_sitename = "${name} git repository" }
    default: { $gitweb_sitename = $sitename }
  }
  $gitweb_config = "/etc/gitweb.d/${name}.conf"
  file{"${gitweb_config}": }
  if $ensure == 'present' {
    File["${gitweb_config}"]{
      content => template("git/web/config")
    }
  } else {
    File["${gitweb_config}"]{
      ensure => absent,
    }
  }
  case $gitweb_webserver {
    'lighttpd': {
      git::web::repo::lighttpd{$name:
        ensure => $ensure,
        gitweb_url => $gitweb_url,
        gitweb_config => $gitweb_config,
      }
    }
    'apache': {
      apache::vhost::gitweb{$gitweb_url:
        ensure => $ensure,
      }
    }
    default: { fail("no supported \$gitweb_webserver defined on ${fqdn}, so can't do git::web::repo: ${name}") }
  }
}
