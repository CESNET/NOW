# Network Orchestrator Wrapper

## Overview
Network Orchestrator Wrapper is the component to extend OpenNebula network orchestration capabilities.

## Deployment

### At OpenNebula host

Users need permissions to manage networks (see [OpenNebula API documentation](http://docs.opennebula.org/stable/integration/system_interfaces/api.html#onevnet)).

For example using a group (users need to be added to it):

    onegroup create --name network --resources NET

Or add ACLs manually (where *groupid* is any users group id number):

    groupid=1
    zone='#0'
    oneacl create "@${groupid} NET/* CREATE ${zone}"
    oneacl create "@${groupid} CLUSTER/* ADMIN ${zone}"

NOW needs service admin account(s):

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
    network:
      VN_MAD: vxlan
      BRIDGE: br0
      PHYDEV: eth0

## Usage
Interface is described in *swagger.yaml*.

Neither authentization or authorization is handled by NOW component, only checks for VLAN ID is performed by NOW.

User identity is part of the URL query. NOW will impersonate this user using the configured service admin account. This way the authorization is delegated to OpenNebula.


### List networks

 *curl http://now.example.com:9292/network?user=myuser*

### Create network

 *curl -i -X POST -d '{ "title": "example1", "description": "Example network", "range": { "address": "fc00:0001::/64", "allocation": "dynamic" }, "vlan": 1}' http://now.example.com:9292/network?user=myuser*

### Delete network

 *curl -i -X DELETE http://now.example.com:9292/network/1?user=myuser*

### Update network

Change of the OpenNebula internal attributes are not supported by NOW (VLAN ID, PHYDEV, BRIDGE). OpenNebula permits changing them only under *oneadmin* user or group.

 *curl -i -X PUT -d '{ "title": "New Title", "description": "New description", "range": { "address": "fc00:42::/64", "gateway": "fc00:42::1:1"}}" http://now.example.com:9292/network/42?user=myuser*

## Development

Launch NOW:

    rackup

Using bundler:

    export BUNDLE_GEMFILE=Gemfile.devel
    bundle install
    bundle exec rackup

### Testing

See *.travis.yml*.
