require 'unit_helper'

RSpec.describe WeatherService do
  let(:service) { described_class.new }
  let(:mock_nats_client) { double('NATS::Client') }
  let(:mock_jetstream) { double('NATS::JetStream') }

  describe 'constants' do
    it 'has correct stream name' do
      expect(described_class::STREAM_NAME).to eq('WEATHER_STREAM')
    end

    it 'has correct default cities' do
      expect(described_class::DEFAULT_CITIES).to match_array(%w[moscow saint_petersburg])
    end
  end

  describe '#initialize' do
    it 'sets default NATS URL' do
      service = described_class.new
      expect(service.instance_variable_get(:@nats_url)).to eq('nats://localhost:4222')
    end

    it 'sets NATS URL from environment variable' do
      ENV['NATS_URL'] = 'nats://custom:4222'
      service = described_class.new
      expect(service.instance_variable_get(:@nats_url)).to eq('nats://custom:4222')
    ensure
      ENV.delete('NATS_URL')
    end
  end

  describe '#default_weather_data' do
    it 'returns correct default data structure' do
      data = service.send(:default_weather_data, 'moscow')

      expect(data['city']).to eq('Moscow')
      expect(data['date']).to eq(Time.current.strftime('%Y-%m-%d'))
      expect(data['hourly_forecast']).to eq([])
    end
  end

  describe '#filter_current_day_hours' do
    let(:weather_data) do
      {
        'hourly_forecast' => [
          { 'hour' => 10, 'temperature' => 20.0 },
          { 'hour' => 11, 'temperature' => 22.1 },
          { 'hour' => 12, 'temperature' => 25.2 }
        ]
      }
    end

    it 'filters hours correctly when current hour is 11' do
      allow(Time).to receive(:current).and_return(Time.new(2024, 1, 1, 11, 0, 0))

      filtered_data = service.send(:filter_current_day_hours, weather_data)

      expect(filtered_data['hourly_forecast'].length).to eq(2)
      expect(filtered_data['hourly_forecast'][0]['hour']).to eq(10)
      expect(filtered_data['hourly_forecast'][1]['hour']).to eq(11)
    end

    it 'returns original data when hourly_forecast is not an array' do
      invalid_data = { 'hourly_forecast' => 'not_an_array' }
      result = service.send(:filter_current_day_hours, invalid_data)

      expect(result).to eq(invalid_data)
    end

    it 'returns original data when hourly_forecast is nil' do
      nil_data = { 'hourly_forecast' => nil }
      result = service.send(:filter_current_day_hours, nil_data)

      expect(result).to eq(nil_data)
    end
  end

  describe 'NATS connection' do
    before do
      allow(NATS).to receive(:connect).and_return(mock_nats_client)
      allow(mock_nats_client).to receive(:jetstream).and_return(mock_jetstream)
      allow(mock_nats_client).to receive(:close)
    end

    describe '#nats_client' do
      it 'creates NATS connection with correct URL' do
        expect(NATS).to receive(:connect).with('nats://localhost:4222').and_return(mock_nats_client)
        service.send(:nats_client)
      end

      it 'returns cached client on subsequent calls' do
        expect(NATS).to receive(:connect).once.and_return(mock_nats_client)

        service.send(:nats_client)
        service.send(:nats_client)
      end
    end

    describe '#jetstream' do
      it 'creates jetstream from nats client' do
        expect(mock_nats_client).to receive(:jetstream).and_return(mock_jetstream)
        service.send(:jetstream)
      end

      it 'returns cached jetstream on subsequent calls' do
        expect(mock_nats_client).to receive(:jetstream).once.and_return(mock_jetstream)

        service.send(:jetstream)
        service.send(:jetstream)
      end
    end

    describe '#close_connection' do
      it 'closes nats client connection' do
        service.send(:nats_client)
        expect(mock_nats_client).to receive(:close)
        service.send(:close_connection)
      end

      it 'resets cached instances' do
        service.send(:nats_client)
        service.send(:jetstream)

        service.send(:close_connection)

        expect(service.instance_variable_get(:@nats_client)).to be_nil
        expect(service.instance_variable_get(:@jetstream)).to be_nil
      end

      it 'handles nil client gracefully' do
        expect { service.send(:close_connection) }.not_to raise_error
      end
    end
  end

  describe '#fetch_city_weather' do
    let(:mock_message) { double('NATS::Message', data: '{"hourly_forecast": []}') }

    before do
      allow(NATS).to receive(:connect).and_return(mock_nats_client)
      allow(mock_nats_client).to receive(:jetstream).and_return(mock_jetstream)
      allow(mock_nats_client).to receive(:close)
    end

    it 'fetches weather data for city successfully' do
      expect(mock_jetstream).to receive(:get_last_msg)
        .with('WEATHER_STREAM', 'weather.moscow')
        .and_return(mock_message)

      result = service.fetch_city_weather('moscow')
      expect(result).to be_a(Hash)
    end

    it 'handles NATS::JetStream::Error::NotFound' do
      expect(mock_jetstream).to receive(:get_last_msg)
        .with('WEATHER_STREAM', 'weather.moscow')
        .and_raise(NATS::JetStream::Error::NotFound)

      result = service.fetch_city_weather('moscow')
      expect(result['city']).to eq('Moscow')
      expect(result['hourly_forecast']).to eq([])
    end

    it 'handles JSON::ParserError' do
      allow(mock_jetstream).to receive(:get_last_msg).and_return(mock_message)
      allow(JSON).to receive(:parse).and_raise(JSON::ParserError.new('Invalid JSON'))

      result = service.fetch_city_weather('moscow')
      expect(result['city']).to eq('Moscow')
      expect(result['hourly_forecast']).to eq([])
    end

    it 'handles general errors' do
      expect(mock_jetstream).to receive(:get_last_msg)
        .with('WEATHER_STREAM', 'weather.moscow')
        .and_raise(StandardError.new('Connection failed'))

      result = service.fetch_city_weather('moscow')
      expect(result['city']).to eq('Moscow')
      expect(result['hourly_forecast']).to eq([])
    end
  end

  describe '#fetch_weather_data' do
    before do
      allow(NATS).to receive(:connect).and_return(mock_nats_client)
      allow(mock_nats_client).to receive(:jetstream).and_return(mock_jetstream)
      allow(mock_nats_client).to receive(:close)
    end

    it 'fetches data for all default cities' do
      service.send(:nats_client)

      expect(service).to receive(:fetch_city_weather).with('moscow').and_return({ 'city' => 'Moscow' })
      expect(service).to receive(:fetch_city_weather).with('saint_petersburg').and_return({ 'city' => 'Saint Petersburg' })
      expect(mock_nats_client).to receive(:close)

      result = service.fetch_weather_data

      expect(result).to have_key('moscow')
      expect(result).to have_key('saint_petersburg')
    end

    it 'closes connection after fetching data' do
      service.send(:nats_client)

      allow(service).to receive(:fetch_city_weather).and_return({ 'city' => 'Test' })
      expect(mock_nats_client).to receive(:close)
      service.fetch_weather_data
    end

    it 'closes connection even if error occurs' do
      service.send(:nats_client)

      allow(service).to receive(:fetch_city_weather).and_raise(StandardError.new('Test error'))
      expect(mock_nats_client).to receive(:close)

      expect { service.fetch_weather_data }.to raise_error(StandardError)
    end
  end
end
