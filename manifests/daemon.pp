class git::daemon {
    include git
    package{'git-daemon':
        ensure => installed,
        require => Package['git'],
    }

    file{'/etc/init.d/git-daemon':
        source => [ "puppet:///modules/site-git/init.d/${fqdn}/git-daemon",
                    "puppet:///modules/site-git/init.d/git-daemon",
                    "puppet:///modules/git/init.d/git-daemon" ],
        require => Package['git-daemon'],
        owner => root, group => 0, mode => 0755;
    }
    file{'/etc/sysconfig/git-daemon':
        source => [ "puppet:///modules/site-git/sysconfig/${fqdn}/git-daemon",
                    "puppet:///modules/site-git/sysconfig/git-daemon",
                    "puppet:///modules/git/sysconfig/git-daemon" ],
        require => Package['git-daemon'],
        owner => root, group => 0, mode => 0644;
    }
    service{'git-daemon':
        ensure => running,
        enable => true,
        hasstatus => true,
        require => [ File['/etc/sysconfig/git-daemon'], File['/etc/init.d/git-daemon'] ],
    }

    if $use_shorewall {
      include shorewall::rules::gitdaemon
    }
}
