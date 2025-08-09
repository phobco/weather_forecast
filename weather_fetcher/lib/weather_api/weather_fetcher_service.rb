# frozen_string_literal: true

require 'yaml'
require_relative 'weather_api_service'
require_relative '../nats/connection_service'

module WeatherApi
  class WeatherFetcherService
    attr_reader :config_path, :config

    def initialize(config_path = nil)
      @config_path = config_path || default_config_path
      @config = load_config
    end

    def fetch_and_publish
      cities.each do |city|
        weather_data = get_weather_data(city['name'])
        publish_weather_data(city['key'], weather_data)
      end
    rescue StandardError => e
      puts "Failed to publish weather data: #{e.message}"
      raise
    ensure
      nats_client&.close
    end

    def cities
      config['cities']
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

    def default_config_path
      File.expand_path('../../config/weather_config.yml', __dir__)
    end

    def load_config
      raise ArgumentError, "Configuration file not found: #{config_path}" unless File.exist?(config_path)

      config = YAML.safe_load_file(config_path) || {}

      raise ArgumentError, "No cities configured. Please check your config file: #{config_path}" if config['cities'].nil? || config['cities'].empty?

      config
    rescue Psych::SyntaxError => e
      raise ArgumentError, "Invalid YAML syntax in config file: #{e.message}"
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
