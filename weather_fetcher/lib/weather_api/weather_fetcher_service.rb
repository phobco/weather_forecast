# frozen_string_literal: true

require_relative 'weather_api_service'
require_relative '../nats/connection_service'

module WeatherApi
  class WeatherFetcherService
    CITIES_MAP = [
      { name: 'Moscow', key: 'moscow' },
      { name: 'Saint-Petersburg', key: 'saint_petersburg' }
    ].freeze

    def fetch_and_publish
      CITIES_MAP.each do |city|
        weather_data = get_weather_data(city[:name])
        publish_weather_data(city[:key], weather_data)
      end
    rescue StandardError => e
      puts "Failed to publish weather data: #{e.message}"
      raise e
    ensure
      nats_client&.close
    end

    private

    def publish_weather_data(city_key, weather_data)
      topic = "weather.#{city_key}"
      json_data = weather_data.to_json
      jetstream.publish(topic, json_data)
      puts "Published to #{topic}"
    rescue StandardError => e
      puts "Failed to publish to #{topic}: #{e.message}"
      raise
    end

    def get_weather_data(city)
      response = fetch_weather(city)
      hourly_data = extract_hourly_data(response)

      {
        city: city,
        date: Time.now.strftime('%Y-%m-%d'),
        hourly_forecast: hourly_data
      }
    end

    def fetch_weather(city)
      weather_api.get_weather(city)
    end

    def weather_api
      @weather_api ||= WeatherApi::WeatherApiService.new
    end

    def nats_client
      @nats_client ||= Nats::ConnectionService.new
    end

    def jetstream
      nats_client.jetstream
    end

    def extract_hourly_data(response)
      return [] unless response.code == 200

      response.parsed_response.dig('forecast', 'forecastday', 0, 'hour')&.map do |hour|
        {
          hour: Time.parse(hour['time']).hour,
          display_time: Time.parse(hour['time']).strftime('%H:%M'),
          temperature: hour['temp_c']
        }
      end || []
    end
  end
end
