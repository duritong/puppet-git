# install git
class git::base {
  package{'git':
    ensure => present,
  }
}
