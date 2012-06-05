class git::daemon::vhosts inherits git::daemon {
  if hiera('git_daemon',true) == 'service' {
    File['/etc/sysconfig/git-daemon']{
      source => [ "puppet:///modules/site_git/sysconfig/${::fqdn}/git-daemon.vhosts",
                  "puppet:///modules/site_git/sysconfig/git-daemon.vhosts",
                  "puppet:///modules/git/sysconfig/git-daemon.vhosts" ],
    }
  } elsif (hiera('git_daemon',true) != false) {
    Xinetd::File['git']{
      source => [ "puppet:///modules/site_git/xinetd.d/${::fqdn}/git.vhosts",
                  "puppet:///modules/site_git/xinetd.d/git.vhosts",
                  "puppet:///modules/git/xinetd.d/git.vhosts" ],
    }
  }
}
