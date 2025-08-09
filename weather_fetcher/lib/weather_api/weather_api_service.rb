# frozen_string_literal: true

require_relative 'api_base'

module WeatherApi
  class WeatherApiService < ApiBase
    def initialize
      @api_key = ENV.fetch('WEATHER_API_KEY', nil)
      raise 'WEATHER_API_KEY not set' unless @api_key
    end

    def get_weather(city)
      api_get("#{API_BASE_URL}/forecast.json?#{query_params(city)}")
    end

    private

    def query_params(city)
      {
        key: @api_key,
        q: city,
        days: 1,
        lang: 'ru'
      }.map { |k, v| "#{k}=#{v}" }.join('&')
    end
  end
end
