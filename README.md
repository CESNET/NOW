# Network Orchestrator Wrapper

## Overview
Network Orchestrator Wrapper is the component to extend OpenNebula network orchestration capabilities.

## Deployment

### At OpenNebula host

NOW needs service admin account with all neccessary permissions (see [OpenNebula API documentation](http://docs.opennebula.org/stable/integration/system_interfaces/api.html#onevnet)). Password must be at least 32 characters long:

    oneuser create nowadmin --driver server_cipher 'the-best-strongest-password-ever'
    oneuser chgrp nowadmin oneadmin

    onegroup create --name nowadmin --resources NET

    # set this to 'nowadmin' group id (onegroup list)
    groupid='@100'
    zone='#0'
    oneacl create "${groupid} NET/* MANAGE+ADMIN ${zone}"
    oneacl create "${groupid} CLUSTER/* ADMIN ${zone}"
    oneacl create "${groupid} USER/* MANAGE ${zone}"

    oneuser addgroup nowadmin nowadmin

Alternatively, instead of using 'nowadmin' group, you can set ACL directly on 'nowadmin' account:

    # set this to 'nowadmin' user id (oneuser list)
    userid='#3'
    zone='#0'
    oneacl create "${userid} NET/* MANAGE+ADMIN+CREATE ${zone}"
    oneacl create "${userid} CLUSTER/* ADMIN ${zone}"
    oneacl create "${userid} USER/* MANAGE ${zone}"

### At NOW host

Configuration is `/etc/now.yml` or `~/.config/now.yml`:

    opennebula:
      # admin user used as service account for impersonation
      # (server_cipher driver)
      admin_user: 'nowadmin'
      admin_password: 'the-best-strongest-password-ever'

      # OpenNebula RPC endpoint
      endpoint: http://nebula.example.com:2633/RPC2

    # parameters for new user networks:
    # * VN_MAD is required
    # * PHYDEV or BRIDGE are required for 'vxlan'
    # * AUTOMATIC_VLAN_ID *must* be there since OpenNebula 5.0
    network:
      AUTOMATIC_VLAN_ID: yes
      VN_MAD: vxlan
      BRIDGE: br0
      PHYDEV: eth0

For deployment of NOW using Puppet see example: `example/puppet/site.pp`.

## Usage
Interface is described in *swagger.yaml*.

Authentication is not handled by NOW component. User identity is part of the URL query.

Authorizations performed by NOW:

* VLAN ID is checked for create and update operations
* owner must be the same for update and delete operations

For read operations authorization is delegated to OpenNebula (list, get). NOW impersonates user using the configured service admin account.

### List networks

 *curl http://now.example.com:9292/network?user=myuser*

### Get network info

 *curl http://now.example.com:9292/network/1?user=myuser*

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

* Changing address type (IPv4 vs IPv6) has been problematic in OpenNebula 5 beta.

## Development

Launch NOW:

    rackup

Using bundler:

    export BUNDLE_GEMFILE=Gemfile.devel
    bundle install
    bundle exec rackup

### Testing

See *.travis.yml*.
