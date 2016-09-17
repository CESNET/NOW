# Network Orchestrator Wrapper

## Overview
Network Orchestrator Wrapper is the component to extend OpenNebula network orchestration capabilities.

## Deployment

### At OpenNebula host

Users need permission to create networks.

NOW needs service admin account(s):

    # admin user for impersonation
    oneuser create nowadmin --driver server_cipher 'the-best-strongest-password-ever'
    oneuser chgrp nowadmin oneadmin
    # admin user to read everything (in all users groups)
    oneuser addgroup nowadmin users

### At NOW host

Cconfiguration is `/etc/now.yaml` or `~/.config/now.yaml`:

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

    # custom parameters for new user networks
    # (PHYDEV and BRIDGE are required)
    network:
      BRIDGE: br0
      PHYDEV: eth0

## Usage
Interface is described in *swagger.yaml*.

Authorization is not handled by NOW component. User identity is part of the URL query. NOW will impersonate this user using the configured service admin account.

### List networks

 *curl http://now.example.com:9292/network?user=myuser*

### Create network

 *curl -i -X POST -d '{ "title": "example1", "description": "Example network", "range": { "address": "fc00::0001::/64", "allocation": "dynamic" }, "vlan": 1}' http://now.example.com:9292/network?user=myuser*

### Delete network

 *curl -i -X DELETE http://now.example.com:9292/network/1?user=myuser*

### Update network

Change of the OpenNebula internal attributes are not supported by NOW (VLAN ID, PHYDEV, BRIGDE). OpenNebula support changing them only under *oneadmin* user or group.

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
