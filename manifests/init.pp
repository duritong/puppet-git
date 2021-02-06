# install git
class git {
  package { 'git-core':
    ensure => present,
  }
}
