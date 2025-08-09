# frozen_string_literal: true

require 'httparty'

module WeatherApi
  class ApiBase
    API_BASE_URL = 'https://api.weatherapi.com/v1'

    def api_get(url)
      send_request('get', url)
    end

    private

    def send_request(http_method, url)
      HTTParty.send(http_method, url, timeout: 10)
    end
  end
end
