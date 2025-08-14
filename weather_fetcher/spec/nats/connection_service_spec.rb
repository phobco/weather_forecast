# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Nats::ConnectionService do
  let(:nats_url) { ENV.fetch('NATS_URL', 'nats://test_user:test_password@localhost:4222') }
  let(:service) { described_class.new(nats_url: nats_url) }

  after(:each) do
    service.close if service.respond_to?(:client) && service.client
  end

  describe '#initialize' do
    it 'uses provided NATS URL' do
      expect(service.nats_url).to eq(nats_url)
    end

    it 'uses custom NATS URL when provided' do
      allow_any_instance_of(described_class).to receive(:setup_stream)

      custom_url = 'nats://custom:4222'
      custom_service = described_class.new(nats_url: custom_url)
      expect(custom_service.nats_url).to eq(custom_url)
    end

    it 'creates NATS connection successfully' do
      expect(service.client).to be_a(NATS::Client)
      expect(service.client.connected?).to be true
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
      expect(service.client).to be_a(NATS::Client)
      expect(service.client.connected?).to be true
    end

    it 'returns same client instance on multiple calls' do
      client1 = service.client
      client2 = service.client
      expect(client1).to eq(client2)
    end
  end

  describe '#jetstream' do
    it 'returns jetstream from client' do
      expect(service.jetstream).to be_a(NATS::JetStream)
    end

    it 'returns same jetstream instance on multiple calls' do
      js1 = service.jetstream
      js2 = service.jetstream
      expect(js1).to eq(js2)
    end
  end

  describe '#close' do
    it 'closes the NATS connection' do
      client = service.client
      expect(client.connected?).to be true

      service.close
      expect(client.connected?).to be false
    end
  end

  describe 'real NATS operations' do
    it 'can publish and subscribe to messages' do
      received_messages = []
      subscription = service.client.subscribe('weather.test') do |msg|
        received_messages << msg.data
      end

      sleep(0.1)

      test_message = 'test weather data'
      service.client.publish('weather.test', test_message)

      sleep(0.1)

      expect(received_messages).to include(test_message)

      subscription.unsubscribe
    end
  end
end
