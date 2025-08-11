require 'rails_helper'

RSpec.describe ForecastController, type: :controller do
  let(:mock_weather_service) { double('WeatherService') }
  let(:weather_data) do
    {
      'moscow' => {
        'city' => 'Moscow',
        'hourly_forecast' => [
          { 'hour' => 10, 'temperature' => 20.0 }
        ]
      },
      'saint_petersburg' => {
        'city' => 'Saint Petersburg',
        'hourly_forecast' => [
          { 'hour' => 11, 'temperature' => 18.0 }
        ]
      }
    }
  end

  before do
    allow(WeatherService).to receive(:new).and_return(mock_weather_service)
  end

  describe 'GET #index' do
    context 'when weather data is available' do
      before do
        allow(mock_weather_service).to receive(:fetch_weather_data).and_return(weather_data)
      end

      it 'returns http success' do
        get :index
        expect(response).to have_http_status(:success)
      end

      it 'assigns weather data to @weather_data' do
        get :index
        expect(assigns(:weather_data)).to eq(weather_data)
      end

      it 'renders index template' do
        get :index
        expect(response).to render_template(:index)
      end

      it 'calls weather service to fetch data' do
        expect(mock_weather_service).to receive(:fetch_weather_data).once
        get :index
      end
    end

    context 'when weather service raises an error' do
      before do
        allow(mock_weather_service).to receive(:fetch_weather_data).and_raise(StandardError.new('Service unavailable'))
      end

      it 'returns http success' do
        get :index
        expect(response).to have_http_status(:success)
      end

      it 'assigns empty hash to @weather_data' do
        get :index
        expect(assigns(:weather_data)).to eq({})
      end

      it 'sets flash alert message' do
        get :index
        expect(flash.now[:alert]).to eq(I18n.t('errors.forecast.failed_to_fetch'))
      end

      it 'renders index template' do
        get :index
        expect(response).to render_template(:index)
      end
    end

    context 'when weather service returns empty data' do
      before do
        allow(mock_weather_service).to receive(:fetch_weather_data).and_return({})
      end

      it 'returns http success' do
        get :index
        expect(response).to have_http_status(:success)
      end

      it 'assigns empty hash to @weather_data' do
        get :index
        expect(assigns(:weather_data)).to eq({})
      end

      it 'renders index template' do
        get :index
        expect(response).to render_template(:index)
      end
    end
  end

  describe 'private methods' do
    describe '#weather_service' do
      it 'creates new WeatherService instance' do
        expect(WeatherService).to receive(:new).and_return(mock_weather_service)
        controller.send(:weather_service)
      end

      it 'caches the service instance' do
        expect(WeatherService).to receive(:new).once.and_return(mock_weather_service)

        controller.send(:weather_service)
        controller.send(:weather_service)
      end
    end
  end
end
