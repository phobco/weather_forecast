# frozen_string_literal: true

require 'httparty'

module WeatherApi
  class ApiBase
    API_BASE_URL = 'https://api.weatherapi.com/v1'
    MAX_ATTEMPTS = 3

    def api_get(url)
      send_request('get', url)
    end

    private

    def send_request(http_method, url)
      MAX_ATTEMPTS.times do |attempt|
        puts "Attempt #{attempt + 1}: #{http_method.upcase} #{API_BASE_URL}"
        response = HTTParty.send(http_method, url, timeout: 10)
        puts "Success: #{response.code}"
        return response
      rescue StandardError => e
        puts "Failed to fetch weather data. Error: #{e.message}"
        sleep(attempt * 3)
      end
      raise "Failed after #{MAX_ATTEMPTS} attempts"
    end
  end
end
