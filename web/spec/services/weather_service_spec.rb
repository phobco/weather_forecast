require 'unit_helper'

RSpec.describe WeatherService do
  let(:service) { described_class.new }
  let(:mock_jetstream) { double('NATS::JetStream') }
  let(:mock_message) { double('NATS::Message', data: '{"hourly_forecast": []}') }

  describe 'constants' do
    it 'has correct stream name' do
      expect(described_class::STREAM_NAME).to eq('WEATHER_STREAM')
    end

    it 'has correct default cities' do
      expect(described_class::DEFAULT_CITIES).to match_array(%w[moscow saint_petersburg])
    end
  end

  describe '#fetch_city_weather' do
    before do
      allow(NatsConnection).to receive(:jetstream_available?).and_return(true)
      allow(NatsConnection).to receive(:jetstream).and_return(mock_jetstream)
    end

    it 'fetches weather data for city successfully' do
      expect(mock_jetstream).to receive(:get_last_msg)
        .with('WEATHER_STREAM', 'weather.moscow')
        .and_return(mock_message)

      result = service.fetch_city_weather('moscow')
      expect(result).to be_a(Hash)
    end

    it 'returns empty data when NATS is not available' do
      allow(NatsConnection).to receive(:jetstream_available?).and_return(false)
      expect(Rails.logger).to receive(:error).with('NATS connection or JetStream not available')

      result = service.fetch_city_weather('moscow')
      expect(result['city']).to eq('Moscow')
      expect(result['hourly_forecast']).to eq([])
    end

    it 'handles NATS::JetStream::Error::NotFound' do
      expect(mock_jetstream).to receive(:get_last_msg)
        .with('WEATHER_STREAM', 'weather.moscow')
        .and_raise(NATS::JetStream::Error::NotFound)
      expect(Rails.logger).to receive(:warn).with('No weather data found for moscow')

      result = service.fetch_city_weather('moscow')
      expect(result['city']).to eq('Moscow')
      expect(result['hourly_forecast']).to eq([])
    end

    it 'handles JSON::ParserError' do
      allow(mock_jetstream).to receive(:get_last_msg).and_return(mock_message)
      allow(JSON).to receive(:parse).and_raise(JSON::ParserError.new('Invalid JSON'))
      expect(Rails.logger).to receive(:error).with('Failed to parse weather data for moscow: Invalid JSON')

      result = service.fetch_city_weather('moscow')
      expect(result['city']).to eq('Moscow')
      expect(result['hourly_forecast']).to eq([])
    end

    it 'handles general errors' do
      expect(mock_jetstream).to receive(:get_last_msg)
        .with('WEATHER_STREAM', 'weather.moscow')
        .and_raise(StandardError.new('Connection failed'))
      expect(Rails.logger).to receive(:error).with('Error fetching weather for moscow: Connection failed')

      result = service.fetch_city_weather('moscow')
      expect(result['city']).to eq('Moscow')
      expect(result['hourly_forecast']).to eq([])
    end
  end

  describe '#empty_weather_data' do
    it 'returns correct default data structure' do
      data = service.send(:empty_weather_data, 'moscow')

      expect(data['city']).to eq('Moscow')
      expect(data['date']).to eq(Time.current.strftime('%Y-%m-%d'))
      expect(data['hourly_forecast']).to eq([])
    end
  end

  describe '#filter_hourly_forecast' do
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

      filtered_data = service.send(:filter_hourly_forecast, weather_data)

      expect(filtered_data['hourly_forecast'].length).to eq(2)
      expect(filtered_data['hourly_forecast'][0]['hour']).to eq(10)
      expect(filtered_data['hourly_forecast'][1]['hour']).to eq(11)
    end

    it 'returns original data when hourly_forecast is not an array' do
      invalid_data = { 'hourly_forecast' => 'not_an_array' }
      result = service.send(:filter_hourly_forecast, invalid_data)

      expect(result).to eq(invalid_data)
    end

    it 'returns original data when hourly_forecast is nil' do
      nil_data = { 'hourly_forecast' => nil }
      result = service.send(:filter_hourly_forecast, nil_data)

      expect(result).to eq(nil_data)
    end
  end

  describe '#fetch_weather_data' do
    before do
      allow(NatsConnection).to receive(:jetstream_available?).and_return(true)
      allow(NatsConnection).to receive(:jetstream).and_return(mock_jetstream)
    end

    it 'fetches data for all default cities' do
      expect(service).to receive(:fetch_city_weather).with('moscow').and_return({ 'city' => 'Moscow' })
      expect(service).to receive(:fetch_city_weather).with('saint_petersburg').and_return({ 'city' => 'Saint Petersburg' })

      result = service.fetch_weather_data

      expect(result).to have_key('moscow')
      expect(result).to have_key('saint_petersburg')
    end

    it 'returns empty data for all cities when NATS is not available' do
      allow(NatsConnection).to receive(:jetstream_available?).and_return(false)
      expect(Rails.logger).to receive(:error).with('NATS connection or JetStream not available').twice

      result = service.fetch_weather_data

      expect(result['moscow']['city']).to eq('Moscow')
      expect(result['moscow']['hourly_forecast']).to eq([])
      expect(result['saint_petersburg']['city']).to eq('Saint_petersburg')
      expect(result['saint_petersburg']['hourly_forecast']).to eq([])
    end
  end
end
