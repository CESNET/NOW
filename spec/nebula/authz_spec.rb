require 'spec_helper'
require 'opennebula'

describe 'init_authz' do
  userpool = l('userpool')
  netpool = '<VNET_POOL>' + l('network-dual') + '</VNET_POOL>'

  context 'create' do
    let(:client) do
      instance_double('client')
    end
    let(:nebula) do
      nebula_base = Now::Nebula.new($config)
      nebula_base.fake_ctx(client)
      nebula_base
    end

    it 'users and networks' do
      allow(client).to receive(:call).and_return(userpool, netpool)
      expect(client).to receive('call').with('userpool.info')
      expect(client).to receive('call').with('vnpool.info', any_args)
      nebula.init_authz('hawking', Set[:create])

      expect(nebula.uid).to eq(5)
      expect(nebula.authz_vlan).to eq('666' => 'oneadmin')
    end
  end

  context 'get' do
    let(:client) do
      instance_double('client')
    end
    let(:nebula) do
      nebula_base = Now::Nebula.new($config)
      nebula_base.fake_ctx(client)
      nebula_base
    end

    it 'nothing needed' do
      nebula.init_authz('hawking', Set[:get])
      expect(nebula.uid).to eq(nil)
      expect(nebula.authz_vlan).to eq(nil)
    end
  end

  context 'update' do
    let(:client) do
      instance_double('client')
    end
    let(:nebula) do
      nebula_base = Now::Nebula.new($config)
      nebula_base.fake_ctx(client)
      nebula_base
    end

    it 'networks' do
      allow(client).to receive(:call).and_return(netpool)
      expect(client).to receive('call').with('vnpool.info', any_args)
      nebula.init_authz('hawking', Set[:update])

      expect(nebula.uid).to eq(nil)
      expect(nebula.authz_vlan).to eq('666' => 'oneadmin')
    end
  end

  context 'delete' do
    let(:client) do
      instance_double('client')
    end
    let(:nebula) do
      nebula_base = Now::Nebula.new($config)
      nebula_base.fake_ctx(client)
      nebula_base
    end

    it 'nothing needed' do
      nebula.init_authz('hawking', Set[:delete])

      expect(nebula.uid).to eq(nil)
      expect(nebula.authz_vlan).to eq(nil)
    end
  end
end
