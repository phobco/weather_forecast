# frozen_string_literal: true

require 'nats/client'
require 'json'

class WeatherService
  STREAM_NAME = 'WEATHER_STREAM'
  DEFAULT_CITIES = %w[moscow saint_petersburg].freeze

  def fetch_weather_data
    DEFAULT_CITIES.each_with_object({}) do |city, obj|
      obj[city] = fetch_city_weather(city)
    end
  end

  def fetch_city_weather(city)
    subject = "weather.#{city}"

    begin
      unless NatsConnection.jetstream_available?
        Rails.logger.error('NATS connection or JetStream not available')
        return empty_weather_data(city)
      end

      message = jetstream.get_last_msg(STREAM_NAME, subject)
      weather_data = JSON.parse(message.data)
      filter_hourly_forecast(weather_data)
    rescue NATS::JetStream::Error::NotFound
      Rails.logger.warn("No weather data found for #{city}")
      empty_weather_data(city)
    rescue JSON::ParserError => e
      Rails.logger.error("Failed to parse weather data for #{city}: #{e.message}")
      empty_weather_data(city)
    rescue StandardError => e
      Rails.logger.error("Error fetching weather for #{city}: #{e.message}")
      empty_weather_data(city)
    end
  end

  private

  def jetstream
    NatsConnection.jetstream
  end

  def filter_hourly_forecast(weather_data)
    return weather_data unless weather_data['hourly_forecast'].is_a?(Array)

    weather_data.merge('hourly_forecast' => filtered_forecast(weather_data))
  end

  def filtered_forecast(weather_data)
    weather_data['hourly_forecast'].select do |hour_data|
      hour_data['hour'] <= Time.current.hour
    end
  end

  def empty_weather_data(city)
    {
      'city' => city.capitalize,
      'date' => Time.current.strftime('%Y-%m-%d'),
      'hourly_forecast' => []
    }
  end
end
