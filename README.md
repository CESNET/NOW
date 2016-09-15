# Network Orchestrator Wrapper

## Overview
Network Orchestrator Wrapper is the component to extend OpenNebula network orchestration capabilities.

## Admin Usage

At OpenNebula host:

    oneuser create nowadmin --driver server_cipher 'the-best-strongest-password-ever'
    oneuser chgrp nowadmin oneadmin

At NOW host (configuration `/etc/now.yaml` or `~/.config/now.yaml`):

    opennebula:
      # admin user used as service account for impersonation
      # (server_cipher driver)
      admin_user: 'nowadmin'
      admin_password: 'the-best-strongest-password-ever'

      # OpenNebula RPC endpoint
      endpoint: http://nebula.example.com:2633/RPC2

      # super user which must be in all user groups to see everything,
      # only read permission is needed (defaults to admin_user)
      super_user: 'nowadmin_reader'

    # custom parameters for new user networks
    # (PHYDEV and BRIDGE are required)
    network:
      BRIDGE: br0
      PHYDEV: eth0

Launch NOW:

    rackup

## Usage

List networks:

 *curl http://now.example.com:9292/network?user=myuser*

Create network:

 *curl -i -X POST -d '{ "title": "example1", "description": "Example network", "range": { "address": "fc00::0001::/64", "allocation": "dynamic" }, "vlan": 1}' http://now.example.com:9292/network?user=myuser*

Delete network:

 *curl -i -X DELETE http://now.example.com:9292/network/1?user=myuser*

## Development

    export BUNDLE_GEMFILE=Gemfile.devel
    bundle install
    bundle exec rackup

### Testing

See *.travis.yml*.
