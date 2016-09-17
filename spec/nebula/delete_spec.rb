require 'spec_helper'
require 'opennebula'

describe 'network delete' do
  net_id = 54
  nebula_base = Now::Nebula.new($config)
  nebula_base.fake_authz('theuser', Set[:delete], {})

  context do
    let(:client) do
      instance_double('client', call: '<VNET/>')
    end
    let(:nebula) do
      nebula_base.fake_ctx(client)
      nebula_base
    end

    it 'called' do
      expect(client).to receive('call').with('vn.delete', net_id)
      nebula.delete_network(net_id)
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
        expect { nebula_noauthz.delete_network(net_id) }.to raise_error(Now::NowError)
      end
      it 'get authz raise' do
        expect { nebula_getauthz.delete_network(net_id) }.to raise_error(Now::NowError)
      end
    end
  end
end
