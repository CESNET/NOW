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

Launch NOW:

    rackup

## Usage

List networks example:

    curl http://now.example.com:9292/network?user=myuser

## Development

    export BUNDLE_GEMFILE=Gemfile.devel
    bundle install
    bundle exec rackup

### Testing

See *.travis.yml*.
