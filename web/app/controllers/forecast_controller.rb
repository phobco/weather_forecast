
# frozen_string_literal: true

class ForecastController < ApplicationController
  rescue_from StandardError do |e|
    Rails.logger.error "Failed to fetch weather data: #{e.message}"
    @weather_data = {}
    flash.now[:alert] = I18n.t('errors.forecast.failed_to_fetch')
    render :index
  end

  def index
    @weather_data = weather_service.fetch_weather_data
  end

  private

  def weather_service
    @weather_service ||= WeatherService.new
  end
end
