# domain: the domain under which this repo will be avaiable
# projectroot: where the git repos are listened
# projects_list: which repos to export
define git::web::repo(
    $projectroot,
    $projects_list,
    $sitename='absent'
){
    include git::web
    $gitweb_url = $name
    case $gitweb_sitename {
        'absent': { $gitweb_sitename = "${name} git repository" }
        default: { $gitweb_sitename = $sitename }
    }
    $gitweb_config = "/etc/gitweb.d/${name}.conf"
    file{"${gitweb_config}":
        content => template("git/web/config")
    }
    case $gitweb_webserver {
        'lighttpd': {
            git::web::repo::lighttpd{$name:
                gitweb_url => $gitweb_url,
                projectroot => $projectroot,
                projects_list => $projects_list,
                gitweb_config => $gitweb_config,
            }
        }
        default: { fail("no supported \$gitweb_webserver defined on ${fqdn}, so can't do git::web::repo: ${name}") }
    }

}

define git::web::repo::lighttpd(
    $gitweb_url,
    $projectroot,
    $projects_list,
    $gitweb_config
){
    include git::web::lighttpd
    file{"/etc/lighttpd/gitweb.d/${name}.conf":
        content => template("git/web/lighttpd"),
        notify => Service['lighttpd'],
        owner => root, group => 0, mode => 0644;
    }
    line{"add_include_of_gitwebrepo_${name}":
        line => "include \"gitweb.d/${name}.conf\"",
        file => "/etc/lighttpd/lighttpd-gitweb.conf",
        require => File['/etc/lighttpd/lighttpd-gitweb.conf'],
        notify => Service['lighttpd'],
    }
}

define git::clone(
    $ensure = present,
    $git_repo,
    $projectroot,
    $cloneddir_user='root',
    $cloneddir_group='0',
    $cloneddir_restrict_mode=true
){
    case $ensure {
        absent: { 
            exec{"rm -rf $projectroot":
                onlyif => "test -d  $projectroot",
            }
        }
        default: {
            include git
            exec {"git-clone_${name}":
		            command => "git-clone --no-hardlinks ${git_repo} ${projectroot}",
		            creates => "${projectroot}/.git",
                user => root,
                require => Package['git'],
                notify => Exec["git-clone-chown_${name}"],
	          }
            exec {"git-clone-chown_${name}":
                command => "chown -R ${cloneddir_user}:${cloneddir_group} ${projectroot}",
                refreshonly => true
            }
            if $cloneddir_restrict_mode {
                exec {"git-clone-chmod_${name}":
                    command => "chmod -R o-rwx ${projectroot}",
                    refreshonly => true,
                    subscribe => Exec["git-clone_${name}"],
                }
            }
	      }
    }
}

