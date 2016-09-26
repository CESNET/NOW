require 'spec_helper'
require 'opennebula'

describe 'network update' do
  net = l('network-example')
  net_id = 0
  nebula_base = Now::Nebula.new($config)
  nebula_base.fake_authz('theuser', Set[:update], {})

  context 'ctx' do
    let(:client) do
      instance_double('client', call: net)
    end
    let(:nebula) do
      nebula_base.fake_ctx(client)
      nebula_base
    end
    let(:network4) do
      range = Now::Range.new(address: IPAddress.parse('192.168.42.2/24'), gateway: IPAddress.parse('192.168.42.1'))
      Now::Network.new(title: 'New title', description: 'New description', range: range)
    end
    let(:network6) do
      range = Now::Range.new(address: IPAddress.parse('fc00:42::/64'), gateway: IPAddress.parse('fc00:42::1:1'))
      Now::Network.new(title: 'New title', description: 'New description', range: range)
    end

    context 'ipv4' do
      it 'ip' do
        expect(client).to receive('call').with('vn.info', net_id)
        expect(client).to receive('call').with('vn.rename', net_id, 'New title')
        expect(client).to receive('call').with('vn.update_ar', net_id, /IP\s*=\s*192\.168\.42\.2,?\n/)
        expect(client).to receive('call').with('vn.update', net_id, /NETWORK_ADDRESS\s*=\s*192\.168\.42\.0,?\s*\n/, 1)
        id = nebula.update_network(net_id, network4)
        expect(id).to eq(net_id.to_s)
      end
    end

    context 'ipv6' do
      it 'ip' do
        expect(client).to receive('call').with('vn.info', net_id)
        expect(client).to receive('call').with('vn.rename', net_id, 'New title')
        # here is a workaround: using GLOBAL_PREFIX instead of ULA_PREFIX in the code to make it work
        expect(client).to receive('call').with('vn.update_ar', net_id, /GLOBAL_PREFIX\s*=\s*fc00:42::,?\n/)
        expect(client).to receive('call').with('vn.update', net_id, /GATEWAY6\s*=\s*fc00:42::1:1,?\s*\n/, 1)
        id = nebula.update_network(net_id, network6)
        expect(id).to eq(net_id.to_s)
      end
    end

    context 'authz' do
      let(:nebula_noauthz) do
        nebula_base.fake_ctx(client)
        nebula_base.fake_authz('theuser', nil, {})
        nebula_base
      end
      let(:nebula_getauthz) do
        nebula_base.fake_ctx(client)
        nebula_base.fake_authz('theuser', Set[:get], {})
        nebula_base
      end

      it 'no authz raise' do
        expect { nebula_noauthz.update_network(net_id, network4) }.to raise_error(Now::NowError)
      end
      it 'get authz raise' do
        expect { nebula_getauthz.update_network(net_id, network6) }.to raise_error(Now::NowError)
      end
    end
  end
end
