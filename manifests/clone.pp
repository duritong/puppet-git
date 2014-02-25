# submodules: Whether we should initialize and update
#             submodules as well
#             Default: false
# clone_before: before which resources a cloning should
#               happen. This is releveant in combination
#               with submodules as the exec of submodules
#               requires the `cwd` and you might get a
#               dependency cycle if you manage $projectroot
#               somewhere else.
define git::clone(
  $git_repo,
  $projectroot,
  $ensure                   = present,
  $submodules               = false,
  $clone_before             = 'absent',
  $cloneddir_user           ='root',
  $cloneddir_group          ='0',
  $cloneddir_restrict_mode  = true,
){
  case $ensure {
    absent: {
      exec{"rm -rf ${projectroot}":
        onlyif => "test -d ${projectroot}",
      }
    }
    default: {
      require ::git
      exec {"git-clone_${name}":
        command => "git clone --no-hardlinks ${git_repo} ${projectroot}",
        creates => "${projectroot}/.git",
        user    => root, # we want to clone as root, rename comes later
        notify  => Exec["git-clone-chown_${name}"],
      }
      if $clone_before != 'absent' {
        Exec["git-clone_${name}"]{
          before => $clone_before,
        }
      }
      if $submodules {
        exec{"git-submodules_${name}":
          command     => 'git submodule init && git submodule update',
          cwd         => $projectroot,
          user        => $cloneddir_user,
          refreshonly => true,
          subscribe   => Exec["git-clone_${name}"],
        }
        if $cloneddir_restrict_mode {
          Exec["git-submodules_${name}"]{
            before => Exec["git-clone-chown_${name}"],
          }
        }
      }
      exec {"git-clone-chown_${name}":
        command     => "chown -R ${cloneddir_user}:${cloneddir_group} ${projectroot};chmod -R og-rwx ${projectroot}/.git",
        refreshonly => true
      }
      if $cloneddir_restrict_mode {
        exec {"git-clone-chmod_${name}":
          command     => "chmod -R o-rwx ${projectroot}",
          refreshonly => true,
          subscribe   => Exec["git-clone_${name}"],
          require     => Exec["git-clone-chown_${name}"],
        }
      }
    }
  }
}
