require 'spec_helper'

describe Now::Range do
  context '#type check' do
    it 'string address raises NowError' do
      expect { Now::Range.new(address: 'eee') }.to raise_error(Now::NowError)
    end
    it 'no address raises NowError' do
      expect { Now::Range.new }.to raise_error(Now::NowError)
    end
  end

  context '#basic' do
    let(:range) { Now::Range.new(address: IPAddress.parse('192.168.0.1/24')) }
    let(:hash) { { address: '192.168.0.1/24' } }

    it 'is a range' do
      expect(range).to be_kind_of Now::Range
    end
    it 'is valid' do
      expect(range.valid?).to be true
    end
    it 'setting nil address raises error' do
      expect { range.address = nil }.to raise_error(Now::NowError)
    end
    it 'to_hash works' do
      expect(range.to_hash).to eq(hash)
    end
  end

  context '#basic IPv6' do
    let(:range) { Now::Range.new(address: IPAddress.parse('fd00::/8')) }
    let(:hash) { { address: 'fd00::/8' } }

    it 'is a range' do
      expect(range).to be_kind_of Now::Range
    end
    it 'is valid' do
      expect(range.valid?).to be true
    end
    it 'setting nil address raises error' do
      expect { range.address = nil }.to raise_error(Now::NowError)
    end
    it 'to_hash works' do
      expect(range.to_hash).to eq(hash)
    end
  end

  context '#basic set' do
    let(:range) do
      r = Now::Range.new(address: IPAddress.parse('172.16.0.0/12'))
      r.allocation = 'dynamic'
      r
    end
    let(:hash) { { address: '172.16.0.0/12', allocation: 'dynamic' } }

    it 'is a range' do
      expect(range).to be_kind_of Now::Range
    end
    it 'is valid' do
      expect(range.valid?).to be true
    end
    it 'setting nil address raises error' do
      expect { range.address = nil }.to raise_error(Now::NowError)
    end
    it 'to_hash works' do
      expect(range.to_hash).to eq(hash)
    end
  end

  context '#basic IPv6 set' do
    let(:range) do
      r = Now::Range.new(address: IPAddress.parse('fd00::/8'))
      r.allocation = 'dynamic'
      r
    end
    let(:hash) { { address: 'fd00::/8', allocation: 'dynamic' } }

    it 'is a range' do
      expect(range).to be_kind_of Now::Range
    end
    it 'is valid' do
      expect(range.valid?).to be true
    end
    it 'setting nil address raises error' do
      expect { range.address = nil }.to raise_error(Now::NowError)
    end
    it 'to_hash works' do
      expect(range.to_hash).to eq(hash)
    end
  end
end
