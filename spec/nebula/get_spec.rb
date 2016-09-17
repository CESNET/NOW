require 'spec_helper'
require 'opennebula'

describe 'network get' do
  net1 = l('network-example')
  net6a = l('network-ipv6-global')
  net6b = l('network-ipv6-local')
  net_mask1 = l('network-mask1')
  net_mask2 = l('network-mask2')
  nebula_base = Now::Nebula.new($config)
  nebula_base.fake_authz('theuser', Set[:get], {})

  context 'example' do
    let(:client) do
      instance_double('client', call: net1)
    end
    let(:nebula) do
      nebula_base.fake_ctx(client)
      nebula_base
    end
    let(:range) { Now::Range.new(address: IPAddress.parse('192.168.0.4/24'), allocation: 'dynamic', gateway: IPAddress.parse('192.168.0.1')) }

    it 'get raw' do
      vn_generic = OpenNebula::VirtualNetwork.build_xml(0)
      vn = OpenNebula::VirtualNetwork.new(vn_generic, client)
      vn.info

      expect(vn['ID']).to eq('0')
      expect(vn['NAME']).to eq('example')
      expect(vn['UNAME']).to eq('oneadmin')
      expect(vn['GNAME']).to eq('users')
      expect(vn['TEMPLATE/BRIDGE']).to eq('br0')
    end

    it 'get by nebula' do
      network = nebula.get(0)

      expect(network.id).to eq(0)
      expect(network.title).to eq('example')
      expect(network.range).to eq(range)
    end
  end

  context 'IPv6 global' do
    let(:client) do
      instance_double('client', call: net6a)
    end
    let(:nebula) do
      nebula_base.fake_ctx(client)
      nebula_base
    end
    let(:id) { 2 }
    let(:range) { Now::Range.new(address: IPAddress.parse('2001:718:1801:1052::/64'), allocation: 'dynamic', gateway: IPAddress.parse('2001:718:1801:1052::1:1')) }

    it 'get' do
      network = nebula.get(id)

      expect(network.id).to eq(id)
      expect(network.title).to eq('vx1')
      expect(network.range).to eq(range)
    end
  end

  context 'IPv6 local' do
    let(:client) do
      instance_double('client', call: net6b)
    end
    let(:nebula) do
      nebula_base.fake_ctx(client)
      nebula_base
    end
    let(:id) { 3 }
    let(:range) { Now::Range.new(address: IPAddress.parse('fd00::/64'), allocation: 'dynamic', gateway: IPAddress.parse('fd00::1:1')) }

    it 'get' do
      network = nebula.get(id)

      expect(network.id).to eq(id)
      expect(network.title).to eq('vx2')
      expect(network.range).to eq(range)
    end
  end

  context 'mask1' do
    let(:client) do
      instance_double('client', call: net_mask1)
    end
    let(:nebula) do
      nebula_base.fake_ctx(client)
      nebula_base
    end
    let(:id) { 0 }
    let(:range) { Now::Range.new(address: IPAddress.parse('192.168.0.4/24'), allocation: 'dynamic', gateway: IPAddress.parse('192.168.0.1')) }

    it 'get' do
      network = nebula.get(id)

      expect(network.id).to eq(id)
      expect(network.title).to eq('example')
      expect(network.range).to eq(range)
    end
  end

  context 'mask2' do
    let(:client) do
      instance_double('client', call: net_mask2)
    end
    let(:nebula) do
      nebula_base.fake_ctx(client)
      nebula_base
    end
    let(:id) { 0 }
    let(:range) { Now::Range.new(address: IPAddress.parse('192.168.0.4/24'), allocation: 'dynamic', gateway: IPAddress.parse('192.168.0.1')) }

    it 'get' do
      network = nebula.get(id)

      expect(network.id).to eq(id)
      expect(network.title).to eq('example')
      expect(network.range).to eq(range)
    end
  end

  context 'authz' do
    let(:client) do
      instance_double('client', call: net1)
    end
    let(:nebula_noauthz) do
      nebula_base.fake_ctx(client)
      nebula_base.fake_authz('theuser', nil, {})
      nebula_base
    end
    let(:nebula_createauthz) do
      nebula_base.fake_ctx(client)
      nebula_base.fake_authz('theuser', Set[:create], {})
      nebula_base
    end
    let(:range) { Now::Range.new(address: IPAddress.parse('192.168.0.4/24'), allocation: 'dynamic', gateway: IPAddress.parse('192.168.0.1')) }

    it 'no raise' do
      expect { nebula_noauthz.get(0) }.to raise_error(Now::NowError)
    end
    it 'create raise' do
      expect { nebula_createauthz.get(0) }.to raise_error(Now::NowError)
    end
  end
end
