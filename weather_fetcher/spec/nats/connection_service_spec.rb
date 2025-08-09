# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Nats::ConnectionService do
  let(:mock_nats_client) { double('NATS::Client') }
  let(:mock_jetstream) { double('JetStream') }
  let(:nats_url) { 'nats://localhost:4222' }

  before do
    allow(NATS).to receive(:connect).and_return(mock_nats_client)
    allow(mock_nats_client).to receive(:jetstream).and_return(mock_jetstream)
    allow(mock_jetstream).to receive(:add_stream)
  end

  subject(:service) { described_class.new(nats_url: nats_url) }

  describe '#initialize' do
    it 'uses provided NATS URL' do
      expect(service.nats_url).to eq('nats://localhost:4222')
    end

    it 'uses custom NATS URL when provided' do
      custom_service = described_class.new(nats_url: 'nats://custom:4222')
      expect(custom_service.nats_url).to eq('nats://custom:4222')
    end

    it 'sets up weather stream on initialization' do
      expect(mock_jetstream).to receive(:add_stream).with(
        name: 'WEATHER_STREAM',
        subjects: ['weather.*']
      )
      service
    end

    context 'when NATS_URL is not set' do
      it 'raises an error for nil value' do
        expect { described_class.new(nats_url: nil) }.to raise_error('NATS_URL is not set')
      end

      it 'raises an error for empty string' do
        expect { described_class.new(nats_url: '') }.to raise_error('NATS_URL is not set')
      end
    end
  end

  describe '#client' do
    it 'creates NATS connection with correct URL' do
      expect(NATS).to receive(:connect).with('nats://test:4222').and_return(mock_nats_client)

      test_service = described_class.new(nats_url: 'nats://test:4222')
      expect(test_service.client).to eq(mock_nats_client)
    end

    it 'returns same client instance on multiple calls' do
      client1 = service.client
      client2 = service.client
      expect(client1).to eq(client2)
    end
  end

  describe '#jetstream' do
    it 'returns jetstream from client' do
      expect(service.jetstream).to eq(mock_jetstream)
    end
  end

  describe '#close' do
    it 'closes the NATS connection' do
      expect(mock_nats_client).to receive(:close)
      service.close
    end
  end
end
