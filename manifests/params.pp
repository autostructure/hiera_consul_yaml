# == Class hiera_consul_yaml::params
#
# This class is meant to be called from hiera_consul_yaml.
# It sets variables according to platform.
#
class hiera_consul_yaml::params {
  case $::osfamily {
    'Debian': {
      $package_name = 'hiera_consul_yaml'
      $service_name = 'hiera_consul_yaml'
    }
    'RedHat', 'Amazon': {
      $package_name = 'hiera_consul_yaml'
      $service_name = 'hiera_consul_yaml'
    }
    default: {
      fail("${::operatingsystem} not supported")
    }
  }
}
