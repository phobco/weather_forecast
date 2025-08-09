# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WeatherApi::WeatherFetcherService do
  let(:service) { described_class.new }
  let(:mock_weather_response) do
    double('HTTParty::Response',
           code: 200,
           parsed_response: {
             'forecast' => {
               'forecastday' => [
                 {
                   'hour' => [
                     {
                       'time' => '2025-08-09 00:00',
                       'temp_c' => 18.5
                     },
                     {
                       'time' => '2025-08-09 01:00',
                       'temp_c' => 17.2
                     }
                   ]
                 }
               ]
             }
           })
  end

  let(:mock_nats_client) { double('Nats::ConnectionService') }
  let(:mock_jetstream) { double('JetStream') }

  before do
    allow(service).to receive(:nats_client).and_return(mock_nats_client)
    allow(mock_nats_client).to receive(:jetstream).and_return(mock_jetstream)
    allow(mock_nats_client).to receive(:close)
    allow(mock_jetstream).to receive(:publish)
  end

  describe '#extract_hourly_data' do
    it 'extracts temperature data from weather response' do
      result = service.send(:extract_hourly_data, mock_weather_response)

      expect(result).to be_an(Array)
      expect(result.size).to eq(2)

      expect(result.first).to include(
        hour: 0,
        display_time: '00:00',
        temperature: 18.5
      )

      expect(result.last).to include(
        hour: 1,
        display_time: '01:00',
        temperature: 17.2
      )
    end

    context 'when API returns error status' do
      let(:error_response) { double('HTTParty::Response', code: 403) }

      it 'returns empty array for error responses' do
        result = service.send(:extract_hourly_data, error_response)
        expect(result).to eq([])
      end
    end

    context 'when response has no forecast data' do
      let(:empty_response) do
        double('HTTParty::Response',
               code: 200,
               parsed_response: {})
      end

      it 'returns empty array' do
        result = service.send(:extract_hourly_data, empty_response)
        expect(result).to eq([])
      end
    end
  end

  describe '#get_weather_data' do
    let(:mock_weather_api) { double('WeatherApi::WeatherApiService') }

    before do
      allow(service).to receive(:weather_api).and_return(mock_weather_api)
      allow(mock_weather_api).to receive(:get_weather).and_return(mock_weather_response)
    end

    it 'formats weather data correctly' do
      result = service.send(:get_weather_data, 'Moscow')

      expect(result).to include(
        city: 'Moscow',
        date: Time.now.strftime('%Y-%m-%d')
      )

      expect(result[:hourly_forecast]).to be_an(Array)
      expect(result[:hourly_forecast].size).to eq(2)
    end
  end

  describe '#fetch_and_publish' do
    let(:mock_weather_api) { double('WeatherApi::WeatherApiService') }

    before do
      allow(service).to receive(:weather_api).and_return(mock_weather_api)
      allow(mock_weather_api).to receive(:get_weather).and_return(mock_weather_response)
    end

    it 'processes all default cities' do
      expect(mock_jetstream).to receive(:publish).with('weather.moscow', anything)
      expect(mock_jetstream).to receive(:publish).with('weather.saint_petersburg', anything)

      service.fetch_and_publish
    end

    it 'publishes JSON data to NATS' do
      expect(mock_jetstream).to receive(:publish) do |topic, data|
        expect(topic).to match(/weather\./)
        expect { JSON.parse(data) }.not_to raise_error
      end.twice

      service.fetch_and_publish
    end

    it 'closes NATS connection after publishing' do
      expect(mock_nats_client).to receive(:close)
      service.fetch_and_publish
    end
  end
end
