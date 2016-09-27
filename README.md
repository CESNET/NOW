# Network Orchestrator Wrapper

## Overview
Network Orchestrator Wrapper is the component to extend OpenNebula network orchestration capabilities.

## Deployment

### At OpenNebula host

Users need permissions to manage networks (see [OpenNebula API documentation](http://docs.opennebula.org/stable/integration/system_interfaces/api.html#onevnet)).

Direct setting of ACL (where *groupid* is users group id number):

    groupid=1
    zone='#0'
    oneacl create "@${groupid} NET/* CREATE+ADMIN ${zone}"
    oneacl create "@${groupid} CLUSTER/* ADMIN ${zone}"

Alternativelly separated group could be used (users need to be added to it):

    onegroup create --name network --resources NET

    # set this to 'network' group id number
    groupid=100
    oneacl create "@${groupid} NET/* ADMIN ${zone}"
    oneacl create "@${groupid} CLUSTER/* ADMIN #0"

NOW needs service admin account(s) (password must be at least 32 characters long):

    # admin user for impersonation
    oneuser create nowadmin --driver server_cipher 'the-best-strongest-password-ever'
    oneuser chgrp nowadmin oneadmin
    # admin user to read everything (it must be in all users groups or have
    # proper ACLs), it may be different account
    oneuser addgroup nowadmin users

### At NOW host

Configuration is `/etc/now.yaml` or `~/.config/now.yaml`:

    opennebula:
      # admin user used as service account for impersonation
      # (server_cipher driver)
      admin_user: 'nowadmin'
      admin_password: 'the-best-strongest-password-ever'

      # OpenNebula RPC endpoint
      endpoint: http://nebula.example.com:2633/RPC2

      # super user which must be in all user groups to see everything,
      # only read permission is needed (defaults to admin_user)
      super_user: 'nowadmin'

    # parameters for new user networks:
    # * VN_MAD is required
    # * PHYDEV or BRIDGE are required for 'vxlan'
    # * AUTOMATIC_VLAN_ID *must* be there since OpenNebula 5.0
    network:
      AUTOMATIC_VLAN_ID: yes
      VN_MAD: vxlan
      BRIDGE: br0
      PHYDEV: eth0

## Usage
Interface is described in *swagger.yaml*.

Neither authentication or authorization is handled by NOW component, only checks for VLAN ID is performed by NOW.

User identity is part of the URL query. NOW will impersonate this user using the configured service admin account. This way the authorization is delegated to OpenNebula.


### List networks

 *curl http://now.example.com:9292/network?user=myuser*

### Create network

 *curl -i -X POST -d '{ "title": "example1", "description": "Example network", "range": { "address": "fc00:0001::/64", "allocation": "dynamic" }, "vlan": 1}' http://now.example.com:9292/network?user=myuser*

### Delete network

 *curl -i -X DELETE http://now.example.com:9292/network/1?user=myuser*

### Update network

 *curl -i -X PUT -d '{ "title": "New Title", "description": "New description", "range": { "address": "fc00:42::/64", "gateway": "fc00:42::1:1"}}" http://now.example.com:9292/network/42?user=myuser*

See also [Limitations/Update network](#Update network).

## Limitations

### Address ranges

Network is permitted to have only one address range.

### Clusters

Network is permitted to be available only on one cluster.

### IP address

For **IPv4**:

* The IP address should point to the first IP address in the address range lease. If the network address is specified instead, 1 as added to this address to produce valid IP address (beware it can be gateway for the network).
* The first IP address in the range is presented.

For **IPv6**:

* There is required the network address. If IP address is specified, it is converted and network address is used instead.
* Only 64-bit networks are supported by OpenNebula (both global and local fc00::7).
* ULA addresses fc00::/7 are stored as global to make it work (tested on OpenNebula <= 5.1.80).
* The network address is presented.

### Update network

There are limitation for network update:

* Adding or removing IP address requires additional *NET\_ADMIN* privileges on the network.
* Changing address type (IPv4 vs IPv6) has been problematic in OpenNebula 5 beta.
*  (VLAN ID, VN\_MAD, PHYDEV, ...).
* OpenNebula "internal" attributes can't be modified by NOW (VLAN ID, VN\_MAD, PHYDEV, BRIDGE, ...). OpenNebula permits changing them only under oneadmin user or group.

## Development

Launch NOW:

    rackup

Using bundler:

    export BUNDLE_GEMFILE=Gemfile.devel
    bundle install
    bundle exec rackup

### Testing

See *.travis.yml*.
