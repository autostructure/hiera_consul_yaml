# == Class hiera_consul_yaml::install
#
# This class is called from hiera_consul_yaml for install.
#
class hiera_consul_yaml::install {

  package { $::hiera_consul_yaml::package_name:
    ensure => present,
  }
}
