# == Class hiera_consul_yaml::service
#
# This class is meant to be called from hiera_consul_yaml.
# It ensure the service is running.
#
class hiera_consul_yaml::service {

  service { $::hiera_consul_yaml::service_name:
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }
}
