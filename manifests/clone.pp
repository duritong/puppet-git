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
  Stdlib::HTTPSUrl
    $git_repo,
  Enum['present','absent']
    $ensure                  = present,
  Stdlib::Unixpath
    $projectroot             = $title,
  Optional[String]
    $branch                  = undef,
  Boolean
    $submodules              = false,
  Integer
    $submodule_timeout       = 600,
  Optional[Integer]
    $clone_depth             = undef,
  Optional[Type[Resource]]
    $clone_before            = undef,
  String
    $clone_as_user           = 'root',
  String
    $cloneddir_user          = 'root',
  Variant[String,Integer]
    $clone_as_group          = 0,
  Variant[String,Integer]
    $cloneddir_group         = 0,
  Boolean
    $cloneddir_restrict_mode = true,
  Boolean
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
      if $clone_depth {
        $clone_depth_cmd = "--depth ${clone_depth} "
      } else {
        $clone_depth_cmd = ''
      }
      require git
      $clone_command = "git clone --no-hardlinks ${clone_depth_cmd}${git_repo} ${projectroot}"
      exec {"git-clone_${name}":
        command => $clone_command,
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
