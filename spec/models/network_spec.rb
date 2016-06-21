require 'spec_helper'

describe Now::Network do
  context '#type check' do
    it 'no id raises NowError' do
      expect { Now::Network.new }.to raise_error(Now::NowError)
    end
    it 'string range raises NowError' do
      expect { Now::Network.new(id: 0, range: 'eee') }.to raise_error(Now::NowError)
    end
  end

  context '#no addess range' do
    let(:network) { Now::Network.new(id: 0) }
    let(:range) { Now::Range.new(address: IPAddress.parse('fd00::/8')) }
    let(:range2) { Now::Range.new(address: IPAddress.parse('fd00::/8')) }
    let(:hash) { { id: 0 } }
    let(:hash_rich) do
      {
        id: 1,
        title: 'Title 1',
        description: 'Description 1',
        user: 'spike',
        vlan: 100,
        range: {
          address: 'fd00::/8',
        },
        zone: '2',
      }
    end

    it 'is a network' do
      expect(network).to be_kind_of Now::Network
    end
    it 'address range is nil' do
      expect(network.range).to be nil
    end
    it 'is valid' do
      expect(network.valid?).to be true
    end
    it 'still valid with addess range' do
      network.range = range
      expect(network.valid?).to be true
    end
    it 'attributes can be set, rich to_hash works' do
      network.id = 1
      network.title = 'Title 1'
      network.description = 'Description 1'
      network.user = 'spike'
      network.vlan = 100
      network.range = range
      network.zone = '2'

      expect(network.id).to eq(1)
      expect(network.title).to eq('Title 1')
      expect(network.description).to eq('Description 1')
      expect(network.user).to eq('spike')
      expect(network.vlan).to eq(100)
      expect(network.range).to eq(range2)
      expect(network.zone).to eq('2')

      expect(network.to_hash).to eq(hash_rich)
    end
    it 'to_hash works' do
      expect(network.to_hash).to eq(hash)
    end
  end

  context '#basic' do
    let(:range) { Now::Range.new(address: IPAddress.parse('192.168.0.1/24')) }
    let(:network) { Now::Network.new(id: 0, range: range) }
    let(:hash) do
      {
        id: 0,
        range: {
          address: '192.168.0.1/24',
        },
      }
    end

    it 'is a network' do
      expect(network).to be_kind_of Now::Network
    end
    it 'is valid' do
      expect(network.valid?).to be true
    end
    it 'still valid with nil address range' do
      network.range = nil
      expect(network.valid?).to be true
    end
    it 'to_hash works' do
      expect(network.to_hash).to eq(hash)
    end
  end

  context '#basic IPv6' do
    let(:range) { Now::Range.new(address: IPAddress.parse('fd00::/8')) }
    let(:network) { Now::Network.new(id: 1, range: range) }
    let(:hash) do
      {
        id: 1,
        range: {
          address: 'fd00::/8',
        }
      }
    end
    it 'is a network' do
      expect(network).to be_kind_of Now::Network
    end
    it 'is valid' do
      expect(network.valid?).to be true
    end
    it 'still valid with nil address range' do
      network.range = nil
      expect(network.valid?).to be true
    end
    it 'to_hash works' do
      expect(network.to_hash).to eq(hash)
    end
  end

  context '#basic set' do
    let(:range) { Now::Range.new(address: IPAddress.parse('172.16.0.0/12')) }
    let(:network) do
      n = Now::Network.new(id: 2)
      n.range = range
      n.title = 'Title'
      n.description = 'Description'
      n.user = 'fluttershy'
      n
    end
    let(:hash) do
      {
        id: 2,
        title: 'Title',
        description: 'Description',
        user: 'fluttershy',
        range: {
          address: '172.16.0.0/12',
        },
      }
    end

    it 'is a network' do
      expect(network).to be_kind_of Now::Network
    end
    it 'is valid' do
      expect(network.valid?).to be true
    end
    it 'still valid with nil address range' do
      network.range = nil
      expect(network.valid?).to be true
    end
    it 'to_hash works' do
      expect(network.to_hash).to eq(hash)
    end
  end

  context '#basic IPv6 set' do
    let(:range) { Now::Range.new(address: IPAddress.parse('fd00::/8')) }
    let(:network) do
      n = Now::Network.new(id: 2)
      n.range = range
      n.title = 'Title'
      n.description = 'Description'
      n.user = 'fluttershy'
      n
    end
    let(:hash) do
      {
        id: 2,
        title: 'Title',
        description: 'Description',
        user: 'fluttershy',
        range: {
          address: 'fd00::/8',
        },
      }
    end

    it 'is a network' do
      expect(network).to be_kind_of Now::Network
    end
    it 'is valid' do
      expect(network.valid?).to be true
    end
    it 'still valid with nil address range' do
      network.range = nil
      expect(network.valid?).to be true
    end
    it 'to_hash works' do
      expect(network.to_hash).to eq(hash)
    end
  end
end
