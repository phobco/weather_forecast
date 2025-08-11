# frozen_string_literal: true

require "nats/client"
require "json"

class WeatherService
  STREAM_NAME = "WEATHER_STREAM"
  DEFAULT_CITIES = %w[moscow saint_petersburg].freeze

  def initialize
    @nats_url = ENV.fetch("NATS_URL", nil) || "nats://localhost:4222"
  end

  def fetch_weather_data
    data = {}

    DEFAULT_CITIES.each do |city|
      data[city] = fetch_city_weather(city)
    end

    data
  ensure
    close_connection
  end

  def fetch_city_weather(city)
    subject = "weather.#{city}"

    begin
      message = jetstream.get_last_msg(STREAM_NAME, subject)
      weather_data = JSON.parse(message.data)
      filter_current_day_hours(weather_data)
    rescue NATS::JetStream::Error::NotFound
      Rails.logger.warn "No weather data found for #{city}"
      default_weather_data(city)
    rescue JSON::ParserError => e
      Rails.logger.error "Failed to parse weather data for #{city}: #{e.message}"
      default_weather_data(city)
    rescue StandardError => e
      Rails.logger.error "Error fetching weather for #{city}: #{e.message}"
      default_weather_data(city)
    end
  end

  private

  def nats_client
    @nats_client ||= NATS.connect(@nats_url)
  end

  def jetstream
    @jetstream ||= nats_client.jetstream
  end

  def close_connection
    @nats_client&.close
  ensure
    @nats_client = nil
    @jetstream = nil
  end

  def filter_current_day_hours(weather_data)
    return weather_data unless weather_data["hourly_forecast"].is_a?(Array)

    filtered_forecast = weather_data["hourly_forecast"].select do |hour_data|
      hour_data["hour"] <= Time.current.hour
    end

    weather_data.merge("hourly_forecast" => filtered_forecast)
  end

  def default_weather_data(city)
    {
      "city" => city.capitalize,
      "date" => Time.current.strftime("%Y-%m-%d"),
      "hourly_forecast" => []
    }
  end
end
