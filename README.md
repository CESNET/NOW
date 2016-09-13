# Network Orchestrator

## Overview
This is the component to extend OpenNebula network orchestration capabilities.

## Admin Usage

At OpenNebula host:

    oneuser create nowadmin --driver server_cipher 'the-best-strongest-password-ever'
    oneuser chgrp nowadmin oneadmin

At NOW host (configuration `/etc/now.yaml`):

    opennebula:
      admin_user: 'nowadmin'
      admin_password: 'the-best-strongest-password-ever'
      endpoint: http://nebula.example.com:2633/RPC2
    bridge: br0
    device: eth0

Launch NOW:

    rackup

## Usage

List networks example:

 *curl http://now.example.com:9292/network?user=myuser*

Create the network:

 *curl -i -X POST -d '{ "title": "example1", "description": "Example network", "range": { "address": "fc00::0001::/64", "allocation": "dynamic" }, "vlan": 1}' http://now.example.com:9292/network?user=myuser*


## Development

    export BUNDLE_GEMFILE=Gemfile.devel
    bundle install
    bundle exec rackup

### Testing

See *.travis.yml*.
