# This is an EXAMPLE manifest to configure NOW.
# Do not use as-is. Modify setting according to your environment.
#
# Setting access in OpenNebula is requried (see README.md#at-opennebula-host).
#
# This site.pp example replaces all the apache configuration, which will be
# managed completely by puppet. It is possible to remove the apache part,
# because apache configurations are provided also by the package. Only setting
# the proper password and OpenNebula endpoint in /etc/now.yml is needed.
#

# puppet module install puppetlabs-apache

$now_user='nowadmin'
$now_password = 'the-best-strongest-password-ever'
$one_host = 'localhost'
$phydev = 'eth0'

class { '::apache':
  default_mods        => false,
  default_confd_files => false,

  default_charset     => 'utf-8',
  server_signature    => false,
  server_tokens       => 'full',
  trace_enable        => 'On',
}

class { '::apache::mod::passenger': }

apache::vhost { 'now-site':
  # co-located with rOCCI server
  servername              => 'localhost',
  vhost_name              => 'localhost',
  port                    => 11080,
  docroot                 => '/usr/share/NOW/public',

  log_level               => 'info',

  directories             => {
    path    => '/usr/share/NOW/public',
    options => ['-MultiViews'],
  },

  passenger_user          => 'now',
  passenger_min_instances => 3,

  custom_fragment         => '
  RackEnv production
',
}

file { '/etc/now.yml':
  owner   => 'now',
  group   => 'now',
  mode    => '0600',
  content => "opennebula:
  admin_user: '${now_user}'
  admin_password: '${now_password}'
  endpoint: http://${one_host}:2633/RPC2
network:
  # must be there since OpenNebula 5.0
  AUTOMATIC_VLAN_ID: yes
  PHYDEV: ${phydev}
  VN_MAD: vxlan",
}

File['/etc/now.yml'] -> Apache::Vhost['now-site']
File['/etc/now.yml'] ~> Class['::apache::service']
