# basic git-daemon setup
class git::daemon(
  $use_shorewall = false,
) {
  require git
  package{'git-daemon':
    ensure => installed,
  }
  if $use_shorewall {
    include shorewall::rules::gitdaemon
  }
}
