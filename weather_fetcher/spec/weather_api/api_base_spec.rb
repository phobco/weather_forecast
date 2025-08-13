# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WeatherApi::ApiBase do
  let(:api_instance) { described_class.new }

  describe 'constants' do
    it 'defines API base URL' do
      expect(described_class::API_BASE_URL).to eq('https://api.weatherapi.com/v1')
    end
  end

  describe '#api_get' do
    let(:test_url) { 'https://api.weatherapi.com/v1/test' }
    let(:mock_response) { double('HTTParty::Response', code: 200) }

    before do
      allow(HTTParty).to receive(:get).and_return(mock_response)
    end

    it 'makes GET request with HTTParty' do
      expect(HTTParty).to receive(:get).with(test_url, timeout: 10)
      api_instance.api_get(test_url)
    end

    it 'returns HTTParty response' do
      result = api_instance.api_get(test_url)
      expect(result).to eq(mock_response)
    end
  end

  describe '#send_request' do
    let(:test_url) { 'https://api.weatherapi.com/v1/test' }
    let(:mock_response) { double('HTTParty::Response', code: 200) }

    before do
      allow(HTTParty).to receive(:send).and_return(mock_response)
    end

    it 'calls HTTParty with correct parameters' do
      expect(HTTParty).to receive(:send).with('get', test_url, timeout: 10)
      api_instance.send(:send_request, 'get', test_url)
    end

    it 'sets timeout to 10 seconds' do
      expect(HTTParty).to receive(:send).with(anything, anything, timeout: 10)
      api_instance.send(:send_request, 'get', test_url)
    end
  end
end
