# install git
class git {
  if versioncmp($facts['os']['release']['major'],'7') > 0 {
    package { 'git-core':
      ensure => present,
    }
  } else {
    package { 'git':
      ensure => present
    }
  }
}
