require 'spec_helper'
require 'opennebula'

describe 'network create' do
  nebula_base = Now::Nebula.new($config)

  context 'example' do
    let(:client) do
      instance_double('client', call: '1')
    end
    let(:nebula) do
      nebula_base.ctx = client
      nebula_base
    end
    let(:network) do
      range = Now::Range.new(address: IPAddress.parse('192.168.0.4/24'), gateway: IPAddress.parse('192.168.0.1'))
      Now::Network.new(title: 'example', description: 'Description', range: range)
    end

    it 'name' do
      expect(client).to receive('call').with('vn.allocate', /NAME\s*=\s*"example"\s*\n/, -1)
      id = nebula.create_network(network)
      expect(id).to eq('1')
    end
    it 'gateway' do
      expect(client).to receive('call').with('vn.allocate', /GATEWAY\s*=\s*192.168.0.1\s*\n/, -1)
      id = nebula.create_network(network)
      expect(id).to eq('1')
    end
    it 'ip' do
      expect(client).to receive('call').with('vn.allocate', /IP\s*=\s*192.168.0.4\s*,?\s*\n/, -1)
      id = nebula.create_network(network)
      expect(id).to eq('1')
    end
    it 'ip type' do
      expect(client).to receive('call').with('vn.allocate', /TYPE\s*=\s*IP4\s*,?\s*\n/, -1)
      id = nebula.create_network(network)
      expect(id).to eq('1')
    end
  end
end
