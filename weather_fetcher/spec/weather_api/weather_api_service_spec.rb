# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WeatherApi::WeatherApiService do
  let(:service) { described_class.new }

  before do
    allow(ENV).to receive(:fetch).with('WEATHER_API_KEY', nil).and_return('test_api_key_12345')
  end

  describe '#initialize' do
    it 'sets API key from environment or default' do
      expect(service.instance_variable_get(:@api_key)).to be_a(String)
      expect(service.instance_variable_get(:@api_key)).not_to be_empty
      expect(service.instance_variable_get(:@api_key)).to eq('test_api_key_12345')
    end

    context 'when API key is not set' do
      it 'raises an error' do
        allow(ENV).to receive(:fetch).with('WEATHER_API_KEY', nil).and_return(nil)
        expect { described_class.new }.to raise_error('WEATHER_API_KEY not set')
      end
    end
  end

  describe '#get_weather' do
    let(:mock_response) do
      {
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
      }
    end

    before do
      stub_request(:get, /api\.weatherapi\.com/)
        .to_return(
          status: 200,
          body: mock_response.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'makes HTTP request to weather API with required parameters' do
      service.get_weather('Moscow')

      expect(WebMock).to have_requested(:get, /api\.weatherapi\.com/)
        .with(query: hash_including(
          'q' => 'Moscow',
          'days' => '1',
          'lang' => 'ru'
        ))
    end
  end
end
