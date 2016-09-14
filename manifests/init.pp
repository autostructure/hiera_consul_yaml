# Class: hiera_consul_yaml
# ===========================
#
# Full description of class hiera_consul_yaml here.
#
# Parameters
# ----------
#
# * `sample parameter`
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
class hiera_consul_yaml (
  $package_name = $::hiera_consul_yaml::params::package_name,
  $service_name = $::hiera_consul_yaml::params::service_name,
) inherits ::hiera_consul_yaml::params {

  # validate parameters here

  class { '::hiera_consul_yaml::install': } ->
  class { '::hiera_consul_yaml::config': } ~>
  class { '::hiera_consul_yaml::service': } ->
  Class['::hiera_consul_yaml']
}
