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
  $ensure                  = present,
  $branch                  = false,
  $submodules              = false,
  $submodule_timeout       = 600,
  $clone_before            = 'absent',
  $clone_as_user           = 'root',
  $cloneddir_user          = 'root',
  $clone_as_group          = 0,
  $cloneddir_group         = 0,
  $cloneddir_restrict_mode = true,
  $restorecon              = str2bool($selinux),
){
  case $ensure {
    'absent': {
      exec{"rm -rf ${projectroot}":
        onlyif => "test -d ${projectroot}",
        before => Anchor["git::clone::${name}::finished"],
      }
    }
    default: {
      require ::git
      exec {"git-clone_${name}":
        command => "git clone --no-hardlinks ${git_repo} ${projectroot}",
        creates => "${projectroot}/.git",
        user    => $clone_as_user,
        group   => $clone_as_group,
        cwd     => dirname($projectroot),
        notify  => Exec["git-clone-chown_${name}"],
      }
      Exec["git-clone_${name}"] -> File<| title == $projectroot |>
      if $branch {
        exec{"git_branch_${name}":
          command => "git checkout ${branch}",
          cwd     => $projectroot,
          unless  => "git branch | grep -Eq '^\\* ${branch}$'",
          require => Exec["git-clone_${name}"],
          notify  => Exec["git-clone-chown_${name}"],
        }
      }
      if $clone_before != 'absent' {
        Exec["git-clone_${name}"]{
          before => $clone_before,
        }
        if $branch {
          Exec["git_branch_${name}"]{
            before => $clone_before,
          }
        }
      }

      exec {"git-clone-chown_${name}":
        command     => "chown -R ${cloneddir_user}:${cloneddir_group} ${projectroot};chmod -R og-rwx ${projectroot}/.git",
        refreshonly => true,
        before      => Anchor["git::clone::${name}::finished"],
      }

      if $submodules {
        exec{"git-submodules_${name}":
          command     => 'git submodule init && git submodule update',
          cwd         => $projectroot,
          user        => $cloneddir_user,
          group       => $cloneddir_group,
          timeout     => $submodule_timeout,
          refreshonly => true,
          before      => Anchor["git::clone::${name}::finished"],
          subscribe   => [ Exec["git-clone_${name}"], Exec["git-clone-chown_${name}"] ],
        }
        if $branch {
          Exec["git-submodules_${name}"]{
            require => Exec["git_branch_${name}"]
          }
        }
      }
      if $cloneddir_restrict_mode {
        exec {"git-clone-chmod_${name}":
          command     => "chmod -R o-rwx ${projectroot}",
          refreshonly => true,
          subscribe   => Exec["git-clone_${name}"],
          before      => Anchor["git::clone::${name}::finished"],
        }
        if $submodules {
          Exec["git-clone-chmod_${name}"]{
            require => Exec["git-submodules_${name}"]
          }
        }
      }
      if $restorecon {
        exec{"restorecon -R ${projectroot}":
          refreshonly => true,
          subscribe   => Exec["git-clone_${name}"],
          before      => Anchor["git::clone::${name}::finished"],
        }
      }
    }
  }
  anchor{"git::clone::${name}::finished": }
}
